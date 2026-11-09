import 'package:blast_buddies/core/audio/audio_service.dart';
import 'package:blast_buddies/core/cosmetics.dart';
import 'package:blast_buddies/core/onboarding.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/features/game/ui/game_stage.dart';
import 'package:blast_buddies/features/shop/economy_widgets.dart';
import 'package:blast_buddies/features/tutorial/tutorial_flow.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A short guided first game: walk, drop a bomb, run, grab a power-up and beat
/// an enemy. Every lesson ends when the player actually does the thing.
class TutorialScreen extends ConsumerStatefulWidget {
  /// Creates the screen.
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> with SingleTickerProviderStateMixin {
  late final TutorialFlow _flow;
  BlastGame? _game;
  late final Ticker _ticker;
  TutorialStep _shown = TutorialStep.move;
  bool _tooFar = false;
  bool _finishing = false;

  /// Coins paid for finishing (0 on a replay).
  int _reward = 0;

  @override
  void initState() {
    super.initState();
    final st = ref.read(settingsProvider);
    _flow = TutorialFlow(skin: Cosmetics.skin(st.hat, st.face, st.color));
    _ticker = createTicker((_) => _tick())..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game ??= BlastGame(
      sim: _flow.world,
      humans: 1,
      onEvent: (e) {
        ref.read(audioProvider).onGameEvent(e);
        _flow.handle(e);
      },
      onFinished: (_) {},
      reducedMotion: MediaQuery.of(context).disableAnimations,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    _flow.update();
    _game?.painter.markerCell = _flow.marker;
    if (_flow.step != _shown || _flow.tooFar != _tooFar) {
      setState(() {
        _shown = _flow.step;
        _tooFar = _flow.tooFar;
      });
    }
    if (_flow.step == TutorialStep.done && !_finishing) {
      _finishing = true;
      _finish();
    }
  }

  Future<void> _finish() async {
    final coins = await ref.read(onboardingProvider.notifier).complete();
    if (mounted) setState(() => _reward = coins);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _skip() async {
    await ref.read(onboardingProvider.notifier).skip();
    if (mounted) _leave();
  }

  void _startStory() {
    final router = GoRouter.of(context);
    router
      ..go('/')
      ..push('/levels');
  }

  @override
  Widget build(BuildContext context) {
    final game = _game!;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          _CoachPanel(
            step: _shown,
            tooFar: _tooFar,
            reward: _reward,
            onSkip: _skip,
            onStartStory: _startStory,
            onMenu: _leave,
          ),
          Expanded(child: GameStage(game: game, battle: false, onPause: () {}, showHud: false)),
        ]),
      ),
    );
  }
}

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({
    required this.step,
    required this.tooFar,
    required this.reward,
    required this.onSkip,
    required this.onStartStory,
    required this.onMenu,
  });

  final TutorialStep step;
  final bool tooFar;
  final int reward;
  final VoidCallback onSkip;
  final VoidCallback onStartStory;
  final VoidCallback onMenu;

  (String, String) _text(AppLocalizations l) => switch (step) {
        TutorialStep.move => (l.tutTitle0, l.tutBody0),
        TutorialStep.bomb => (l.tutTitle1, tooFar ? l.tutTooFar : l.tutBody1),
        TutorialStep.escape => (l.tutTitle2, l.tutBody2),
        TutorialStep.powerUp => (l.tutTitle3, l.tutBody3),
        TutorialStep.enemy => (l.tutTitle4, l.tutBody4),
        TutorialStep.done => (l.tutTitle5, l.tutBody5),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (title, body) = _text(l);
    final done = step == TutorialStep.done;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: BuddyColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BuddyColors.gold.withValues(alpha: done ? .8 : .35), width: done ? 2 : 1),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            for (var i = 0; i < TutorialFlow.lessons; i++)
              Container(
                width: i == step.index ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i < step.index || done
                      ? BuddyColors.gold
                      : (i == step.index ? Colors.white : Colors.white24),
                ),
              ),
            const Spacer(),
            if (!done) TextButton(onPressed: onSkip, child: Text(l.tutSkip)),
          ]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(
                liveRegion: true,
                child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: BuddyColors.gold)),
              ),
              const SizedBox(height: 2),
              Text(body, style: const TextStyle(fontSize: 14.5, height: 1.3, color: Colors.white)),
              if (done) ...[
                if (reward > 0) ...[
                  const SizedBox(height: 10),
                  Row(children: [
                    const CoinIcon(size: 22),
                    const SizedBox(width: 6),
                    Text(l.rewardGot(reward),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: BuddyColors.gold)),
                  ]),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onStartStory,
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                      child: Text(l.tutDoneStart),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(onPressed: onMenu, child: Text(l.mainMenu)),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}
