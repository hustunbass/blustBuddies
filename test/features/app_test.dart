import 'package:blast_buddies/app.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
  addTearDown(container.dispose);
  // The menu logo hops forever; let tests settle like a reduced-motion user.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const BlastBuddiesApp(),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('main menu shows title and five entries (English)', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    expect(find.text('Blast Buddies'), findsOneWidget);
    for (final t in ['Story', 'Battle', 'Online', 'How to Play', 'Settings']) {
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('Turkish localisation is used for a Turkish device', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    expect(find.text('Hikaye'), findsOneWidget);
    expect(find.text('Savaş'), findsOneWidget);
    expect(find.text('Nasıl Oynanır'), findsOneWidget);
  });

  testWidgets('level select locks levels beyond progress', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, prefs: {'unlocked': 3});
    await tester.tap(find.text('Story'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.lock), findsWidgets);
    expect(find.text('Level 3'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('World 1'), findsOneWidget);
  });

  testWidgets('settings are persisted', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final c = await pumpApp(tester);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).music, isFalse);
    expect(c.read(prefsProvider).getBool('music'), isFalse);
  });

  testWidgets('battle setup: one human against 1..3 bots', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    await tester.tap(find.text('Battle'));
    await tester.pumpAndSettle();
    expect(find.text('Battle setup'), findsOneWidget);
    expect(find.text('Start battle'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    IconButton button(IconData i) => tester.widget(find.widgetWithIcon(IconButton, i));
    expect(button(Icons.remove_circle_outline).onPressed, isNull);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
    }
    expect(find.text('3'), findsOneWidget);
    expect(button(Icons.add_circle_outline).onPressed, isNull);
    expect(find.text('AI'), findsNWidgets(3));
  });

  testWidgets('battle setup offers 2v2 only with four players', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    await tester.tap(find.text('Battle'));
    await tester.pumpAndSettle();
    SwitchListTile teamSwitch() =>
        tester.widget(find.widgetWithText(SwitchListTile, 'Teams (2 vs 2)'));
    expect(teamSwitch().onChanged, isNull);
    await tester.tap(find.byIcon(Icons.add_circle_outline).last);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_circle_outline).last);
    await tester.pumpAndSettle();
    expect(teamSwitch().onChanged, isNotNull);
    await tester.tap(find.text('Teams (2 vs 2)'));
    await tester.pumpAndSettle();
    expect(teamSwitch().value, isTrue);
  });

  testWidgets('online screen asks only for a name; custom server is advanced (Turkish)', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, prefs: {'onlineName': 'Ece'});
    await tester.tap(find.text('Çevrimiçi'));
    await tester.pumpAndSettle();
    expect(find.text('Çevrimiçi savaş'), findsOneWidget);
    expect(find.text('Ece'), findsOneWidget);
    expect(find.text('Bağlan'), findsOneWidget);
    expect(find.text('Özel sunucu adresi'), findsNothing);
    await tester.tap(find.text('Gelişmiş'));
    await tester.pumpAndSettle();
    expect(find.text('Özel sunucu adresi'), findsOneWidget);
  });

  testWidgets('how to play lists power-ups', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    expect(find.text('Bomb kick'), findsOneWidget);
  });

  testWidgets('starting a story level opens the game with HUD and pause overlay', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    await tester.tap(find.text('Story'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byIcon(Icons.pause_circle_filled), findsOneWidget);
    expect(find.bySemanticsLabel('Drop bomb'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause_circle_filled));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Paused'), findsOneWidget);
    expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), containsAll(['en', 'tr']));
  });
}
