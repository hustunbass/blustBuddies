import 'dart:math';

import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:flutter/material.dart';

/// On-screen 4-direction joystick.
class VirtualJoystick extends StatefulWidget {
  /// Creates a joystick of [size] logical pixels.
  const VirtualJoystick({
    super.key,
    required this.onChanged,
    this.size = 140,
    this.semanticLabel = 'Joystick',
  });

  /// Called when the direction changes.
  final ValueChanged<Dir> onChanged;

  /// Diameter.
  final double size;

  /// Accessibility label.
  final String semanticLabel;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knob = Offset.zero;
  Dir _dir = Dir.none;

  void _update(Offset local) {
    final r = widget.size / 2;
    var v = local - Offset(r, r);
    if (v.distance > r) v = v / v.distance * r;
    var d = Dir.none;
    if (v.distance > r * 0.28) {
      d = v.dx.abs() > v.dy.abs()
          ? (v.dx > 0 ? Dir.right : Dir.left)
          : (v.dy > 0 ? Dir.down : Dir.up);
    }
    setState(() => _knob = v);
    if (d != _dir) {
      _dir = d;
      widget.onChanged(d);
    }
  }

  void _release() {
    setState(() => _knob = Offset.zero);
    if (_dir != Dir.none) {
      _dir = Dir.none;
      widget.onChanged(Dir.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Semantics(
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _update(d.localPosition),
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => _release(),
        onPanCancel: _release,
        child: SizedBox(
          width: s,
          height: s,
          child: CustomPaint(painter: _JoystickPainter(_knob, s)),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  _JoystickPainter(this.knob, this.size);

  final Offset knob;
  final double size;

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(size / 2, size / 2);
    canvas.drawCircle(c, size / 2, Paint()..color = const Color(0x33FFFFFF));
    canvas.drawCircle(
      c,
      size / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x66FFFFFF),
    );
    canvas.drawCircle(c + knob * 0.8, size * 0.2, Paint()..color = const Color(0xCCFFFFFF));
  }

  @override
  bool shouldRepaint(_JoystickPainter old) => old.knob != knob || old.size != size;
}

/// Joystick that appears wherever the thumb lands inside its zone and
/// follows it; a faint ring marks the resting spot when idle.
class FloatingJoystick extends StatefulWidget {
  /// Creates a floating joystick filling its parent.
  const FloatingJoystick({
    super.key,
    required this.onChanged,
    this.size = 140,
    this.alignment = Alignment.bottomLeft,
    this.home,
    this.semanticLabel = 'Joystick',
  });

  /// Called when the direction changes.
  final ValueChanged<Dir> onChanged;

  /// Diameter of the stick.
  final double size;

  /// Resting position inside the zone.
  final Alignment alignment;

  /// Centre of the resting ring in zone coordinates; overrides [alignment].
  final Offset? home;

  /// Accessibility label.
  final String semanticLabel;

  @override
  State<FloatingJoystick> createState() => _FloatingJoystickState();
}

class _FloatingJoystickState extends State<FloatingJoystick> {
  Offset? _origin;
  Offset _knob = Offset.zero;
  Dir _dir = Dir.none;
  int? _pointer;

  void _move(Offset local) {
    final o = _origin;
    if (o == null) return;
    final r = widget.size / 2;
    var v = local - o;
    if (v.distance > r) {
      // Drag the stick along when the thumb leaves the ring.
      final excess = v - v / v.distance * r;
      _origin = o + excess;
      v = v / v.distance * r;
    }
    var d = Dir.none;
    if (v.distance > r * 0.28) {
      d = v.dx.abs() > v.dy.abs() ? (v.dx > 0 ? Dir.right : Dir.left) : (v.dy > 0 ? Dir.down : Dir.up);
    }
    setState(() => _knob = v);
    if (d != _dir) {
      _dir = d;
      widget.onChanged(d);
    }
  }

  void _release() {
    _pointer = null;
    setState(() {
      _origin = null;
      _knob = Offset.zero;
    });
    if (_dir != Dir.none) {
      _dir = Dir.none;
      widget.onChanged(Dir.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      child: LayoutBuilder(builder: (context, c) {
        final rest = widget.home ??
            widget.alignment
                .inscribe(Size.square(widget.size), Offset.zero & Size(c.maxWidth, c.maxHeight))
                .center;
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            if (_pointer != null) return;
            _pointer = e.pointer;
            _origin = e.localPosition;
            _move(e.localPosition);
          },
          onPointerMove: (e) {
            if (e.pointer == _pointer) _move(e.localPosition);
          },
          onPointerUp: (e) {
            if (e.pointer == _pointer) _release();
          },
          onPointerCancel: (e) {
            if (e.pointer == _pointer) _release();
          },
          child: CustomPaint(
            size: Size(c.maxWidth, c.maxHeight),
            painter: _FloatingPainter(_origin ?? rest, _knob, widget.size, active: _origin != null),
          ),
        );
      }),
    );
  }
}

class _FloatingPainter extends CustomPainter {
  _FloatingPainter(this.center, this.knob, this.size, {required this.active});

  final Offset center;
  final Offset knob;
  final double size;
  final bool active;

  @override
  void paint(Canvas canvas, Size s) {
    final a = active ? 1.0 : .45;
    canvas.drawCircle(center, size / 2, Paint()..color = Color.fromRGBO(255, 255, 255, .2 * a));
    canvas.drawCircle(
      center,
      size / 2 - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Color.fromRGBO(255, 255, 255, .4 * a),
    );
    canvas.drawCircle(center + knob * 0.8, size * 0.2, Paint()..color = Color.fromRGBO(255, 255, 255, .8 * a));
  }

  @override
  bool shouldRepaint(_FloatingPainter old) =>
      old.center != center || old.knob != knob || old.active != active || old.size != size;
}

/// Round bomb button.
class BombButton extends StatelessWidget {
  /// Creates the button.
  const BombButton({
    super.key,
    required this.onPressed,
    this.size = 96,
    this.semanticLabel = 'Bomb',
  });

  /// Tap handler (fires on pointer down for responsiveness).
  final VoidCallback onPressed;

  /// Diameter.
  final double size;

  /// Accessibility label.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onPressed(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xCCFF7043),
            border: Border.all(color: Colors.white54, width: 3),
          ),
          child: Icon(Icons.circle, size: size * 0.45, color: const Color(0xFF263238)),
        ),
      ),
    );
  }
}

/// Convenience for sizing relative to the settings scale.
double scaled(double base, double scale) => base * min(1.4, max(0.7, scale));
