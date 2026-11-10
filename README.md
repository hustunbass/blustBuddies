# Blast Buddies

A colourful, original arcade maze-bomber for iOS and Android built with
**Flutter + Flame**. Round "buddy" robots, crates, chain explosions, power-ups,
100 story levels in 10 worlds, Battle mode against bots and online matches for
up to 7 players.

> All art is drawn in code and all characters are original. No assets,
> names or sounds from any commercial game are used. See
> [assets/CREDITS.md](assets/CREDITS.md).

## Run

```bash
flutter pub get
flutter run            # pick an iOS/Android device or simulator
flutter analyze && flutter test
```

Desktop/test controls: arrows or WASD + Space/Enter (E detonates).

Regenerate generated assets:
`python3 tool/gen_audio.py` (placeholder sounds), `python3 tool/gen_icon.py`
(icon source), then `flutter pub run flutter_launcher_icons` and
`flutter pub run flutter_native_splash:create`. Localisation:
`flutter gen-l10n` (also runs on build).

## Features

**Gameplay**

* 13×11 grid; steel walls on the border and at every even/even cell; random
  crates with empty, safe start corners; themed arenas.
* Smooth 4-direction movement with corner assist; bombs (3 s fuse) blast in a
  plus shape, stop at walls, destroy crates and chain-react; the owner can walk
  off a freshly placed bomb, after which it is solid.
* Seven power-ups (30 % drop): extra bomb, range, speed, shield, bomb kick,
  detonator, ghost.
* Enemies: wanderer, BFS chaser, speedster, and a boss at the end of every
  25th level.

**Story**

* 100 levels in 10 worlds with a gentle difficulty curve, a time limit per
  level and **3-star ratings**.
* Story uses **lives**: 5 at most, one regenerates every 30 minutes, a life can
  be bought for 60 coins or earned by watching a rewarded ad.

**Battle**

