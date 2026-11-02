import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:blast_buddies/net/snapshot.dart';
import 'package:flutter/foundation.dart';

/// Connection state of [OnlineClient].
enum OnlineStatus {
  /// Not connected.
  disconnected,

  /// Opening the socket / waiting for welcome.
  connecting,

  /// Connected and greeted.
  connected,
}

/// Turns user input like `192.168.1.5`, `host:9000` or `wss://x.com` into a
/// WebSocket URI (default scheme `ws`, default port [defaultServerPort]).
Uri? parseServerAddress(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (!s.contains('://')) s = 'ws://$s';
  final u = Uri.tryParse(s);
  if (u == null || u.host.isEmpty || (u.scheme != 'ws' && u.scheme != 'wss')) return null;
  return u.hasPort || u.scheme == 'wss' ? u : u.replace(port: defaultServerPort);
}

/// A running online match as seen by this client: a mirror [GameWorld] fed by
/// server snapshots, with player positions smoothed between snapshots.
class OnlineMatch implements RemoteSession {
  /// Creates the mirror world for the server's [seed] and room shape.
  OnlineMatch({
    required int seed,
    required int capacity,
    required bool teams,
    required this.localId,
    required this.names,
    required void Function(Map<String, dynamic>) send,
  })  : _send = send,
        world = GameWorld.battle(humans: capacity, bots: 0, seed: seed, teams: teams) {
    _tx = [for (final p in world.players) p.x];
    _ty = [for (final p in world.players) p.y];
  }

  /// Mirror of the server world (never ticked locally).
  final GameWorld world;

  @override
  final int localId;

  /// Player names by slot.
  final List<String> names;

  final void Function(Map<String, dynamic>) _send;
  late final List<double> _tx;
  late final List<double> _ty;
  Dir _sentDir = Dir.none;
  bool _hasSnapshot = false;

  /// True once the server reported the end.
  bool ended = false;

  /// True if the connection dropped mid-match.
  bool disconnected = false;

  @override
  void move(Dir d) {
    if (d == _sentDir || ended) return;
    _sentDir = d;
    _send({'t': Msg.input, 'd': d.index});
  }

  @override
  void bomb() {
    if (!ended) _send({'t': Msg.input, 'd': _sentDir.index, 'b': true});
  }

  /// Applies a server snapshot.
  void apply(Map<String, dynamic> m) {
    final shown = [for (final p in world.players) (p.x, p.y)];
    applySnapshot(world, m);
    for (var i = 0; i < world.players.length; i++) {
      final p = world.players[i];
      _tx[i] = p.x;
      _ty[i] = p.y;
      if (_hasSnapshot) {
        p
          ..x = shown[i].$1
          ..y = shown[i].$2;
      }
    }
    _hasSnapshot = true;
  }

  @override
  void advance(double dt) {
    final k = 1 - exp(-dt * 20);
    for (var i = 0; i < world.players.length; i++) {
      final p = world.players[i];
      final dx = _tx[i] - p.x, dy = _ty[i] - p.y;
      if (dx.abs() + dy.abs() > 1.5) {
        p
          ..x = _tx[i]
          ..y = _ty[i];
      } else {
        p
          ..x += dx * k
          ..y += dy * k;
      }
    }
  }
}

/// WebSocket client for the online lobby and matches.
class OnlineClient extends ChangeNotifier {
  /// Creates a client. [connector] is replaceable in tests.
  ///
  /// A sleeping free-tier host can take about a minute to wake up, so failed
  /// connection attempts are retried for up to [wakeUpTime].
  OnlineClient({
    Future<WebSocket> Function(Uri)? connector,
    this.wakeUpTime = const Duration(seconds: 90),
    this.retryDelay = const Duration(seconds: 3),
  }) : _connector = connector ?? ((u) => WebSocket.connect(u.toString()));

  final Future<WebSocket> Function(Uri) _connector;

  /// How long to keep retrying while the server wakes up.
  final Duration wakeUpTime;

  /// Pause between connection attempts.
  final Duration retryDelay;

  /// True while retrying because the first attempt failed (server waking up).
  bool waking = false;
  WebSocket? _ws;
  StreamSubscription<Object?>? _sub;
  Completer<bool>? _welcome;
  final StreamController<ErrorCode> _errors = StreamController.broadcast();

  /// Connection state.
  OnlineStatus status = OnlineStatus.disconnected;

  /// True if the last connection ended unexpectedly.
  bool lostConnection = false;

  /// Public room list (while not in a room).
  List<RoomSummary> rooms = const [];

  /// Room the client sits in.
  RoomDetails? room;

  /// Current match, kept after the end until [closeMatch].
  OnlineMatch? match;

  /// Winner slot of the last match (null = draw).
  int? winner;

  /// Winning team of the last match (null = draw).
  int? winnerTeam;

