import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:blast_buddies/core/cosmetics.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/render/world_painter.dart';
import 'package:blast_buddies/features/menu/wardrobe_screen.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/l10n/names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Uint8List> draw(WorldPainter painter, Skin skin) async {
  final rec = ui.PictureRecorder();
  painter.paintBuddyPreview(Canvas(rec), const Size(96, 96), skin, 0);
  final img = await rec.endRecording().toImage(96, 96);
  return (await img.toByteData())!.buffer.asUint8List();
}

/// Renders a lone buddy to raw pixels (image work needs real async).
Future<Uint8List> render(WidgetTester t, Skin skin) async =>
    (await t.runAsync(() => draw(WorldPainter(reducedMotion: true), skin)))!;

void main() {
  group('catalogue', () {
    test('has plenty to buy: 24 hats, 12 faces, 16 colours (34 accessories)', () {
      expect(Cosmetics.hats.length, 24);
      expect(Cosmetics.faces.length, 12);
      expect(Cosmetics.colors.length, 16);
      expect((Cosmetics.hats.length - 1) + (Cosmetics.faces.length - 1), greaterThanOrEqualTo(31));
    });

    test('each kind starts with three free items, everything else costs 1K-5K coins', () {
      int free(List<CosmeticItem> l) => l.where((i) => i.price == 0).length;
      expect(free(Cosmetics.hats), 3, reason: 'none, cap, beanie');
      expect(free(Cosmetics.faces), 3, reason: 'classic, happy, sleepy');
      // The slot colour plus three real colours.
      expect(free(Cosmetics.colors), 4);
      expect(Cosmetics.colors.where((c) => c.price == 0 && c.color != null).length, 3);
      for (final list in [Cosmetics.hats, Cosmetics.faces, Cosmetics.colors]) {
        expect(list.first.price, 0);
        for (final item in list.where((i) => !i.free)) {
          expect(item.price, inInclusiveRange(1000, 5000));
          expect(item.price % 1000, 0);
        }
      }
      // Rarer means dearer: the price never goes down as the rank goes up.
      for (final list in [Cosmetics.hats, Cosmetics.faces, Cosmetics.colors]) {
        final paid = list.where((i) => !i.free).toList()..sort((a, b) => a.stars.compareTo(b.stars));
        for (var i = 1; i < paid.length; i++) {
          expect(paid[i].price, greaterThanOrEqualTo(paid[i - 1].price));
        }
        expect(paid.first.price, 1000);
        expect(paid.last.price, 5000);
      }
    });

    test('body colours are all different and the first keeps the slot colour', () {
      expect(Cosmetics.colors.first.color, isNull);
      final values = Cosmetics.colors.skip(1).map((c) => c.color).toList();
      expect(values.every((c) => c != null), isTrue);
      expect(values.toSet().length, values.length);
    });

    test('byPrice lists every item once, free ones first, then cheapest first', () {
      for (final items in [Cosmetics.hats, Cosmetics.faces, Cosmetics.colors]) {
        final order = Cosmetics.byPrice(items);
        expect(order.toSet().length, items.length);
        expect(order.first, 0);
        for (var i = 1; i < order.length; i++) {
          expect(items[order[i]].price, greaterThanOrEqualTo(items[order[i - 1]].price));
        }
        final freeCount = items.where((i) => i.free).length;
        expect(order.take(freeCount).every((i) => items[i].free), isTrue);
      }
    });

    test('out-of-range indices (a newer app on the other end) fall back safely', () {
      final s = Cosmetics.skin(999, 999, 999);
      expect(s.hat, Cosmetics.hats.length - 1);
      expect(s.face, Cosmetics.faces.length - 1);
      expect(Cosmetics.skin(-5, -5, -5).hat, 0);
    });

    test('every item has its own name in English and Turkish', () async {
      for (final locale in ['en', 'tr']) {
        final l = await AppLocalizations.delegate.load(Locale(locale));
        final hats = [for (var i = 0; i < Cosmetics.hats.length; i++) Names.hat(l, i)];
        final faces = [for (var i = 0; i < Cosmetics.faces.length; i++) Names.face(l, i)];
        expect(hats.every((n) => n.trim().isNotEmpty), isTrue, reason: locale);
        expect(hats.toSet().length, hats.length, reason: '$locale hats');
        expect(faces.every((n) => n.trim().isNotEmpty), isTrue, reason: locale);
        expect(faces.toSet().length, faces.length, reason: '$locale faces');
      }
    });
  });

  group('drawing', () {
    testWidgets('every hat looks different from every other one', (tester) async {
      final seen = <String, int>{};
      for (var h = 0; h < Cosmetics.hats.length; h++) {
        final px = await render(tester, Skin(hat: h, color: 0xFF26A69A));
        final key = px.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff).toString();
        expect(seen.containsKey(key), isFalse, reason: 'hat $h draws the same as hat ${seen[key]}');
        seen[key] = h;
      }
    });

    testWidgets('every face looks different from every other one', (tester) async {
      final seen = <String, int>{};
      for (var f = 0; f < Cosmetics.faces.length; f++) {
        final px = await render(tester, Skin(face: f, color: 0xFF26A69A));
        final key = px.fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff).toString();
        expect(seen.containsKey(key), isFalse, reason: 'face $f draws the same as face ${seen[key]}');
        seen[key] = f;
      }
    });

    testWidgets('all hat / face / colour combinations draw without errors', (tester) async {
      final painter = WorldPainter(reducedMotion: true);
      for (var h = 0; h < Cosmetics.hats.length; h++) {
        for (var f = 0; f < Cosmetics.faces.length; f++) {
          for (final c in [null, 0xFF212121, 0xFFECEFF1]) {
            final rec = ui.PictureRecorder();
            painter.paintBuddyPreview(Canvas(rec), const Size(64, 64), Skin(hat: h, face: f, color: c), 1);
            rec.endRecording().dispose();
          }
        }
      }
    });

    testWidgets('animated hats move: flame hair and the propeller change over time', (tester) async {
      final a = WorldPainter(reducedMotion: false);
      final b = WorldPainter(reducedMotion: false)..update(.37);
      for (final hat in [17, 20]) {
        Future<Uint8List> shot(WorldPainter p) async => (await tester.runAsync(() => draw(p, Skin(hat: hat))))!;
        expect(await shot(a), isNot(equals(await shot(b))), reason: 'hat $hat');
      }
    });
  });

  group('wardrobe', () {
    Future<ProviderContainer> open(WidgetTester tester,
        {int coins = 500, Map<String, Object> extra = const {}, double width = 430}) async {
      SharedPreferences.setMockInitialValues({'walletInit': true, 'coin': coins, ...extra});
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
      addTearDown(c.dispose);
      tester.view.physicalSize = Size(width, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: buildTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WardrobeScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      return c;
    }

    testWidgets('shows every hat and face, the cheapest first', (tester) async {
      await open(tester);
      for (final n in ['Beanie', 'Rainbow afro', 'Cat ears', 'Sleepy', 'Cyclops', 'Robot visor']) {
        expect(find.text(n), findsOneWidget, reason: n);
      }
      // Cap (3 stars) is listed before Crown (25) and Horns (90).
      double x(String name) => tester.getTopLeft(find.text(name)).dx + tester.getTopLeft(find.text(name)).dy * 1000;
      expect(x('Cap'), lessThan(x('Crown')));
      expect(x('Crown'), lessThan(x('Horns')));
    });

    testWidgets('every list is exactly four columns wide on every phone', (tester) async {
      // iPhone SE, 15, 16, 16 Pro and Plus/Max widths.
      for (final width in [320.0, 375.0, 393.0, 402.0, 430.0]) {
        await open(tester, width: width);
        double y(String t) => tester.getCenter(find.text(t)).dy;
        double x(String t) => tester.getCenter(find.text(t)).dx;
        // Hats: None, Cap and Beanie are free, Cat ears is the cheapest paid one.
        final row = ['None', 'Cap', 'Beanie', 'Cat ears'];
        for (final n in row.skip(1)) {
          expect(y(n), closeTo(y('None'), 4), reason: '$n on a ${width.toInt()} wide phone');
        }
        for (var i = 1; i < row.length; i++) {
          expect(x(row[i]), greaterThan(x(row[i - 1])), reason: '${width.toInt()}');
        }
        // The fifth hat starts the second row, under the first one.
        expect(y('Chef hat'), greaterThan(y('None') + 20), reason: '${width.toInt()}');
        expect(x('Chef hat'), closeTo(x('None'), 1), reason: '${width.toInt()}');
        // The tiles fill the width in four equal columns.
        final span = x('Cat ears') - x('None');
        expect(span, closeTo((width - 32 - 30) / 4 * 3 + 30, 2), reason: '${width.toInt()}');
      }
    });

    testWidgets('a locked colour still shows its real colour and the unlock dialog previews it', (tester) async {
      await open(tester, coins: 5000);
      const purple = Color(0xFF8E24AA); // 10 stars: 1K
      bool isSwatch(Widget w, Color c) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).color == c;
      final locked = find.byWidgetPredicate((w) => isSwatch(w, purple.withValues(alpha: .55)));
      expect(locked, findsOneWidget, reason: 'dimmed colour, not a grey lock');
      expect(find.byIcon(Icons.lock_rounded), findsWidgets);
      await tester.tap(locked);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Buy'), findsOneWidget);
      // The dialog repeats the colour at full strength above the question.
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.byWidgetPredicate((w) => isSwatch(w, purple))), findsOneWidget);
    });

    testWidgets('buying a new hat takes its price and puts it on', (tester) async {
      final c = await open(tester, coins: 5000);
      await tester.tap(find.text('Party hat')); // 1K
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Buy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.read(walletProvider).coin, 4000);
      expect(c.read(walletProvider).has('hat:2'), isTrue);
      expect(c.read(settingsProvider).hat, 2);
    });

    testWidgets('too poor: nothing is bought and the hat stays off', (tester) async {
      final c = await open(tester, coins: 10);
      await tester.tap(find.text('Rainbow afro')); // 5K
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Buy'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.read(walletProvider).coin, 10);
      expect(c.read(walletProvider).has('hat:23'), isFalse);
      expect(c.read(settingsProvider).hat, 0);
    });

    testWidgets('an owned hat is put on for free', (tester) async {
      final c = await open(tester, coins: 0, extra: {'owned': ['hat:12']});
      await tester.tap(find.text('Cat ears'));
      await tester.pump();
      expect(c.read(settingsProvider).hat, 12);
      expect(c.read(walletProvider).coin, 0);
    });
  });
}
