import 'dart:math';
import 'dart:ui';

/// Fixed-size particle pool (no allocation while playing).
class ParticleSystem {
  /// Creates a pool of [capacity] particles.
  ParticleSystem({this.capacity = 320})
      : _x = List.filled(capacity, 0),
        _y = List.filled(capacity, 0),
        _vx = List.filled(capacity, 0),
        _vy = List.filled(capacity, 0),
        _life = List.filled(capacity, 0),
        _maxLife = List.filled(capacity, 1),
        _size = List.filled(capacity, 0),
        _color = List.filled(capacity, 0);

  /// Pool size.
  final int capacity;
  final List<double> _x, _y, _vx, _vy, _life, _maxLife, _size;
  final List<int> _color;
  final Random _rng = Random();
  int _next = 0;
  final Paint _paint = Paint();

  /// Number of live particles.
  int get alive => _life.where((l) => l > 0).length;

  /// Emits [n] particles around ([x],[y]) (cell units).
  void burst(double x, double y, int n, List<Color> colors,
      {double speed = 2.5, double life = 0.6, double size = 0.08}) {
    for (var i = 0; i < n; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final s = speed * (0.3 + _rng.nextDouble());
      final k = _next;
      _next = (_next + 1) % capacity;
      _x[k] = x;
      _y[k] = y;
      _vx[k] = cos(a) * s;
      _vy[k] = sin(a) * s;
      _maxLife[k] = life * (0.6 + _rng.nextDouble() * 0.6);
      _life[k] = _maxLife[k];
      _size[k] = size * (0.6 + _rng.nextDouble() * 0.8);
      _color[k] = colors[_rng.nextInt(colors.length)].toARGB32();
    }
  }

  /// Advances all particles by [dt] seconds.
  void update(double dt) {
    for (var i = 0; i < capacity; i++) {
      if (_life[i] <= 0) continue;
      _life[i] -= dt;
      _x[i] += _vx[i] * dt;
      _y[i] += _vy[i] * dt;
      _vy[i] += 4 * dt;
      _vx[i] *= 1 - 2 * dt;
    }
  }

  /// Draws all particles in cell space.
  void paint(Canvas canvas) {
    for (var i = 0; i < capacity; i++) {
      if (_life[i] <= 0) continue;
      final t = (_life[i] / _maxLife[i]).clamp(0.0, 1.0);
      _paint.color = Color(_color[i]).withValues(alpha: t);
      canvas.drawCircle(Offset(_x[i], _y[i]), _size[i] * (0.4 + t), _paint);
    }
  }
}
