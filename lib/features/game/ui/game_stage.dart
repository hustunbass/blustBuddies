import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/features/game/ui/controls.dart';
import 'package:blast_buddies/features/game/ui/game_hud.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// HUD + Flame view + touch controls, laid out for portrait or landscape.
class GameStage extends ConsumerWidget {
  /// Creates the stage for [game].
  const GameStage({
    super.key,
    required this.game,
    required this.battle,
    required this.onPause,
    this.names,
    this.teams = false,
  });

  /// Running game.
  final BlastGame game;

  /// Battle HUD layout.
  final bool battle;

  /// Pause / menu button.
  final VoidCallback onPause;

  /// Player names for the battle HUD (online).
  final List<String>? names;

  /// Show team colours in the battle HUD.
  final bool teams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scale = ref.watch(settingsProvider.select((s) => s.controlScale));
    return LayoutBuilder(builder: (context, c) {
      final portrait = c.maxHeight > c.maxWidth;
      final hud = ValueListenableBuilder<HudState>(
        valueListenable: game.hud,
        builder: (_, s, _) =>
            GameHud(state: s, battle: battle, onPause: onPause, names: names, teams: teams),
      );
      final joystick = VirtualJoystick(
        size: scaled(140, scale),
        semanticLabel: l.joystick,
        onChanged: (d) => game.touchDir = d,
      );
      final bomb = BombButton(
        size: scaled(96, scale),
        semanticLabel: l.bombButton,
        onPressed: game.touchBomb,
      );
      final view = GameWidget<BlastGame>(game: game);
      if (portrait) {
        return Column(children: [
          hud,
          Flexible(child: AspectRatio(aspectRatio: 13 / 11, child: view)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [joystick, bomb],
              ),
            ),
          ),
        ]);
      }
      return Column(children: [
        hud,
        Expanded(
          child: Stack(children: [
            Positioned.fill(child: view),
            Positioned(left: 24, bottom: 12, child: joystick),
            Positioned(right: 24, bottom: 12, child: bomb),
          ]),
        ),
      ]);
    });
  }
}

/// Full-screen dimmed panel with a title and action buttons.
class ResultPanel extends StatelessWidget {
  /// Creates a panel.
  const ResultPanel({super.key, required this.title, required this.actions, this.subtitle});

  /// Headline.
  final String title;

  /// Optional second line.
  final String? subtitle;

  /// Buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(subtitle!, style: const TextStyle(fontSize: 22, color: Colors.amber)),
                  ),
                const SizedBox(height: 20),
                for (final a in actions) Padding(padding: const EdgeInsets.all(6), child: a),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
