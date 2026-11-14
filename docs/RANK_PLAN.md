# Ranked 1v1: plan

Branch: `feature/ranked`. Ships as an **update after 1.0.0** (main stays
releasable; the server must stay backward compatible, old clients keep playing
unranked).

## Decisions
* Sign-in: **Apple and Google** through Supabase Auth.
* Storage: **Supabase** (Postgres, Auth, RLS). The game server writes with the
  service-role key; clients only read the leaderboard.
* Ranked mode: **online 1v1 only**. Ranked rooms: no ad boost, no private room
  codes, no password.

## Leagues, TP and promotion
Two numbers per player:
* **MMR** (hidden Elo, start 1000): matchmaking and the size of TP changes.
* **TP** (visible experience points, 0-100 inside a league).

Leagues: Bronze, Silver, Gold, Diamond, Champion.

| Rule | Value |
|---|---|
| Placement | 5 games; only MMR moves. Placement league from MMR: < 1040 Bronze, 1040+ Silver, 1110+ Gold. Never above Gold. Start at 40 TP. |
| Win | +10..+34 TP (22 between equals). Beating a stronger player pays more. |
| Loss | -8..-28 TP (18 between equals). Losing to a weaker player costs more. |
| Draw (timeout) | No TP change, half-weight Elo. |
| 100 TP | A **promotion match** is offered (best of one, matched against someone of similar MMR). |
| Promotion won | Next league, 25 TP, 3 games of demotion shield. |
| Promotion lost | Back to 75 TP, league stays. |
| Below 0 TP | Demoted a league at 75 TP (not during the shield, never from Bronze). |
| Champion | No promotion match; TP is uncapped; the badge shows the leaderboard position. |
| K factor | 48 in placement, 32 until 30 games, then 24 (20 from 1800). |

Rough pace: an even player gains 4 net TP per win/loss pair, so Bronze to
Silver takes about 3-5 wins in a row or ~15 games at 55 % wins.
All numbers live in `RankRules` ([lib/core/rank/rank.dart](../lib/core/rank/rank.dart)).

## To do
**Done**
- [x] Rank engine (pure Dart) with tests: [lib/core/rank/rank.dart](../lib/core/rank/rank.dart), [test/core/rank_test.dart](../test/core/rank_test.dart)
- [x] Database schema: [supabase/schema.sql](../supabase/schema.sql)

- [x] Server: ranked queue (MMR window 100 + 50 per 10 s, max 600), hidden ranked rooms, no ad boost, leaving counts as a loss, pair limit per hour, sign-in token check in `hello`, rank in `welcome`/`end`, leaderboard message. Tests: [test/net/ranked_test.dart](../test/net/ranked_test.dart)
- [x] Supabase adapters (auth check, profile store, leaderboard) with request-shape tests: [lib/net/server/supabase.dart](../lib/net/server/supabase.dart)
- [x] `bin/server.dart` turns ranked on when `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY` are set

**Needs you (accounts and consoles)**: see [RANK_SETUP_CHECKLIST.md](RANK_SETUP_CHECKLIST.md)
- [ ] Create the Supabase project; run `supabase/schema.sql`.
- [ ] Apple: enable *Sign in with Apple* for the app id, create a Services ID and key.
- [ ] Google: OAuth client ids (iOS, Android, Web) in Google Cloud.
- [ ] Supabase Auth: enable the Apple and Google providers with those keys.
- [ ] Give the server `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` (Render env vars; never in the app).
- [ ] Decide when to leave the free Render plan (cold starts hurt ranked).

**Server**
- [ ] Delete-account endpoint (store requirement) and rate limit for brand-new accounts.
- [ ] Test against a real Supabase project once the keys exist.

**App**
- [ ] Sign-in screen (Apple, Google), sign out, delete account (store requirement).
- [ ] Ranked tab in Online: league badge, TP bar, "Find ranked match".
- [ ] Promotion match banner; result screen with TP and league change.
- [ ] Leaderboard screen; profile shows league.
- [ ] League badge art, TR/EN strings.

**Release**
- [ ] Update privacy policy, App Privacy labels, Play Data safety (accounts, game results).
- [ ] Account deletion flow documented for the stores.
- [ ] Deploy the server first, then ship the app (README rule).
