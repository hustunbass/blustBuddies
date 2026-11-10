import 'package:blast_buddies/core/emotes.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/features/game/ui/game_stage.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRemote implements RemoteSession {
  final List<int> sent = [];

  @override
  int get localId => 0;

  @override
  void move(Dir d) {}

  @override
  void bomb() {}

  @override
  void detonate() {}

  @override
  void emote(int i) => sent.add(i);

  @override
  List<int> get emotes => List.filled(2, -1);

  @override
  void advance(double dt) {}
}

Future<FakeRemote> pumpStage(WidgetTester tester, {required Size size, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues({'walletInit': true, 'coin': 20000, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final remote = FakeRemote();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final game = BlastGame(
    sim: GameWorld.battle(humans: 2, bots: 0, seed: 3),
    humans: 1,
    remote: remote,
    onEvent: (_) {},
    onFinished: (_) {},
  );
  await tester.pumpWidget(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(sp)],
    child: MaterialApp(
      theme: buildTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => ToastHost(child: child!),
      home: Scaffold(body: GameStage(game: game, battle: true, onPause: () {})),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 200));
  return remote;
}

void main() {
  // Bomb cluster dragged right to the top of the control area, as in the layout
  // editor: the old inline popup grew upwards out of the area and was cut off.
  const movedUp = {'controlsP': '0,0,0,-1'};

  for (final size in [const Size(393, 852), const Size(402, 874), const Size(360, 740)]) {
    testWidgets('emote picker is fully visible with the buttons moved up (${size.width.toInt()}x${size.height.toInt()})',
        (tester) async {
      final remote = await pumpStage(tester, size: size, prefs: movedUp);
      await tester.tap(find.byIcon(Icons.emoji_emotions));
      await tester.pump(const Duration(milliseconds: 300));
      // All twelve emotes are on screen, inside the window.
      for (final e in Emotes.emoji) {
        final f = find.text(e);
        expect(f, findsOneWidget, reason: e);
        final r = tester.getRect(f);
        expect(r.top, greaterThanOrEqualTo(0), reason: e);
        expect(r.bottom, lessThanOrEqualTo(size.height), reason: e);
        expect(r.left, greaterThanOrEqualTo(0), reason: e);
        expect(r.right, lessThanOrEqualTo(size.width), reason: e);
      }
      await tester.tap(find.text('👍'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(remote.sent, [0]);
      expect(find.text('😂'), findsNothing, reason: 'the picker closes after a pick');
    });
  }

  testWidgets('a premium emote asks first and costs 10K', (tester) async {
    final remote = await pumpStage(tester, size: const Size(393, 852));
    await tester.tap(find.byIcon(Icons.emoji_emotions));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('10K'), findsNWidgets(9), reason: 'nine premium emotes show their price');
    await tester.tap(find.text('😭'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Buy'), findsOneWidget);
    await tester.tap(find.text('Buy'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(remote.sent, [6]);
  });
}
