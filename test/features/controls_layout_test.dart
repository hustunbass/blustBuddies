import 'dart:ui';

import 'package:blast_buddies/core/settings/control_layout.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/game/ui/controls.dart';
import 'package:blast_buddies/features/settings/controls_editor_screen.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const area = Size(800, 300);
  const stick = 140.0, bomb = 96.0;

  group('geometry', () {
    test('the default layout is the classic one: stick left, bomb right, 24 / 12 from the edges', () {
      final s = ControlGeometry.stick(area, stick, leftHanded: false, layout: const ControlLayout());
      final b = ControlGeometry.bomb(area, bomb, leftHanded: false, layout: const ControlLayout());
      expect(s, const Rect.fromLTWH(24, 300 - 12 - 140, 140, 140));
      expect(b, const Rect.fromLTWH(800 - 24 - 96, 300 - 12 - 96, 96, 96));
    });

    test('left-handed players get the mirrored default', () {
      final s = ControlGeometry.stick(area, stick, leftHanded: true, layout: const ControlLayout());
      final b = ControlGeometry.bomb(area, bomb, leftHanded: true, layout: const ControlLayout());
      expect(s.right, 800 - 24);
      expect(b.left, 24);
    });

    test('offsets move the controls; they never leave the screen', () {
      const far = ControlLayout(stickDx: 5, stickDy: -5, buttonsDx: -5, buttonsDy: 5);
      final s = ControlGeometry.stick(area, stick, leftHanded: false, layout: far);
      final b = ControlGeometry.bomb(area, bomb, leftHanded: false, layout: far);
      for (final r in [s, b]) {
        expect(r.left, greaterThanOrEqualTo(ControlGeometry.edge));
        expect(r.top, greaterThanOrEqualTo(ControlGeometry.edge));
        expect(r.right, lessThanOrEqualTo(area.width - ControlGeometry.edge));
        expect(r.bottom, lessThanOrEqualTo(area.height - ControlGeometry.edge));
      }
    });

    test('a controls area smaller than the controls does not crash', () {
      const tiny = Size(100, 80);
      final s = ControlGeometry.stick(tiny, stick, leftHanded: false, layout: const ControlLayout(stickDx: .5));
      expect(s.width, stick);
    });

    test('placing a control and reading the layout back gives the same rectangle', () {
      final target = const Rect.fromLTWH(300, 50, stick, stick);
      final layout = ControlGeometry.withStickAt(const ControlLayout(), area, stick, target, leftHanded: false);
      expect(ControlGeometry.stick(area, stick, leftHanded: false, layout: layout), target);
      final bombTarget = const Rect.fromLTWH(500, 120, bomb, bomb);
      final both = ControlGeometry.withBombAt(layout, area, bomb, bombTarget, leftHanded: false);
      expect(ControlGeometry.bomb(area, bomb, leftHanded: false, layout: both), bombTarget);
      // Moving the bomb button leaves the joystick alone.
      expect(both.stickDx, layout.stickDx);
    });

    test('mirroring for the other hand swaps sides', () {
      const l = ControlLayout(stickDx: .1, stickDy: -.2, buttonsDx: -.3, buttonsDy: .05);
      final m = l.mirrored();
      expect([m.stickDx, m.stickDy, m.buttonsDx, m.buttonsDy], [-.1, -.2, .3, .05]);
      expect(m.mirrored(), l);
    });
  });

  group('storage', () {
    test('survives encode/decode; garbage falls back to the default', () {
      const l = ControlLayout(stickDx: .25, stickDy: -.125, buttonsDx: -.5, buttonsDy: .0625);
      expect(ControlLayout.decode(l.encode()), l);
      for (final bad in [null, '', 'a,b,c,d', '1,2,3', '1,2,3,4,5', 'NaN,0,0,0', 'Infinity,0,0,0']) {
        expect(ControlLayout.decode(bad).isDefault, isTrue, reason: '$bad');
      }
      expect(ControlLayout.decode('9,-9,0,0').stickDx, 1); // clamped
    });

    test('portrait and landscape are saved separately and persist', () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
      addTearDown(c.dispose);
      expect(c.read(settingsProvider).controlsPortrait.isDefault, isTrue);
      await c.read(settingsProvider.notifier).update(c.read(settingsProvider).copyWith(
            controlsPortrait: const ControlLayout(stickDx: .2),
            controlsLandscape: const ControlLayout(buttonsDy: -.1),
          ));
      final again = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
      addTearDown(again.dispose);
      expect(again.read(settingsProvider).controlsPortrait.stickDx, .2);
      expect(again.read(settingsProvider).controlsPortrait.buttonsDy, 0);
      expect(again.read(settingsProvider).controlsLandscape.buttonsDy, -.1);
      expect(again.read(settingsProvider).controlsLandscape.stickDx, 0);
    });
  });

  Future<ProviderContainer> pumpEditor(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
    addTearDown(c.dispose);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ControlsEditorScreen(),
      ),
    ));
    await tester.pump();
    return c;
  }

  testWidgets('dragging the joystick in portrait saves a portrait layout only', (tester) async {
    final c = await pumpEditor(tester, const Size(420, 900));
    expect(find.text('Customize controls'), findsOneWidget);
    await tester.drag(find.byType(VirtualJoystick), const Offset(120, -60));
    await tester.pump();
    final s = c.read(settingsProvider);
    expect(s.controlsPortrait.stickDx, greaterThan(0));
    expect(s.controlsPortrait.stickDy, lessThan(0));
    expect(s.controlsPortrait.buttonsDx, 0);
    expect(s.controlsLandscape.isDefault, isTrue);
  });

  testWidgets('dragging the bomb button in landscape saves a landscape layout only', (tester) async {
    final c = await pumpEditor(tester, const Size(900, 420));
    await tester.drag(find.byType(BombButton), const Offset(-150, -40));
    await tester.pump();
    final s = c.read(settingsProvider);
    expect(s.controlsLandscape.buttonsDx, lessThan(0));
    expect(s.controlsLandscape.buttonsDy, lessThan(0));
    expect(s.controlsPortrait.isDefault, isTrue);
  });

  testWidgets('reset puts the controls back; switching hands mirrors the placement', (tester) async {
    final c = await pumpEditor(tester, const Size(420, 900));
    await tester.drag(find.byType(VirtualJoystick), const Offset(100, -50));
    await tester.pump();
    final dx = c.read(settingsProvider).controlsPortrait.stickDx;
    expect(dx, greaterThan(0));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(c.read(settingsProvider).leftHanded, isTrue);
    expect(c.read(settingsProvider).controlsPortrait.stickDx, -dx);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(c.read(settingsProvider).controlsPortrait.isDefault, isTrue);
  });
}
