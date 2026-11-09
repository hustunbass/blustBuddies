import 'dart:math';
import 'dart:ui';

/// Where the player moved the joystick and the bomb button, as fractions of
/// the control area relative to their default spots (positive = right/down).
/// Portrait and landscape keep separate layouts.
class ControlLayout {
  /// Creates a layout; all zeros is the default placement.
  const ControlLayout({this.stickDx = 0, this.stickDy = 0, this.buttonsDx = 0, this.buttonsDy = 0});

  /// Joystick offset.
  final double stickDx, stickDy;

  /// Bomb-button cluster offset.
  final double buttonsDx, buttonsDy;

  /// Nothing was moved.
  bool get isDefault => stickDx == 0 && stickDy == 0 && buttonsDx == 0 && buttonsDy == 0;

  /// Copy with changes.
  ControlLayout copyWith({double? stickDx, double? stickDy, double? buttonsDx, double? buttonsDy}) => ControlLayout(
        stickDx: stickDx ?? this.stickDx,
        stickDy: stickDy ?? this.stickDy,
        buttonsDx: buttonsDx ?? this.buttonsDx,
        buttonsDy: buttonsDy ?? this.buttonsDy,
      );

  /// The same arrangement for the other hand (left/right swapped).
  ControlLayout mirrored() =>
      ControlLayout(stickDx: -stickDx, stickDy: stickDy, buttonsDx: -buttonsDx, buttonsDy: buttonsDy);

  /// Compact text form for shared preferences.
  String encode() => '$stickDx,$stickDy,$buttonsDx,$buttonsDy';

  /// Parses [encode] output; anything unreadable gives the default layout.
  static ControlLayout decode(String? s) {
    final p = s?.split(',').map(double.tryParse).toList();
    if (p == null || p.length != 4 || p.any((v) => v == null || !v.isFinite)) return const ControlLayout();
    double f(int i) => p[i]!.clamp(-1.0, 1.0);
    return ControlLayout(stickDx: f(0), stickDy: f(1), buttonsDx: f(2), buttonsDy: f(3));
  }

  @override
  bool operator ==(Object other) => other is ControlLayout && other.encode() == encode();

  @override
  int get hashCode => encode().hashCode;
}

/// Turns a [ControlLayout] into screen rectangles, shared by the game and the
/// editor so both always agree.
class ControlGeometry {
  ControlGeometry._();

  /// Gap to the screen side in the default layout.
  static const double sideMargin = 24;

  /// Gap to the bottom in the default layout.
  static const double bottomMargin = 12;

  /// Controls never get closer than this to any edge.
  static const double edge = 4;

  static Rect _clamp(Rect r, Size area) => Rect.fromLTWH(
        r.left.clamp(edge, max(edge, area.width - r.width - edge)),
        r.top.clamp(edge, max(edge, area.height - r.height - edge)),
        r.width,
        r.height,
      );

  /// Default joystick rectangle: bottom corner opposite the buttons.
  static Rect defaultStick(Size area, double size, {required bool leftHanded}) => Rect.fromLTWH(
        leftHanded ? area.width - sideMargin - size : sideMargin,
        area.height - bottomMargin - size,
        size,
        size,
      );

  /// Default bomb-button rectangle: bottom corner on the dominant-hand side.
  static Rect defaultBomb(Size area, double size, {required bool leftHanded}) => Rect.fromLTWH(
        leftHanded ? sideMargin : area.width - sideMargin - size,
        area.height - bottomMargin - size,
        size,
        size,
      );

  /// Joystick rectangle for [layout].
  static Rect stick(Size area, double size, {required bool leftHanded, required ControlLayout layout}) =>
      _clamp(
        defaultStick(area, size, leftHanded: leftHanded)
            .shift(Offset(layout.stickDx * area.width, layout.stickDy * area.height)),
        area,
      );

  /// Bomb-button rectangle for [layout].
  static Rect bomb(Size area, double size, {required bool leftHanded, required ControlLayout layout}) =>
      _clamp(
        defaultBomb(area, size, leftHanded: leftHanded)
            .shift(Offset(layout.buttonsDx * area.width, layout.buttonsDy * area.height)),
        area,
      );

  /// The layout that puts the joystick at [rect] (clamped inside [area]).
  static ControlLayout withStickAt(
    ControlLayout base,
    Size area,
    double size,
    Rect rect, {
    required bool leftHanded,
  }) {
    final r = _clamp(rect, area);
    final d = defaultStick(area, size, leftHanded: leftHanded);
    return base.copyWith(stickDx: (r.left - d.left) / area.width, stickDy: (r.top - d.top) / area.height);
  }

  /// The layout that puts the bomb button at [rect] (clamped inside [area]).
  static ControlLayout withBombAt(
    ControlLayout base,
    Size area,
    double size,
    Rect rect, {
    required bool leftHanded,
  }) {
    final r = _clamp(rect, area);
    final d = defaultBomb(area, size, leftHanded: leftHanded);
    return base.copyWith(buttonsDx: (r.left - d.left) / area.width, buttonsDy: (r.top - d.top) / area.height);
  }
}
