import 'package:blast_buddies/app.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/emotes.dart';
import 'package:blast_buddies/core/onboarding.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
  // Most tests are not about the first-run welcome offer.
  SharedPreferences.setMockInitialValues({'onboardingOffered': true, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
  addTearDown(container.dispose);
  // A phone-sized screen: the menu has five secondary buttons and scrolls on
  // the tiny default test surface.
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
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
    expect(find.text('Boom Pals'), findsOneWidget);
    for (final t in ['Story', 'Battle', 'Online', 'How to Play', 'Settings']) {
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('secondary menu buttons form a 2 - 1 - 2 grid', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    Rect r(String label) => tester.getRect(find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first);
    final daily = r('Daily'), wardrobe = r('Wardrobe'), ach = r('Achievements');
    final how = r('How to Play'), settings = r('Settings');
    // Row 1: two side by side.
    expect(daily.top, wardrobe.top);
    expect(daily.right, lessThan(wardrobe.left));
    // Row 2: one button spanning both columns.
    expect(ach.top, greaterThan(daily.bottom));
    expect(ach.left, daily.left);
    expect(ach.right, wardrobe.right);
    // Row 3: two again.
    expect(how.top, settings.top);
    expect(how.top, greaterThan(ach.bottom));
    expect(how.left, daily.left);
    expect(settings.right, wardrobe.right);
  });

  testWidgets('first launch offers the tutorial once; "Maybe later" counts as skipping', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final c = await pumpApp(tester, prefs: {'onboardingOffered': false});
    expect(find.text('Welcome, pal!'), findsOneWidget);
    expect(find.text('Learn the basics in under a minute and get 50 coins.'), findsOneWidget);
    expect(c.read(onboardingProvider).offered, isTrue);
    await tester.tap(find.text('Maybe later'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, pal!'), findsNothing);
    expect(c.read(onboardingProvider).done, isTrue);
    expect(c.read(walletProvider).coin, 100, reason: 'only the welcome gift, no tutorial reward');
  });

  testWidgets('the welcome offer is not repeated once it was shown', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, prefs: {'onboardingOffered': true});
    expect(find.text('Welcome, pal!'), findsNothing);
  });

  testWidgets('"Let\'s go" opens the tutorial', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester, prefs: {'onboardingOffered': false});
    await tester.tap(find.text("Let's go"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('How to Play can replay the tutorial', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpApp(tester);
    await tester.tap(find.text('How to Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play the tutorial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Move'), findsOneWidget);
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

  testWidgets('achievements screen lists series and pays a claimed reward', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final c = await pumpApp(tester, prefs: {
      'walletInit': true,
      'coin': 0,
      'ach': ['kills_1'],
    });
    await tester.tap(find.text('Achievements'));
    await tester.pumpAndSettle();
    expect(find.text('Ready to claim'), findsOneWidget);
    expect(find.text('Exterminator I'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    await tester.tap(find.text('Claim all · 5'));
    await tester.pumpAndSettle();
    expect(c.read(walletProvider).coin, 5);
    expect(find.text('Ready to claim'), findsNothing);
  });

  testWidgets('wardrobe sells premium emotes for a flat 10K, free ones stay free', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final c = await pumpApp(tester, prefs: {'walletInit': true, 'coin': 15000});
    await tester.tap(find.text('Wardrobe'));
    // The buddy preview animates forever, so never wait for it to settle.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.scrollUntilVisible(find.text('Emotes'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('👍'), findsOneWidget); // free
    final locked = find.text('😭');
    await tester.scrollUntilVisible(locked, 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(locked);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Buy'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.read(walletProvider).coin, 5000);
    expect(c.read(walletProvider).has(Emotes.key(6)), isTrue);
    // 5K is too little for the next one: nothing is bought.
    await tester.tap(find.text('🥳'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Buy'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.read(walletProvider).coin, 5000);
    expect(c.read(walletProvider).has(Emotes.key(7)), isFalse);
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

  testWidgets('battle setup: one human against 1..6 bots (seven players at most)', (tester) async {
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
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pump();
    }
    expect(find.text('6'), findsOneWidget);
    expect(button(Icons.add_circle_outline).onPressed, isNull);
    expect(find.text('AI'), findsNWidgets(6));
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
