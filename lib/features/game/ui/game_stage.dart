import 'dart:async';

import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/emotes.dart';
import 'package:blast_buddies/core/settings/control_layout.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:blast_buddies/features/game/ui/controls.dart';
import 'package:blast_buddies/features/game/ui/game_hud.dart';
import 'package:blast_buddies/features/shop/purchase.dart';
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
    this.showHud = true,
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

  /// Show the top bar (the tutorial has its own).
  final bool showHud;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, c) {
      final portrait = c.maxHeight > c.maxWidth;
      final hud = !showHud ? const SizedBox.shrink() : ValueListenableBuilder<HudState>(
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
    final wallet = ref.watch(walletProvider);
    final l = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final game = widget.game;
    final left = s.leftHanded;
    final stickSide = left ? Alignment.bottomRight : Alignment.bottomLeft;
    final stickSize = scaled(140, s.controlScale);
    return LayoutBuilder(builder: (context, c) {
      final area = Size(c.maxWidth, c.maxHeight);
      final layout = widget.landscape ? s.controlsLandscape : s.controlsPortrait;
      final stickRect = ControlGeometry.stick(area, stickSize, leftHanded: left, layout: layout);
      final bombSize = scaled(96, s.controlScale);
      final bombRect = ControlGeometry.bomb(area, bombSize, leftHanded: left, layout: layout);
      final zone = c.maxWidth * (widget.landscape ? .42 : .58);
      // The floating stick listens in a zone that follows the moved joystick.
      final zoneLeft = ((left ? c.maxWidth - zone : 0.0) + layout.stickDx * c.maxWidth).clamp(0.0, c.maxWidth - zone);
      final stick = s.floatingStick
          ? Positioned(
              top: 0,
              bottom: 0,
              left: zoneLeft,
              width: zone,
              child: FloatingJoystick(
                size: stickSize,
                alignment: stickSide,
                home: Offset(
                  (stickRect.center.dx - zoneLeft).clamp(stickSize / 2, zone - stickSize / 2),
                  stickRect.center.dy,
                ),
                semanticLabel: l.joystick,
                onChanged: (d) => game.touchDir = d,
              ),
            )
          : Positioned(
              left: stickRect.left,
              top: stickRect.top,
              child: VirtualJoystick(
                size: stickSize,
                semanticLabel: l.joystick,
                onChanged: (d) => game.touchDir = d,
              ),
            );
      final small = scaled(56, s.controlScale);
      final buttons = Positioned(
        bottom: c.maxHeight - bombRect.bottom,
        left: left ? bombRect.left : null,
        right: left ? null : c.maxWidth - bombRect.right,
        child: ValueListenableBuilder<HudState>(
          valueListenable: game.hud,
          builder: (_, hud, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            children: [
              if (_emotes && game.remote != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  // Two rows of six: free emotes first, then the premium ones.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 6 * small + 5 * 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      alignment: left ? WrapAlignment.start : WrapAlignment.end,
                      children: [
                        for (var i = 0; i < Emotes.count; i++)
                          _EmoteButton(
                            size: small,
                            index: i,
                            owned: Emotes.isFree(i) || wallet.has(Emotes.key(i)),
                            label: l.emote,
                            onTap: () async {
                              final remote = game.remote!;
                              if (!Emotes.isFree(i) &&
                                  !await purchaseWithCoins(context, ref, Emotes.key(i), Emotes.price)) {
                                return;
                              }
                              remote.emote(i);
                              unawaited(ref.read(statsProvider.notifier).add({'emotes': 1}));
                              if (mounted) setState(() => _emotes = false);
                            },
                          ),
                      ],
                    ),
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

/// One emote in the picker; premium ones show a lock until bought.
class _EmoteButton extends StatelessWidget {
  const _EmoteButton({
    required this.size,
    required this.index,
    required this.owned,
    required this.label,
    required this.onTap,
  });

  final double size;
  final int index;
  final bool owned;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        Opacity(
          opacity: owned ? 1 : .55,
          child: _RoundButton(
            size: size,
            color: owned ? Colors.white24 : Colors.black45,
            semanticLabel: label,
            onTap: onTap,
            child: Text(Emotes.emoji[index], style: TextStyle(fontSize: size * .5)),
          ),
        ),
        if (!owned)
          Positioned(
            right: -2,
            bottom: -2,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                child: Icon(Icons.lock, size: size * .28, color: Colors.amber),
              ),
            ),
          ),
      ]);
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
