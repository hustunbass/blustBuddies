import 'package:blast_buddies/core/audio/audio_service.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/features/game/ui/game_stage.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Overlay { none, menu, finished }

/// Plays an [OnlineMatch]: input goes to the server, the world mirrors it.
/// The match cannot be paused; the menu only offers to leave.
class OnlineGameView extends ConsumerStatefulWidget {
  /// Creates the view.
  const OnlineGameView({super.key, required this.client, required this.match});

  /// Connection.
  final OnlineClient client;

  /// Match to show.
  final OnlineMatch match;

  @override
  ConsumerState<OnlineGameView> createState() => _OnlineGameViewState();
}

class _OnlineGameViewState extends ConsumerState<OnlineGameView> {
  BlastGame? _game;
  late final AudioService _audio;
  final ValueNotifier<_Overlay> _overlay = ValueNotifier(_Overlay.none);

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioProvider);
    _audio.startMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= BlastGame(
      sim: widget.match.world,
      humans: 1,
      remote: widget.match,
      onEvent: _audio.onGameEvent,
      onFinished: (_) => Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        _audio.stopMusic();
        _overlay.value = _Overlay.finished;
      }),
      reducedMotion: MediaQuery.of(context).disableAnimations,
    );
  }

  @override
  void dispose() {
    _audio.stopMusic();
    _overlay.dispose();
    super.dispose();
  }

  String _resultTitle(AppLocalizations l) {
    final w = widget.match.world;
    final team = w.winnerTeam;
    if (team == null) return l.draw;
    if (w.teams) return l.teamWins(team + 1);
    return l.nameWins(widget.match.names[w.winnerId!]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final game = _game!;
    final match = widget.match;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _overlay.value == _Overlay.none) _overlay.value = _Overlay.menu;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              GameStage(
                game: game,
                battle: true,
                names: match.names,
                teams: match.world.teams,
                onPause: () => _overlay.value = _Overlay.menu,
              ),
              ValueListenableBuilder<_Overlay>(
                valueListenable: _overlay,
                builder: (_, o, _) {
                  if (match.disconnected) {
                    return ResultPanel(
                      title: l.connectionLost,
                      actions: [FilledButton(onPressed: widget.client.closeMatch, child: Text(l.back))],
                    );
                  }
                  return switch (o) {
                    _Overlay.none => const SizedBox.shrink(),
                    _Overlay.menu => ResultPanel(
                        title: l.leaveMatchQuestion,
                        actions: [
                          FilledButton(
                            onPressed: () => _overlay.value = _Overlay.none,
                            child: Text(l.resume),
                          ),
                          FilledButton.tonal(onPressed: widget.client.leaveRoom, child: Text(l.leaveMatch)),
                        ],
                      ),
                    _Overlay.finished => ResultPanel(
                        title: _resultTitle(l),
                        actions: [
                          FilledButton(onPressed: widget.client.closeMatch, child: Text(l.backToRoom)),
                          FilledButton.tonal(onPressed: widget.client.leaveRoom, child: Text(l.leaveRoom)),
                        ],
                      ),
                  };
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
