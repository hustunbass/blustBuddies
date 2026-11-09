import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/core/ui/toast.dart';
import 'package:blast_buddies/features/game/render/powerup_art.dart';
import 'package:blast_buddies/features/menu/achievement_toast.dart';
import 'package:blast_buddies/features/menu/how_to_play_screen.dart';
import 'package:blast_buddies/features/online/quick_match_dialog.dart';
import 'package:blast_buddies/features/shop/shop_sheet.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The test font (Ahem) is twice as wide as Roboto/SF; this scale brings text
/// back to realistic widths.
Widget realWidths(Widget child) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(.55)),
        child: child,
      ),
    );

Widget app(Widget home, {ToastController? toastController, Locale locale = const Locale('en')}) => MaterialApp(
      theme: buildTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => ToastHost(controller: toastController, child: child!),
      home: home,
    );

Future<ProviderContainer> container([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues({'walletInit': true, 'coin': 100, ...prefs});
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('toast', () {
    testWidgets('slides in, stays, leaves; the next one in the queue follows', (tester) async {
      final c = ToastController();
      await tester.pumpWidget(app(const Scaffold(), toastController: c));
      c.show(const ToastMessage('First'));
      c.show(const ToastMessage('Second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsNothing);
      expect(c.current, isNull);
    });

    testWidgets('stays visible with "reduce motion" on (it used to vanish at once)', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final c = ToastController();
      await tester.pumpWidget(app(const Scaffold(), toastController: c));
      c.show(const ToastMessage('Hello'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.text('Hello'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Hello'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('once the last toast is over nothing is left on screen to swallow taps', (tester) async {
      final c = ToastController();
      var taps = 0;
      await tester.pumpWidget(app(
        Scaffold(appBar: AppBar(actions: [IconButton(onPressed: () => taps++, icon: const Icon(Icons.add))])),
        toastController: c,
      ));
      c.show(const ToastMessage('Gone soon'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Gone soon'), findsNothing);
      await tester.tap(find.byIcon(Icons.add));
      expect(taps, 1);
    });

    testWidgets('an identical message is not shown twice in a row', (tester) async {
      final c = ToastController();
      await tester.pumpWidget(app(const Scaffold(), toastController: c));
      c.show(const ToastMessage('Same'));
      c.show(const ToastMessage('Same'));
      c.show(const ToastMessage('Same'));
      expect(c.waiting, 0);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('the action button runs and closes the toast', (tester) async {
      final c = ToastController();
      var tapped = 0;
      await tester.pumpWidget(app(const Scaffold(), toastController: c));
      c.show(ToastMessage('Not enough', kind: ToastKind.error, actionLabel: 'Shop', onAction: () => tapped++));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Shop'));
      await tester.pump();
      expect(tapped, 1);
      expect(c.current, isNull);
    });

    testWidgets('tapping a toast dismisses it', (tester) async {
      final c = ToastController();
      await tester.pumpWidget(app(const Scaffold(), toastController: c));
      c.show(const ToastMessage('Tap me'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Tap me'));
      await tester.pump();
      expect(c.current, isNull);
    });

    testWidgets('achievements raise a gold toast with the name', (tester) async {
      final l = await AppLocalizations.delegate.load(const Locale('en'));
      toasts.clear();
      addTearDown(toasts.clear);
      toastAchievements(l, [achievements.firstWhere((a) => a.id == 'bombs_300')]);
      expect(toasts.current?.kind, ToastKind.achievement);
      expect(toasts.current?.text, 'Bomber IV');
      expect(toasts.current?.title, 'Achievement unlocked');
    });
  });

  group('coin shop', () {
    for (final width in [320.0, 360.0, 430.0]) {
      testWidgets('does not overflow at $width px wide, even for the biggest pack', (tester) async {
        final c = await container();
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(UncontrolledProviderScope(container: c, child: app(realWidths(const Scaffold(body: ShopSheet())))));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('10000'), findsOneWidget);
        expect(find.text('Coin shop'), findsOneWidget);
        expect(find.text('Starter pack'), findsOneWidget);
      });
    }

    testWidgets('has a close button that leaves the shop, and a tap outside also closes it', (tester) async {
      final c = await container();
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: app(realWidths(Scaffold(
          body: Builder(builder: (ctx) => TextButton(onPressed: () => showShopSheet(ctx), child: const Text('open'))),
        ))),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Coin shop'), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Coin shop'), findsNothing);
      // And the scrim above the sheet still dismisses it.
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(215, 8));
      await tester.pumpAndSettle();
      expect(find.text('Coin shop'), findsNothing);
    });

    testWidgets('explains the first-purchase bonus once, with a short chip on every pack', (tester) async {
      final c = await container();
      tester.view.physicalSize = const Size(430, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(container: c, child: app(realWidths(const Scaffold(body: ShopSheet())))));
      await tester.pump();
      expect(find.text('Your first pack pays a bonus.'), findsOneWidget);
      expect(find.text('+500 bonus coins'), findsOneWidget);
      expect(find.text('+1500 bonus coins'), findsNWidgets(3));
    });
  });

  group('quick match', () {
    for (final (label, players) in [('1 vs 1', 2), ('4-player free-for-all', 4), ('7-player party', 7)]) {
      testWidgets('"$label" picks $players players', (tester) async {
        int? picked;
        await tester.pumpWidget(app(Scaffold(
          body: Builder(
            builder: (c) => TextButton(onPressed: () async => picked = await showQuickMatchDialog(c), child: const Text('go')),
          ),
        )));
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(find.text('Quick match'), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(picked, players);
      });
    }

    testWidgets('can be dismissed with Cancel', (tester) async {
      int? picked = -1;
      await tester.pumpWidget(app(Scaffold(
        body: Builder(
          builder: (c) => TextButton(onPressed: () async => picked = await showQuickMatchDialog(c), child: const Text('go')),
        ),
      )));
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(picked, isNull);
    });
  });

  group('how to play', () {
    testWidgets('mentions no keyboard keys (English)', (tester) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(const HowToPlayScreen()));
      final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' ').toLowerCase();
      for (final banned in ['wasd', 'arrow', 'space', 'key e', 'keyboard']) {
        expect(texts.contains(banned), isFalse, reason: banned);
      }
    });

    testWidgets('mentions no keyboard keys (Turkish)', (tester) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(const HowToPlayScreen(), locale: const Locale('tr')));
      final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' ').toLowerCase();
      for (final banned in ['wasd', 'ok tuşları', 'boşluk', 'e tuşu', 'klavye']) {
        expect(texts.contains(banned), isFalse, reason: banned);
      }
    });

    testWidgets('shows every power-up with the same picture as the arena', (tester) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(const HowToPlayScreen()));
      final shown = tester.widgetList<PowerUpIcon>(find.byType(PowerUpIcon)).map((w) => w.type).toSet();
      expect(shown, PowerUpType.values.toSet());
      expect(find.text('Bomb kick'), findsOneWidget);
    });
  });

  test('every power-up has a tile colour', () {
    for (final t in PowerUpType.values) {
      expect(PowerUpArt.colors.containsKey(t), isTrue, reason: '$t');
    }
  });
}
