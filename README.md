# Blast Buddies

A colourful, original arcade maze-bomber for iOS and Android built with
**Flutter + Flame**. Round "buddy" robots, crates, chain explosions, power-ups,
12 story levels and a 2–4 player Battle mode with bots.

> All art is drawn in code and all characters are original. No assets,
> names or sounds from any commercial game are used. See
> [assets/CREDITS.md](assets/CREDITS.md).

## Run

```bash
flutter pub get
flutter run            # pick an iOS/Android device or simulator
flutter analyze && flutter test
```

Desktop/test controls: arrows or WASD + Space/Enter.

Regenerate generated assets:
`python3 tool/gen_audio.py` (placeholder sounds), `python3 tool/gen_icon.py`
(icon source), then `flutter pub run flutter_launcher_icons` and
`flutter pub run flutter_native_splash:create`. Localisation:
`flutter gen-l10n` (also runs on build).

## Architecture (feature-first)

```
lib/
  core/        grid model, map generator, blast, BFS, power-ups (pure Dart),
               settings (Riverpod + shared_preferences), audio/haptics, theme
  features/
    game/
      logic/   GameWorld simulation, entities, bots, level config (pure Dart)
      render/  WorldPainter (vector drawing) + pooled ParticleSystem
      ui/      BlastGame (Flame host), HUD, joystick, game screen
      application/  GameArgs, HudState
    menu/      main menu, level select, battle setup, how to play
    online/    connect form, room list, create-room dialog, room lobby, online game
    settings/  settings screen
  net/         protocol + snapshot codec (pure Dart), WebSocket client,
               server/ BlastServer (pure dart:io, authoritative)
  l10n/        ARB files (en, tr)
bin/server.dart  online server entry point
```

Design choices:

* **Game rules never depend on Flame.** `GameWorld` is a deterministic,
  seedable simulation (cell-space coordinates). `BlastGame` only feeds input,
  ticks the world, and draws it, so rules are unit-tested without an engine.
* **Performance:** one canvas scale per frame, reused `Paint`s, no per-entity
  component churn, a fixed-size particle pool, flame state in a flat array, and
  HUD updates only when its snapshot changes. Frame time is capped (`dt ≤ 50 ms`).
* **Quality:** `flutter_lints` + a few extra rules; tests cover grid/map
  generation, blast propagation, BFS, power-ups, movement/collision, bombs,
  chain reactions, kicking, enemies, level flow, bots, Flame integration and UI.

## Online (different devices)

Players on different phones connect to one **server**, see its room list and
join a room. The server runs the real `GameWorld` (60 Hz) and streams
snapshots (30 Hz); phones only send input (direction / bomb), so nobody can
cheat by moving themselves.

Players never run or type a server: the app connects to the hosted server
in [lib/net/server_config.dart](lib/net/server_config.dart)
(`defaultServerUrl`, override with `--dart-define=BLAST_SERVER=wss://...`).
A custom address can still be entered under *Advanced* (testing / LAN).

