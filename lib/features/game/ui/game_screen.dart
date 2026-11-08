import 'dart:async';

import 'package:blast_buddies/core/audio/audio_service.dart';
import 'package:blast_buddies/core/cosmetics.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/features/game/ui/game_stage.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/l10n/names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _Overlay { none, paused, finished }

/// The playable screen: HUD, Flame canvas, touch controls and overlays.
class GameScreen extends ConsumerStatefulWidget {
  /// Creates the screen for [args].
  const GameScreen({super.key, required this.args});

  /// What to play.
  final GameArgs args;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  BlastGame? _game;
  late final AudioService _audio;
  final ValueNotifier<_Overlay> _overlay = ValueNotifier(_Overlay.none);
  WorldStatus _result = WorldStatus.playing;
  int _stars = 0;
  final Map<String, int> _delta = {};

  bool get _battle => widget.args.mode == GameMode.battle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio = ref.read(audioProvider);
    _audio.startMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    final l = AppLocalizations.of(context);
    final st = ref.read(settingsProvider);
    final game = BlastGame(
      sim: widget.args.buildWorld(skin: Cosmetics.skin(st.hat, st.face, st.color)),
      humans: widget.args.humans,
      onEvent: _onEvent,
      onFinished: _onFinished,
      reducedMotion: MediaQuery.of(context).disableAnimations,
    );
    final w = game.sim;
    final map = Names.map(l, w.themeId);
    if (_battle) {
      game.painter.title = widget.args.daily ? l.dailyArena : map;
      game.painter.subtitle = widget.args.daily ? map : null;
    } else {
      final lv = widget.args.level;
      game.painter.title = LevelConfig.isBossLevel(lv) ? '${l.levelStart(lv)} · ${l.bossLevel}' : l.levelStart(lv);
      game.painter.subtitle = lv % 10 == 1 ? '${l.worldN((lv - 1) ~/ 10 + 1)} · $map\n${Names.story(l, (lv - 1) ~/ 10)}' : map;
    }
    _game = game;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audio.stopMusic();
    if (_delta.isNotEmpty) {
      // Keep counters of an abandoned run (no toast, the screen is gone).
      final stats = ref.read(statsProvider.notifier);
      unawaited(stats.add(Map.of(_delta)));
    }
    _overlay.dispose();
    super.dispose();
  }

  void _onEvent(GameEvent e) {
    _audio.onGameEvent(e);
    switch (e.type) {
      case GameEventType.bombPlaced when e.id == 0:
        _bump('bombs');
      case GameEventType.blockDestroyed when e.id == 0:
        _bump('blocks');
      case GameEventType.enemyKilled when e.id == 0:
        _bump('kills');
      case GameEventType.powerUp when !_battle:
        _bump('powerups');
      default:
        break;
    }
  }

  void _bump(String k, [int n = 1]) => _delta[k] = (_delta[k] ?? 0) + n;

  /// Saves counters and shows a toast for each newly earned achievement.
  Future<void> _flushStats() async {
    if (_delta.isEmpty) return;
    final delta = Map<String, int>.of(_delta);
    _delta.clear();
    final fresh = await ref.read(statsProvider.notifier).add(delta);
    if (!mounted || fresh.isEmpty) return;
    final l = AppLocalizations.of(context);
    final m = ScaffoldMessenger.of(context);
    for (final a in fresh) {
      m.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.emoji_events, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(l.achievementUnlocked(Names.achievement(l, a.id)))),
        ]),
      ));
    }
  }

  void _pause() {
    if (_overlay.value != _Overlay.none) return;
    _game!.pauseEngine();
    _audio.pauseMusic();
    _overlay.value = _Overlay.paused;
  }

  void _resume() {
    _overlay.value = _Overlay.none;
    _game!.resumeEngine();
    _audio.resumeMusic();
  }

  void _onFinished(WorldStatus status) {
    final w = _game!.sim;
    _bump('games');
    if (!_battle) {
      final p = w.players.first;
      ref.read(progressProvider.notifier).submitScore(p.score);
      if (status == WorldStatus.levelComplete) {
        final lv = widget.args.level;
        final cfg = LevelConfig.forLevel(lv);
        _stars = 1 + (w.hits == 0 ? 1 : 0) + (w.timeLeft >= cfg.timeLimit * 0.4 ? 1 : 0);
        ref.read(progressProvider.notifier)
          ..unlock(lv + 1)
          ..recordStars(lv, _stars);
        _bump('levels');
        if (LevelConfig.isBossLevel(lv)) _bump('bosses');
      }
    } else if (w.winnerTeam != null && w.winnerTeam == w.players.first.teamId && widget.args.bots > 0) {
      _bump('wins');
    }
    _flushStats();
    // Let the final explosion/death animation play before the dialog.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _result = status;
      _audio.stopMusic();
      _overlay.value = _Overlay.finished;
    });
  }

  void _restart() => context.pushReplacement(
        '/game',
        extra: widget.args.mode == GameMode.story
            ? GameArgs.story(level: widget.args.level)
            : GameArgs.battle(
                humans: widget.args.humans,
                bots: widget.args.bots,
                teams: widget.args.teams,
                botLevel: widget.args.botLevel,
                daily: widget.args.daily,
              ),
      );

  void _next() => context.pushReplacement(
        '/game',
        extra: GameArgs.story(level: widget.args.level + 1, carry: _game!.sim.players.first),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final game = _game!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause();
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              GameStage(
                game: game,
                battle: _battle,
                onPause: _pause,
                teams: game.sim.teams,
              ),
              ValueListenableBuilder<_Overlay>(
                valueListenable: _overlay,
                builder: (_, o, _) => switch (o) {
                  _Overlay.none => const SizedBox.shrink(),
                  _Overlay.paused => ResultPanel(
                      title: l.paused,
                      actions: [
                        FilledButton(onPressed: _resume, child: Text(l.resume)),
                        FilledButton.tonal(onPressed: _restart, child: Text(l.restart)),
                        FilledButton.tonal(onPressed: () => context.go('/'), child: Text(l.mainMenu)),
                      ],
                    ),
                  _Overlay.finished => _buildResult(l, game),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(AppLocalizations l, BlastGame game) {
    final w = game.sim;
    final menu = FilledButton.tonal(onPressed: () => context.go('/'), child: Text(l.mainMenu));
    if (_battle) {
      return ResultPanel(
        title: w.winnerTeam == null
            ? l.draw
            : w.teams
                ? l.teamWins(w.winnerTeam! + 1)
                : l.playerWins(w.winnerId! + 1),
        actions: [FilledButton(onPressed: _restart, child: Text(l.playAgain)), menu],
      );
    }
    final score = l.finalScore(w.players.first.score);
    if (_result == WorldStatus.levelComplete) {
      final more = widget.args.hasNextLevel;
      return ResultPanel(
        title: more ? l.levelComplete : l.allLevelsDone,
        subtitle: score,
        header: Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < 3; i++)
            Icon(i < _stars ? Icons.star : Icons.star_border,
                size: 48, color: i < _stars ? Colors.amber : Colors.white38),
        ]),
        actions: [
          if (more) FilledButton(onPressed: _next, child: Text(l.nextLevel)),
          FilledButton.tonal(onPressed: _restart, child: Text(l.restart)),
          menu,
        ],
      );
    }
    return ResultPanel(
      title: l.gameOver,
      subtitle: score,
      actions: [FilledButton(onPressed: _restart, child: Text(l.tryAgain)), menu],
    );
  }
}
