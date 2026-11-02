import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:blast_buddies/net/snapshot.dart';
import 'package:crypto/crypto.dart';

/// Authoritative online server: room list, password-protected rooms,
/// ready-up with countdown, and the match simulation ([GameWorld] at
/// [tickRate] Hz, snapshots every [snapshotEvery] ticks).
///
/// Pure `dart:io`; run it with `dart run bin/server.dart`.
class BlastServer {
  /// Creates a server. Durations are configurable for tests.
  BlastServer({
    this.countdown = const Duration(seconds: 3),
    this.tickRate = 60,
    this.snapshotEvery = 2,
    this.maxRooms = 200,
    this.maxClients = 1000,
    this.passwordAttempts = 5,
    this.passwordWindow = const Duration(minutes: 1),
    this.log,
    Random? random,
  }) : _rng = random ?? Random.secure();

  /// Delay between "everyone ready" and the match start.
  final Duration countdown;

  /// Simulation steps per second.
  final int tickRate;

  /// Ticks between snapshots.
  final int snapshotEvery;

  /// Maximum simultaneous rooms.
  final int maxRooms;

  /// Maximum simultaneous connections.
  final int maxClients;

  /// Wrong passwords allowed per [passwordWindow] and connection.
  final int passwordAttempts;

  /// Window for [passwordAttempts].
  final Duration passwordWindow;

  /// Optional logger.
  final void Function(String)? log;

  final Random _rng;
  HttpServer? _http;
  final Set<_Client> _clients = {};
  final Map<String, _Room> _rooms = {};
  int _nextClientId = 1;

  /// Number of open rooms (tests/monitoring).
  int get roomCount => _rooms.length;

  /// Binds to [port] (0 = any free port) and returns the bound port.
  Future<int> start({int port = defaultServerPort, Object? address}) async {
    final http = await HttpServer.bind(address ?? InternetAddress.anyIPv4, port);
    _http = http;
    http.listen(_onRequest);
    log?.call('listening on ${http.address.address}:${http.port}');
    return http.port;
  }

  /// Stops matches, closes connections and the listener.
  Future<void> close() async {
    for (final r in _rooms.values) {
      r.dispose();
    }
    _rooms.clear();
    for (final c in _clients.toList()) {
      await c.ws.close();
    }
    _clients.clear();
    await _http?.close(force: true);
    _http = null;
  }

  Future<void> _onRequest(HttpRequest req) async {
    if (WebSocketTransformer.isUpgradeRequest(req)) {
      if (_clients.length >= maxClients) {
        req.response.statusCode = HttpStatus.serviceUnavailable;
        await req.response.close();
        return;
      }
      final ws = await WebSocketTransformer.upgrade(req);
      ws.pingInterval = const Duration(seconds: 10);
      final c = _Client(_nextClientId++, ws);
      _clients.add(c);
      ws.listen(
        (data) => _onMessage(c, data),
        onDone: () => _onGone(c),
        onError: (_) => _onGone(c),
        cancelOnError: true,
      );
      return;
    }
    final ok = req.uri.path == '/health' || req.uri.path == '/';
    req.response
      ..statusCode = ok ? HttpStatus.ok : HttpStatus.notFound
      ..write(ok ? 'blast-buddies ok' : 'not found');
    await req.response.close();
  }

  // ----------------------------------------------------------- messaging

