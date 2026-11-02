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
}