* Local Battle: you against 1–3 bots (easy / normal / hard), optional 2v2 teams.
* **Daily arena** and **daily quests** that pay coins.
* Online battle on separate devices (see [Online](#online)): room list,
  password rooms, 1v1, 2v2 and 3–7 player free-for-all, **Quick match**, room
  codes to share, 12 emotes (6 free, 6 bought with coins).

**Progression and economy**

* **Coins** from quests, achievements and ads; spent on lives, premium emotes
  and cosmetics.
* **Wardrobe**: hats, faces and body colours, bought with coins (the price
  scales with the item's star tier).
* **Achievements**, statistics and a player profile.
* **Shop** (in-app purchases): four coin packs (`coin_500`, `coin_1500`,
  `coin_4000`, `coin_10000`), a one-time starter pack (`starter_pack`, offered
  for 48 h after the first launch), a first-purchase bonus and the
  non-consumable **remove ads** (`remove_ads`) with *Restore purchases*.
  Catalogue: [lib/core/economy/packages.dart](lib/core/economy/packages.dart);
  the same ids must exist in App Store Connect and Play Console.
* **Ads** (Google AdMob, [lib/core/ads/](lib/core/ads)): rewarded ads (earn
  coins, extra life, start bombs, double reward), an interstitial at story
  result screens and banners in menus. Debug/profile builds always use Google's
  test units; release builds use the live units in
  [ad_config.dart](lib/core/ads/ad_config.dart) (iOS only so far). Players who
  bought *remove ads* see no banners or interstitials.

**Quality of life**

* First-run **tutorial** and welcome flow, how-to-play screen.
* **Control layout editor** (move and resize joystick and bomb buttons),
  sound/music/vibration settings, reduced-motion setting.
* English + Turkish (follows the device, no in-app switch).
* Accessibility: semantic labels on HUD and controls, system text scaling.

## Architecture (feature-first)

```
lib/
  core/        grid model, map generator, blast, BFS, power-ups, bot AI (pure
               Dart); settings, stats, profile, daily quests, economy (wallet,
               lives, packages), store + purchase service, ads, cosmetics,
               emotes, audio/haptics, theme, toasts
  features/
    game/      logic/ GameWorld simulation, entities, level config (pure Dart)
               render/ WorldPainter (vector drawing), cosmetic and power-up art,
                       pooled ParticleSystem
               ui/ BlastGame (Flame host), HUD, joystick, game screen
    menu/      main menu, level select, battle setup, wardrobe, achievements,
               how to play
    daily/     daily arena and quests
    shop/      shop sheet, lives UI, rewarded-ad flows, banner slot
    tutorial/  tutorial flow and welcome dialog
    profile/   profile widgets
    online/    connect form, room list, create-room dialog, quick match, room
               lobby, online game view
    settings/  settings screen, control layout editor
  net/         protocol + snapshot codec (pure Dart), WebSocket client with
               prediction and reconnect, server/ BlastServer (pure dart:io,
               authoritative)
  l10n/        ARB files (en, tr)
bin/server.dart  online server entry point
```

Design choices:

* **Game rules never depend on Flame.** `GameWorld` is a deterministic,
  seedable simulation (cell-space coordinates). `BlastGame` only feeds input,
  ticks the world, and draws it, so rules are unit-tested without an engine.
* **Platform services sit behind interfaces** (`AdService`, `PurchaseService`)
  so screens and tests never touch AdMob or the store directly.
* **Performance:** one canvas scale per frame, reused `Paint`s, no per-entity
  component churn, a fixed-size particle pool, flame state in a flat array, and
  HUD updates only when its snapshot changes. Frame time is capped (`dt ≤ 50 ms`).
  Recording one frame takes about 0.3 ms.
* **Quality:** `flutter_lints` plus a few extra rules; the test suite covers
  rules, bots, economy, store, ads logic, quests, cosmetics, tutorial, UI and
  the whole online stack against a real in-process server.

## Online

Players on different phones connect to one **server**, see its room list and
join a room. The server runs the real `GameWorld` (60 Hz) and streams
snapshots (30 Hz); phones only send input (direction / bomb / detonate), so
nobody can cheat by moving themselves.

Players never run or type a server: the app connects to the hosted server
in [lib/net/server_config.dart](lib/net/server_config.dart)
(`defaultServerUrl`, override with `--dart-define=BLAST_SERVER=wss://...`).
A custom address can still be entered under *Advanced* (testing / LAN).

### Deploying the server (developer)

Free on [Render](https://render.com) (no card needed) with the blueprint
[render.yaml](render.yaml) and the self-contained
[server.Dockerfile](server.Dockerfile):

1. Push this project to a GitHub repository (private is fine).
2. Render → **New → Blueprint** → pick the repo → **Apply**.
3. When the deploy is live, open the shown URL + `/health`
   (→ `blast-buddies ok`). The service runs in Frankfurt (`region` in
   `render.yaml`), close to players in Turkey/Europe.
4. If Render assigned a different URL (name taken), put it into
   `defaultServerUrl` as `wss://<host>` **before** archiving the app.

Free plan limits: the service sleeps after 15 minutes without traffic and
takes about a minute to wake up (measured: 12–13 s for the first request, and
the event loop is slow for a short while afterwards); the app retries for up
to 90 s and shows "waking up the server". Render may restart free services at
any time, which ends running rooms. For no sleep and steadier latency, switch
the service to a paid plan or use [fly.toml](fly.toml) on Fly.io
(`fly deploy --ha=false`, paid).

**Redeploy the server whenever `lib/net/` changes.** Clients talk to
the hosted server, so a new app build and the server must match. Reconnecting
needs the new server; against an older server the client simply behaves as
before (no reconnect).

Local run (testing):

```bash
# use Flutter's bundled Dart; `dart run` fails because of Flutter
# native-asset dependencies, running the file directly works:
"$(dirname "$(which flutter)")/dart" bin/server.dart --port 8080
curl localhost:8080/health   # -> blast-buddies ok
```

### Playing

1. In the app: **Online** → name → **Connect**.
2. **Create room**: player count 2–7, *Teams (2 vs 2)* with 4 players,
   optional password. Or **Quick match** (picks or opens a public room of the
   chosen size, everybody is ready automatically) or join by room code.
3. When the room is full and **everyone** taps *Ready*, a 3-second countdown
   starts (un-ready or leaving cancels it), then the match begins. After the
   match everyone returns to the room and can ready up again (*Rematch*).
4. Watching a rewarded ad before the match gives a small advantage: you start
   with extra bombs for that one match (the room sees a badge). The server
   cannot verify the ad, which is why the advantage is deliberately small.
5. During a match, tap an emote to flash it above your buddy (throttled to one
   per 0.8 s; premium emotes must be owned).

### Reconnecting to a running match

Phones lose their connection all the time (Wi-Fi to mobile handover, tunnel,
lock screen, app switch). A dropped player **keeps their seat**:

* The server issues a random session **token** in `welcome` (`tok`). When a
  socket closes mid-match the buddy stands still for up to **30 s**
  (`BlastServer.reconnectGrace`) and the others get an `away` message
  (a toast "X lost connection").
* The client keeps the match on screen ("Reconnecting…") and retries every
  second for 25 s with `hello {resume: token}`. The server hands the seat to
  the new socket, answers `welcome {resumed: true}`, re-sends `start`
  (`resume: true`) and a full snapshot, and tells the room the player is back
  (`away: false`). The client keeps the same `OnlineMatch` and just re-syncs.
* A **silence watchdog** treats a match as dropped when no packet arrives for
  5 s (snapshots come 30 times a second), because half-open sockets after a
  network switch can otherwise take minutes to time out.
* If the grace time runs out, the match ended meanwhile, or the token is
  unknown, the player is eliminated / sent back with "Connection lost".
  Pressing *Leave* (or leaving the screen) gives the seat up immediately.
* The token only works for the seat it was issued for and is not stored
  anywhere on the server after the connection or room is gone.

### Latency and smoothness

* The client predicts its own player's movement with the same movement code as
  the server and blends in corrections measured against where it was one round
  trip ago (RTT from `ping`/`pong`), so your own buddy reacts instantly. A
  simulation with 50–200 ms latency, jitter and 250 ms stalls showed no visible
  rubber-banding for the local player.
* Other players are drawn about 100 ms behind the newest snapshot and
  interpolated, so they glide even when packets arrive unevenly.
* Frames are not compressed (`permessage-deflate` is off): snapshots are only
  about 400–600 bytes, and compressing each one per client would cost the small
  free-tier CPU more than it saves. TCP_NODELAY is on for both ends.
* What is *not* hidden: bombs (yours and others') appear after the server
  confirmed them, i.e. one round trip later, and a stalled TCP connection
  freezes everyone else until it recovers. Typical RTT to the Frankfurt server
  from Turkey is about 100 ms (p99 ≈ 280 ms).

### Monitoring

`GET /stats` (e.g. `https://blast-buddies-eu.onrender.com/stats`) returns
`online`, `peakOnline` (since the last restart), `inMatch`, `rooms`, `matches`,
`lagMs` (worst event-loop delay of the last minute) and `load` (`ok` < 20 ms,
`busy` < 50 ms, else `overloaded`). The same line is written to the service log
every 5 minutes while anyone is connected. Upgrade the plan when `load` stays
`busy`/`overloaded` during peak hours. Measured locally: 70 simulated players
in 14 rooms use about 7 % of one CPU core.

### Server rules

Passwords are stored as salted SHA-256 hashes only; 5 wrong passwords per
minute per connection, then `tooManyAttempts`; names/room names are
length-limited and sanitised; frames > 4 KB and invalid input are rejected;
a player who leaves/disconnects for good mid-match is eliminated; empty rooms
are deleted. In 2v2, slots 1+3 (top corners) face 2+4 (bottom corners) and
blasts hurt teammates too (friendly fire). Use `wss://` when hosting on the
internet (Render and Fly.io provide it; elsewhere put Caddy/nginx in front).

## Varsayımlar (Assumptions)

* Flame is used as the render/loop host; the virtual joystick and bomb button
  are Flutter widgets overlaid on the game (better safe-area and
  accessibility handling than in-engine widgets). The joystick is 4-direction.
* Coordinates: the grid is 13 columns × 11 rows including the border; "even
  row/column intersections" is read as 0-based even x and even y.
* Story: lives (hearts), score and upgrades (except shield) carry between
  levels within a run; restarting a level resets them. Time limit shrinks with
  the world number.
* Battle players have 1 life; the round ends when ≤ 1 is alive or after
  3 minutes (draw). Bots are heuristic (flee blasts, bomb crates/opponents when
  an escape exists).
* Local Battle has exactly one human (1–3 bots); playing with friends is done
  through Online mode on separate devices.
* Audio files are synthesized placeholders (CC0). Icon/splash are generated
  from `tool/gen_icon.py`; replace with final art before release.
* Language follows the device (en/tr), there is no in-app language switch.
* Online play sends the chosen name, look and game input to the game server;
  the app also contains AdMob and in-app purchases, so the privacy policy and
  store privacy forms must say so (see below).

## Release prep

See [store/metadata.md](store/metadata.md) (store listings, checklist) and
[store/privacy_policy.md](store/privacy_policy.md).

## Open items

* **Android ads:** the manifest still has Google's *sample* AdMob app id and
  `AdConfig.androidUnits` is empty, so release builds show no ads on Android.
* **Android signing:** release builds use the debug signing config.
* **Store listings and privacy:** `store/metadata.md` still says "no ads, no
  tracking / Data Not Collected"; update it (and Play *Data safety*, App
  *Privacy*, ATT/UMP consent) now that ads and purchases exist. Fill the
  bracketed parts of `store/privacy_policy.md` and publish it at a URL.
* **Store products:** create the coin packs, starter pack and `remove_ads` in
  App Store Connect and Play Console and test purchase and restore.
* Real audio and final artwork; screenshots and feature graphic for the stores.
* On-device tuning of speeds and the joystick dead-zone; profile on low-end
  phones (the renderer redraws the full grid each frame; a cached floor
  `Picture` is the next optimisation if needed).
* Online: predict the local player's own bomb (it currently appears one round
  trip late), bots to fill online rooms, multiple server regions, a server
  plan that does not sleep.
* Gamepad support and more enemy types.
