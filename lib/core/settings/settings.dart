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
    this.hat = 0,
    this.face = 0,
    this.color = 0,
    this.floatingStick = true,
    this.leftHanded = false,
    this.botLevel = 1,
  });

  /// Sound effects on.
  final bool sound;

  /// Music on.
  final bool music;

  /// Haptics on.
  final bool vibration;

  /// On-screen control scale (0.7 – 1.4).
  final double controlScale;

  /// Selected hat / face / body colour (indices into `Cosmetics`).
  final int hat, face, color;

  /// Joystick appears where the thumb touches down.
  final bool floatingStick;

  /// Joystick on the right, buttons on the left.
  final bool leftHanded;

  /// Default bot difficulty (index into `BotLevel`).
  final int botLevel;

  /// Copy with changes.
  AppSettings copyWith({
    bool? sound,
    bool? music,
    bool? vibration,
    double? controlScale,
    int? hat,
    int? face,
    int? color,
    bool? floatingStick,
    bool? leftHanded,
    int? botLevel,
  }) =>
      AppSettings(
        sound: sound ?? this.sound,
        music: music ?? this.music,
        vibration: vibration ?? this.vibration,
        controlScale: controlScale ?? this.controlScale,
        hat: hat ?? this.hat,
        face: face ?? this.face,
        color: color ?? this.color,
        floatingStick: floatingStick ?? this.floatingStick,
        leftHanded: leftHanded ?? this.leftHanded,
        botLevel: botLevel ?? this.botLevel,
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
      hat: p.getInt('hat') ?? 0,
      face: p.getInt('face') ?? 0,
      color: p.getInt('color') ?? 0,
      floatingStick: p.getBool('floatingStick') ?? true,
      leftHanded: p.getBool('leftHanded') ?? false,
      botLevel: (p.getInt('botLevel') ?? 1).clamp(0, 2),
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
    await p.setInt('hat', s.hat);
    await p.setInt('face', s.face);
    await p.setInt('color', s.color);
    await p.setBool('floatingStick', s.floatingStick);
    await p.setBool('leftHanded', s.leftHanded);
    await p.setInt('botLevel', s.botLevel);
  }
}

/// Settings provider.
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Story progress.
class Progress {
  /// Creates progress.
  const Progress({this.unlockedLevel = 1, this.bestScore = 0, this.stars = const {}});

  /// Highest level the player may start (1-based).
  final int unlockedLevel;

  /// Best total score of a story run.
  final int bestScore;

  /// Best star rating (1-3) per cleared level.
  final Map<int, int> stars;

  /// Stars collected over all levels.
  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  /// Levels cleared with three stars.
  int get perfectLevels => stars.values.where((s) => s >= 3).length;

  /// Stars earned in levels [from]..[to] (inclusive).
  int starsIn(int from, int to) {
    var n = 0;
    for (var l = from; l <= to; l++) {
      n += stars[l] ?? 0;
    }
    return n;
  }

  /// Copy with changes.
  Progress copyWith({int? unlockedLevel, int? bestScore, Map<int, int>? stars}) => Progress(
        unlockedLevel: unlockedLevel ?? this.unlockedLevel,
        bestScore: bestScore ?? this.bestScore,
        stars: stars ?? this.stars,
      );
}

/// Persists story progress.
class ProgressNotifier extends Notifier<Progress> {
  @override
  Progress build() {
    final p = ref.watch(prefsProvider);
    final stars = <int, int>{};
    for (final part in (p.getString('stars') ?? '').split(',')) {
      final kv = part.split(':');
      if (kv.length == 2) {
        final l = int.tryParse(kv[0]), s = int.tryParse(kv[1]);
        if (l != null && s != null) stars[l] = s.clamp(0, 3);
      }
    }
    return Progress(
      unlockedLevel: p.getInt('unlocked') ?? 1,
      bestScore: p.getInt('best') ?? 0,
      stars: stars,
    );
  }

  /// Unlocks [level] if it is further than the current progress.
  Future<void> unlock(int level) async {
    if (level <= state.unlockedLevel) return;
    state = state.copyWith(unlockedLevel: level);
    await ref.read(prefsProvider).setInt('unlocked', level);
  }

  /// Records a score if it is a new best.
  Future<void> submitScore(int score) async {
    if (score <= state.bestScore) return;
    state = state.copyWith(bestScore: score);
    await ref.read(prefsProvider).setInt('best', score);
  }

  /// Keeps the best star rating of [level].
  Future<void> recordStars(int level, int stars) async {
    if (stars <= (state.stars[level] ?? 0)) return;
    final next = {...state.stars, level: stars.clamp(1, 3)};
    state = state.copyWith(stars: next);
    await ref.read(prefsProvider).setString(
          'stars',
          next.entries.map((e) => '${e.key}:${e.value}').join(','),
        );
  }
}

/// Progress provider.
final progressProvider =
    NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);
