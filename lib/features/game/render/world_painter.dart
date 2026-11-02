import 'dart:math';
import 'dart:ui';

import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/render/particles.dart';

/// Draws a [GameWorld] with vector shapes (no image assets needed).
///
/// All drawing happens in cell units after a single canvas scale, and every
/// [Paint] is reused, so painting allocates (almost) nothing per frame.
class WorldPainter {
  /// Creates a painter. [reducedMotion] disables shake and particles;
  /// [highlightId] marks the local player (online).
  WorldPainter({this.reducedMotion = false, this.highlightId});

  /// Accessibility: skip shake/particles.
  bool reducedMotion;

  /// Player drawn with a "you" marker.
  final int? highlightId;

  /// Particle pool.
  final ParticleSystem particles = ParticleSystem();

  final Paint _fill = Paint();
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  double _shake = 0;
  double _t = 0;

  static const _fireColors = [Color(0xFFFFEE58), Color(0xFFFF9800), Color(0xFFFF5722)];
  static const _debris = [Color(0xFFB9773E), Color(0xFF8D5A2B), Color(0xFFD7A86E)];

  /// Reacts to simulation events with particles and shake.
  void onEvent(GameEvent e) {
    if (reducedMotion) return;
    switch (e.type) {
      case GameEventType.explosion:
        _shake = 0.12;
        particles.burst(e.x, e.y, 24, _fireColors, speed: 4);
      case GameEventType.blockDestroyed:
        particles.burst(e.x, e.y, 10, _debris, speed: 2.5, size: 0.1);
      case GameEventType.powerUp:
        particles.burst(e.x, e.y, 12, const [Color(0xFFFFFFFF), Color(0xFF80DEEA)], speed: 2);
      case GameEventType.playerHit:
        _shake = 0.2;
        particles.burst(e.x, e.y, 16, const [Color(0xFFFF5252), Color(0xFFFFFFFF)], speed: 3);
      case GameEventType.enemyKilled:
        particles.burst(e.x, e.y, 14, const [Color(0xFFFFFFFF), Color(0xFFB388FF)], speed: 3);
      default:
        break;
    }
  }

  /// Advances animations.
  void update(double dt) {
    _t += dt;
    _shake = max(0, _shake - dt * 0.6);
    if (!reducedMotion) particles.update(dt);
  }

  /// Paints [w] into a canvas of [size].
  void paint(Canvas canvas, GameWorld w, Size size) {
    final cell = min(size.width / GridModel.cols, size.height / GridModel.rows);
    final ox = (size.width - GridModel.cols * cell) / 2;
    final oy = (size.height - GridModel.rows * cell) / 2;
    final sx = _shake > 0 ? sin(_t * 90) * _shake : 0.0;
    final sy = _shake > 0 ? cos(_t * 110) * _shake : 0.0;
    canvas
      ..save()
      ..translate(ox + sx * cell, oy + sy * cell)
      ..scale(cell);

    _drawTerrain(canvas, w);
    _drawExit(canvas, w);
    w.powerUps.forEach((c, t) => _drawPowerUp(canvas, c, t));
    for (final b in w.bombs) {
      _drawBomb(canvas, b);
    }
    _drawFlames(canvas, w);
    for (final e in w.enemies) {
      if (e.alive) _drawEnemy(canvas, e);
    }
    for (final p in w.players) {
      if (!p.alive) continue;
      if (w.teams) _drawTeamRing(canvas, p);
      _drawBuddy(canvas, p);
      if (p.id == highlightId) _drawYouMarker(canvas, p);
    }
    if (!reducedMotion) particles.paint(canvas);
    canvas.restore();
  }

