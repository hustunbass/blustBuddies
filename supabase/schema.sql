-- Ranked 1v1 storage for Boom Pals (Supabase / Postgres).
-- Run in the Supabase SQL editor. Sign-in (Apple, Google) is handled by
-- Supabase Auth; this file only holds the game data.
--
-- Writes happen ONLY from the game server using the service-role key.
-- Clients get read access to the public leaderboard, nothing else.

create table if not exists public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  display_name  text not null check (char_length(display_name) between 2 and 16),
  mmr           int  not null default 1000,
  games         int  not null default 0,
  wins          int  not null default 0,
  league        smallint not null default 0 check (league between 0 and 4), -- bronze..champion
  tp            int  not null default 0,
  promotion     boolean not null default false,
  shield        int  not null default 0,
  season        int  not null default 1,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists profiles_leaderboard_idx
  on public.profiles (season, mmr desc) where games >= 5;

create table if not exists public.ranked_matches (
  id            bigint generated always as identity primary key,
  season        int  not null,
  player_a      uuid not null references public.profiles (id) on delete cascade,
  player_b      uuid not null references public.profiles (id) on delete cascade,
  winner        uuid references public.profiles (id) on delete set null, -- null = draw
  a_mmr_before  int not null,
  b_mmr_before  int not null,
  a_mmr_after   int not null,
  b_mmr_after   int not null,
  reason        text not null default 'normal' check (reason in ('normal', 'leave', 'timeout')),
  created_at    timestamptz not null default now()
);

create index if not exists ranked_matches_a_idx on public.ranked_matches (player_a, created_at desc);
create index if not exists ranked_matches_b_idx on public.ranked_matches (player_b, created_at desc);

-- Public leaderboard: no ids beyond what the app needs, placed players only.
create or replace view public.leaderboard as
  select display_name, league, tp, mmr, games, wins,
         rank() over (partition by season order by mmr desc) as position
  from public.profiles
  where games >= 5;

alter table public.profiles enable row level security;
alter table public.ranked_matches enable row level security;

-- A signed-in player may read his own profile and match history.
drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles for select using (auth.uid() = id);

drop policy if exists "own matches" on public.ranked_matches;
create policy "own matches" on public.ranked_matches for select
  using (auth.uid() in (player_a, player_b));

-- No insert/update/delete policies: only the service role (game server) writes.
grant select on public.leaderboard to anon, authenticated;

-- Records one finished game and both profiles atomically.
create or replace function public.record_ranked_match(
  p_season int, p_a uuid, p_b uuid, p_winner uuid, p_reason text,
  p_a_state jsonb, p_b_state jsonb, p_a_mmr_before int, p_b_mmr_before int
) returns void language plpgsql security definer set search_path = public as $$
begin
  update profiles set
    mmr = (p_a_state->>'mmr')::int, games = (p_a_state->>'games')::int,
    wins = (p_a_state->>'wins')::int, league = (p_a_state->>'league')::int,
    tp = (p_a_state->>'tp')::int, promotion = (p_a_state->>'promotion')::boolean,
    shield = (p_a_state->>'shield')::int, updated_at = now()
  where id = p_a;
  update profiles set
    mmr = (p_b_state->>'mmr')::int, games = (p_b_state->>'games')::int,
    wins = (p_b_state->>'wins')::int, league = (p_b_state->>'league')::int,
    tp = (p_b_state->>'tp')::int, promotion = (p_b_state->>'promotion')::boolean,
    shield = (p_b_state->>'shield')::int, updated_at = now()
  where id = p_b;
  insert into ranked_matches (season, player_a, player_b, winner,
    a_mmr_before, b_mmr_before, a_mmr_after, b_mmr_after, reason)
  values (p_season, p_a, p_b, p_winner, p_a_mmr_before, p_b_mmr_before,
    (p_a_state->>'mmr')::int, (p_b_state->>'mmr')::int, p_reason);
end $$;

-- Only the service role may call it.
revoke all on function public.record_ranked_match from public, anon, authenticated;


-- Coins an admin gives to one player. Insert a row by hand (SQL editor or
-- table editor); the app picks it up the next time the player is signed in
-- and online, adds the coins and the server marks the row as claimed.
--   insert into grants (user_id, coins, note) values ('<user uuid>', 5000, 'tester gift');
create table if not exists public.grants (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  coins      int  not null check (coins > 0 and coins <= 1000000),
  note       text not null default '',
  created_at timestamptz not null default now(),
  claimed_at timestamptz
);

create index if not exists grants_open_idx on public.grants (user_id) where claimed_at is null;

-- Nobody but the game server (service role) reads or writes grants.
alter table public.grants enable row level security;
