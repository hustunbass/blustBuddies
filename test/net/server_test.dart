import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:blast_buddies/net/server_config.dart';
import 'package:blast_buddies/net/server/blast_server.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> waitFor(bool Function() cond, {Duration timeout = const Duration(seconds: 5)}) async {
  final sw = Stopwatch()..start();
  while (!cond()) {
    if (sw.elapsed > timeout) throw TimeoutException('condition not met');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late BlastServer server;
  late String address;
  final clients = <OnlineClient>[];

  Future<OnlineClient> connect(String name) async {
    final c = OnlineClient();
    clients.add(c);
    expect(await c.connect(address, name), isTrue);
    return c;
  }

  setUp(() async {
    server = BlastServer(countdown: const Duration(milliseconds: 150), passwordAttempts: 2);
    final port = await server.start(port: 0, address: '127.0.0.1');
    address = '127.0.0.1:$port';
  });

  tearDown(() async {
    for (final c in clients) {
      await c.disconnect();
    }
    clients.clear();
    await server.close();
  });

  test('parseServerAddress adds scheme and default port', () {
    expect(parseServerAddress('192.168.1.5').toString(), 'ws://192.168.1.5:$defaultServerPort');
    expect(parseServerAddress('host:9000').toString(), 'ws://host:9000');
    expect(parseServerAddress('wss://game.example.com').toString(), 'wss://game.example.com');
    expect(parseServerAddress(''), isNull);
    expect(parseServerAddress('http://x'), isNull);
    final def = parseServerAddress(defaultServerUrl)!;
    expect(def.scheme, 'wss');
    expect(def.host, isNotEmpty);
  });

  test('server answers pings and the client measures round-trip time', () async {
    final c = await connect('Ping');
    expect(c.rtt, inInclusiveRange(0.02, 0.5));
    final ws = await WebSocket.connect('ws://$address');
    final got = <Map<String, dynamic>>[];
    ws.listen((m) => got.add(jsonDecode(m as String) as Map<String, dynamic>));
    ws.add(jsonEncode({'t': Msg.hello, 'name': 'raw', 'v': protocolVersion}));
    await waitFor(() => got.any((m) => m['t'] == Msg.welcome));
    expect(got.firstWhere((m) => m['t'] == Msg.welcome)['ping'], isTrue);
    ws.add(jsonEncode({'t': Msg.ping, 'c': 12.5}));
    await waitFor(() => got.any((m) => m['t'] == Msg.pong));
    expect(got.firstWhere((m) => m['t'] == Msg.pong)['c'], 12.5);
    await ws.close();
  });

  test('/stats reports players, rooms, matches and load', () async {
    Future<Map<String, dynamic>> stats() async {
      final http = HttpClient();
      final res = await (await http.getUrl(Uri.parse('http://$address/stats'))).close();
      final body = await res.transform(utf8.decoder).join();
      http.close();
      expect(res.headers.contentType?.mimeType, 'application/json');
      return jsonDecode(body) as Map<String, dynamic>;
    }

    var s = await stats();
    expect(s['online'], 0);
    expect(s['load'], 'ok');

    final a = await connect('A');
    final b = await connect('B');
    a.createRoom(name: 'R', capacity: 2, teams: false);
    await waitFor(() => b.rooms.isNotEmpty);
    b.joinRoom(b.rooms.single.id);
    await waitFor(() => a.room?.filled == 2);
    a.setReady(true);
    b.setReady(true);
    await waitFor(() => a.match != null);

    s = await stats();
    expect(s['online'], 2);
    expect(s['peakOnline'], 2);
    expect(s['rooms'], 1);
    expect(s['matches'], 1);
    expect(s['inMatch'], 2);
    expect(s['lagMs'], isA<int>());

    await b.disconnect();
    await waitFor(() => server.stats()['online'] == 1);
    expect(server.stats()['peakOnline'], 2);
  });

  test('connect fails cleanly when no server listens', () async {
    final c = OnlineClient(wakeUpTime: Duration.zero);
    expect(await c.connect('127.0.0.1:1', 'x'), isFalse);
    expect(c.status, OnlineStatus.disconnected);
  });

  test('connect retries while the server wakes up', () async {
    var attempts = 0;
    final c = OnlineClient(
      retryDelay: const Duration(milliseconds: 20),
      connector: (u) {
        attempts++;
        if (attempts < 3) return Future.error(const SocketException('sleeping'));
        return WebSocket.connect(u.toString());
      },
    );
    clients.add(c);
    var sawWaking = false;
    c.addListener(() => sawWaking |= c.waking);
    expect(await c.connect(address, 'Uyku'), isTrue);
    expect(attempts, 3);
    expect(sawWaking, isTrue);
    expect(c.waking, isFalse);
  });

  test('cancelling a waking connection stops retrying', () async {
    var attempts = 0;
    final c = OnlineClient(
      retryDelay: const Duration(milliseconds: 20),
      connector: (_) {
        attempts++;
        return Future.error(const SocketException('sleeping'));
      },
    );
    final result = c.connect(address, 'x');
    await waitFor(() => c.waking);
    await c.disconnect();
    expect(await result, isFalse);
    final n = attempts;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(attempts, n);
    expect(c.status, OnlineStatus.disconnected);
  });

  test('password room: list, reject, join, ready, countdown, play, win on disconnect', () async {
    final a = await connect('Ali');
    final b = await connect('Banu');
    final errors = <ErrorCode>[];
    b.errors.listen(errors.add);

    a.createRoom(name: 'Gizli', capacity: 2, teams: false, password: 'kedi');
    await waitFor(() => a.room != null && b.rooms.isNotEmpty);
    final listed = b.rooms.single;
    expect(listed.locked, isTrue);
    expect(listed.players, 1);
    expect(listed.name, 'Gizli');
    expect(a.room!.mySlot, 0);

    b.joinRoom(listed.id, password: 'yanlis');
    await waitFor(() => errors.isNotEmpty);
    expect(errors.single, ErrorCode.wrongPassword);
    expect(b.room, isNull);

    b.joinRoom(listed.id, password: 'kedi');
    await waitFor(() => b.room != null && a.room!.filled == 2);
    expect(b.room!.mySlot, 1);
    expect(b.room!.slots[0]!.name, 'Ali');

    a.setReady(true);
    await waitFor(() => b.room!.slots[0]!.ready);
    expect(b.room!.phase, RoomPhase.lobby);
    b.setReady(true);
    await waitFor(() => a.room!.phase == RoomPhase.countdown);
    expect(a.room!.countdown, greaterThan(0));

    await waitFor(() => a.match != null && b.match != null);
    expect(a.match!.localId, 0);
    expect(b.match!.localId, 1);
    expect(b.match!.names, ['Ali', 'Banu']);

    // B walks; A's mirror of B must follow (snapshots + smoothing).
    final mirror = a.match!.world.players[1];
    final y0 = mirror.y;
    b.match!.move(Dir.up);
    await waitFor(() {
      a.match!.advance(1 / 60);
      return mirror.y < y0 - 0.5;
    });

    await a.disconnect();
    await waitFor(() => b.match!.ended);
    expect(b.winner, 1);
    expect(b.match!.world.winnerId, 1);
    await waitFor(() => b.room!.phase == RoomPhase.lobby && b.room!.filled == 1);
    expect(b.room!.slots[1]!.ready, isFalse);
  });

  test('wrong passwords are rate limited', () async {
    final a = await connect('A');
    final b = await connect('B');
    final errors = <ErrorCode>[];
    b.errors.listen(errors.add);
    a.createRoom(name: 'r', capacity: 2, teams: false, password: 'p');
    await waitFor(() => b.rooms.isNotEmpty);
    for (var i = 0; i < 3; i++) {
      b.joinRoom(b.rooms.single.id, password: 'x');
    }
    b.joinRoom(b.rooms.single.id, password: 'p');
    await waitFor(() => errors.length == 4);
    expect(errors, [
      ErrorCode.wrongPassword,
      ErrorCode.wrongPassword,
      ErrorCode.tooManyAttempts,
      ErrorCode.tooManyAttempts,
    ]);
    expect(b.room, isNull);
  });

  test('open room is joinable without password; full room rejects', () async {
    final a = await connect('A');
    final b = await connect('B');
    final c = await connect('C');
    final errors = <ErrorCode>[];
    c.errors.listen(errors.add);
    a.createRoom(name: '', capacity: 2, teams: false);
    await waitFor(() => b.rooms.isNotEmpty);
    expect(b.rooms.single.locked, isFalse);
    expect(b.rooms.single.name, 'A');
    b.joinRoom(b.rooms.single.id);
    await waitFor(() => b.room != null && c.rooms.single.players == 2);
    expect(c.rooms.single.joinable, isFalse);
    c.joinRoom(c.rooms.single.id);
    await waitFor(() => errors.isNotEmpty);
    expect(errors.single, ErrorCode.roomFull);
  });

  test('un-ready during the countdown cancels the start', () async {
    await server.close();
    server = BlastServer(countdown: const Duration(milliseconds: 400));
    final port = await server.start(port: 0, address: '127.0.0.1');
    address = '127.0.0.1:$port';
    final a = await connect('A');
    final b = await connect('B');
    a.createRoom(name: 'r', capacity: 2, teams: false);
    await waitFor(() => b.rooms.isNotEmpty);
    b.joinRoom(b.rooms.single.id);
    await waitFor(() => a.room?.filled == 2);
    a.setReady(true);
    b.setReady(true);
    await waitFor(() => a.room!.phase == RoomPhase.countdown);
    b.setReady(false);
    await waitFor(() => a.room!.phase == RoomPhase.lobby);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(a.match, isNull);
  });

  test('2v2 room starts a team match; invalid shapes are rejected', () async {
    final players = [for (final n in ['A', 'B', 'C', 'D']) await connect(n)];
    final errors = <ErrorCode>[];
    players[0].errors.listen(errors.add);
    players[0].createRoom(name: 'x', capacity: 3, teams: true);
    await waitFor(() => errors.isNotEmpty);
    expect(errors.single, ErrorCode.badRequest);

    players[0].createRoom(name: 'takim', capacity: 4, teams: true);
    await waitFor(() => players[1].rooms.isNotEmpty);
    final id = players[1].rooms.single.id;
    for (final p in players.skip(1)) {
      p.joinRoom(id);
    }
    await waitFor(() => players[0].room?.filled == 4);
    expect(players[0].room!.teams, isTrue);
    for (final p in players) {
      p.setReady(true);
    }
    await waitFor(() => players.every((p) => p.match != null));
    final w = players[2].match!.world;
    expect(w.teams, isTrue);
    expect([for (final p in w.players) p.teamId], [0, 1, 0, 1]);

    // Team 1 (slots 1 and 3) leaves: team 0 wins.
    await players[1].disconnect();
    await players[3].disconnect();
    await waitFor(() => players[0].match!.ended);
    expect(players[0].winnerTeam, 0);
  });

  test('a seven-player room fills up and everybody starts on their own cell', () async {
    final players = [for (final n in ['A', 'B', 'C', 'D', 'E', 'F', 'G']) await connect(n)];
    players[0].createRoom(name: 'party', capacity: 7, teams: false);
    await waitFor(() => players[1].rooms.isNotEmpty);
    final room = players[1].rooms.single;
    expect(room.capacity, 7);
    for (final p in players.skip(1)) {
      p.joinRoom(room.id);
    }
    await waitFor(() => players[0].room?.filled == 7);
    for (final p in players) {
      p.setReady(true);
    }
    await waitFor(() => players.every((p) => p.match != null), timeout: const Duration(seconds: 10));
    expect({for (final p in players) p.match!.localId}, {0, 1, 2, 3, 4, 5, 6});
    final w = players.first.match!.world;
    expect(w.players.length, 7);
    expect({for (final p in w.players) p.spawn}.length, 7);
    // A snapshot arrives and keeps all seven alive at the start.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(w.players.every((p) => p.alive), isTrue);
  });

  test('rooms for more than seven are rejected', () async {
    final a = await connect('A');
    final errors = <ErrorCode>[];
    a.errors.listen(errors.add);
    a.createRoom(name: 'x', capacity: 8, teams: false);
    await waitFor(() => errors.isNotEmpty);
    expect(errors.single, ErrorCode.badRequest);
  });

  test('empty rooms are removed', () async {
    final a = await connect('A');
    a.createRoom(name: 'r', capacity: 3, teams: false);
    await waitFor(() => a.room != null);
    expect(server.roomCount, 1);
    a.leaveRoom();
    await waitFor(() => server.roomCount == 0);
    await waitFor(() => a.rooms.isEmpty);
  });

  test('server ignores malformed input', () async {
    final a = await connect('A');
    final errors = <ErrorCode>[];
    a.errors.listen(errors.add);
    a.createRoom(name: 'r', capacity: 9, teams: false);
    a.joinRoom('NOPE');
    await waitFor(() => errors.length == 2);
    expect(errors, [ErrorCode.badRequest, ErrorCode.roomNotFound]);
    expect(a.status, OnlineStatus.connected);
  });

  test('quick match pairs two players, auto-readies them and shares looks', () async {
    final a = OnlineClient();
    final b = OnlineClient();
    clients.addAll([a, b]);
    expect(await a.connect(address, 'Ann', skin: [4, 2, 1]), isTrue);
    expect(await b.connect(address, 'Bob', skin: [1, 1, 1]), isTrue);
    a.quickMatch(2);
    await waitFor(() => a.room != null);
    expect(a.room!.filled, 1);
    b.quickMatch(2);
    await waitFor(() => a.match != null && b.match != null);
    expect(server.roomCount, 1, reason: 'both ended up in one room');
    final skins = [for (final p in a.match!.world.players) p.skin];
    expect(skins[0].hat, 4);
    expect(skins[1].hat, 1);
    expect(skins[0].color, isNotNull);
    expect(skins[1].color, isNull, reason: 'duplicate body colour falls back to the slot colour');
  });

  test('advantage ad: next match starts with 2 bombs, once, and the room sees the badge', () async {
    final a = OnlineClient();
    final b = OnlineClient();
    clients.addAll([a, b]);
    await a.connect(address, 'Ann');
    await b.connect(address, 'Bob');
    a.setBoost(true);
    expect(a.boosted, isTrue);
    a.quickMatch(2);
    await waitFor(() => a.room != null);
    b.quickMatch(2);
    // Bob sees Ann's badge while they wait for the countdown.
    await waitFor(() => b.room?.slots.any((m) => m?.boost ?? false) ?? false);
    await waitFor(() => a.match != null && b.match != null);
    final me = a.match!.localId;
    final other = 1 - me;
    await waitFor(() => a.match!.world.players[me].stats.maxBombs == boostedStartBombs);
    expect(a.match!.world.players[other].stats.maxBombs, 1);
    expect(b.match!.world.players[me].stats.maxBombs == boostedStartBombs ||
        b.match!.world.players[me].stats.maxBombs == 1, isTrue);
    // Used up: the client forgets it and the room shows no badge any more.
    expect(a.boosted, isFalse);
    await waitFor(() => b.room?.slots.every((m) => !(m?.boost ?? false)) ?? false);
  });

  test('advantage can be revoked before the match', () async {
    final a = OnlineClient();
    clients.add(a);
    await a.connect(address, 'Ann');
    a.setBoost(true);
    a.setBoost(false);
    expect(a.boosted, isFalse);
    a.createRoom(name: 'R', capacity: 2, teams: false);
    await waitFor(() => a.room != null);
    expect(a.room!.slots.first!.boost, isFalse);
  });

  test('emotes reach the room, are throttled, and leaving is announced', () async {
    final a = OnlineClient();
    final b = OnlineClient();
    clients.addAll([a, b]);
    await a.connect(address, 'Ann');
    await b.connect(address, 'Bob');
    a.quickMatch(2);
    await waitFor(() => a.room != null);
    b.quickMatch(2);
    await waitFor(() => a.match != null && b.match != null);
    final left = <int>[];
    a.match!.leftSlots.listen(left.add);
    b.match!.emote(3);
    b.match!.emote(4); // inside the throttle window: dropped
    await waitFor(() => a.match!.emotes[1] == 3);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(a.match!.emotes[1], 3);
    // Premium emotes (6..11) travel too; indexes beyond the catalogue do not.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    b.match!.emote(11);
    await waitFor(() => a.match!.emotes[1] == 11);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    b.match!.emote(12);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(a.match!.emotes[1], 11);
    b.leaveRoom();
    await waitFor(() => left.isNotEmpty);
    expect(left, [1]);
  });

  group('reconnect', () {
    late BlastServer grace;
    late String addr;
    final sockets = <WebSocket>[];
    var blockConnect = false;

    Future<WebSocket> tracked(Uri u) async {
      if (blockConnect) throw const SocketException('offline');
      final ws = await WebSocket.connect(u.toString());
      sockets.add(ws);
      return ws;
    }

    setUp(() async {
      blockConnect = false;
      sockets.clear();
      grace = BlastServer(countdown: const Duration(milliseconds: 100), reconnectGrace: const Duration(milliseconds: 800));
      addr = '127.0.0.1:${await grace.start(port: 0, address: '127.0.0.1')}';
    });

    tearDown(() async {
      await grace.close();
    });

    Future<(OnlineClient, OnlineClient)> startMatch() async {
      final a = OnlineClient(
        connector: tracked,
        reconnectDelay: const Duration(milliseconds: 50),
        reconnectWindow: const Duration(milliseconds: 1500),
      );
      final b = OnlineClient();
      clients.addAll([a, b]);
      expect(await a.connect(addr, 'Ann'), isTrue);
      expect(await b.connect(addr, 'Bob'), isTrue);
      a.quickMatch(2);
      await waitFor(() => a.room != null);
      b.quickMatch(2);
      await waitFor(() => a.match != null && b.match != null);
      return (a, b);
    }

    test('a dropped player gets the same seat and the same match back', () async {
      final (a, b) = await startMatch();
      final match = a.match!;
      final seat = match.localId;
      final away = <(int, bool)>[];
      b.match!.awaySlots.listen(away.add);
      await waitFor(() => match.world.timeLeft > 0);
      final before = match.world.timeLeft;

      var sawReconnecting = false;
      a.addListener(() => sawReconnecting |= a.reconnecting && match.disconnected);
      sockets.last.close().ignore();
      await waitFor(() => away.length == 2);
      await waitFor(() => !a.reconnecting && !match.disconnected);
      expect(sawReconnecting, isTrue, reason: 'the UI is told while the connection is down');

      expect(identical(a.match, match), isTrue, reason: 'the match object survives');
      expect(match.localId, seat);
      expect(a.status, OnlineStatus.connected);
      expect(a.lostConnection, isFalse);
      expect(away, [(seat, true), (seat, false)]);
      // Snapshots flow again after the gap.
      await waitFor(() => match.world.timeLeft < before);
      expect(grace.roomCount, 1);

      // The returned player can still act.
      match.move(Dir.down);
      await waitFor(() => match.world.players[seat].moveDir == Dir.down);
    });

    test('the seat is lost after the grace time', () async {
      final (a, b) = await startMatch();
      final left = <int>[];
      b.match!.leftSlots.listen(left.add);
      blockConnect = true;
      sockets.last.close().ignore();
      await waitFor(() => left.isNotEmpty, timeout: const Duration(seconds: 4));
      expect(left, [a.match!.localId]);
      await waitFor(() => b.match!.ended, timeout: const Duration(seconds: 4));
      expect(b.match!.world.winnerId, b.match!.localId);
      await waitFor(() => a.lostConnection, timeout: const Duration(seconds: 4));
      expect(a.match!.disconnected, isTrue);
      expect(a.reconnecting, isFalse);
    });

    test('a finished match cannot be resumed and the seat is cleaned up', () async {
      final (a, b) = await startMatch();
      blockConnect = true;
      sockets.last.close().ignore();
      await waitFor(() => a.reconnecting);
      b.leaveRoom(); // the opponent leaves: the match ends while A is away
      await waitFor(() => grace.roomCount == 0, timeout: const Duration(seconds: 4));
      blockConnect = false;
      await waitFor(() => a.lostConnection, timeout: const Duration(seconds: 4));
    });

    test('a client that never had a match just disconnects without reconnecting', () async {
      final a = OnlineClient(connector: tracked);
      clients.add(a);
      expect(await a.connect(addr, 'Solo'), isTrue);
      sockets.last.close().ignore();
      await waitFor(() => a.status == OnlineStatus.disconnected);
      expect(a.reconnecting, isFalse);
      expect(a.lostConnection, isTrue);
    });

    test('a forged token does not take anyone\'s seat', () async {
      final (_, b) = await startMatch();
      final ws = await WebSocket.connect('ws://$addr');
      final got = <Map<String, dynamic>>[];
      ws.listen((m) => got.add(jsonDecode(m as String) as Map<String, dynamic>));
      ws.add(jsonEncode({'t': Msg.hello, 'name': 'Eve', 'v': protocolVersion, 'resume': 'deadbeef'}));
      await waitFor(() => got.any((m) => m['t'] == Msg.welcome));
      final w = got.firstWhere((m) => m['t'] == Msg.welcome);
      expect(w['resumed'], isNull);
      expect(got.any((m) => m['t'] == Msg.start), isFalse);
      expect(b.match!.ended, isFalse);
      await ws.close();
    });
  });
}
