import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/render/world_painter.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keyboard bindings for one local player.
class KeyScheme {
  /// Creates a scheme.
  const KeyScheme(this.up, this.down, this.left, this.right, this.bomb);

  /// Up key(s).
  final Set<LogicalKeyboardKey> up;

  /// Down key(s).
  final Set<LogicalKeyboardKey> down;

  /// Left key(s).
  final Set<LogicalKeyboardKey> left;

  /// Right key(s).
  final Set<LogicalKeyboardKey> right;

  /// Bomb key(s).
  final Set<LogicalKeyboardKey> bomb;

  /// Direction for [k], or null.
  Dir? dirFor(LogicalKeyboardKey k) {
    if (up.contains(k)) return Dir.up;
    if (down.contains(k)) return Dir.down;
    if (left.contains(k)) return Dir.left;
    if (right.contains(k)) return Dir.right;
    return null;
  }

  /// Solo scheme: arrows and WASD, Space/Enter.
  static final solo = KeyScheme(
    {LogicalKeyboardKey.arrowUp, LogicalKeyboardKey.keyW},
    {LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.keyS},
    {LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA},
    {LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD},
    {LogicalKeyboardKey.space, LogicalKeyboardKey.enter},
  );

  /// Shared-keyboard schemes for players 1-4.
  static final multi = [
    KeyScheme(
      {LogicalKeyboardKey.keyW},
      {LogicalKeyboardKey.keyS},
      {LogicalKeyboardKey.keyA},
      {LogicalKeyboardKey.keyD},
      {LogicalKeyboardKey.space},
    ),
    KeyScheme(
      {LogicalKeyboardKey.arrowUp},
      {LogicalKeyboardKey.arrowDown},
      {LogicalKeyboardKey.arrowLeft},
      {LogicalKeyboardKey.arrowRight},
      {LogicalKeyboardKey.enter},
    ),
    KeyScheme(
      {LogicalKeyboardKey.keyI},
      {LogicalKeyboardKey.keyK},
      {LogicalKeyboardKey.keyJ},
      {LogicalKeyboardKey.keyL},
      {LogicalKeyboardKey.keyU},
    ),
    KeyScheme(
      {LogicalKeyboardKey.keyT},
      {LogicalKeyboardKey.keyG},
      {LogicalKeyboardKey.keyF},
      {LogicalKeyboardKey.keyH},
      {LogicalKeyboardKey.keyR},
    ),
  ];
}

/// A match simulated elsewhere (online server): input is forwarded and the
/// local world is only advanced visually.
abstract interface class RemoteSession {
  /// Player id controlled by this device.
  int get localId;

  /// Sends the held direction.
  void move(Dir d);

  /// Sends a bomb request.
  void bomb();

  /// Detonates own bombs (detonator power-up).
  void detonate();

  /// Shows emote [i] above the local buddy.
  void emote(int i);

  /// Current emote per player slot (-1 = none).
  List<int> get emotes;

  /// Advances client-side smoothing by [dt] seconds.
  void advance(double dt);
}

/// Flame host for a [GameWorld]: feeds input, ticks the simulation and
/// renders through [WorldPainter]. Game rules live in [GameWorld].
class BlastGame extends FlameGame with KeyboardEvents {
  /// Creates a game for [sim] with [humans] keyboard/touch players.
  BlastGame({
    required this.sim,
    required this.humans,
    required this.onEvent,
    required this.onFinished,
    this.remote,
    bool reducedMotion = false,
  }) : painter = WorldPainter(reducedMotion: reducedMotion, highlightId: remote?.localId) {
    hud = ValueNotifier(HudState.from(sim, remote?.localId ?? 0));
  }

  /// Simulation.
  final GameWorld sim;

  /// Number of human players on this device.
  final int humans;

  /// Set for online matches; [sim] is then a mirror and never ticked here.
  final RemoteSession? remote;

  /// Called for every simulation event (audio/haptics).
  final void Function(GameEvent) onEvent;

  /// Called once when the world leaves [WorldStatus.playing].
  final void Function(WorldStatus) onFinished;

  /// Renderer.
  final WorldPainter painter;

  /// HUD data.
  late final ValueNotifier<HudState> hud;

  /// Touch joystick direction (player 1).
  Dir touchDir = Dir.none;

  final List<List<Dir>> _held = List.generate(4, (_) => <Dir>[]);
  bool _finished = false;

  @override
  Color backgroundColor() => const Color(0xFF1B2238);

  /// Touch bomb button.
  void touchBomb() => _bomb(0);

  /// Touch detonate button.
  void touchDetonate() {
    final r = remote;
    if (r != null) {
      r.detonate();
    } else {
      sim.requestDetonate(0);
    }
  }

  void _bomb(int i) {
    final r = remote;
    if (r != null) {
      r.bomb();
    } else {
      sim.requestBomb(i);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final r = remote;
    for (var i = 0; i < humans && i < sim.players.length; i++) {
      final held = _held[i];
      var d = held.isEmpty ? Dir.none : held.last;
      if (i == 0 && touchDir != Dir.none) d = touchDir;
      if (r != null) {
        r.move(d);
      } else {
        sim.setMove(i, d);
      }
    }
    if (r != null) {
      r.advance(dt);
    } else {
      sim.tick(dt);
    }
    painter.update(dt);
    if (r != null) painter.emotes = r.emotes;
    for (final e in sim.drainEvents()) {
      painter.onEvent(e);
      onEvent(e);
    }
    final s = HudState.from(sim, r?.localId ?? 0);
    if (s != hud.value) hud.value = s;
    if (!_finished && sim.status != WorldStatus.playing) {
      _finished = true;
      onFinished(sim.status);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    painter.paint(canvas, sim, Size(size.x, size.y));
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final schemes = humans == 1 ? [KeyScheme.solo] : KeyScheme.multi;
    var handled = false;
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyE) {
      touchDetonate();
      handled = true;
    }
    for (var i = 0; i < humans && i < schemes.length; i++) {
      final s = schemes[i];
      final d = s.dirFor(event.logicalKey);
      if (d != null) {
        handled = true;
        _held[i].remove(d);
        if (event is! KeyUpEvent) _held[i].add(d);
      } else if (event is KeyDownEvent && s.bomb.contains(event.logicalKey)) {
        handled = true;
        _bomb(i);
      }
    }
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }
}
