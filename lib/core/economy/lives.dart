import 'package:blast_buddies/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Story lives: up to [LivesNotifier.maxLives], one regenerates every
/// [LivesNotifier.regen].
class LivesData {
  /// Creates lives data. [nextAtMs] is when the next life arrives (epoch ms),
  /// only meaningful while below the maximum.
  const LivesData({required this.lives, this.nextAtMs = 0});

  /// Lives available now.
  final int lives;

  /// Epoch milliseconds of the next regenerated life.
  final int nextAtMs;

  /// Whether the player is at the cap.
  bool get full => lives >= LivesNotifier.maxLives;

  /// Time until the next life, or null at the cap.
  Duration? untilNext(DateTime now) {
    if (full) return null;
    final ms = nextAtMs - now.millisecondsSinceEpoch;
    return Duration(milliseconds: ms < 0 ? 0 : ms);
  }
}

/// Persists and regenerates story lives.
class LivesNotifier extends Notifier<LivesData> {
  /// Life cap.
  static const maxLives = 5;

  /// Time to regenerate one life.
  static const regen = Duration(minutes: 30);

  /// Price of one life in coins.
  static const coinPrice = 60;

  /// Clock used for regeneration (overridable in tests).
  DateTime Function() now = DateTime.now;

  @override
  LivesData build() {
    final p = ref.watch(prefsProvider);
    final data = LivesData(
      lives: (p.getInt('lives') ?? maxLives).clamp(0, maxLives),
      nextAtMs: p.getInt('livesNext') ?? 0,
    );
    return _regenerated(data);
  }

  LivesData _regenerated(LivesData d) {
    if (d.full) return LivesData(lives: maxLives);
    final nowMs = now().millisecondsSinceEpoch;
    final step = regen.inMilliseconds;
    var lives = d.lives;
    var next = d.nextAtMs;
    // Guard against the device clock being set back: never wait longer than
    // one full regeneration period.
    if (next == 0 || next - nowMs > step) next = nowMs + step;
    while (lives < maxLives && nowMs >= next) {
      lives++;
      next += step;
    }
    return LivesData(lives: lives, nextAtMs: lives >= maxLives ? 0 : next);
  }

  Future<void> _save(LivesData d) async {
    state = d;
    final p = ref.read(prefsProvider);
    await p.setInt('lives', d.lives);
    await p.setInt('livesNext', d.nextAtMs);
  }

  /// Applies regeneration for the time that passed.
  void refresh() {
    final next = _regenerated(state);
    if (next.lives != state.lives || next.nextAtMs != state.nextAtMs) {
      _save(next);
    }
  }

  /// Uses one life; returns false if none is left.
  Future<bool> consume() async {
    refresh();
    if (state.lives <= 0) return false;
    final lives = state.lives - 1;
    final next = state.full
        ? now().millisecondsSinceEpoch + regen.inMilliseconds
        : state.nextAtMs;
    await _save(LivesData(lives: lives, nextAtMs: next));
    return true;
  }

  /// Gives [n] lives back (ads, purchases, refunds), capped at the maximum.
  Future<void> add([int n = 1]) async {
    refresh();
    final lives = (state.lives + n).clamp(0, maxLives);
    await _save(
      LivesData(lives: lives, nextAtMs: lives >= maxLives ? 0 : state.nextAtMs),
    );
  }
}

/// Lives provider.
final livesProvider = NotifierProvider<LivesNotifier, LivesData>(
  LivesNotifier.new,
);
