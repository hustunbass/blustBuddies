import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Must be overridden at startup with the loaded instance.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);

/// User-adjustable options.
class AppSettings {
  /// Creates settings.
  const AppSettings({
    this.sound = true,
    this.music = true,
    this.vibration = true,
    this.controlScale = 1.0,
  });

  /// Sound effects on.
  final bool sound;

  /// Music on.
  final bool music;

  /// Haptics on.
  final bool vibration;

  /// On-screen control scale (0.7 – 1.4).
  final double controlScale;

  /// Copy with changes.
  AppSettings copyWith({
    bool? sound,
    bool? music,
    bool? vibration,
    double? controlScale,
  }) =>
      AppSettings(
        sound: sound ?? this.sound,
        music: music ?? this.music,
        vibration: vibration ?? this.vibration,
        controlScale: controlScale ?? this.controlScale,
      );
}

/// Persists [AppSettings] in shared_preferences.
class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final p = ref.watch(prefsProvider);
    return AppSettings(
      sound: p.getBool('sound') ?? true,
      music: p.getBool('music') ?? true,
      vibration: p.getBool('vibration') ?? true,
      controlScale: (p.getDouble('controlScale') ?? 1.0).clamp(0.7, 1.4),
    );
  }

  /// Updates and saves settings.
  Future<void> update(AppSettings s) async {
    state = s;
    final p = ref.read(prefsProvider);
    await p.setBool('sound', s.sound);
    await p.setBool('music', s.music);
    await p.setBool('vibration', s.vibration);
    await p.setDouble('controlScale', s.controlScale);
  }
}

/// Settings provider.
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Story progress.
class Progress {
  /// Creates progress.
  const Progress({this.unlockedLevel = 1, this.bestScore = 0});

  /// Highest level the player may start (1-based).
  final int unlockedLevel;

  /// Best total score of a story run.
  final int bestScore;
}

/// Persists story progress.
class ProgressNotifier extends Notifier<Progress> {
  @override
  Progress build() {
    final p = ref.watch(prefsProvider);
    return Progress(
      unlockedLevel: p.getInt('unlocked') ?? 1,
      bestScore: p.getInt('best') ?? 0,
    );
  }

  /// Unlocks [level] if it is further than the current progress.
  Future<void> unlock(int level) async {
    if (level <= state.unlockedLevel) return;
    state = Progress(unlockedLevel: level, bestScore: state.bestScore);
    await ref.read(prefsProvider).setInt('unlocked', level);
  }

  /// Records a score if it is a new best.
  Future<void> submitScore(int score) async {
    if (score <= state.bestScore) return;
    state = Progress(unlockedLevel: state.unlockedLevel, bestScore: score);
    await ref.read(prefsProvider).setInt('best', score);
  }
}

/// Progress provider.
final progressProvider =
    NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);
