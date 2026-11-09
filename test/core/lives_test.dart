import 'package:blast_buddies/core/economy/lives.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, LivesNotifier, List<DateTime>)> setup([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
  addTearDown(c.dispose);
  final clock = [DateTime(2026, 1, 1, 12)];
  final n = c.read(livesProvider.notifier)..now = () => clock[0];
  return (c, n, clock);
}

void main() {
  test('starts full and a used life regenerates after 30 minutes', () async {
    final (c, n, clock) = await setup();
    expect(c.read(livesProvider).lives, 5);
    expect(await n.consume(), isTrue);
    expect(c.read(livesProvider).lives, 4);
    clock[0] = clock[0].add(const Duration(minutes: 29));
    n.refresh();
    expect(c.read(livesProvider).lives, 4);
    clock[0] = clock[0].add(const Duration(minutes: 2));
    n.refresh();
    expect(c.read(livesProvider).lives, 5);
  });

  test('cannot go below zero and several lives regenerate over time', () async {
    final (c, n, clock) = await setup();
    for (var i = 0; i < 5; i++) {
      expect(await n.consume(), isTrue);
    }
    expect(await n.consume(), isFalse);
    expect(c.read(livesProvider).lives, 0);
    clock[0] = clock[0].add(const Duration(minutes: 95));
    n.refresh();
    expect(c.read(livesProvider).lives, 3);
  });

  test('refunds and ad lives are capped at five', () async {
    final (c, n, _) = await setup();
    await n.add(3);
    expect(c.read(livesProvider).lives, 5);
    await n.consume();
    await n.add();
    expect(c.read(livesProvider).lives, 5);
  });

  test('setting the device clock back does not extend the wait', () async {
    final (c, n, clock) = await setup();
    for (var i = 0; i < 5; i++) {
      await n.consume();
    }
    clock[0] = clock[0].subtract(const Duration(days: 3));
    n.refresh();
    final left = c.read(livesProvider).untilNext(clock[0])!;
    expect(left <= LivesNotifier.regen, isTrue);
  });

  test('stars get harder: 3 needs no hit and lots of time, 2 allows one hit', () {
    final cfg = LevelConfig.forLevel(10);
    expect(cfg.starsFor(hits: 0, timeLeft: cfg.timeLimit * 0.9), 3);
    expect(cfg.starsFor(hits: 0, timeLeft: cfg.timeLimit * 0.4), 2);
    expect(cfg.starsFor(hits: 1, timeLeft: cfg.timeLimit * 0.9), 2);
    expect(cfg.starsFor(hits: 2, timeLeft: cfg.timeLimit * 0.9), 1);
    expect(cfg.starsFor(hits: 0, timeLeft: cfg.timeLimit * 0.1), 1);
    // The bar rises with the level number.
    final late = LevelConfig.forLevel(99);
    expect(late.starsFor(hits: 0, timeLeft: late.timeLimit * 0.55), 2);
    expect(cfg.starsFor(hits: 0, timeLeft: cfg.timeLimit * 0.55), 3);
  });
}
