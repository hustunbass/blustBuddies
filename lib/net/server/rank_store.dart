import 'package:blast_buddies/core/rank/rank.dart';

/// A signed-in player as the auth backend knows them.
class AuthUser {
  /// Creates a user.
  const AuthUser(this.id, [this.email]);

  /// Stable account id (Supabase `auth.users.id`).
  final String id;

  /// Optional e-mail, only for logs.
  final String? email;
}

/// Checks the access token a client sends in `hello`.
abstract class AuthVerifier {
  /// The user behind [token], or null if it is invalid or expired.
  Future<AuthUser?> verify(String token);
}

/// One finished ranked game, for the history table.
class RankedResult {
  /// Creates a result.
  const RankedResult({
    required this.season,
    required this.aId,
    required this.bId,
    required this.winnerId,
    required this.reason,
    required this.aBefore,
    required this.aAfter,
    required this.bBefore,
    required this.bAfter,
  });

  /// Season number.
  final int season;

  /// Account ids of the two players.
  final String aId, bId;

  /// Winner's id, null for a draw.
  final String? winnerId;

  /// `normal`, `leave` or `timeout`.
  final String reason;

  /// States before and after the game.
  final RankState aBefore, aAfter, bBefore, bAfter;
}

/// A row of the public leaderboard.
class LeaderboardEntry {
  /// Creates an entry.
  const LeaderboardEntry({
    required this.name,
    required this.league,
    required this.tp,
    required this.mmr,
    required this.games,
    required this.wins,
  });

  /// Display name.
  final String name;

  /// League and TP.
  final League league;

  /// Experience points.
  final int tp;

  /// Hidden rating (used only for ordering, never sent to clients).
  final int mmr;

  /// Games and wins.
  final int games, wins;

  /// What a client may see.
  Map<String, dynamic> toPublicJson() => {
        'name': name,
        'league': league.index,
        'tp': tp,
        'games': games,
        'wins': wins,
      };
}

/// Coins an admin gave to one player (a row of the `grants` table).
class Grant {
  /// Creates a grant.
  const Grant({required this.id, required this.coins, this.note = ''});

  /// Row id (also the idempotency key on the client).
  final int id;

  /// Coins to add.
  final int coins;

  /// Free text of the admin (not shown to the player).
  final String note;

  /// What the client receives.
  Map<String, dynamic> toJson() => {'id': id, 'coins': coins};
}

/// Persistent ranking data.
abstract class RankStore {
  /// The player's state, creating a new profile named [displayName] on first
  /// sight.
  Future<RankState> load(String userId, String displayName);

  /// Saves a finished game and both new states.
  Future<void> recordMatch(RankedResult r);

  /// Best placed players first.
  Future<List<LeaderboardEntry>> leaderboard({int limit = 100});

  /// Gifts for [userId] that have not been confirmed yet, oldest first.
  Future<List<Grant>> pendingGrants(String userId);

  /// Marks the gifts [ids] of [userId] as received (others are ignored).
  Future<void> markGrantsClaimed(String userId, List<int> ids);

  /// Deletes the account with all its data (profile, history, sign-in).
  /// Deleting an account that does not exist is not an error.
  Future<void> deleteAccount(String userId);
}

/// Keeps everything in memory (tests, local runs). Lost on restart.
class InMemoryRankStore implements RankStore {
  final Map<String, RankState> _states = {};
  final Map<String, String> _names = {};

  /// Recorded games, oldest first.
  final List<RankedResult> history = [];

  /// Sets a player's state directly (tests).
  void put(String userId, RankState state, {String name = 'Player'}) {
    _states[userId] = state;
    _names[userId] = name;
  }

  /// Current state of [userId], if known.
  RankState? stateOf(String userId) => _states[userId];

  @override
  Future<RankState> load(String userId, String displayName) async {
    _names.putIfAbsent(userId, () => displayName);
    return _states.putIfAbsent(userId, () => const RankState());
  }

  @override
  Future<void> recordMatch(RankedResult r) async {
    _states[r.aId] = r.aAfter;
    _states[r.bId] = r.bAfter;
    history.add(r);
  }

  @override
  Future<void> deleteAccount(String userId) async {
    _states.remove(userId);
    _names.remove(userId);
    history.removeWhere((r) => r.aId == userId || r.bId == userId);
    deleted.add(userId);
  }

  /// Ids of deleted accounts (tests).
  final List<String> deleted = [];

  final List<({int id, String userId, int coins, bool claimed})> _grants = [];
  int _nextGrant = 1;

  /// Gives [userId] a gift of [coins] (tests); returns its id.
  int addGrant(String userId, int coins) {
    final id = _nextGrant++;
    _grants.add((id: id, userId: userId, coins: coins, claimed: false));
    return id;
  }

  @override
  Future<List<Grant>> pendingGrants(String userId) async => [
        for (final g in _grants)
          if (g.userId == userId && !g.claimed) Grant(id: g.id, coins: g.coins),
      ];

  @override
  Future<void> markGrantsClaimed(String userId, List<int> ids) async {
    for (var i = 0; i < _grants.length; i++) {
      final g = _grants[i];
      if (g.userId == userId && ids.contains(g.id)) {
        _grants[i] = (id: g.id, userId: g.userId, coins: g.coins, claimed: true);
      }
    }
  }

  /// Ids of the gifts confirmed so far (tests).
  List<int> get claimedGrants => [for (final g in _grants) if (g.claimed) g.id];

  @override
  Future<List<LeaderboardEntry>> leaderboard({int limit = 100}) async {
    final rows = [
      for (final e in _states.entries)
        if (!e.value.placing)
          LeaderboardEntry(
            name: _names[e.key] ?? '?',
            league: e.value.league,
            tp: e.value.tp,
            mmr: e.value.mmr,
            games: e.value.games,
            wins: e.value.wins,
          ),
    ]..sort((a, b) => b.mmr.compareTo(a.mmr));
    return rows.take(limit).toList();
  }
}

/// Accepts tokens of the form `dev:<id>` and nothing else. Tests only.
class DevAuthVerifier implements AuthVerifier {
  @override
  Future<AuthUser?> verify(String token) async =>
      token.startsWith('dev:') && token.length > 4 ? AuthUser(token.substring(4)) : null;
}
