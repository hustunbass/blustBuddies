import 'package:blast_buddies/core/rank/rank.dart';
import 'package:flutter_test/flutter_test.dart';

RankState _placed({League league = League.silver, int tp = 50, int mmr = 1100, int shield = 0, bool promo = false}) =>
    RankState(mmr: mmr, games: 20, wins: 10, league: league, tp: tp, shield: shield, promotion: promo);

void main() {
  group('hidden rating', () {
    test('equal players: winner gains, loser loses, same amount', () {
      final w = Ranking.apply(const RankState(games: 40, mmr: 1200), 1200, Outcome.win);
      final l = Ranking.apply(const RankState(games: 40, mmr: 1200), 1200, Outcome.loss);
      expect(w.mmrDelta, 12);
      expect(l.mmrDelta, -12);
    });

    test('beating a stronger player pays more than beating a weaker one', () {
      final up = Ranking.apply(_placed(mmr: 1000), 1300, Outcome.win);
      final down = Ranking.apply(_placed(mmr: 1000), 700, Outcome.win);
      expect(up.mmrDelta, greaterThan(down.mmrDelta));
    });

    test('draw between equals changes nothing', () {
      final r = Ranking.apply(_placed(mmr: 1100), 1100, Outcome.draw);
      expect(r.mmrDelta, 0);
      expect(r.tpDelta, 0);
      expect(r.after.games, 21);
    });

    test('never below zero', () {
      final r = Ranking.apply(const RankState(mmr: 5, games: 3), 3000, Outcome.loss);
      expect(r.after.mmr, greaterThanOrEqualTo(0));
    });
  });

  group('tp sizing', () {
    test('equal opponents: +22 / -18', () {
      expect(Ranking.tpForWin(1200, 1200), 22);
      expect(Ranking.tpForLoss(1200, 1200), 18);
    });

    test('stays inside 10..34 and 8..28', () {
      for (final gap in [-2000, -600, 0, 600, 2000]) {
        final w = Ranking.tpForWin(1500, 1500 + gap);
        final l = Ranking.tpForLoss(1500, 1500 + gap);
        expect(w, inInclusiveRange(10, 34));
        expect(l, inInclusiveRange(8, 28));
      }
    });

    test('an even player gains more than he loses (no TP treadmill)', () {
      expect(Ranking.tpForWin(1000, 1000), greaterThan(Ranking.tpForLoss(1000, 1000)));
    });
  });

  group('placement', () {
    test('only the hidden rating moves until the fifth game', () {
      var s = const RankState();
      for (var i = 0; i < 4; i++) {
        final c = Ranking.apply(s, 1000, Outcome.win);
        s = c.after;
        expect(s.placing, isTrue);
        expect(s.tp, 0);
        expect(c.placed, isFalse);
      }
      expect(s.games, 4);
      final last = Ranking.apply(s, 1000, Outcome.win);
      expect(last.placed, isTrue);
      expect(last.after.placing, isFalse);
      expect(last.after.tp, RankRules.placementTp);
      expect(last.after.shield, RankRules.demotionShieldGames);
    });

    test('a perfect run places in gold, never above', () {
      var s = const RankState();
      for (var i = 0; i < 5; i++) {
        s = Ranking.apply(s, 1600, Outcome.win).after;
      }
      expect(s.league, League.gold);
    });

    test('losing everything places in bronze', () {
      var s = const RankState();
      for (var i = 0; i < 5; i++) {
        s = Ranking.apply(s, 1000, Outcome.loss).after;
      }
      expect(s.league, League.bronze);
    });

    test('placement thresholds', () {
      expect(Ranking.placementLeague(900), League.bronze);
      expect(Ranking.placementLeague(RankRules.placeSilver), League.silver);
      expect(Ranking.placementLeague(RankRules.placeGold), League.gold);
      expect(Ranking.placementLeague(2500), League.gold);
    });
  });

  group('promotion', () {
    test('reaching 100 TP offers a promotion match and holds at 100', () {
      final c = Ranking.apply(_placed(tp: 95), 1100, Outcome.win);
      expect(c.promotionOffered, isTrue);
      expect(c.after.promotion, isTrue);
      expect(c.after.tp, 100);
      expect(c.after.league, League.silver);
    });

    test('winning the promotion match moves up with a TP head start and a shield', () {
      final c = Ranking.apply(_placed(tp: 100, promo: true), 1100, Outcome.win);
      expect(c.promoted, isTrue);
      expect(c.after.league, League.gold);
      expect(c.after.tp, RankRules.promotedTp);
      expect(c.after.promotion, isFalse);
      expect(c.after.shield, RankRules.demotionShieldGames);
    });

    test('losing it falls back to 75 TP and the league stays', () {
      final c = Ranking.apply(_placed(tp: 100, promo: true), 1100, Outcome.loss);
      expect(c.promotionFailed, isTrue);
      expect(c.after.league, League.silver);
      expect(c.after.tp, RankRules.failedPromotionTp);
      expect(c.after.promotion, isFalse);
    });

    test('a draw in a promotion match leaves it pending', () {
      final c = Ranking.apply(_placed(tp: 100, promo: true), 1100, Outcome.draw);
      expect(c.after.promotion, isTrue);
      expect(c.after.league, League.silver);
    });

    test('champion has no promotion and TP is not capped', () {
      final c = Ranking.apply(_placed(league: League.champion, tp: 130), 1900, Outcome.win);
      expect(c.promotionOffered, isFalse);
      expect(c.after.tp, greaterThan(130));
      expect(c.after.league, League.champion);
    });

    test('full climb: bronze to silver in a realistic win streak', () {
      var s = _placed(league: League.bronze, tp: 40, mmr: 1000);
      var games = 0;
      while (!s.promotion && games < 50) {
        s = Ranking.apply(s, s.mmr, Outcome.win).after;
        games++;
      }
      expect(s.promotion, isTrue);
      expect(games, lessThanOrEqualTo(4));
      expect(Ranking.apply(s, s.mmr, Outcome.win).after.league, League.silver);
    });
  });

  group('demotion', () {
    test('dropping below 0 TP demotes to the league below at 75 TP', () {
      final c = Ranking.apply(_placed(league: League.gold, tp: 5), 1100, Outcome.loss);
      expect(c.demoted, isTrue);
      expect(c.after.league, League.silver);
      expect(c.after.tp, RankRules.demotedTp);
    });

    test('the shield after a promotion holds the player at 0 TP', () {
      final c = Ranking.apply(_placed(league: League.gold, tp: 5, shield: 2), 1100, Outcome.loss);
      expect(c.demoted, isFalse);
      expect(c.after.league, League.gold);
      expect(c.after.tp, 0);
    });

    test('bronze cannot be demoted', () {
      final c = Ranking.apply(_placed(league: League.bronze, tp: 3), 1000, Outcome.loss);
      expect(c.demoted, isFalse);
      expect(c.after.tp, 0);
    });

    test('shield counts down game by game', () {
      var s = _placed(shield: 3);
      s = Ranking.apply(s, 1100, Outcome.win).after;
      expect(s.shield, 2);
    });
  });
}
