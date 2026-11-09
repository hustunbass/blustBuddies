import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
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
/// server snapshots.
///
/// Other players are smoothed between snapshots. The local player is
/// *predicted*: it moves immediately on input using the same movement code as
/// the server, and each snapshot is compared with where the prediction was
/// one round trip ago; the difference is blended in, so the player only
/// "rubber-bands" when the server really disagrees (e.g. an unseen bomb).
class OnlineMatch implements RemoteSession {
  /// Creates the mirror world for the server's [seed] and room shape.
  OnlineMatch({
    required int seed,
    required int capacity,
    required bool teams,
    required this.localId,
    required this.names,
    required void Function(Map<String, dynamic>) send,
    double Function()? latency,
    List<Skin> skins = const [],
  })  : _send = send,
        _latency = latency ?? (() => 0.15),
        world = GameWorld.battle(humans: capacity, bots: 0, seed: seed, teams: teams) {
    _buf = [for (final _ in world.players) <_Sample>[]];
    _emotes = List.filled(world.players.length, -1);
    _emoteLeft = List.filled(world.players.length, 0);
    for (var i = 0; i < world.players.length && i < skins.length; i++) {
      world.players[i].skin = skins[i];
    }
  }

  /// Mirror of the server world (never ticked locally).
  final GameWorld world;

  @override
  final int localId;

  /// Player names by slot.
  final List<String> names;

  final void Function(Map<String, dynamic>) _send;
  final double Function() _latency;
  late final List<List<_Sample>> _buf;
  late final List<int> _emotes;
  late final List<double> _emoteLeft;
  final StreamController<int> _left = StreamController.broadcast();

  /// Slots of players that left during the match.
  Stream<int> get leftSlots => _left.stream;

  /// Reports that [slot] left.
  void playerLeft(int slot) {
    if (!_left.isClosed) _left.add(slot);
  }

  /// Shows emote [e] above player [slot] for a couple of seconds.
  void showEmote(int slot, int e) {
    if (slot < 0 || slot >= _emotes.length) return;
    _emotes[slot] = e;
    _emoteLeft[slot] = 2.2;
  }

  @override
  List<int> get emotes => _emotes;

  @override
  void detonate() {
    if (!ended) _send({'t': Msg.input, 'd': _sentDir.index, 'x': true});
  }

  @override
  void emote(int i) {
    if (!ended) _send({'t': Msg.emote, 'e': i});
  }
  Dir _sentDir = Dir.none;
  bool _hasSnapshot = false;

  /// Whether the local player is predicted (on by default).
  bool predict = true;

  /// How far behind the newest snapshot other players are drawn. Two
  /// snapshot intervals absorb network jitter, so they glide instead of
  /// speeding up and stalling when packets arrive unevenly.
  static const double interpDelay = 0.1;

  /// Position error below which prediction is trusted while running; smaller
  /// differences are timing noise and correcting them is what felt like
  /// sudden speed-ups.
  static const double _deadband = 0.12;

  double _clock = 0;
  double _renderT = 0;
  double _latest = 0;
  final List<(double, double, double)> _history = [];
  double _pendX = 0, _pendY = 0;

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

  bool get _predicting => predict && !ended && !disconnected && localId < world.players.length;

  /// Applies a server snapshot.
  void apply(Map<String, dynamic> m) {
    final shown = [for (final p in world.players) (p.x, p.y)];
    applySnapshot(world, m);
    // Server match time when sent; arrival time for servers that don't say.
    final n = m['n'];
    final stamp = n is num ? n / 1000 : _clock;
    if (!_hasSnapshot) {
      _latest = stamp;
      _renderT = stamp - interpDelay;
    } else if (stamp > _latest) {
      _latest = stamp;
    }
    for (var i = 0; i < world.players.length; i++) {
      final p = world.players[i];
      final b = _buf[i];
      if (b.isEmpty || stamp > b.last.t) b.add(_Sample(stamp, p.x, p.y));
      if (!_hasSnapshot) continue;
      if (i == localId && _predicting) {
        _reconcile(p, shown[i].$1, shown[i].$2);
      } else {
        p
          ..x = shown[i].$1
          ..y = shown[i].$2;
      }
    }
    if (!_hasSnapshot) _history.add((_clock, world.players[localId].x, world.players[localId].y));
    _hasSnapshot = true;
  }