  /// Rejected requests (wrong password, room full, ...).
  Stream<ErrorCode> get errors => _errors.stream;

  /// Connects to [address] as [name]. Returns false on failure.
  Future<bool> connect(String address, String name) async {
    final uri = parseServerAddress(address);
    if (uri == null || status != OnlineStatus.disconnected) return false;
    status = OnlineStatus.connecting;
    lostConnection = false;
    notifyListeners();
    try {
      final ws = await _open(uri);
      if (ws == null) {
        await disconnect();
        return false;
      }
      ws.pingInterval = const Duration(seconds: 10);
      _ws = ws;
      _welcome = Completer();
      _sub = ws.listen(_onData, onDone: _onClosed, onError: (_) => _onClosed());
      _send({'t': Msg.hello, 'name': cleanText(name, Limits.name), 'v': protocolVersion});
      final ok = await _welcome!.future.timeout(const Duration(seconds: 6), onTimeout: () => false);
      if (!ok) await disconnect();
      return ok;
    } on Object {
      await disconnect();
      return false;
    }
  }

  /// Closes the connection and clears all state.
  Future<void> disconnect() async {
    final ws = _ws;
    _ws = null;
    await _sub?.cancel();
    _sub = null;
    _reset();
    notifyListeners();
    await ws?.close();
  }

  /// Opens the socket, retrying while the server wakes up. Null if it gave up
  /// or the attempt was cancelled with [disconnect].
  Future<WebSocket?> _open(Uri uri) async {
    final sw = Stopwatch()..start();
    while (true) {
      try {
        final ws = await _connector(uri).timeout(const Duration(seconds: 20));
        if (status != OnlineStatus.connecting || _disposed) {
          await ws.close();
          return null;
        }
        return ws;
      } on Object {
        if (status != OnlineStatus.connecting || _disposed || sw.elapsed + retryDelay > wakeUpTime) return null;
        if (!waking) {
          waking = true;
          notifyListeners();
        }
        await Future<void>.delayed(retryDelay);
        if (status != OnlineStatus.connecting || _disposed) return null;
      }
    }
  }

  void _reset() {
    status = OnlineStatus.disconnected;
    waking = false;
    rooms = const [];
    room = null;
    match?.disconnected = !(match?.ended ?? true);
    _completeWelcome(false);
  }

  void _completeWelcome(bool ok) {
    final w = _welcome;
    if (w != null && !w.isCompleted) w.complete(ok);
  }

  void _onClosed() {
    if (_ws == null) return;
    _ws = null;
    lostConnection = status == OnlineStatus.connected;
    _reset();
    notifyListeners();
  }

  void _send(Map<String, dynamic> m) => _ws?.add(jsonEncode(m));

  /// Creates a room and joins it.
  void createRoom({required String name, required int capacity, required bool teams, String password = ''}) =>
      _send({'t': Msg.createRoom, 'name': name, 'capacity': capacity, 'teams': teams, 'password': password});

  /// Joins room [id].
  void joinRoom(String id, {String password = ''}) =>
      _send({'t': Msg.joinRoom, 'room': id, 'password': password});

  /// Leaves the current room (and match).
  void leaveRoom() {
    _send({'t': Msg.leaveRoom});
    room = null;
    closeMatch();
  }

  /// Toggles ready.
  void setReady(bool ready) => _send({'t': Msg.setReady, 'ready': ready});

  /// Forgets the finished match (back to the room screen).
  void closeMatch() {
    if (match == null) return;
    match = null;
    notifyListeners();
  }

  void _onData(Object? data) {
    if (data is! String) return;
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(data) as Map<String, dynamic>;
    } on Object {
      return;
    }
    switch (m['t']) {
      case Msg.snapshot:
        match?.apply(m);
        return; // high frequency: no listener notification
      case Msg.welcome:
        status = OnlineStatus.connected;
        waking = false;
        _completeWelcome(true);
      case Msg.rooms:
        rooms = [
          for (final r in m['rooms'] as List) RoomSummary.fromJson((r as Map).cast<String, dynamic>()),
        ];
      case Msg.room:
        room = RoomDetails.fromJson((m['room'] as Map).cast<String, dynamic>());
      case Msg.start:
        winner = null;
        winnerTeam = null;
        match = OnlineMatch(
          seed: m['seed'] as int,
          capacity: m['cap'] as int,
          teams: m['teams'] as bool,
          localId: m['you'] as int,
          names: (m['names'] as List).cast<String>(),
          send: _send,
        );
      case Msg.end:
        winner = m['winner'] as int?;
        winnerTeam = m['team'] as int?;
        match?.ended = true;
      case Msg.error:
        final code = ErrorCode.parse(m['code']);
        if (code == ErrorCode.versionMismatch) _completeWelcome(false);
        _errors.add(code);
      default:
        return;
    }
    notifyListeners();
  }

  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    unawaited(_errors.close());
    super.dispose();
  }
}
