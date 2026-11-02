import 'package:blast_buddies/core/audio/audio_service.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/features/game/ui/game_stage.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
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
    _game ??= BlastGame(
      sim: widget.args.buildWorld(),
      humans: widget.args.humans,
      onEvent: _audio.onGameEvent,
      onFinished: _onFinished,
      reducedMotion: MediaQuery.of(context).disableAnimations,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audio.stopMusic();
    _overlay.dispose();
    super.dispose();
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
    if (!_battle) {
      final p = w.players.first;
      ref.read(progressProvider.notifier).submitScore(p.score);
      if (status == WorldStatus.levelComplete) {
        ref.read(progressProvider.notifier).unlock(widget.args.level + 1);
      }
    }
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
        actions: [
          if (more) FilledButton(onPressed: _next, child: Text(l.nextLevel)),
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
