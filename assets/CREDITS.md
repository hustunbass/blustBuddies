# Asset credits & licences

## Graphics
All in-game graphics are drawn at runtime with Flutter `Canvas` vector shapes
(`lib/features/game/render/world_painter.dart`). No third-party artwork is
bundled. The characters ("buddies", enemy robots) are original designs.

If you later add CC0 art (for example from <https://kenney.nl>), put it in
`assets/images/` and list file, author and licence here.

## Audio (placeholders)
| File | Source | Licence |
|------|--------|---------|
| `audio/place.wav`, `explosion.wav`, `pickup.wav`, `hit.wav`, `win.wav`, `lose.wav`, `music.wav` | Synthesised by `tool/gen_audio.py` (simple sine/noise placeholders) | CC0 / public domain |

These are **placeholders**. Replace them with final audio from CC0 sources
(e.g. Kenney "Interface Sounds" / "Impact Sounds", <https://kenney.nl>, or
OpenGameArt CC0 packs) and update this table. No audio from any commercial
game is used or imitated.

## Fonts
Default platform fonts only.
