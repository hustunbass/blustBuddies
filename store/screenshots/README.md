# App Store screenshots

Ready to upload, one folder per device size and language:

| Folder | Size | App Store Connect slot |
|---|---|---|
| `iphone-6.3/en`, `iphone-6.3/tr` | 1206 × 2622 | iPhone 6.1"/6.3" Display slot (accepted sizes: 1179 × 2556, 1206 × 2622) |
| `iphone-6.9/en`, `iphone-6.9/tr` | 1320 × 2868 | iPhone 6.9" Display |
| `ipad-13/en`, `ipad-13/tr` | 2064 × 2752 | iPad 13" Display |

Upload `en` to the English (U.S.) page and `tr` to the Turkish page. Files are
numbered in the order they should appear (the first three show in search).

The screenshots are real captures from the app (iPhone 17 Pro Max and iPad Pro
13" simulators) on a branded background. Apple scales these sizes down for the
smaller iPhone/iPad slots, so no other sizes are needed.

## Regenerating

1. `flutter run -d <simulator> -t tool/shots/shots_main.dart` (iPad: add
   `--dart-define=SHOT_CMD=/tmp/shot_cmd_ipad`). The harness seeds demo progress
   and polls the command file.
2. Capture raw screens into `<raw>/iphone_en`, `iphone_tr`, `ipad_en`, `ipad_tr`
   by writing commands (`route /levels`, `battle 7`, `room 1`, `locale tr`, ...)
   to the command file and running `xcrun simctl io <id> screenshot`.
3. `python3 tool/shots/make_posters.py <raw> store/screenshots`.

Headlines and sub-lines live in `tool/shots/make_posters.py`.