  void _drawTerrain(Canvas canvas, GameWorld w) {
    for (var y = 0; y < GridModel.rows; y++) {
      for (var x = 0; x < GridModel.cols; x++) {
        final r = Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1);
        switch (w.grid.typeAt(x, y)) {
          case CellType.wall:
            _fill.color = BuddyColors.wall;
            canvas.drawRect(r, _fill);
            _fill.color = const Color(0x33FFFFFF);
            canvas.drawRect(Rect.fromLTWH(x + .06, y + .06, .88, .2), _fill);
            _fill.color = const Color(0x33000000);
            canvas.drawRect(Rect.fromLTWH(x + .06, y + .76, .88, .18), _fill);
          case CellType.block:
            _fill.color = BuddyColors.floorA;
            canvas.drawRect(r, _fill);
            _fill.color = BuddyColors.block;
            canvas.drawRRect(
                RRect.fromRectAndRadius(r.deflate(.05), const Radius.circular(.12)), _fill);
            _stroke
              ..color = const Color(0xFF7A4A22)
              ..strokeWidth = .07;
            canvas
              ..drawLine(Offset(x + .2, y + .2), Offset(x + .8, y + .8), _stroke)
              ..drawLine(Offset(x + .8, y + .2), Offset(x + .2, y + .8), _stroke);
          case CellType.empty:
            _fill.color = (x + y).isEven ? BuddyColors.floorA : BuddyColors.floorB;
            canvas.drawRect(r, _fill);
        }
      }
    }
  }

  void _drawExit(Canvas canvas, GameWorld w) {
    final e = w.exit;
    if (e == null || !w.exitRevealed) return;
    final c = Offset(e.x + .5, e.y + .5);
    final open = w.exitOpen;
    _fill.color = open ? const Color(0xFF00E676) : const Color(0xFF616161);
    canvas.drawCircle(c, .4, _fill);
    _fill.color = open
        ? Color.lerp(const Color(0xFFB9F6CA), const Color(0xFFFFFFFF), (sin(_t * 6) + 1) / 2)!
        : const Color(0xFF212121);
    canvas.drawCircle(c, .26 + (open ? sin(_t * 6) * .03 : 0), _fill);
  }

  void _drawPowerUp(Canvas canvas, GridPos c, PowerUpType t) {
    final bob = sin(_t * 5 + c.x) * .03;
    final center = Offset(c.x + .5, c.y + .5 + bob);
    const colors = {
      PowerUpType.bomb: Color(0xFF90A4AE),
      PowerUpType.range: Color(0xFFFF7043),
      PowerUpType.speed: Color(0xFFFFEE58),
      PowerUpType.shield: Color(0xFF4FC3F7),
      PowerUpType.kick: Color(0xFFBA68C8),
    };
    _fill.color = colors[t]!;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCircle(center: center, radius: .34), const Radius.circular(.12)),
        _fill);
    _fill.color = const Color(0xFF212121);
    _stroke
      ..color = const Color(0xFF212121)
      ..strokeWidth = .08;
    switch (t) {
      case PowerUpType.bomb:
        canvas.drawCircle(center.translate(0, .03), .14, _fill);
      case PowerUpType.range:
        canvas
          ..drawLine(center.translate(-.16, 0), center.translate(.16, 0), _stroke)
          ..drawLine(center.translate(0, -.16), center.translate(0, .16), _stroke);
      case PowerUpType.speed:
        final path = Path()
          ..moveTo(center.dx + .05, center.dy - .18)
          ..lineTo(center.dx - .1, center.dy + .03)
          ..lineTo(center.dx, center.dy + .03)
          ..lineTo(center.dx - .05, center.dy + .18)
          ..lineTo(center.dx + .1, center.dy - .04)
          ..lineTo(center.dx, center.dy - .04)
          ..close();
        canvas.drawPath(path, _fill);
      case PowerUpType.shield:
        canvas.drawCircle(center, .16, _stroke);
      case PowerUpType.kick:
        canvas
          ..drawLine(center.translate(-.15, 0), center.translate(.15, 0), _stroke)
          ..drawLine(center.translate(.04, -.11), center.translate(.15, 0), _stroke)
          ..drawLine(center.translate(.04, .11), center.translate(.15, 0), _stroke);
    }
  }

  void _drawBomb(Canvas canvas, Bomb b) {
    final pulse = 1 + sin(_t * (b.fuse < 1 ? 24 : 8)) * .06;
    final c = Offset(b.drawX + .5, b.drawY + .55);
    _fill.color = const Color(0x55000000);
    canvas.drawOval(Rect.fromCenter(center: c.translate(0, .3), width: .6, height: .18), _fill);
    _fill.color = b.fuse < 1 ? const Color(0xFF5D1F1F) : const Color(0xFF263238);
    canvas.drawCircle(c, .32 * pulse, _fill);
    _fill.color = const Color(0x55FFFFFF);
    canvas.drawCircle(c.translate(-.1, -.1), .08, _fill);
    _stroke
      ..color = const Color(0xFFBCAAA4)
      ..strokeWidth = .05;
    canvas.drawLine(c.translate(.1, -.28), c.translate(.2, -.38), _stroke);
    _fill.color = (_t * 12).floor().isEven ? const Color(0xFFFFEE58) : const Color(0xFFFF7043);
    canvas.drawCircle(c.translate(.22, -.4), .07, _fill);
  }

  void _drawFlames(Canvas canvas, GameWorld w) {
    for (var y = 0; y < GridModel.rows; y++) {
      for (var x = 0; x < GridModel.cols; x++) {
        final t = w.flameTime[y * GridModel.cols + x];
        if (t <= 0) continue;
        final k = (t / GameWorld.flameDuration).clamp(0.0, 1.0);
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + .06, y + .06, .88, .88),
          const Radius.circular(.25),
        );
        _fill.color = Color.lerp(const Color(0xFFFF5722), const Color(0xFFFF9800), k)!
            .withValues(alpha: .55 + .45 * k);
        canvas.drawRRect(r, _fill);
        _fill.color = const Color(0xFFFFF59D).withValues(alpha: k);
        canvas.drawCircle(Offset(x + .5, y + .5), .28 * (.6 + k * .4), _fill);
      }
    }
  }

  void _drawTeamRing(Canvas canvas, Player p) {
    _stroke
      ..color = BuddyColors.teams[p.teamId % 2]
      ..strokeWidth = .07;
    canvas.drawOval(Rect.fromCenter(center: Offset(p.x, p.y + .34), width: .78, height: .3), _stroke);
  }

  void _drawYouMarker(Canvas canvas, Player p) {
    final y = p.y - .72 + sin(_t * 5) * .04;
    final path = Path()
      ..moveTo(p.x - .14, y - .12)
      ..lineTo(p.x + .14, y - .12)
      ..lineTo(p.x, y + .04)
      ..close();
    _fill.color = const Color(0xFFFFFFFF);
    canvas.drawPath(path, _fill);
  }

  void _drawBuddy(Canvas canvas, Player p) {
    if (p.invuln > 0 && (_t * 12).floor().isEven) return;
    final color = BuddyColors.players[p.id % 4];
    final moving = p.moveDir != Dir.none;
    final bob = moving ? sin(_t * 18).abs() * .05 : 0.0;
    final c = Offset(p.x, p.y - bob);
    _fill.color = const Color(0x55000000);
    canvas.drawOval(Rect.fromCenter(center: Offset(p.x, p.y + .36), width: .6, height: .18), _fill);
    // Feet
    _fill.color = Color.lerp(color, const Color(0xFF000000), .35)!;
    final foot = moving ? sin(_t * 18) * .06 : 0.0;
    canvas
      ..drawCircle(Offset(p.x - .15, p.y + .32 + foot), .09, _fill)
      ..drawCircle(Offset(p.x + .15, p.y + .32 - foot), .09, _fill);
    // Antenna
    _stroke
      ..color = const Color(0xFFCFD8DC)
      ..strokeWidth = .05;
    canvas.drawLine(c.translate(0, -.3), c.translate(0, -.45), _stroke);
    _fill.color = (_t * 3).floor().isEven ? const Color(0xFFFF5252) : const Color(0xFFFFFFFF);
    canvas.drawCircle(c.translate(0, -.46), .06, _fill);
    // Body
    _fill.color = color;
    canvas.drawCircle(c, .36, _fill);
    // Visor
    _fill.color = const Color(0xFFECEFF1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c.translate(p.facing.dx * .05, p.facing.dy * .04 - .02), width: .46, height: .26),
        const Radius.circular(.13),
      ),
      _fill,
    );
    _fill.color = const Color(0xFF263238);
    final look = Offset(p.facing.dx * .05, p.facing.dy * .03);
    canvas
      ..drawCircle(c.translate(-.1, -.02) + look, .045, _fill)
      ..drawCircle(c.translate(.1, -.02) + look, .045, _fill);
    if (p.stats.shield > 0) {
      final fade = p.stats.shield < 2 && (_t * 10).floor().isEven ? .15 : .35;
      _fill.color = const Color(0xFF4FC3F7).withValues(alpha: fade);
      canvas.drawCircle(c, .5 + sin(_t * 6) * .02, _fill);
    }
  }

  void _drawEnemy(Canvas canvas, Enemy e) {
    final c = Offset(e.x, e.y);
    final wob = sin(_t * 10 + e.x * 3) * .03;
    _fill.color = const Color(0x55000000);
    canvas.drawOval(Rect.fromCenter(center: c.translate(0, .34), width: .6, height: .16), _fill);
    switch (e.type) {
      case EnemyType.wanderer:
        _fill.color = const Color(0xFFAB47BC);
        canvas.drawCircle(c.translate(0, -wob), .33, _fill);
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(c.translate(i * .2, .26 + wob * i), .1, _fill);
        }
      case EnemyType.chaser:
        _fill.color = const Color(0xFFE53935);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: .66, height: .62), const Radius.circular(.16)),
          _fill,
        );
        final horn = Path()
          ..moveTo(c.dx - .26, c.dy - .26)
          ..lineTo(c.dx - .18, c.dy - .46)
          ..lineTo(c.dx - .08, c.dy - .28)
          ..moveTo(c.dx + .26, c.dy - .26)
          ..lineTo(c.dx + .18, c.dy - .46)
          ..lineTo(c.dx + .08, c.dy - .28);
        _fill.color = const Color(0xFFFFCDD2);
        canvas.drawPath(horn, _fill);
      case EnemyType.speedster:
        _fill.color = const Color(0xFFFFB300);
        canvas.drawOval(Rect.fromCenter(center: c, width: .72, height: .56), _fill);
        _fill.color = const Color(0xFFFFE082);
        canvas.drawRect(Rect.fromCenter(center: c.translate(-e.dir.dx * .1, 0), width: .1, height: .5), _fill);
    }
    _fill.color = const Color(0xFFFFFFFF);
    canvas
      ..drawCircle(c.translate(-.1, -.06), .08, _fill)
      ..drawCircle(c.translate(.1, -.06), .08, _fill);
    _fill.color = const Color(0xFF212121);
    final look = Offset(e.dir.dx * .03, e.dir.dy * .03);
    canvas
      ..drawCircle(c.translate(-.1, -.06) + look, .04, _fill)
      ..drawCircle(c.translate(.1, -.06) + look, .04, _fill);
  }
}
