import 'dart:async';

import 'package:blast_buddies/core/rank/rank.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/server/blast_server.dart';
import 'package:blast_buddies/net/server/rank_store.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> until(bool Function() cond, {Duration timeout = const Duration(seconds: 6)}) async {
  final sw = Stopwatch()..start();
  while (!cond()) {
    if (sw.elapsed > timeout) throw TimeoutException('condition not met');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late BlastServer server;
  late InMemoryRankStore store;
  late String address;
  final clients = <OnlineClient>[];

  Future<OnlineClient> connect(String name, {String? token}) async {
    final c = OnlineClient();
    clients.add(c);
    expect(await c.connect(address, name, authToken: token), isTrue);
    return c;
  }

  setUp(() async {
    store = InMemoryRankStore();
    server = BlastServer(
      countdown: const Duration(milliseconds: 100),
      auth: DevAuthVerifier(),
      ranks: store,
      rankedPairInterval: const Duration(milliseconds: 50),
    );
    address = '127.0.0.1:${await server.start(port: 0, address: '127.0.0.1')}';
  });

  tearDown(() async {
    for (final c in clients) {
      await c.disconnect();
    }
    clients.clear();
    await server.close();
  });

  test('signed-in players know their rank, guests do not', () async {
    final a = await connect('Ann', token: 'dev:ann');
    final g = await connect('Guest');
    final bad = await connect('Fake', token: 'garbage');
    expect(a.rank, isNotNull);
    expect(a.rank!.placing, isTrue);
    expect(g.rank, isNull);
    expect(bad.rank, isNull);
    expect(bad.authRejected, isTrue);
    expect(g.authRejected, isFalse);
  });

  test('ranked search finds an opponent; leaving ends it with a rank result for the winner', () async {
    final a = await connect('Ann', token: 'dev:ann');
    final b = await connect('Bob', token: 'dev:bob');
    a.rankedSearch();
    await until(() => a.searchingRanked);
    b.rankedSearch();
    await until(() => a.match != null && b.match != null);
    expect(a.room!.ranked, isTrue);
    expect(a.searchingRanked, isFalse);

    b.leaveRoom();
    await until(() => a.rankResult != null);
    final r = a.rankResult!;
    expect(r.outcome, Outcome.win);
    expect(r.after.games, 1);
    expect(a.rank!.games, 1);
    expect(b.rankResult, isNull, reason: 'the leaver left the match already');
  });

  test('cancelling the search stops it', () async {
    final a = await connect('Ann', token: 'dev:ann');
    a.rankedSearch();
    await until(() => a.searchingRanked);
    a.cancelRanked();
    await until(() => !a.searchingRanked);
    expect(server.stats()['queued'], 0);
  });

  test('casual rooms stay casual even for signed-in players: no rank result, no rank change', () async {
    final a = await connect('Ann', token: 'dev:ann');
    final b = await connect('Bob', token: 'dev:bob');
    a.createRoom(name: 'Fun', capacity: 2, teams: false);
    await until(() => a.room != null);
    expect(a.room!.ranked, isFalse);
    b.joinRoom(a.room!.id);
    await until(() => b.room != null);
    a.setReady(true);
    b.setReady(true);
    await until(() => a.match != null && b.match != null);
    b.leaveRoom();
    await until(() => a.match?.ended ?? false);
    expect(a.rankResult, isNull);
    expect(a.rank!.games, 0);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(store.history, isEmpty);
  });

  test('leaderboard request fills the list', () async {
    store.put('x', const RankState(mmr: 1400, games: 12, wins: 9, league: League.gold, tp: 40), name: 'Xena');
    final a = await connect('Ann');
    a.requestLeaderboard();
    await until(() => a.leaderboard.isNotEmpty);
    expect(a.leaderboard.single.name, 'Xena');
    expect(a.leaderboard.single.league, League.gold);
  });

  test('guests who try to search get a sign-in error', () async {
    final g = await connect('Guest');
    final errors = <Object>[];
    final sub = g.errors.listen(errors.add);
    g.rankedSearch();
    await until(() => errors.isNotEmpty);
    expect(errors.first.toString(), contains('signInRequired'));
    expect(g.searchingRanked, isFalse);
    await sub.cancel();
  });
}