1. **Deploy the server once (developer)**, free on [Render](https://render.com)
   (no card needed) with the blueprint [render.yaml](render.yaml) and the
   self-contained [server.Dockerfile](server.Dockerfile):

   1. Push this project to a GitHub repository (private is fine).
   2. Render → **New → Blueprint** → pick the repo → **Apply**.
   3. When the deploy is live, open the shown URL + `/health`
      (→ `blast-buddies ok`). The service runs in Frankfurt (`region` in
      `render.yaml`), close to players in Turkey/Europe.
   4. If Render assigned a different URL (name taken), put it into
      `defaultServerUrl` as `wss://<host>` **before** archiving the app.

   Free plan limits: the service sleeps after 15 minutes without traffic and
   takes about a minute to wake up; the app retries for up to 90 s and shows
   "waking up the server". 750 free instance hours/month (enough for one
   always-on service). Render may restart free services at any time, which
   ends running rooms. For no sleep, switch the service to a paid plan or use
   [fly.toml](fly.toml) on Fly.io (`fly deploy --ha=false`, paid).

   Local run (testing):

   ```bash
   # use Flutter's bundled Dart (3.11); `dart run` fails because of Flutter
   # native-asset dependencies, running the file directly works:
   "$(dirname "$(which flutter)")/dart" bin/server.dart --port 8080
   curl localhost:8080/health   # -> blast-buddies ok
   ```

2. In the app: **Online** → name → **Connect**.
3. **Create room**: player count 2/3/4, *Teams (2 vs 2)* with 4 players,
   optional password. Modes: 1v1, 2v2, 3 and 4 free-for-all.
4. Others see the room (lock icon if it has a password, `n/cap`) and join.
5. When the room is full and **everyone** taps *Ready*, a 3-second countdown
   starts (un-ready or leaving cancels it), then the match begins. After the
   match everyone returns to the room and can ready up again.

Monitoring: `GET /stats` (e.g. `https://blast-buddies-eu.onrender.com/stats`)
returns `online`, `peakOnline` (since the last restart), `inMatch`, `rooms`,
`matches`, `lagMs` (worst event-loop delay of the last minute) and `load`
(`ok` < 20 ms, `busy` < 50 ms, else `overloaded`). The same line is written to
the service log every 5 minutes while anyone is connected. Upgrade the Render
plan when `load` stays `busy`/`overloaded` during peak hours.

Latency: the client predicts its own player's movement with the same
movement code as the server and blends in corrections measured against where
it was one round trip ago (RTT from `ping`/`pong`), so your own buddy reacts
instantly; other players are smoothed between 30 Hz snapshots.

Server rules: passwords are stored as salted SHA-256 hashes only; 5 wrong
passwords per minute per connection, then `tooManyAttempts`; names/room names
are length-limited and sanitised; frames > 4 KB and invalid input are
rejected; a player who leaves/disconnects mid-match is eliminated; empty rooms
are deleted. In 2v2, slots 1+3 (top corners) face 2+4 (bottom corners) and
blasts hurt teammates too (friendly fire). Use `wss://` when hosting on the
internet (Fly.io provides it; elsewhere put Caddy/nginx in front).

## Features

* 13×11 grid; steel walls on the border and at every even/even cell; random
  crates with empty, safe start corners.
* Smooth 4-direction movement with corner assist; bombs (3 s fuse) blast in a
  plus shape, stop at walls, destroy crates, chain-react; the owner can walk off
  a freshly placed bomb, after which it is solid.
* Power-ups (30 % drop): extra bomb, range, speed, shield, bomb kick.
* Enemies: wanderer, BFS chaser, speedster. Exit door opens when all are dead.
* 3 lives, score, 3-minute timer, 12 levels with rising difficulty.
* Battle: you against 1–3 bots, optional 2v2 teams (you + a bot vs 2 bots).
* Online battle across devices: room list, password rooms, 1v1 / 2v2 / 3 / 4
  free-for-all, ready-up with 3-second countdown.
* Menus: main, level select, battle setup, pause, result, settings
  (sound, music, vibration, control size), how to play. English + Turkish.
* Accessibility: semantic labels on HUD and controls, system text scaling,
  reduced-motion setting disables shake and particles.

## Varsayımlar (Assumptions)

* Flame is used as the render/loop host; the virtual joystick and bomb button
  are Flutter widgets overlaid on the game (better safe-area and
  accessibility handling than in-engine widgets). The joystick is 4-direction.
* Coordinates: the grid is 13 columns × 11 rows including the border; "even
  row/column intersections" is read as 0-based even x and even y.
* Story: lives, score and upgrades (except shield) carry between levels;
  restarting a level resets to 3 lives. Time limit is 3 minutes per level.
* Battle players have 1 life; the round ends when ≤ 1 is alive or after
  3 minutes (draw). Bots are heuristic (flee blasts, bomb crates/opponents when
  an escape exists).
* Local Battle has exactly one human (1–3 bots); playing with friends is done
  through Online mode on separate devices.
* Audio files are synthesized placeholders (CC0). Icon/splash are generated
  from `tool/gen_icon.py`; replace with final art before release.
* Language follows the device (en/tr), there is no in-app language switch.
* Ads and analytics are absent. Online play sends the chosen name and game
  input to the game server; this is described in `store/privacy_policy.md`
  (still a draft: fill in the bracketed parts).

## Release prep

See [store/metadata.md](store/metadata.md) (store listings, checklist) and
[store/privacy_policy.md](store/privacy_policy.md).

## Open items

* Real audio and final artwork; screenshots and feature graphic for the stores.
* On-device tuning of speeds and the joystick dead-zone; profile on low-end
  phones (the renderer redraws the full grid each frame; a cached floor
  `Picture` is the next optimisation if needed).
* Signing configuration, final bundle id, privacy policy URL.
* Gamepad support, more enemy types and boss levels.
* Online: reconnect to a running match, bots to fill online rooms, multiple
  server regions.