  void _reconcile(Player p, double shownX, double shownY) {
    final sx = p.x, sy = p.y;
    p
      ..x = shownX
      ..y = shownY;
    final past = _historyAt(_clock - _latency() - 0.02);
    if (!p.alive || past == null) {
      _snapLocal(p, sx, sy);
      return;
    }
    var ex = sx - past.$1, ey = sy - past.$2;
    if (ex.abs() + ey.abs() > 1.2) {
      _snapLocal(p, sx, sy);
      return;
    }
    if (_sentDir != Dir.none) {
      ex = _beyondDeadband(ex);
      ey = _beyondDeadband(ey);
    }
    _pendX += ex;
    _pendY += ey;
    for (var i = 0; i < _history.length; i++) {
      final h = _history[i];
      _history[i] = (h.$1, h.$2 + ex, h.$3 + ey);
    }
  }

  static double _beyondDeadband(double v) =>
      v.abs() < _deadband ? 0 : v - _deadband * v.sign;

  void _snapLocal(Player p, double x, double y) {
    p
      ..x = x
      ..y = y;
    _pendX = 0;
    _pendY = 0;
    _history
      ..clear()
      ..add((_clock, x, y));
  }

  /// Predicted (corrected) position at time [t], linearly interpolated.
  (double, double)? _historyAt(double t) {
    if (_history.isEmpty) return null;
    if (t <= _history.first.$1) return (_history.first.$2, _history.first.$3);
    for (var i = _history.length - 1; i >= 0; i--) {
      final a = _history[i];
      if (a.$1 <= t) {
        if (i == _history.length - 1) return (a.$2, a.$3);
        final b = _history[i + 1];
        final k = (t - a.$1) / (b.$1 - a.$1);
        return (a.$2 + (b.$2 - a.$2) * k, a.$3 + (b.$3 - a.$3) * k);
      }
    }
    return null;
  }

  @override
  void advance(double dt) {
    _clock += dt;
    for (var i = 0; i < _emoteLeft.length; i++) {
      if (_emoteLeft[i] > 0 && (_emoteLeft[i] -= dt) <= 0) _emotes[i] = -1;
    }
    if (!_hasSnapshot) return;
    // Render time runs on the local clock and is steered gently towards
    // "newest snapshot minus delay" (half an interval added to centre the
    // sawtooth of arrivals), so bursts of packets never change the speed.
    final target = _latest - interpDelay + 0.0165;
    if ((target - _renderT).abs() > 0.5) {
      _renderT = target;
    } else {
      _renderT += dt + (target - _renderT) * min(1.0, dt * 1.0);
    }
    for (var i = 0; i < world.players.length; i++) {
      final p = world.players[i];
      if (i == localId && _predicting) {
        _advanceLocal(p, dt);
        continue;
      }
      final b = _buf[i];
      while (b.length > 2 && b[1].t < _renderT - 0.25) {
        b.removeAt(0);
      }
      final pos = _sampleAt(b, _renderT);
      if (pos != null) {
        p
          ..x = pos.$1
          ..y = pos.$2;
      }
    }
  }

  /// Position at [t] between buffered snapshots; holds the newest one if [t]
  /// is past it and jumps (no gliding) across teleports such as respawns.
  static (double, double)? _sampleAt(List<_Sample> b, double t) {
    if (b.isEmpty) return null;
    if (t <= b.first.t) return (b.first.x, b.first.y);
    for (var i = b.length - 1; i > 0; i--) {
      final a = b[i - 1], c = b[i];
      if (a.t <= t) {
        if (t >= c.t) return (c.x, c.y);
        if ((c.x - a.x).abs() + (c.y - a.y).abs() > 1.5) return (a.x, a.y);
        final k = (t - a.t) / (c.t - a.t);
        return (a.x + (c.x - a.x) * k, a.y + (c.y - a.y) * k);
      }
    }
    return (b.first.x, b.first.y);
  }