  void _onMessage(_Client c, Object? data) {
    if (data is! String || data.length > Limits.messageBytes) {
      _error(c, ErrorCode.badRequest);
      return;
    }
    Map<String, dynamic> m;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      m = decoded;
    } on FormatException {
      _error(c, ErrorCode.badRequest);
      return;
    }
    final type = m['t'];
    if (c.name == null && type != Msg.hello) {
      _error(c, ErrorCode.badRequest);
      return;
    }
    try {
      switch (type) {
        case Msg.hello:
          _hello(c, m);
        case Msg.createRoom:
          _create(c, m);
        case Msg.joinRoom:
          _join(c, m);
        case Msg.leaveRoom:
          _leave(c);
        case Msg.setReady:
          _ready(c, m['ready'] == true);
        case Msg.input:
          _input(c, m);
        default:
          _error(c, ErrorCode.badRequest);
      }
    } on TypeError {
      _error(c, ErrorCode.badRequest);
    }
  }

  void _send(_Client c, Map<String, dynamic> m) {
    if (_clients.contains(c)) c.ws.add(jsonEncode(m));
  }

  void _error(_Client c, ErrorCode code) => _send(c, {'t': Msg.error, 'code': code.name});

  void _onGone(_Client c) {
    if (!_clients.remove(c)) return;
    _leave(c);
  }

  // --------------------------------------------------------------- lobby

  void _hello(_Client c, Map<String, dynamic> m) {
    if (m['v'] != protocolVersion) {
      _error(c, ErrorCode.versionMismatch);
      return;
    }
    final name = cleanText(m['name'], Limits.name);
    c.name = name.isEmpty ? 'Player ${c.id}' : name;
    _send(c, {'t': Msg.welcome, 'id': c.id});
    _sendRoomList(c);
  }

  List<Map<String, dynamic>> get _roomList => [
        for (final r in _rooms.values) r.summary.toJson(),
      ];

  void _sendRoomList(_Client c) => _send(c, {'t': Msg.rooms, 'rooms': _roomList});

  void _broadcastRoomList() {
    final msg = jsonEncode({'t': Msg.rooms, 'rooms': _roomList});
    for (final c in _clients) {
      if (c.name != null && c.room == null) c.ws.add(msg);
    }
  }

  void _broadcastRoom(_Room r) {
    for (final c in r.members) {
      _send(c, {'t': Msg.room, 'room': r.detailsFor(c).toJson()});
    }
  }

  String _newRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String id;
    do {
      id = String.fromCharCodes(
          List.generate(5, (_) => chars.codeUnitAt(_rng.nextInt(chars.length))));
    } while (_rooms.containsKey(id));
    return id;
  }

  void _create(_Client c, Map<String, dynamic> m) {
    final cap = m['capacity'];
    final teams = m['teams'] == true;
    if (cap is! int || !validRoomShape(cap, teams)) {
      _error(c, ErrorCode.badRequest);
      return;
    }
    if (_rooms.length >= maxRooms) {
      _error(c, ErrorCode.serverFull);
      return;
    }
    _leave(c);
    final name = cleanText(m['name'], Limits.roomName);
    final password = cleanText(m['password'], Limits.password);
    final r = _Room(
      id: _newRoomId(),
      name: name.isEmpty ? c.name! : name,
      capacity: cap,
      teams: teams,
    );
    if (password.isNotEmpty) {
      r.salt = List.generate(16, (_) => _rng.nextInt(256));
      r.hash = _hashPassword(r.salt!, password);
    }
    _rooms[r.id] = r;
    r.slots[0] = c;
    c.room = r;
    log?.call('room ${r.id} created by ${c.name} (cap $cap, teams $teams, locked ${r.locked})');
    _broadcastRoom(r);
    _broadcastRoomList();
  }

  static List<int> _hashPassword(List<int> salt, String password) =>
      sha256.convert([...salt, ...utf8.encode(password)]).bytes;

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  void _join(_Client c, Map<String, dynamic> m) {
    final r = _rooms[m['room']];
    if (r == null) {
      _error(c, ErrorCode.roomNotFound);
      return;
    }
    if (c.room == r) {
      _broadcastRoom(r);
      return;
    }
    if (r.phase != RoomPhase.lobby) {
      _error(c, ErrorCode.inProgress);
      return;
    }
    if (r.filled >= r.capacity) {
      _error(c, ErrorCode.roomFull);
      return;
    }
    if (r.locked) {
      final now = DateTime.now();
      c.failedPasswords.removeWhere((t) => now.difference(t) > passwordWindow);
      if (c.failedPasswords.length >= passwordAttempts) {
        _error(c, ErrorCode.tooManyAttempts);
        return;
      }
      final given = cleanText(m['password'], Limits.password);
      if (!_sameBytes(_hashPassword(r.salt!, given), r.hash!)) {
        c.failedPasswords.add(now);
        _error(c, ErrorCode.wrongPassword);
        return;
      }
    }
    _leave(c);
    r.slots[r.slots.indexOf(null)] = c;
    c.room = r;
    _broadcastRoom(r);
    _broadcastRoomList();
  }

  void _leave(_Client c) {
    final r = c.room;
    if (r == null) return;
    final slot = r.slots.indexOf(c);
    r.slots[slot] = null;
    r.ready.remove(c);
    c.room = null;
    if (r.phase == RoomPhase.countdown) _cancelCountdown(r);
    final match = r.match;
    if (match != null) {
      final p = match.world.players[slot];
      if (p.alive) {
        p.alive = false;
        match.pending.add(GameEvent(GameEventType.playerHit, p.x, p.y, p.id));
      }
    }
    if (r.filled == 0) {
      r.dispose();
      _rooms.remove(r.id);
      log?.call('room ${r.id} closed');
    } else {
      _broadcastRoom(r);
    }
    if (_clients.contains(c)) _sendRoomList(c);
    _broadcastRoomList();
  }

  void _ready(_Client c, bool ready) {
    final r = c.room;
    if (r == null || r.phase == RoomPhase.playing) return;
    if (ready) {
      r.ready.add(c);
    } else {
      r.ready.remove(c);
    }
    final all = r.filled == r.capacity && r.members.every(r.ready.contains);
    if (all && r.phase == RoomPhase.lobby) {
      r
        ..phase = RoomPhase.countdown
        ..countdownEnds = DateTime.now().add(countdown)
        ..countdownTimer = Timer(countdown, () => _startMatch(r));
      _broadcastRoomList();
    } else if (!all && r.phase == RoomPhase.countdown) {
      _cancelCountdown(r);
      _broadcastRoomList();
    }
    _broadcastRoom(r);
  }

  void _cancelCountdown(_Room r) {
    r.countdownTimer?.cancel();
    r
      ..countdownTimer = null
      ..countdownEnds = null
      ..phase = RoomPhase.lobby;
  }

  // --------------------------------------------------------------- match

  void _startMatch(_Room r) {
    r.countdownTimer = null;
    r.countdownEnds = null;
    if (r.filled < r.capacity) {
      r.phase = RoomPhase.lobby;
      _broadcastRoom(r);
      return;
    }
    final seed = _rng.nextInt(1 << 31);
    final world = GameWorld.battle(humans: r.capacity, bots: 0, seed: seed, teams: r.teams);
    final match = _Match(world);
    r
      ..phase = RoomPhase.playing
      ..match = match;
    final names = [for (final c in r.slots) c?.name ?? ''];
    for (final c in r.members) {
      _send(c, {
        't': Msg.start,
        'seed': seed,
        'cap': r.capacity,
        'teams': r.teams,
        'you': r.slots.indexOf(c),
        'names': names,
      });
    }
    _broadcastRoom(r);
    _broadcastRoomList();
    _sendSnapshot(r, match);
    final step = 1 / tickRate;
    match.clock.start();
    match.timer = Timer.periodic(Duration(microseconds: 1000000 ~/ tickRate), (_) {
      final now = match.clock.elapsedMicroseconds / 1e6;
      match.acc += now - match.last;
      match.last = now;
      // Catch up after hiccups, but never more than 5 steps at once.
      var steps = 0;
      while (match.acc >= step && steps < 5) {
        world.tick(step);
        match.pending.addAll(world.drainEvents());
        match.acc -= step;
        match.ticks++;
        steps++;
        if (world.status != WorldStatus.playing) break;
      }
      if (steps == 5) match.acc = 0;
      if (world.status != WorldStatus.playing) {
        _sendSnapshot(r, match);
        _endMatch(r, match);
      } else if (match.ticks - match.lastSnapshotTick >= snapshotEvery) {
        _sendSnapshot(r, match);
      }
    });
    log?.call('room ${r.id} match started (seed $seed)');
  }

  void _sendSnapshot(_Room r, _Match match) {
    match.lastSnapshotTick = match.ticks;
    final msg = jsonEncode(encodeSnapshot(match.world, match.pending));
    match.pending.clear();
    for (final c in r.members) {
      if (_clients.contains(c)) c.ws.add(msg);
    }
  }

  void _endMatch(_Room r, _Match match) {
    match.timer?.cancel();
    r
      ..match = null
      ..phase = RoomPhase.lobby;
    r.ready.clear();
    for (final c in r.members) {
      _send(c, {'t': Msg.end, 'winner': match.world.winnerId, 'team': match.world.winnerTeam});
    }
    _broadcastRoom(r);
    _broadcastRoomList();
    log?.call('room ${r.id} match over (winner ${match.world.winnerId})');
  }

  void _input(_Client c, Map<String, dynamic> m) {
    final r = c.room;
    final match = r?.match;
    if (r == null || match == null) return;
    final d = m['d'];
    if (d is! int || d < 0 || d >= Dir.values.length) {
      _error(c, ErrorCode.badRequest);
      return;
    }
    final slot = r.slots.indexOf(c);
    match.world.setMove(slot, Dir.values[d]);
    if (m['b'] == true) match.world.requestBomb(slot);
  }
}

