import 'dart:math';

/// Competitive leagues, lowest first.
enum League {
  /// Entry league.
  bronze,

  /// Second league.
  silver,

  /// Third league.
  gold,

  /// Fourth league.
  diamond,

  /// Top league: no promotion match, rank is the leaderboard position.
  champion;

  /// The next league up, or null at the top.
  League? get next => index + 1 < League.values.length ? League.values[index + 1] : null;

  /// The next league down, or null at the bottom.
  League? get previous => index > 0 ? League.values[index - 1] : null;
}

/// Result of a ranked 1v1 for one player.
enum Outcome {
  /// The player won.
  win,

  /// The player lost (including leaving a running match).
  loss,

  /// Time ran out with no winner.
  draw,
}

/// Tunable numbers of the ranking system, in one place.
class RankRules {
  RankRules._();

  /// Hidden rating every new player starts with.
  static const int startMmr = 1000;

  /// Ranked games before the league is assigned.
  static const int placementGames = 5;

  /// Highest league a placement can award.
  static const League placementCeiling = League.gold;

  /// Hidden-rating thresholds used to assign the league after placement.
  static const int placeSilver = 1040;

  /// See [placeSilver].
  static const int placeGold = 1110;

  /// TP a player has right after placement.
  static const int placementTp = 40;

  /// TP needed to be offered a promotion match.
  static const int promotionTp = 100;

  /// TP after winning a promotion match.
  static const int promotedTp = 25;

  /// TP after losing a promotion match.
  static const int failedPromotionTp = 75;

  /// TP after dropping into the league below.
  static const int demotedTp = 75;

  /// Games after a promotion in which TP cannot drop the player a league.
  static const int demotionShieldGames = 3;

  /// Largest MMR gap a matchmaker should ever accept.
  static const int maxMatchGap = 600;

  /// K factor: fast while the rating is still uncertain.
  static int kFactor(int games, int mmr) {
    if (games < placementGames) return 48;
    if (games < 30) return 32;
    return mmr >= 1800 ? 20 : 24;
  }

  /// Probability that a player rated [own] beats one rated [opponent].
  static double expected(int own, int opponent) => 1 / (1 + pow(10, (opponent - own) / 400));
}

/// Everything the ranking remembers about one player.
class RankState {
  /// Creates a state; the defaults are a brand-new player.
  const RankState({
    this.mmr = RankRules.startMmr,
    this.games = 0,
    this.wins = 0,
    this.league = League.bronze,
    this.tp = 0,
    this.promotion = false,
    this.shield = 0,
  });

  /// Hidden rating (Elo). Used for matchmaking and to size TP changes.
  final int mmr;

  /// Ranked games played.
  final int games;

  /// Ranked games won.
  final int wins;

  /// Current league (meaningless while [placing]).
  final League league;

  /// Experience points inside the league, 0..100 (unbounded in champion).
  final int tp;

  /// True while the next game is a promotion match.
  final bool promotion;

  /// Games left in which the player cannot be demoted.
  final int shield;

  /// True until the placement games are done.
  bool get placing => games < RankRules.placementGames;

  /// Copy with changes.
  RankState copyWith({
    int? mmr,
    int? games,
    int? wins,
    League? league,
    int? tp,
    bool? promotion,
    int? shield,
  }) =>
      RankState(
        mmr: mmr ?? this.mmr,
        games: games ?? this.games,
        wins: wins ?? this.wins,
        league: league ?? this.league,
        tp: tp ?? this.tp,
        promotion: promotion ?? this.promotion,
        shield: shield ?? this.shield,
      );

  @override
  bool operator ==(Object other) =>
      other is RankState &&
      other.mmr == mmr &&
      other.games == games &&
      other.wins == wins &&
      other.league == league &&
      other.tp == tp &&
      other.promotion == promotion &&
      other.shield == shield;

  @override
  int get hashCode => Object.hash(mmr, games, wins, league, tp, promotion, shield);

  @override
  String toString() => 'RankState(mmr $mmr, ${league.name} $tp TP, games $games'
      '${promotion ? ', promotion' : ''}${shield > 0 ? ', shield $shield' : ''})';
}

/// What one game did to a player's rank.
class RankChange {
  /// Creates a change record.
  const RankChange({
    required this.before,
    required this.after,
    required this.outcome,
    this.promoted = false,
    this.demoted = false,
    this.promotionFailed = false,
    this.promotionOffered = false,
    this.placed = false,
  });

  /// State before the game.
  final RankState before;

  /// State after the game.
  final RankState after;

