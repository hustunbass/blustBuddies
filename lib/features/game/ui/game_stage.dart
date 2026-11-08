import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/features/game/ui/controls.dart';
import 'package:blast_buddies/features/game/render/world_painter.dart';
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
    return LayoutBuilder(builder: (context, c) {
      final portrait = c.maxHeight > c.maxWidth;
      final hud = ValueListenableBuilder<HudState>(
        valueListenable: game.hud,
        builder: (_, s, _) =>
            GameHud(state: s, battle: battle, onPause: onPause, names: names, teams: teams),
      );
      final view = GameWidget<BlastGame>(game: game);
      if (portrait) {
        return Column(children: [
          hud,
          Flexible(child: AspectRatio(aspectRatio: 13 / 11, child: view)),
          Expanded(child: _Controls(game: game, landscape: false)),
        ]);
      }
      return Column(children: [
        hud,
        Expanded(
          child: Stack(children: [
            Positioned.fill(child: view),
            Positioned.fill(child: _Controls(game: game, landscape: true)),
          ]),
        ),
      ]);
    });
  }
}

/// Joystick zone on one side, action buttons on the other (mirrored for
/// left-handed players).
class _Controls extends ConsumerStatefulWidget {
  const _Controls({required this.game, required this.landscape});

  final BlastGame game;
  final bool landscape;

  @override
  ConsumerState<_Controls> createState() => _ControlsState();
}

class _ControlsState extends ConsumerState<_Controls> {
  bool _emotes = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final game = widget.game;
    final left = s.leftHanded;
    final stickSide = left ? Alignment.bottomRight : Alignment.bottomLeft;
    final stickSize = scaled(140, s.controlScale);
    return LayoutBuilder(builder: (context, c) {
      final zone = c.maxWidth * (widget.landscape ? .42 : .58);
      final stick = s.floatingStick
          ? Positioned(
              top: 0,
              bottom: 0,
              left: left ? null : 0,
              right: left ? 0 : null,
              width: zone,
              child: FloatingJoystick(
                size: stickSize,
                alignment: stickSide,
                semanticLabel: l.joystick,
                onChanged: (d) => game.touchDir = d,
              ),
            )
          : Positioned(
              bottom: 12,
              left: left ? null : 24,
              right: left ? 24 : null,
              child: VirtualJoystick(
                size: stickSize,
                semanticLabel: l.joystick,
                onChanged: (d) => game.touchDir = d,
              ),
            );
      final bombSize = scaled(96, s.controlScale);
      final small = scaled(56, s.controlScale);
      final buttons = Positioned(
        bottom: 12,
        left: left ? 24 : null,
        right: left ? null : 24,
        child: ValueListenableBuilder<HudState>(
          valueListenable: game.hud,
          builder: (_, hud, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              if (_emotes && game.remote != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: left ? WrapAlignment.start : WrapAlignment.end,
                    children: [
                      for (var i = 0; i < WorldPainter.emoji.length; i++)
                        _RoundButton(
                          size: small,
                          color: Colors.white24,
                          semanticLabel: l.emote,
                          onTap: () {
                            game.remote!.emote(i);
                            setState(() => _emotes = false);
                          },
                          child: Text(WorldPainter.emoji[i], style: TextStyle(fontSize: small * .5)),
                        ),
                    ],
                  ),
                ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (game.remote != null)
                  _RoundButton(
                    size: small,
                    color: Colors.white24,
                    semanticLabel: l.emote,
                    onTap: () => setState(() => _emotes = !_emotes),
                    child: Icon(Icons.emoji_emotions, size: small * .55, color: Colors.white),
                  ),
                if (hud.detonate) ...[
                  const SizedBox(width: 10),
                  _RoundButton(
                    size: small + 8,
                    color: const Color(0xCCEF5350),
                    semanticLabel: l.detonateButton,
                    onTap: game.touchDetonate,
                    child: Icon(Icons.flash_on, size: small * .6, color: Colors.white),
                  ),
                ],
              ]),
              const SizedBox(height: 10),
              BombButton(size: bombSize, semanticLabel: l.bombButton, onPressed: game.touchBomb),
            ],
          ),
        ),
      );
      return Stack(children: [stick, buttons]);
    });
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.size,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final double size;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => onTap(),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: child,
          ),
        ),
      );
}

/// Full-screen dimmed panel with a title and action buttons.
class ResultPanel extends StatelessWidget {
  /// Creates a panel.
  const ResultPanel({super.key, required this.title, required this.actions, this.subtitle, this.header});

  /// Optional widget between subtitle and buttons (e.g. star rating).
  final Widget? header;

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
                if (header != null) Padding(padding: const EdgeInsets.only(top: 12), child: header),
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
