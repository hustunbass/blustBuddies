import 'package:blast_buddies/core/daily/daily.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/features/daily/daily_screen.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A container with a clock the test can move.
class Rig {
  Rig(this.prefs, this.clock);

  final SharedPreferences prefs;
  DateTime clock;

  /// Starts the app on [clock]; reading the provider runs the day roll-over.
  ProviderContainer open() {
    final c = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      dailyClockProvider.overrideWithValue(() => clock),
    ]);
    addTearDown(c.dispose);
    c.read(dailyProvider);
    return c;
  }
}

Future<Rig> rig([Map<String, Object> values = const {}, DateTime? start]) async {
  SharedPreferences.setMockInitialValues({'walletInit': true, 'coin': 0, ...values});
  return Rig(await SharedPreferences.getInstance(), start ?? DateTime(2026, 3, 10, 9));
}

void main() {
  group('streak', () {
    test('starts at 1 and grows on consecutive days', () async {
      final r = await rig();
      var c = r.open();
      expect(c.read(dailyProvider).streak, 1);
      r.clock = DateTime(2026, 3, 11, 23, 59);
      c = r.open();
      expect(c.read(dailyProvider).streak, 2);
      r.clock = DateTime(2026, 3, 12, 0, 1);
      c = r.open();
      expect(c.read(dailyProvider).streak, 3);
      expect(c.read(dailyProvider).bestStreak, 3);
    });

    test('opening the app again the same day changes nothing', () async {
      final r = await rig();
      r.open();
      r.clock = DateTime(2026, 3, 10, 22);
      final c = r.open();
      expect(c.read(dailyProvider).streak, 1);
    });

    test('a missed day resets the streak but keeps the best one', () async {
      final r = await rig();
      r.open();
      r.clock = DateTime(2026, 3, 11, 9);
      r.open();
      r.clock = DateTime(2026, 3, 14, 9); // two days skipped
      final c = r.open();
      expect(c.read(dailyProvider).streak, 1);
      expect(c.read(dailyProvider).bestStreak, 2);
    });

    test('moving the clock back never rewinds or extends the streak', () async {
      final r = await rig();
      r.open();
      r.clock = DateTime(2026, 3, 11, 9);
      r.open();
      r.clock = DateTime(2026, 3, 1, 9);
      final c = r.open();
      expect(c.read(dailyProvider).streak, 2);
      expect(c.read(dailyProvider).day, DailyNotifier.dayNumber(DateTime(2026, 3, 11)));
    });

    test('refresh rolls over when the app stays open past midnight', () async {
      final r = await rig();
      final c = r.open();
      expect(c.read(dailyProvider).streak, 1);
      r.clock = DateTime(2026, 3, 11, 0, 5);
      c.read(dailyProvider.notifier).refresh();
      expect(c.read(dailyProvider).streak, 2);
      expect(c.read(dailyProvider).loginClaimed, isFalse);
    });

    test('feeds the streak achievements (best streak, claimed or not)', () async {
      final r = await rig();
      for (var d = 0; d < 3; d++) {
        r.clock = DateTime(2026, 3, 10 + d, 9);
        r.open();
      }
      final c = r.open();
      final fresh = await c.read(statsProvider.notifier).check();
      expect(fresh.map((a) => a.id), contains('streak_3'));
    });
  });

  group('login reward', () {
    test('pays the day of the 7-day cycle once', () async {
      final r = await rig();
      final c = r.open();
      final n = c.read(dailyProvider.notifier);
      expect(n.loginReward, 10);
      expect(await n.claimLogin(), 10);
      expect(await n.claimLogin(), 0);
      expect(c.read(walletProvider).coin, 10);
    });

    test('rewards rise over the week and the cycle repeats', () async {
      final r = await rig();
      var total = 0;
      for (var d = 0; d < 8; d++) {
        r.clock = DateTime(2026, 3, 10 + d, 9);
        final c = r.open();
        final n = c.read(dailyProvider.notifier);
        final expected = DailyNotifier.loginRewards[d % 7];
        expect(n.loginReward, expected, reason: 'day ${d + 1}');
        total += await n.claimLogin();
      }
      expect(total, DailyNotifier.loginRewards.reduce((a, b) => a + b) + 10);
    });

    test('claiming survives a restart on the same day', () async {
      final r = await rig();
      await r.open().read(dailyProvider.notifier).claimLogin();
      final c = r.open();
      expect(c.read(dailyProvider).loginClaimed, isTrue);
      expect(await c.read(dailyProvider.notifier).claimLogin(), 0);
    });
  });

  group('quests', () {
    test('three quests per day, one per tier, never the same statistic', () {
      for (var day = 0; day < 400; day++) {
        final q = questsForDay(day);
        expect(q.map((e) => e.tier), [QuestTier.easy, QuestTier.medium, QuestTier.hard]);
        expect(q.map((e) => e.stat).toSet().length, 3, reason: 'day $day');
      }
    });

    test('are the same for the same day and vary over days', () {
      expect(questsForDay(500).map((q) => q.id), questsForDay(500).map((q) => q.id));
      final seen = {for (var d = 0; d < 30; d++) questsForDay(d).map((q) => q.id).join(',')};
      expect(seen.length, greaterThan(10));
    });

    test('progress counts only what happens today', () async {
      final r = await rig();
      var c = r.open();
      await c.read(statsProvider.notifier).add({'kills': 100, 'blocks': 100, 'bombs': 100, 'games': 10, 'powerups': 10});
      // A new day: yesterday's totals are the baseline.
      r.clock = DateTime(2026, 3, 11, 9);
      c = r.open();
      final n = c.read(dailyProvider.notifier);
      for (final q in n.quests) {
        expect(n.progress(q), 0, reason: q.id);
      }
      final q = n.quests.first;
      await c.read(statsProvider.notifier).add({q.stat: q.goal + 5});
      expect(n.progress(q), q.goal); // capped at the goal
      expect(n.isDone(q), isTrue);
    });

    test('pay once, only when finished', () async {
      final r = await rig();
      final c = r.open();
      final n = c.read(dailyProvider.notifier);
      final q = n.quests.first;
      expect(await n.claimQuest(q), 0); // not finished
      await c.read(statsProvider.notifier).add({q.stat: q.goal});
      expect(n.canClaim(q), isTrue);
      expect(await n.claimQuest(q), q.reward);
      expect(await n.claimQuest(q), 0);
      expect(c.read(walletProvider).coin, q.reward);
    });

    test('the all-quests bonus needs all three claimed, once', () async {
      final r = await rig();
      final c = r.open();
      final n = c.read(dailyProvider.notifier);
      expect(await n.claimBonus(), 0);
      var total = 0;
      for (final q in n.quests) {
        await c.read(statsProvider.notifier).add({q.stat: q.goal});
        total += await n.claimQuest(q);
        if (q != n.quests.last) expect(await n.claimBonus(), 0);
      }
      expect(await n.claimBonus(), DailyNotifier.allDoneBonus);
      expect(await n.claimBonus(), 0);
      expect(c.read(walletProvider).coin, total + DailyNotifier.allDoneBonus);
    });

    test('a new day resets claims and bonus', () async {
      final r = await rig();
      var c = r.open();
      await c.read(dailyProvider.notifier).claimLogin();
      r.clock = DateTime(2026, 3, 11, 9);
      c = r.open();
      expect(c.read(dailyProvider).loginClaimed, isFalse);
      expect(c.read(dailyProvider).claimed, isEmpty);
      expect(c.read(dailyProvider).bonusClaimed, isFalse);
    });
  });

  group('red dot', () {
    test('shows until everything is collected, comes back with progress', () async {
      final r = await rig();
      final c = r.open();
      final n = c.read(dailyProvider.notifier);
      expect(c.read(dailyAttentionProvider), isTrue); // login reward waiting
      await n.claimLogin();
      expect(c.read(dailyAttentionProvider), isFalse);
      final q = n.quests.first;
      await c.read(statsProvider.notifier).add({q.stat: q.goal});
      expect(c.read(dailyAttentionProvider), isTrue); // a finished quest
      await n.claimQuest(q);
      expect(c.read(dailyAttentionProvider), isFalse);
    });
  });

  testWidgets('the daily screen shows the streak, claims the reward and a quest', (tester) async {
    final r = await rig({}, DateTime(2026, 3, 10, 9));
    final c = r.open();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DailyScreen(),
      ),
    ));
    await tester.pump();
    expect(find.text('1-day streak'), findsOneWidget);
    expect(find.text("Today's quests"), findsOneWidget);
    await tester.tap(find.text('Claim · 10'));
    await tester.pump();
    await tester.pump();
    expect(c.read(walletProvider).coin, 10);
    expect(find.text('Collected – come back tomorrow'), findsOneWidget);
    final q = c.read(dailyProvider.notifier).quests.first;
    await c.read(statsProvider.notifier).add({q.stat: q.goal});
    await tester.pump();
    await tester.tap(find.text(' ${q.reward}'));
    await tester.pump();
    await tester.pump();
    expect(c.read(walletProvider).coin, 10 + q.reward);
  });
}