class _Client {
  _Client(this.id, this.ws);

  final int id;
  final WebSocket ws;
  String? name;
  _Room? room;
  final List<DateTime> failedPasswords = [];
}

class _Room {
  _Room({required this.id, required this.name, required this.capacity, required this.teams})
      : slots = List.filled(capacity, null);

  final String id;
  final String name;
  final int capacity;
  final bool teams;
  final List<_Client?> slots;
  final Set<_Client> ready = {};
  List<int>? salt;
  List<int>? hash;
  RoomPhase phase = RoomPhase.lobby;
  Timer? countdownTimer;
  DateTime? countdownEnds;
  _Match? match;

  bool get locked => hash != null;

  int get filled => slots.where((c) => c != null).length;

  Iterable<_Client> get members => slots.whereType<_Client>();

  RoomSummary get summary => RoomSummary(
        id: id,
        name: name,
        capacity: capacity,
        teams: teams,
        locked: locked,
        players: filled,
        phase: phase,
      );

  RoomDetails detailsFor(_Client viewer) {
    final ends = countdownEnds;
    return RoomDetails(
      id: id,
      name: name,
      capacity: capacity,
      teams: teams,
      locked: locked,
      slots: [
        for (final c in slots)
          c == null ? null : RoomMember(name: c.name!, ready: ready.contains(c), you: c == viewer),
      ],
      phase: phase,
      countdown: ends == null
          ? null
          : max(0, ends.difference(DateTime.now()).inMilliseconds / 1000),
    );
  }

  void dispose() {
    countdownTimer?.cancel();
    match?.timer?.cancel();
  }
}

class _Match {
  _Match(this.world);

  final GameWorld world;
  final Stopwatch clock = Stopwatch();
  final List<GameEvent> pending = [];
  Timer? timer;
  double acc = 0;
  double last = 0;
  int ticks = 0;
  int lastSnapshotTick = 0;
}
