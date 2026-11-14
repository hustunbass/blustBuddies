import 'dart:convert';
import 'dart:io';

import 'package:blast_buddies/core/rank/rank.dart';
import 'package:blast_buddies/net/server/rank_store.dart';
import 'package:blast_buddies/net/server/supabase.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tiny stand-in for Supabase that records requests.
class _Fake {
  final requests = <({String method, String path, Map<String, String> headers, String body})>[];
  final replies = <String, (int, String)>{};
  late HttpServer server;

  Future<String> start() async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final body = await utf8.decoder.bind(req).join();
      final path = req.uri.toString();
      requests.add((
        method: req.method,
        path: path,
        headers: {
          'apikey': req.headers.value('apikey') ?? '',
          'authorization': req.headers.value('authorization') ?? '',
          'prefer': req.headers.value('prefer') ?? '',
        },
        body: body,
      ));
      final key = replies.keys.firstWhere((k) => path.startsWith(k), orElse: () => '');
      final (status, text) = replies[key] ?? (404, '{}');
      req.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(text);
      await req.response.close();
    });
    return 'http://127.0.0.1:${server.port}';
  }
}

void main() {
  late _Fake fake;
  late String url;

  setUp(() async {
    fake = _Fake();
    url = await fake.start();
  });
  tearDown(() => fake.server.close(force: true));

  test('auth: valid token returns the user, sent as the bearer with the anon key', () async {
    fake.replies['/auth/v1/user'] = (200, '{"id":"u-1","email":"a@b.c"}');
    final user = await SupabaseAuth(SupabaseApi(url, 'anon-key')).verify('user-jwt');
    expect(user!.id, 'u-1');
    final r = fake.requests.single;
    expect(r.headers['apikey'], 'anon-key');
    expect(r.headers['authorization'], 'Bearer user-jwt');
  });

  test('auth: rejected token and garbage give null', () async {
    fake.replies['/auth/v1/user'] = (401, '{"msg":"bad"}');
    expect(await SupabaseAuth(SupabaseApi(url, 'k')).verify('x'), isNull);
    fake.replies['/auth/v1/user'] = (200, '[1,2]');
    expect(await SupabaseAuth(SupabaseApi(url, 'k')).verify('x'), isNull);
  });

  test('store: existing profile is read, a new one is created and starts fresh', () async {
    final store = SupabaseRankStore(SupabaseApi(url, 'service-key'));
    fake.replies['/rest/v1/profiles?id=eq.u-1'] =
        (200, '[{"mmr":1234,"games":9,"wins":5,"league":2,"tp":61,"promotion":false,"shield":1}]');
    final s = await store.load('u-1', 'Ann');
    expect(s.mmr, 1234);
    expect(s.league, League.gold);
    expect(s.tp, 61);
    expect(fake.requests.single.headers['authorization'], 'Bearer service-key');

    fake.requests.clear();
    fake.replies['/rest/v1/profiles?id=eq.u-2'] = (200, '[]');
    fake.replies['/rest/v1/profiles?on_conflict'] = (201, '');
    final fresh = await store.load('u-2', 'x');
    expect(fresh, const RankState());
    final post = fake.requests.last;
    expect(post.method, 'POST');
    final sent = jsonDecode(post.body) as Map;
    expect(sent['id'], 'u-2');
    expect((sent['display_name'] as String).length, greaterThanOrEqualTo(2), reason: 'DB requires 2..16');
    expect(post.headers['prefer'], contains('ignore-duplicates'));
  });

  test('store: a read error is thrown, not swallowed into a fake profile', () async {
    final store = SupabaseRankStore(SupabaseApi(url, 'k'));
    fake.replies['/rest/v1/profiles?id=eq.u-3'] = (500, 'boom');
    await expectLater(store.load('u-3', 'Ann'), throwsA(isA<HttpException>()));
  });

  test('store: recordMatch calls the RPC with both states and the winner', () async {
    final store = SupabaseRankStore(SupabaseApi(url, 'k'));
    fake.replies['/rest/v1/rpc/record_ranked_match'] = (204, '');
    await store.recordMatch(RankedResult(
      season: 3,
      aId: 'a',
      bId: 'b',
      winnerId: 'a',
      reason: 'leave',
      aBefore: const RankState(),
      aAfter: const RankState(mmr: 1024, games: 1, wins: 1),
      bBefore: const RankState(),
      bAfter: const RankState(mmr: 976, games: 1),
    ));
    final r = fake.requests.single;
    expect(r.path, '/rest/v1/rpc/record_ranked_match');
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    expect(b['p_season'], 3);
    expect(b['p_winner'], 'a');
    expect(b['p_reason'], 'leave');
    expect((b['p_a_state'] as Map)['mmr'], 1024);
    expect((b['p_b_state'] as Map)['mmr'], 976);
    expect(b['p_a_mmr_before'], 1000);
  });

  test('store: leaderboard rows are parsed', () async {
    final store = SupabaseRankStore(SupabaseApi(url, 'k'));
    fake.replies['/rest/v1/leaderboard'] = (
      200,
      '[{"display_name":"Xena","league":4,"tp":120,"mmr":1900,"games":50,"wins":40}]'
    );
    final top = await store.leaderboard(limit: 10);
    expect(top.single.name, 'Xena');
    expect(top.single.league, League.champion);
    expect(fake.requests.single.path, contains('limit=10'));
  });
}
