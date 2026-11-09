import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:flutter/material.dart';

/// The picture of every power-up, drawn in "cell" units (one arena cell = 1).
///
/// The arena, the how-to-play list and the in-game HUD all use this one
/// drawing, so a power-up looks the same everywhere.
class PowerUpArt {
  PowerUpArt._();

  /// Tile colour of each power-up.
  static const Map<PowerUpType, Color> colors = {
    PowerUpType.bomb: Color(0xFF90A4AE),
    PowerUpType.range: Color(0xFFFF7043),
    PowerUpType.speed: Color(0xFFFFEE58),
    PowerUpType.shield: Color(0xFF4FC3F7),
    PowerUpType.kick: Color(0xFFBA68C8),
    PowerUpType.detonator: Color(0xFFEF5350),
    PowerUpType.ghost: Color(0xFFCFD8DC),
  };

  /// Half the width of the rounded tile, in cell units.
  static const double tileRadius = .34;

  static final Paint _fill = Paint();
  static final Paint _stroke = Paint()..style = PaintingStyle.stroke;

  /// Draws [t] centred on [center].
  static void paint(Canvas canvas, Offset center, PowerUpType t) {
    _fill
      ..style = PaintingStyle.fill
      ..color = colors[t]!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCircle(center: center, radius: tileRadius), const Radius.circular(.12)),
      _fill,
    );
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
      case PowerUpType.detonator:
        canvas
          ..drawCircle(center, .17, _stroke)
          ..drawCircle(center, .06, _fill);
      case PowerUpType.ghost:
        canvas
          ..drawCircle(center.translate(0, -.04), .13, _fill)
          ..drawRect(Rect.fromLTRB(center.dx - .13, center.dy - .04, center.dx + .13, center.dy + .13), _fill);
        _fill.color = const Color(0xFFCFD8DC);
        canvas
          ..drawCircle(center.translate(-.05, -.05), .028, _fill)
          ..drawCircle(center.translate(.05, -.05), .028, _fill);
    }
  }
}

/// A power-up as a widget, [size] logical pixels wide.
class PowerUpIcon extends StatelessWidget {
  /// Creates the icon.
  const PowerUpIcon(this.type, {super.key, this.size = 28});

  /// Which power-up.
  final PowerUpType type;

  /// Edge length of the rounded tile.
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _PowerUpPainter(type)),
        ),
      );
}

class _PowerUpPainter extends CustomPainter {
  _PowerUpPainter(this.type);

  final PowerUpType type;

  @override
  void paint(Canvas canvas, Size size) {
    // The tile spans 2 * tileRadius cell units; scale it to fill the widget.
    final k = size.width / (PowerUpArt.tileRadius * 2);
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(k)
      ..translate(0, 0);
    PowerUpArt.paint(canvas, Offset.zero, type);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PowerUpPainter old) => old.type != type;
}
