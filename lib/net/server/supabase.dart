import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blast_buddies/core/rank/rank.dart';
import 'package:blast_buddies/net/server/rank_store.dart';

/// Minimal Supabase REST client (pure `dart:io`).
class SupabaseApi {
  /// [url] is the project url (`https://xyz.supabase.co`), [key] the API key
  /// sent as `apikey` (anon key for auth checks, service-role key for data).
  SupabaseApi(this.url, this.key, {HttpClient? client})
      : _http = client ?? (HttpClient()..connectionTimeout = const Duration(seconds: 8)),
        _base = url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  /// Project url.
  final String url;

  /// API key.
  final String key;

  final HttpClient _http;
  final String _base;

  /// Sends a request; [bearer] defaults to [key]. Returns status and body.
  Future<(int, String)> request(
    String method,
    String path, {
    Object? body,
    String? bearer,
    Map<String, String> headers = const {},
  }) async {
    final req = await _http.openUrl(method, Uri.parse('$_base$path')).timeout(const Duration(seconds: 8));
    req.headers
      ..set('apikey', key)
      ..set('Content-Type', 'application/json');
    // The new `sb_publishable_...` / `sb_secret_...` keys are not JWTs and go
    // in `apikey` only; the old anon/service_role keys are JWTs and are also
    // sent as the bearer. A player's own access token is always a bearer.
    final auth = bearer ?? (key.startsWith('sb_') ? null : key);
    if (auth != null) req.headers.set('Authorization', 'Bearer $auth');
    headers.forEach(req.headers.set);
    if (body != null) req.add(utf8.encode(jsonEncode(body)));
    final res = await req.close().timeout(const Duration(seconds: 8));
    final text = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 8));
    return (res.statusCode, text);
  }

  /// Closes idle connections.
  void close() => _http.close(force: true);
}

/// Checks a player's access token with Supabase Auth (`GET /auth/v1/user`).
/// Needs only the project url and the public anon key.
class SupabaseAuth implements AuthVerifier {
  /// Creates the verifier.
  SupabaseAuth(this.api);

  /// Client built with the anon key.
  final SupabaseApi api;

  @override
  Future<AuthUser?> verify(String token) async {
    if (token.length > 4096) return null;
    final (status, body) = await api.request('GET', '/auth/v1/user', bearer: token);
    if (status != 200) return null;
    final j = jsonDecode(body);
    if (j is! Map || j['id'] is! String) return null;
    return AuthUser(j['id'] as String, j['email'] as String?);
  }
}

/// Ranking data in Supabase Postgres (see `supabase/schema.sql`). Uses the
/// service-role key: it must exist only on the server.
class SupabaseRankStore implements RankStore {
  /// Creates the store.
  SupabaseRankStore(this.api, {this.season = 1});

  /// Client built with the service-role key.
  final SupabaseApi api;

  /// Season used for new matches.
  final int season;

  static const _cols = 'mmr,games,wins,league,tp,promotion,shield';

  static String _displayName(String s) {
    final t = s.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    final cut = t.length > 16 ? t.substring(0, 16) : t;
    return cut.length < 2 ? 'Player' : cut;
  }

  @override
  Future<RankState> load(String userId, String displayName) async {
    final id = Uri.encodeQueryComponent(userId);
    final (status, body) = await api.request('GET', '/rest/v1/profiles?id=eq.$id&select=$_cols');
    if (status != 200) throw HttpException('profile read failed ($status): $body');
    final rows = jsonDecode(body) as List;
    if (rows.isNotEmpty) return RankState.fromJson((rows.first as Map).cast<String, dynamic>());
    final (ins, text) = await api.request(
      'POST',
      '/rest/v1/profiles?on_conflict=id',
      body: {'id': userId, 'display_name': _displayName(displayName)},
      headers: {'Prefer': 'resolution=ignore-duplicates,return=minimal'},
    );
    if (ins >= 300) throw HttpException('profile create failed ($ins): $text');
    return const RankState();
  }

  @override
  Future<void> recordMatch(RankedResult r) async {
    final (status, body) = await api.request('POST', '/rest/v1/rpc/record_ranked_match', body: {
      'p_season': r.season,
      'p_a': r.aId,
      'p_b': r.bId,
      'p_winner': r.winnerId,
      'p_reason': r.reason,
      'p_a_state': r.aAfter.toJson(),
      'p_b_state': r.bAfter.toJson(),
      'p_a_mmr_before': r.aBefore.mmr,
      'p_b_mmr_before': r.bBefore.mmr,
    });
    if (status >= 300) throw HttpException('saving match failed ($status): $body');
  }

  @override
  Future<void> deleteAccount(String userId) async {
    // Deleting the auth user cascades to the profile and the match history
    // (see schema.sql). Needs the secret key.
    final (status, body) = await api.request('DELETE', '/auth/v1/admin/users/${Uri.encodeComponent(userId)}');
    if (status == 404) return; // already gone
    if (status >= 300) throw HttpException('deleting account failed ($status): $body');
  }

  @override
  Future<List<LeaderboardEntry>> leaderboard({int limit = 100}) async {
    final (status, body) = await api.request(
      'GET',
      '/rest/v1/leaderboard?select=display_name,league,tp,mmr,games,wins&order=position.asc&limit=$limit',
    );
    if (status != 200) throw HttpException('leaderboard read failed ($status): $body');
    return [
      for (final row in jsonDecode(body) as List)
        () {
          final j = (row as Map).cast<String, dynamic>();
          return LeaderboardEntry(
            name: j['display_name'] as String? ?? '?',
            league: League.values[((j['league'] as num?)?.toInt() ?? 0).clamp(0, League.values.length - 1)],
            tp: (j['tp'] as num?)?.toInt() ?? 0,
            mmr: (j['mmr'] as num?)?.toInt() ?? 0,
            games: (j['games'] as num?)?.toInt() ?? 0,
            wins: (j['wins'] as num?)?.toInt() ?? 0,
          );
        }(),
    ];
  }
}