  /// The result that caused it.
  final Outcome outcome;

  /// Won a promotion match: moved up a league.
  final bool promoted;

  /// Dropped into the league below.
  final bool demoted;

  /// Lost a promotion match.
  final bool promotionFailed;

  /// Reached the TP target: the next game is a promotion match.
  final bool promotionOffered;

  /// This game finished the placement series.
  final bool placed;

  /// TP gained or lost (league changes aside).
  int get tpDelta => after.tp - before.tp;

  /// Hidden rating gained or lost.
  int get mmrDelta => after.mmr - before.mmr;
}

/// Pure ranking rules for a ranked 1v1.
class Ranking {
  Ranking._();

  /// League a player lands in after placement, from the hidden rating.
  static League placementLeague(int mmr) {
    final League l = mmr >= RankRules.placeGold
        ? League.gold
        : mmr >= RankRules.placeSilver
            ? League.silver
            : League.bronze;
    return League.values[min(l.index, RankRules.placementCeiling.index)];
  }

  /// TP won for a victory over an opponent rated [opponentMmr]: 10 to 34, 22
  /// between equals; beating a stronger player pays more.
  static int tpForWin(int mmr, int opponentMmr) =>
      (10 + 24 * (1 - RankRules.expected(mmr, opponentMmr))).round();

  /// TP lost for a defeat: 8 to 28, 18 between equals; losing to a weaker
  /// player costs more.
  static int tpForLoss(int mmr, int opponentMmr) =>
      (8 + 20 * RankRules.expected(mmr, opponentMmr)).round();

  /// Applies one finished game to [s].
  static RankChange apply(RankState s, int opponentMmr, Outcome outcome) {
    final score = switch (outcome) {
      Outcome.win => 1.0,
      Outcome.draw => 0.5,
      Outcome.loss => 0.0,
    };
    final k = RankRules.kFactor(s.games, s.mmr);
    final mmr = max(0, s.mmr + (k * (score - RankRules.expected(s.mmr, opponentMmr))).round());
    final games = s.games + 1;
    final wins = s.wins + (outcome == Outcome.win ? 1 : 0);

    // Placement: only the hidden rating moves until the last game.
    if (s.placing) {
      if (games < RankRules.placementGames) {
        return RankChange(
          before: s,
          after: s.copyWith(mmr: mmr, games: games, wins: wins),
          outcome: outcome,
        );
      }
      return RankChange(
        before: s,
        after: RankState(
          mmr: mmr,
          games: games,
          wins: wins,
          league: placementLeague(mmr),
          tp: RankRules.placementTp,
          shield: RankRules.demotionShieldGames,
        ),
        outcome: outcome,
        placed: true,
      );
    }

    final shield = max(0, s.shield - 1);
    var next = s.copyWith(mmr: mmr, games: games, wins: wins, shield: shield);

    if (outcome == Outcome.draw) return RankChange(before: s, after: next, outcome: outcome);

    // Promotion match: win moves up, loss falls back and has to be re-earned.
    if (s.promotion) {
      if (outcome == Outcome.win) {
        return RankChange(
          before: s,
          after: next.copyWith(
            league: s.league.next ?? s.league,
            tp: RankRules.promotedTp,
            promotion: false,
            shield: RankRules.demotionShieldGames,
          ),
          outcome: outcome,
          promoted: true,
        );
      }
      return RankChange(
        before: s,
        after: next.copyWith(tp: RankRules.failedPromotionTp, promotion: false),
        outcome: outcome,
        promotionFailed: true,
      );
    }

    if (outcome == Outcome.win) {
      final tp = s.tp + tpForWin(s.mmr, opponentMmr);
      if (s.league.next != null && tp >= RankRules.promotionTp) {
        return RankChange(
          before: s,
          after: next.copyWith(tp: RankRules.promotionTp, promotion: true),
          outcome: outcome,
          promotionOffered: true,
        );
      }
      return RankChange(before: s, after: next.copyWith(tp: tp), outcome: outcome);
    }

    // Loss.
    final tp = s.tp - tpForLoss(s.mmr, opponentMmr);
    if (tp >= 0) {
      next = next.copyWith(tp: tp);
      return RankChange(before: s, after: next, outcome: outcome);
    }
    final lower = s.league.previous;
    if (lower == null || s.shield > 0) {
      return RankChange(before: s, after: next.copyWith(tp: 0), outcome: outcome);
    }
    return RankChange(
      before: s,
      after: next.copyWith(league: lower, tp: RankRules.demotedTp),
      outcome: outcome,
      demoted: true,
    );
  }
}
