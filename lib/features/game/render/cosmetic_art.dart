import 'dart:math';

import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:flutter/material.dart';

/// Hats and faces of the buddy, drawn in cell units around the body centre `c`
/// (body radius .36, the visor spans about .46 x .26).
///
/// Hat and face numbers are the indices of `Cosmetics.hats` / `Cosmetics.faces`
/// and travel over the wire, so only ever append new ones.
class CosmeticArt {
  CosmeticArt._();

  static final Paint _fill = Paint();
  static final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static const _ink = Color(0xFF263238);

  /// Hats that sit beside the antenna instead of replacing it.
  static bool keepsAntenna(int hat) => hat == 0 || hat == 6 || hat == 16;

  static Paint _f(Color c) => _fill
    ..style = PaintingStyle.fill
    ..color = c;

  static Paint _s(Color c, double w) => _stroke
    ..color = c
    ..strokeWidth = w;

  static RRect _rr(Rect r, double radius) => RRect.fromRectAndRadius(r, Radius.circular(radius));

  /// Draws hat [hat] on a buddy of body colour [body]; [t] is the animation clock.
  static void hat(Canvas canvas, Offset c, int hat, double t, Color body) {
    final top = c.translate(0, -.32);
    switch (hat) {
      case 1: // cap
        canvas
          ..drawArc(Rect.fromCenter(center: top.translate(0, .02), width: .62, height: .5), pi, pi, true, _f(const Color(0xFFE53935)))
          ..drawRRect(_rr(Rect.fromLTWH(top.dx - .02, top.dy - .03, .4, .07), .035), _f(const Color(0xFFE53935)));
      case 2: // party
        canvas.drawPath(
          Path()
            ..moveTo(top.dx - .2, top.dy + .04)
            ..lineTo(top.dx, top.dy - .42)
            ..lineTo(top.dx + .2, top.dy + .04)
            ..close(),
          _f(const Color(0xFFAB47BC)),
        );
        canvas
          ..drawCircle(top.translate(0, -.43), .06, _f(const Color(0xFFFFEE58)))
          ..drawRect(Rect.fromLTWH(top.dx - .13, top.dy - .12, .26, .05), _f(const Color(0xFFFFEE58)));
      case 3: // cowboy
        canvas
          ..drawOval(Rect.fromCenter(center: top.translate(0, .02), width: .8, height: .16), _f(const Color(0xFF8D6E63)))
          ..drawRRect(_rr(Rect.fromCenter(center: top.translate(0, -.1), width: .38, height: .3), .1), _f(const Color(0xFF8D6E63)))
          ..drawRect(Rect.fromCenter(center: top.translate(0, -.03), width: .38, height: .05), _f(const Color(0xFF5D4037)));
      case 4: // crown
        canvas.drawPath(
          Path()
            ..moveTo(top.dx - .22, top.dy + .04)
            ..lineTo(top.dx - .25, top.dy - .25)
            ..lineTo(top.dx - .11, top.dy - .12)
            ..lineTo(top.dx, top.dy - .3)
            ..lineTo(top.dx + .11, top.dy - .12)
            ..lineTo(top.dx + .25, top.dy - .25)
            ..lineTo(top.dx + .22, top.dy + .04)
            ..close(),
          _f(const Color(0xFFFFCA28)),
        );
        canvas.drawCircle(top.translate(0, -.08), .035, _f(const Color(0xFFE53935)));
      case 5: // wizard
        canvas
          ..drawOval(Rect.fromCenter(center: top.translate(0, .02), width: .7, height: .13), _f(const Color(0xFF3949AB)))
          ..drawPath(
            Path()
              ..moveTo(top.dx - .2, top.dy)
              ..lineTo(top.dx + .04, top.dy - .55)
              ..lineTo(top.dx + .2, top.dy)
              ..close(),
            _f(const Color(0xFF3949AB)),
          )
          ..drawCircle(top.translate(0, -.2), .045, _f(const Color(0xFFFFEE58)));
      case 6: // halo
        canvas.drawOval(Rect.fromCenter(center: top.translate(0, -.22 + sin(t * 4) * .02), width: .5, height: .15), _s(const Color(0xFFFFEE58), .06));
      case 7: // horns
        for (final k in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(top.dx + k * .25, top.dy + .04)
              ..lineTo(top.dx + k * .3, top.dy - .26)
              ..lineTo(top.dx + k * .08, top.dy - .02)
              ..close(),
            _f(const Color(0xFFD32F2F)),
          );
        }
      case 8: // beanie
        canvas
          ..drawArc(Rect.fromCenter(center: top.translate(0, .03), width: .66, height: .52), pi, pi, true, _f(const Color(0xFF1E88E5)))
          ..drawRRect(_rr(Rect.fromLTWH(top.dx - .34, top.dy - .0, .68, .1), .04), _f(const Color(0xFFE3F2FD)))
          ..drawCircle(top.translate(0, -.27), .08, _f(const Color(0xFFFFFFFF)));
      case 9: // chef
        for (final p in [const Offset(-.14, -.2), const Offset(0, -.28), const Offset(.14, -.2)]) {
          canvas.drawCircle(top + p, p.dx == 0 ? .15 : .13, _f(const Color(0xFFFFFFFF)));
        }
        canvas
          ..drawRRect(_rr(Rect.fromLTWH(top.dx - .21, top.dy - .12, .42, .17), .03), _f(const Color(0xFFFFFFFF)))
          ..drawLine(top.translate(-.2, .0), top.translate(.2, .0), _s(const Color(0xFFCFD8DC), .03));
      case 10: // pirate
        canvas.drawPath(
          Path()
            ..moveTo(top.dx - .42, top.dy + .05)
            ..quadraticBezierTo(top.dx - .3, top.dy - .08, top.dx - .2, top.dy - .12)
            ..quadraticBezierTo(top.dx, top.dy - .38, top.dx + .2, top.dy - .12)
            ..quadraticBezierTo(top.dx + .3, top.dy - .08, top.dx + .42, top.dy + .05)
            ..quadraticBezierTo(top.dx, top.dy - .02, top.dx - .42, top.dy + .05)
            ..close(),
          _f(const Color(0xFF263238)),
        );
        canvas
          ..drawLine(top.translate(-.38, .04), top.translate(.38, .04), _s(const Color(0xFFFFCA28), .025))
          ..drawCircle(top.translate(0, -.13), .045, _f(const Color(0xFFFFFFFF)))
          ..drawLine(top.translate(-.06, -.06), top.translate(.06, -.1), _s(const Color(0xFFFFFFFF), .02))
          ..drawLine(top.translate(-.06, -.1), top.translate(.06, -.06), _s(const Color(0xFFFFFFFF), .02));
      case 11: // viking
        for (final k in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(top.dx + k * .27, top.dy + .02)
              ..quadraticBezierTo(top.dx + k * .46, top.dy - .02, top.dx + k * .4, top.dy - .3),
            _s(const Color(0xFFFFF3E0), .09),
          );
        }
        canvas
          ..drawArc(Rect.fromCenter(center: top.translate(0, .04), width: .64, height: .5), pi, pi, true, _f(const Color(0xFF90A4AE)))
          ..drawRRect(_rr(Rect.fromLTWH(top.dx - .32, top.dy - .0, .64, .08), .03), _f(const Color(0xFF607D8B)))
          ..drawRect(Rect.fromCenter(center: top.translate(0, -.1), width: .04, height: .18), _f(const Color(0xFF78909C)));
      case 12: // cat ears
        final ear = Color.lerp(body, const Color(0xFF000000), .15)!;
        for (final k in [-1.0, 1.0]) {
          canvas
            ..drawPath(
              Path()
                ..moveTo(top.dx + k * .31, top.dy + .07)
                ..lineTo(top.dx + k * .27, top.dy - .28)
                ..lineTo(top.dx + k * .05, top.dy - .0)
                ..close(),
              _f(ear),
            )
            ..drawPath(
              Path()
                ..moveTo(top.dx + k * .26, top.dy + .02)
                ..lineTo(top.dx + k * .24, top.dy - .18)
                ..lineTo(top.dx + k * .11, top.dy - .0)
                ..close(),
              _f(const Color(0xFFF8BBD0)),
            );
        }
      case 13: // bunny ears
        for (final k in [-1.0, 1.0]) {
          canvas
            ..save()
            ..translate(top.dx + k * .14, top.dy - .22)
            ..rotate(k * .16)
            ..drawOval(Rect.fromCenter(center: Offset.zero, width: .17, height: .52), _f(Color.lerp(body, const Color(0xFFFFFFFF), .3)!))
            ..drawOval(Rect.fromCenter(center: const Offset(0, .02), width: .08, height: .38), _f(const Color(0xFFF8BBD0)))
            ..restore();
        }
      case 14: // top hat
        canvas
          ..drawRRect(_rr(Rect.fromLTWH(top.dx - .31, top.dy - .01, .62, .07), .03), _f(const Color(0xFF212121)))
          ..drawRRect(_rr(Rect.fromLTWH(top.dx - .2, top.dy - .4, .4, .42), .03), _f(const Color(0xFF212121)))
          ..drawRect(Rect.fromLTWH(top.dx - .2, top.dy - .1, .4, .08), _f(const Color(0xFFD32F2F)));
      case 15: // daisy
        final f = top.translate(.14, -.03);
        for (var i = 0; i < 6; i++) {
          final a = i * pi / 3;
          canvas.drawCircle(f + Offset(cos(a), sin(a)) * .075, .06, _f(const Color(0xFFFFFFFF)));
        }
        canvas.drawCircle(f, .05, _f(const Color(0xFFFFCA28)));
      case 16: // headphones
        canvas.drawArc(Rect.fromCenter(center: c.translate(0, -.01), width: .8, height: .8), pi, pi, false, _s(const Color(0xFF37474F), .06));
        for (final k in [-1.0, 1.0]) {
          canvas
            ..drawRRect(_rr(Rect.fromCenter(center: c.translate(k * .39, 0), width: .13, height: .26), .05), _f(const Color(0xFFE53935)))
            ..drawRRect(_rr(Rect.fromCenter(center: c.translate(k * .39, 0), width: .06, height: .17), .03), _f(const Color(0xFFB71C1C)));
        }
      case 17: // propeller cap
        canvas
          ..drawArc(Rect.fromCenter(center: top.translate(0, .03), width: .58, height: .42), pi, pi, true, _f(const Color(0xFFE53935)))
          ..drawArc(Rect.fromCenter(center: top.translate(0, .03), width: .58, height: .42), pi * 1.34, pi * .32, true, _f(const Color(0xFF1E88E5)))
          ..drawLine(top.translate(0, -.18), top.translate(0, -.26), _s(const Color(0xFF455A64), .03))
          ..drawCircle(top.translate(0, -.19), .035, _f(const Color(0xFFFFEE58)));
        final blade = (cos(t * 14)).abs() * .46 + .05;
        canvas.drawOval(Rect.fromCenter(center: top.translate(0, -.27), width: blade, height: .05), _f(const Color(0xFFFFEE58)));
      case 18: // santa
        canvas
          ..drawPath(
            Path()
              ..moveTo(top.dx - .31, top.dy + .05)
              ..quadraticBezierTo(top.dx - .16, top.dy - .42, top.dx + .22, top.dy - .26)
              ..lineTo(top.dx + .31, top.dy + .05)
              ..close(),
            _f(const Color(0xFFE53935)),
          )
          ..drawRRect(_rr(Rect.fromLTWH(top.dx - .34, top.dy - .02, .68, .1), .045), _f(const Color(0xFFFFFFFF)))
          ..drawCircle(top.translate(.24, -.27), .075, _f(const Color(0xFFFFFFFF)));
      case 19: // ninja band
        canvas.drawPath(
          Path()
            ..moveTo(c.dx + .28, c.dy - .21)
            ..lineTo(c.dx + .52, c.dy - .1 + sin(t * 8) * .02)
            ..lineTo(c.dx + .3, c.dy - .16)
            ..close()
            ..moveTo(c.dx + .28, c.dy - .19)
            ..lineTo(c.dx + .5, c.dy - .26 - sin(t * 8) * .02)
            ..lineTo(c.dx + .3, c.dy - .23)
            ..close(),
          _f(const Color(0xFFD32F2F)),
        );
        canvas
          ..drawRRect(_rr(Rect.fromCenter(center: c.translate(0, -.205), width: .64, height: .085), .03), _f(const Color(0xFFD32F2F)))
          ..drawRRect(_rr(Rect.fromCenter(center: c.translate(0, -.205), width: .16, height: .07), .02), _f(const Color(0xFFCFD8DC)))
          ..drawLine(c.translate(-.04, -.205), c.translate(.04, -.205), _s(const Color(0xFF455A64), .02));
      case 20: // flame hair
        for (var i = -1; i <= 1; i++) {
          final x = top.dx + i * .13;
          final h = (i == 0 ? .34 : .26) + sin(t * 11 + i * 1.7) * .05;
          final sway = sin(t * 8 + i) * .04;
          for (final (scale, color) in [(1.0, const Color(0xFFFF7043)), (.62, const Color(0xFFFFEE58))]) {
            canvas.drawPath(
              Path()
                ..moveTo(x - .09 * scale, top.dy + .04)
                ..quadraticBezierTo(x - .08 * scale, top.dy - h * .55 * scale, x + sway, top.dy - h * scale)
                ..quadraticBezierTo(x + .08 * scale, top.dy - h * .55 * scale, x + .09 * scale, top.dy + .04)
                ..close(),
              _f(color),
            );
          }
        }
      case 21: // jester
        for (final (k, color) in [(-1.0, const Color(0xFF7E57C2)), (1.0, const Color(0xFFFFA726))]) {
          canvas
            ..drawPath(
              Path()
                ..moveTo(top.dx + k * .01, top.dy + .05)
                ..quadraticBezierTo(top.dx + k * .3, top.dy - .0, top.dx + k * .34, top.dy - .28)
                ..quadraticBezierTo(top.dx + k * .12, top.dy - .12, top.dx + k * -.2, top.dy + .05)
                ..close(),
              _f(color),
            )
            ..drawCircle(top.translate(k * .34, -.29), .05, _f(const Color(0xFFFFEE58)));
        }
        canvas.drawRRect(_rr(Rect.fromLTWH(top.dx - .22, top.dy - .01, .44, .07), .03), _f(const Color(0xFFE53935)));
      case 22: // laurel wreath
        for (var i = 0; i < 9; i++) {
          final a = pi * (1.08 + i * .105);
          final p = c + Offset(cos(a), sin(a)) * .38;
          canvas
            ..save()
            ..translate(p.dx, p.dy)
            // Leaves lie along the head instead of sticking out of it.
            ..rotate(a + pi / 2 + (i < 4 ? -1.15 : 1.15))
            ..drawOval(Rect.fromCenter(center: Offset.zero, width: .075, height: .17), _f(i.isEven ? const Color(0xFF66BB6A) : const Color(0xFF43A047)))
            ..restore();
        }
      case 23: // rainbow afro
        const colors = [Color(0xFFE53935), Color(0xFFFB8C00), Color(0xFFFDD835), Color(0xFF43A047), Color(0xFF00ACC1), Color(0xFF8E24AA)];
        for (var i = 0; i < colors.length; i++) {
          final a = pi * (1.12 + i * (0.76 / (colors.length - 1)));
          canvas.drawCircle(c + Offset(cos(a), sin(a)) * .37, .125 + (i == 2 || i == 3 ? .02 : 0), _f(colors[i]));
        }
    }
  }

  static Path _heart(Offset c, double s) => Path()
    ..moveTo(c.dx, c.dy + s * .9)
    ..cubicTo(c.dx - s * 1.5, c.dy + s * .1, c.dx - s * .9, c.dy - s, c.dx, c.dy - s * .35)
    ..cubicTo(c.dx + s * .9, c.dy - s, c.dx + s * 1.5, c.dy + s * .1, c.dx, c.dy + s * .9)
    ..close();

  /// Draws face [face] on the visor of a buddy looking towards [facing].
  static void face(Canvas canvas, Offset c, Dir facing, int face, double t) {
    final look = Offset(facing.dx * .05, facing.dy * .03);
    final l = c.translate(-.1, -.02) + look, r = c.translate(.1, -.02) + look;
    final dot = _f(_ink);
    _s(_ink, .04);
    switch (face) {
      case 1: // happy ^ ^
        for (final e in [l, r]) {
          canvas.drawArc(Rect.fromCenter(center: e.translate(0, .02), width: .1, height: .1), pi, pi, false, _stroke);
        }
      case 2: // sunglasses
        for (final e in [l, r]) {
          canvas.drawRRect(_rr(Rect.fromCenter(center: e, width: .17, height: .12), .04), _f(const Color(0xFF111418)));
        }
        for (final e in [l, r]) {
          canvas.drawCircle(e.translate(-.03, -.02), .02, _f(const Color(0x66FFFFFF)));
        }
      case 3: // angry
        canvas
          ..drawCircle(l, .045, _f(_ink))
          ..drawCircle(r, .045, _f(_ink))
          ..drawLine(l.translate(-.07, -.1), l.translate(.05, -.05), _s(_ink, .04))
          ..drawLine(r.translate(.07, -.1), r.translate(-.05, -.05), _s(_ink, .04));
      case 4: // wink
        canvas
          ..drawCircle(l, .045, _f(_ink))
          ..drawLine(r.translate(-.05, 0), r.translate(.05, 0), _s(_ink, .04));
      case 5: // star eyes
        for (final e in [l, r]) {
          canvas
            ..drawCircle(e, .05, _f(const Color(0xFFFFB300)))
            ..drawLine(e.translate(-.08, 0), e.translate(.08, 0), _s(const Color(0xFFFFB300), .04))
            ..drawLine(e.translate(0, -.08), e.translate(0, .08), _s(const Color(0xFFFFB300), .04));
        }
      case 6: // sleepy
        for (final e in [l, r]) {
          canvas.drawArc(Rect.fromCenter(center: e.translate(0, -.03), width: .1, height: .1), 0, pi, false, _s(_ink, .04));
        }
        final z = c.translate(.3, -.32 + sin(t * 3) * .015);
        canvas.drawPath(
          Path()
            ..moveTo(z.dx - .05, z.dy - .05)
            ..lineTo(z.dx + .05, z.dy - .05)
            ..lineTo(z.dx - .05, z.dy + .05)
            ..lineTo(z.dx + .05, z.dy + .05),
          _s(const Color(0xFFFFFFFF), .035),
        );
      case 7: // surprised
        for (final e in [l, r]) {
          canvas
            ..drawCircle(e, .06, _f(_ink))
            ..drawCircle(e.translate(-.02, -.02), .02, _f(const Color(0xFFFFFFFF)))
            ..drawArc(Rect.fromCenter(center: e.translate(0, -.1), width: .12, height: .08), pi * 1.1, pi * .8, false, _s(_ink, .03));
        }
        canvas.drawCircle(c.translate(0, .075) + look, .03, _s(_ink, .03));
      case 8: // heart eyes
        for (final e in [l, r]) {
          canvas.drawPath(_heart(e.translate(0, -.005 + sin(t * 6) * .006), .06), _f(const Color(0xFFEC407A)));
        }
      case 9: // silly: one big eye, one small, tongue out
        canvas
          ..drawCircle(l, .065, _f(_ink))
          ..drawCircle(l.translate(-.02, -.02), .022, _f(const Color(0xFFFFFFFF)))
          ..drawCircle(r, .032, _f(_ink))
          ..drawLine(c.translate(-.07, .095), c.translate(.09, .095), _s(_ink, .03))
          ..drawRRect(_rr(Rect.fromCenter(center: c.translate(.05, .18), width: .09, height: .15), .045), _f(const Color(0xFFF06292)))
          ..drawLine(c.translate(.05, .12), c.translate(.05, .18), _s(const Color(0xFFC2185B), .015));
      case 10: // robot visor with a scanning light
        canvas.drawRRect(_rr(Rect.fromCenter(center: c.translate(0, -.02), width: .46, height: .17), .06), _f(const Color(0xFF102027)));
        final scan = sin(t * 3.2) * .15;
        for (final e in [l, r]) {
          canvas.drawRRect(_rr(Rect.fromCenter(center: e.translate(0, 0), width: .1, height: .045), .02), _f(const Color(0xFF00BCD4)));
        }
        canvas.drawRRect(_rr(Rect.fromCenter(center: c.translate(scan, -.02), width: .05, height: .1), .02), _f(const Color(0x9900E5FF)));
      case 11: // cyclops
        canvas
          ..drawCircle(c.translate(0, -.02) + look, .105, _s(_ink, .035))
          ..drawCircle(c.translate(0, -.02) + look * 1.4, .06, _f(_ink))
          ..drawCircle(c.translate(-.02, -.045) + look, .02, _f(const Color(0xFFFFFFFF)));
      default:
        canvas
          ..drawCircle(l, .045, dot)
          ..drawCircle(r, .045, dot);
    }
  }
}
