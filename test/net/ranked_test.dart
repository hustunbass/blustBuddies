import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blast_buddies/core/rank/rank.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:blast_buddies/net/server/blast_server.dart';
import 'package:blast_buddies/net/server/rank_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bare WebSocket client that records every message.
class _Raw {
  _Raw(this.ws) {
    ws.listen((d) => msgs.add(jsonDecode(d as String) as Map<String, dynamic>));
  }

  final WebSocket ws;
  final List<Map<String, dynamic>> msgs = [];

  void send(Map<String, dynamic> m) => ws.add(jsonEncode(m));

  Map<String, dynamic>? last(String type) {
    for (var i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i]['t'] == type) return msgs[i];
    }
    return null;
  }

  bool has(String type, [bool Function(Map<String, dynamic>)? where]) =>
      msgs.any((m) => m['t'] == type && (where?.call(m) ?? true));
}

Future<void> until(bool Function() cond, {Duration timeout = const Duration(seconds: 6)}) async {
  final sw = Stopwatch()..start();
  while (!cond()) {
    if (sw.elapsed > timeout) throw TimeoutException('condition not met');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class _FailingStore extends InMemoryRankStore {
  @override
  Future<void> deleteAccount(String userId) async => throw const HttpException('boom');
}

void main() {
  late BlastServer server;
  late InMemoryRankStore store;
  late String url;
  final open = <_Raw>[];

  Future<_Raw> connect(String name, {String? token}) async {
    final c = _Raw(await WebSocket.connect(url));
    open.add(c);
    c.send({'t': Msg.hello, 'v': protocolVersion, 'name': name, if (token != null) 'auth': token});
    await until(() => c.has(Msg.welcome));
    return c;
  }

  Future<void> startServer({int pairsPerHour = 4}) async {
    store = InMemoryRankStore();
    server = BlastServer(
      countdown: const Duration(milliseconds: 100),
      auth: DevAuthVerifier(),
      ranks: store,
      rankedPairInterval: const Duration(milliseconds: 50),
      maxPairMatchesPerHour: pairsPerHour,
    );
    final port = await server.start(port: 0, address: '127.0.0.1');
    url = 'ws://127.0.0.1:$port';
  }

  setUp(() => startServer());

  tearDown(() async {
    for (final c in open) {
      await c.ws.close();
    }
    open.clear();
    await server.close();
  });

  test('a guest cannot queue for ranked', () async {
    final g = await connect('Guest');
    g.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => g.has(Msg.error, (m) => m['code'] == 'signInRequired'));
  });

  test('a bad token gives a guest welcome with auth:false', () async {
    final g = await connect('Fake', token: 'nope');
    expect(g.last(Msg.welcome)!['auth'], isFalse);
    expect(g.last(Msg.welcome)!.containsKey('rank'), isFalse);
    g.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => g.has(Msg.error, (m) => m['code'] == 'signInRequired'));
  });

  test('a signed-in player gets his rank in the welcome, without the hidden rating', () async {
    final a = await connect('Ann', token: 'dev:ann');
    final rank = a.last(Msg.welcome)!['rank'] as Map<String, dynamic>;
    expect(rank['placing'], isTrue);
    expect(rank.containsKey('mmr'), isFalse);
  });

  test('two even players are paired into a hidden ranked room and the match starts', () async {
    final a = await connect('Ann', token: 'dev:ann');
    final b = await connect('Bob', token: 'dev:bob');
    final watcher = await connect('Watcher');
    a.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => a.has(Msg.queue, (m) => m['on'] == true));
    b.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => a.has(Msg.queue, (m) => m['found'] == true) && b.has(Msg.queue, (m) => m['found'] == true));
    await until(() => a.has(Msg.start) && b.has(Msg.start));

    final room = a.last(Msg.room)!['room'] as Map<String, dynamic>;
    expect(room['ranked'], isTrue);
    expect(room['cap'], 2);
    // Hidden from the lobby and not joinable by code.
    watcher.send({'t': Msg.joinRoom, 'room': room['id']});
    await until(() => watcher.has(Msg.error, (m) => m['code'] == 'roomNotFound'));
    final list = watcher.last(Msg.rooms)!['rooms'] as List;
    expect(list, isEmpty);
    // No advantage ad in ranked.
    expect((a.last(Msg.start)!['boost'] as List).every((x) => x == false), isTrue);
  });

  test('leaving a running ranked match loses it; both ratings and the history are saved', () async {
    final a = await connect('Ann', token: 'dev:ann');
    final b = await connect('Bob', token: 'dev:bob');
    a.send({'t': Msg.rankedQueue, 'on': true});
    b.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => a.has(Msg.start) && b.has(Msg.start));

    b.send({'t': Msg.leaveRoom});
    await until(() => a.has(Msg.end));
    final end = a.last(Msg.end)!;
    final info = end['rank'] as Map<String, dynamic>;
    expect(info['outcome'], 'win');
    expect((info['after'] as Map)['games'], 1);
    expect(info.toString().contains('mmr'), isFalse, reason: 'hidden rating is never sent');

    await until(() => store.history.isNotEmpty);
    final r = store.history.single;
    expect(r.reason, 'leave');
    expect(r.winnerId, 'ann');
    expect(store.stateOf('ann')!.mmr, greaterThan(1000));
    expect(store.stateOf('bob')!.mmr, lessThan(1000));
    expect(store.stateOf('ann')!.games, 1);
    expect(store.stateOf('bob')!.games, 1);
  });

  test('players far apart in rating wait instead of being paired', () async {
    store.put('pro', const RankState(mmr: 1600, games: 30, league: League.diamond, tp: 50));
    final a = await connect('Newbie', token: 'dev:new');
    final b = await connect('Pro', token: 'dev:pro');
    a.send({'t': Msg.rankedQueue, 'on': true});
    b.send({'t': Msg.rankedQueue, 'on': true});
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(a.has(Msg.queue, (m) => m['found'] == true), isFalse);
    expect(server.stats()['queued'], 2);
  });

  test('the same two players are not paired again past the hourly limit', () async {
    await server.close();
    await startServer(pairsPerHour: 0);
    final a = await connect('Ann', token: 'dev:ann');
    final b = await connect('Bob', token: 'dev:bob');
    a.send({'t': Msg.rankedQueue, 'on': true});
    b.send({'t': Msg.rankedQueue, 'on': true});
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(a.has(Msg.queue, (m) => m['found'] == true), isFalse);
  });

  test('leaving the queue works', () async {
    final a = await connect('Ann', token: 'dev:ann');
    a.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => server.stats()['queued'] == 1);
    a.send({'t': Msg.rankedQueue, 'on': false});
    await until(() => server.stats()['queued'] == 0);
    expect(a.has(Msg.queue, (m) => m['on'] == false), isTrue);
  });

  test('the other player searches again when the opponent leaves during the countdown', () async {
    final a = await connect('Ann', token: 'dev:ann');
    final b = await connect('Bob', token: 'dev:bob');
    a.send({'t': Msg.rankedQueue, 'on': true});
    b.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => a.has(Msg.queue, (m) => m['found'] == true));
    b.send({'t': Msg.leaveRoom});
    await until(() => a.has(Msg.queue, (m) => m['left'] == true));
    expect(server.stats()['queued'], 1);
    expect(a.has(Msg.start), isFalse);
  });

  test('the same account cannot queue twice from two devices', () async {
    final a1 = await connect('Ann', token: 'dev:ann');
    final a2 = await connect('Ann2', token: 'dev:ann');
    a1.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => server.stats()['queued'] == 1);
    a2.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => a2.has(Msg.error, (m) => m['code'] == 'alreadyRanked'));
  });

  test('deleting the account removes all data and turns the player into a guest', () async {
    final a = await connect('Ann', token: 'dev:ann');
    final a2 = await connect('Ann phone', token: 'dev:ann');
    a.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => server.stats()['queued'] == 1);

    a.send({'t': Msg.deleteAccount});
    await until(() => a.has(Msg.accountDeleted));
    expect(store.deleted, ['ann']);
    expect(store.stateOf('ann'), isNull);
    expect(server.stats()['queued'], 0, reason: 'leaves the queue');

    // Both connections of that account are guests now.
    a.send({'t': Msg.rankedQueue, 'on': true});
    a2.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => a.has(Msg.error, (m) => m['code'] == 'signInRequired'));
    await until(() => a2.has(Msg.error, (m) => m['code'] == 'signInRequired'));
  });

  test('a guest cannot delete an account', () async {
    final g = await connect('Guest');
    g.send({'t': Msg.deleteAccount});
    await until(() => g.has(Msg.error, (m) => m['code'] == 'signInRequired'));
    expect(g.has(Msg.accountDeleted), isFalse);
  });

  test('a store failure is reported and nothing changes', () async {
    await server.close();
    final failing = _FailingStore();
    server = BlastServer(auth: DevAuthVerifier(), ranks: failing);
    url = 'ws://127.0.0.1:${await server.start(port: 0, address: '127.0.0.1')}';
    final a = await connect('Ann', token: 'dev:ann');
    a.send({'t': Msg.deleteAccount});
    await until(() => a.has(Msg.error, (m) => m['code'] == 'accountDeleteFailed'));
    expect(a.has(Msg.accountDeleted), isFalse);
    // Still signed in: can retry.
    a.send({'t': Msg.rankedQueue, 'on': true});
    await until(() => a.has(Msg.queue, (m) => m['on'] == true));
  });

  test('leaderboard lists placed players only', () async {
    store.put('x', const RankState(mmr: 1300, games: 12, wins: 8, league: League.gold, tp: 60), name: 'Xena');
    store.put('y', const RankState(mmr: 1100, games: 2), name: 'Yan');
    final a = await connect('Ann');
    a.send({'t': Msg.leaderboardRequest});
    await until(() => a.has(Msg.leaderboard));
    final top = a.last(Msg.leaderboard)!['top'] as List;
    expect(top.length, 1);
    expect((top.single as Map)['name'], 'Xena');
    expect((top.single as Map).containsKey('mmr'), isFalse);
  });
}