  void _advanceLocal(Player p, double dt) {
    if (p.alive) {
      p.moveDir = _sentDir;
      world.predictMove(localId, dt);
    }
    // Blend server corrections in over roughly 100 ms.
    final c = 1 - exp(-dt * 12);
    final cx = _pendX * c, cy = _pendY * c;
    p
      ..x += cx
      ..y += cy;
    _pendX -= cx;
    _pendY -= cy;
    _history.add((_clock, p.x + _pendX, p.y + _pendY));
    while (_history.length > 2 && _history.first.$1 < _clock - 1.5) {
      _history.removeAt(0);
    }
  }
}

class _Sample {
  const _Sample(this.t, this.x, this.y);

  final double t, x, y;
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

  /// Smoothed round-trip time to the server in seconds.
  double rtt = 0.15;

  final Stopwatch _rttClock = Stopwatch()..start();
  double? _helloSentAt;
  Timer? _pinger;
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

  /// The player watched the advantage ad: the next match starts with extra
  /// bombs. Cleared when that match begins (or the connection drops, since the
  /// server forgets the flag).
  bool boosted = false;

  /// Winner slot of the last match (null = draw).
  int? winner;

  /// Winning team of the last match (null = draw).
  int? winnerTeam;

  /// Rejected requests (wrong password, room full, ...).
  Stream<ErrorCode> get errors => _errors.stream;

  /// Connects to [address] as [name]. Returns false on failure.
  Future<bool> connect(String address, String name, {List<int>? skin}) async {
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
      _helloSentAt = _now;
      _send({
        't': Msg.hello,
        'name': cleanText(name, Limits.name),
        'v': protocolVersion,
        if (skin != null) 'skin': skin,
      });
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

  double get _now => _rttClock.elapsedMicroseconds / 1e6;

  void _addRttSample(double sample) {
    if (sample < 0 || sample > 5) return;
    rtt = rtt * 0.7 + sample * 0.3;
  }

  void _reset() {
    _pinger?.cancel();
    _pinger = null;
    status = OnlineStatus.disconnected;
    waking = false;
    boosted = false;
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

  /// Joins a public waiting room of [capacity] players or opens one; the
  /// match starts as soon as it is full.
  void quickMatch(int capacity) => _send({'t': Msg.quick, 'capacity': capacity});

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

  /// Tells the server that the advantage ad was watched ([on]) or revokes it.
  void setBoost(bool on) {
    boosted = on;
    _send({'t': Msg.boost, 'on': on});
    notifyListeners();
  }

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
        final sent = _helloSentAt;
        if (sent != null) rtt = (_now - sent).clamp(0.02, 1.0);
        if (m['ping'] == true) {
          _pinger?.cancel();
          _pinger = Timer.periodic(const Duration(seconds: 2), (_) => _send({'t': Msg.ping, 'c': _now}));
        }
        _completeWelcome(true);
      case Msg.pong:
        final c = m['c'];
        if (c is num) _addRttSample(_now - c);
        return;
      case Msg.rooms:
        rooms = [
          for (final r in m['rooms'] as List) RoomSummary.fromJson((r as Map).cast<String, dynamic>()),
        ];
      case Msg.room:
        room = RoomDetails.fromJson((m['room'] as Map).cast<String, dynamic>());
      case Msg.start:
        winner = null;
        winnerTeam = null;
        // The server used the advantage up for this match.
        boosted = false;
        match = OnlineMatch(
          seed: m['seed'] as int,
          capacity: m['cap'] as int,
          teams: m['teams'] as bool,
          localId: m['you'] as int,
          names: (m['names'] as List).cast<String>(),
          send: _send,
          latency: () => rtt,
          skins: [
            for (final k in (m['skins'] as List? ?? const []))
              Skin(
                hat: (k as List)[0] as int,
                face: k[1] as int,
                color: (k[2] as int) == 0 ? null : k[2] as int,
              ),
          ],
        );
      case Msg.emoteFrom:
        match?.showEmote(m['from'] as int, m['e'] as int);
        return;
      case Msg.left:
        match?.playerLeft(m['slot'] as int);
        return;
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
