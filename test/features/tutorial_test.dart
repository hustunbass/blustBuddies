import 'dart:async';

import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/onboarding.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/tutorial/tutorial_flow.dart';
import 'package:blast_buddies/features/tutorial/tutorial_screen.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs the world like the game does: tick, deliver events, update the flow.
void run(TutorialFlow f, double seconds) {
  for (var i = 0; i < seconds * 60; i++) {
    f.world.tick(1 / 60);
    for (final e in f.world.drainEvents()) {
      f.handle(e);
    }
    f.update();
  }
}

void walkTo(TutorialFlow f, Dir d, GridPos goal, {double max = 6}) {
  f.world.setMove(0, d);
  for (var i = 0; i < max * 60 && f.world.players.first.cell != goal; i++) {
    f.world.tick(1 / 60);
    for (final e in f.world.drainEvents()) {
      f.handle(e);
    }
    f.update();
  }
  f.world.setMove(0, Dir.none);
}

void main() {
  group('arena', () {
    test('one buddy at the start, the lesson crate blocks the corridor, no enemy yet', () {
      final f = TutorialFlow();
      final p = f.world.players.single;
      expect(p.cell, TutorialFlow.start);
      expect(p.lives, 99);
      expect(f.world.grid.typeAt(TutorialFlow.crate.x, TutorialFlow.crate.y), CellType.block);
      for (var x = 1; x < TutorialFlow.crate.x; x++) {
        expect(f.world.grid.typeAt(x, 1), CellType.empty, reason: 'corridor cell $x');
      }
      expect(f.world.enemies, isEmpty);
      expect(f.step, TutorialStep.move);
      expect(f.marker, TutorialFlow.target);
    });

    test('the world never ends by itself (no timer, no exit)', () {
      final f = TutorialFlow();
      run(f, 30);
      expect(f.world.status, WorldStatus.playing);
      expect(f.step, TutorialStep.move);
    });
  });

  group('lessons', () {
    test('walk, bomb, run, power-up, enemy, done - the whole tutorial', () {
      final f = TutorialFlow();
      walkTo(f, Dir.right, TutorialFlow.target);
      expect(f.step, TutorialStep.bomb);
      expect(f.marker, TutorialFlow.stand);

      walkTo(f, Dir.right, TutorialFlow.stand);
      f.world.requestBomb(0);
      run(f, .1);
      expect(f.step, TutorialStep.escape);
      expect(f.marker, isNull);

      // Back along the corridor, out of the blast, until the bomb goes off.
      walkTo(f, Dir.left, const GridPos(3, 1));
      run(f, 4);
      expect(f.world.players.first.lives, 99, reason: 'the player got away');
      expect(f.world.grid.typeAt(7, 1), CellType.empty, reason: 'the crate is gone');
      expect(f.step, TutorialStep.powerUp);
      expect(f.marker, TutorialFlow.crate);

      // A power-up is waiting where the crate was.
      run(f, 1);
      expect(f.world.powerUps.containsKey(TutorialFlow.crate), isTrue);

      walkTo(f, Dir.right, TutorialFlow.crate);
      run(f, .2);
      expect(f.step, TutorialStep.enemy);
      expect(f.world.enemies, hasLength(1));
      expect(f.world.enemies.single.type, EnemyType.wanderer);

      f.handle(const GameEvent(GameEventType.enemyKilled, 0, 0, 0));
      expect(f.step, TutorialStep.done);
    });

    test('a bomb dropped far from the crate repeats the lesson with a hint', () {
      final f = TutorialFlow()..step = TutorialStep.bomb;
      f.world.requestBomb(0); // at the start cell: nowhere near the crate
      run(f, .1);
      expect(f.step, TutorialStep.escape);
      walkTo(f, Dir.right, const GridPos(3, 1)); // out of the blast
      run(f, 4);
      expect(f.world.grid.typeAt(7, 1), CellType.block);
      expect(f.step, TutorialStep.bomb);
      expect(f.tooFar, isTrue);
      // Trying again clears the hint once a bomb is down.
      walkTo(f, Dir.right, TutorialFlow.stand);
      f.world.requestBomb(0);
      run(f, .1);
      expect(f.step, TutorialStep.escape);
      expect(f.tooFar, isFalse);
    });

    test('the crate always hides a power-up, whatever the random drop did', () {
      final f = TutorialFlow()..step = TutorialStep.escape;
      f.world.grid.setType(7, 1, CellType.empty);
      f.world.powerUps.remove(TutorialFlow.crate);
      f.handle(const GameEvent(GameEventType.explosion, 0, 0));
      f.update();
      expect(f.step, TutorialStep.powerUp);
      f.update();
      expect(f.world.powerUps[TutorialFlow.crate], PowerUpType.range);
    });

    test('lessons do not jump ahead: an enemy kill during the bomb lesson changes nothing', () {
      final f = TutorialFlow()..step = TutorialStep.bomb;
      f.handle(const GameEvent(GameEventType.enemyKilled, 0, 0, 0));
      f.handle(const GameEvent(GameEventType.powerUp, 0, 0, 0));
      expect(f.step, TutorialStep.bomb);
    });
  });

  group('first-run state', () {
    Future<ProviderContainer> container([Map<String, Object> prefs = const {}]) async {
      SharedPreferences.setMockInitialValues({'walletInit': true, 'coin': 0, ...prefs});
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
      addTearDown(c.dispose);
      return c;
    }

    test('fresh install: nothing offered, nothing done', () async {
      final c = await container();
      final s = c.read(onboardingProvider);
      expect([s.offered, s.done, s.rewarded], [false, false, false]);
    });

    test('finishing pays 50 coins, once, even if it is played again', () async {
      final c = await container();
      final n = c.read(onboardingProvider.notifier);
      expect(await n.complete(), OnboardingNotifier.reward);
      expect(c.read(walletProvider).coin, 50);
      expect(c.read(onboardingProvider).done, isTrue);
      expect(await n.complete(), 0);
      expect(c.read(walletProvider).coin, 50);
    });

    test('skipping pays nothing but counts as done; a later run still pays once', () async {
      final c = await container();
      final n = c.read(onboardingProvider.notifier);
      await n.skip();
      expect(c.read(onboardingProvider).done, isTrue);
      expect(c.read(walletProvider).coin, 0);
      expect(await n.complete(), OnboardingNotifier.reward);
    });

    test('the state survives a restart', () async {
      final c = await container();
      await c.read(onboardingProvider.notifier).complete();
      final again = await container({'onboardingOffered': true, 'onboardingDone': true, 'onboardingRewarded': true});
      expect(again.read(onboardingProvider).rewarded, isTrue);
      expect(await again.read(onboardingProvider.notifier).complete(), 0);
    });
  });

  group('screen', () {
    Future<(ProviderContainer, GoRouter)> open(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'walletInit': true, 'coin': 0, 'onboardingOffered': true});
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
      addTearDown(c.dispose);
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(initialLocation: '/', routes: [
        GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('HOME'))),
        GoRoute(path: '/tutorial', builder: (_, _) => const TutorialScreen()),
        GoRoute(path: '/levels', builder: (_, _) => const Scaffold(body: Text('LEVELS'))),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ));
      unawaited(router.push('/tutorial'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return (c, router);
    }

    testWidgets('starts with the move lesson and its progress dots', (tester) async {
      await open(tester);
      expect(find.text('Move'), findsOneWidget);
      expect(find.text('Drag the joystick to the glowing spot.'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('Skip leaves, pays nothing and is remembered', (tester) async {
      final (c, _) = await open(tester);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('HOME'), findsOneWidget);
      expect(c.read(onboardingProvider).done, isTrue);
      expect(c.read(walletProvider).coin, 0);
    });
  });
}
