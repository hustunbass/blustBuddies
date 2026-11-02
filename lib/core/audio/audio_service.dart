import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays sound effects, music and haptics according to [AppSettings].
///
/// All platform calls are guarded: a missing plugin (tests) or missing file
/// never crashes the game.
class AudioService {
  /// Creates the service.
  AudioService(this._ref);

  final Ref _ref;

  static const _files = [
    'place.wav',
    'explosion.wav',
    'pickup.wav',
    'hit.wav',
    'win.wav',
    'lose.wav',
    'music.wav',
  ];

  AppSettings get _s => _ref.read(settingsProvider);

  /// Preloads audio files.
  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(_files);
    } catch (e) {
      debugPrint('Audio preload skipped: $e');
    }
  }

  Future<void> _sfx(String file, [double volume = 1]) async {
    if (!_s.sound) return;
    try {
      await FlameAudio.play(file, volume: volume);
    } catch (e) {
      debugPrint('SFX failed: $e');
    }
  }

  /// Starts looping background music (if enabled).
  Future<void> startMusic() async {
    if (!_s.music) return;
    try {
      await FlameAudio.bgm.play('music.wav', volume: 0.35);
    } catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  /// Stops background music.
  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  /// Pauses background music.
  Future<void> pauseMusic() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (_) {}
  }

  /// Resumes background music.
  Future<void> resumeMusic() async {
    if (!_s.music) return;
    try {
      await FlameAudio.bgm.resume();
    } catch (_) {}
  }

  /// Light haptic tap.
  void tap() {
    if (_s.vibration) HapticFeedback.selectionClick();
  }

  /// Reacts to a gameplay event with sound and vibration.
  void onGameEvent(GameEvent e) {
    switch (e.type) {
      case GameEventType.bombPlaced:
        _sfx('place.wav', 0.6);
      case GameEventType.explosion:
        _sfx('explosion.wav');
        if (_s.vibration) HapticFeedback.mediumImpact();
      case GameEventType.powerUp:
        _sfx('pickup.wav');
      case GameEventType.playerHit:
        _sfx('hit.wav');
        if (_s.vibration) HapticFeedback.heavyImpact();
      case GameEventType.levelComplete:
        _sfx('win.wav');
      case GameEventType.gameOver:
        _sfx('lose.wav');
      default:
        break;
    }
  }
}

/// Audio provider.
final audioProvider = Provider<AudioService>(AudioService.new);
