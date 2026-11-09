import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/render/powerup_art.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Top bar: lives, score, timer, power-ups (story) or player chips (battle).
class GameHud extends StatelessWidget {
  /// Creates the HUD for [state].
  const GameHud({
    super.key,
    required this.state,
    required this.battle,
    required this.onPause,
    this.names,
    this.teams = false,
  });

  /// Player names (online); defaults to P1..P4.
  final List<String>? names;

  /// Outline chips with team colours.
  final bool teams;

  /// Data to show.
  final HudState state;

  /// Battle layout.
  final bool battle;

  /// Pause callback.
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = state.seconds ~/ 60;
    final s = (state.seconds % 60).toString().padLeft(2, '0');
    final time = Semantics(
      label: '${l.time} $m:$s',
      child: Text('$m:$s',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: state.seconds <= 30 ? Colors.redAccent : Colors.white,
          )),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.black26,
      child: Row(
        children: [
         // Everything but the pause button scales down to fit, never overflows.
         Expanded(
          child: FittedBox(
           fit: BoxFit.scaleDown,
           alignment: Alignment.centerLeft,
           child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
          if (battle)
            for (var i = 0; i < state.alive.length; i++)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Opacity(
                  opacity: state.alive[i] ? 1 : .3,
                  child: Chip(
                    backgroundColor: BuddyColors.players[i],
                    side: teams ? BorderSide(color: BuddyColors.teams[i % 2], width: 3) : null,
                    label: Text(names?[i] ?? l.playerN(i + 1),
                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              )
          else ...[
            Semantics(
              label: '${l.lives} ${state.lives}',
              child: Row(children: [
                const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                const SizedBox(width: 4),
                Text('${state.lives}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(width: 14),
            Semantics(
              label: '${l.score} ${state.score}',
              child: Text('${state.score}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber)),
            ),
            const SizedBox(width: 14),
            Text('Lv ${state.level}', style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 10),
            Semantics(
              label: '${l.enemiesLeft} ${state.enemies}',
              child: Row(children: [
                const Icon(Icons.smart_toy, size: 18, color: Colors.purpleAccent),
                Text(' ${state.enemies}'),
              ]),
            ),
          ],
          const SizedBox(width: 16),
          if (!battle) ...[
            _Stat(PowerUpType.bomb, '${state.maxBombs}'),
            _Stat(PowerUpType.range, '${state.range}'),
            _Stat(PowerUpType.speed, state.speed.toStringAsFixed(1)),
            if (state.kick) const _Stat(PowerUpType.kick, ''),
            if (state.detonate) const _Stat(PowerUpType.detonator, ''),
            if (state.ghost > 0) _Stat(PowerUpType.ghost, '${state.ghost}'),
            if (state.shield > 0) _Stat(PowerUpType.shield, '${state.shield}'),
            const SizedBox(width: 10),
          ],
          time,
            ],
           ),
          ),
         ),
          IconButton(
            tooltip: l.pause,
            onPressed: onPause,
            icon: const Icon(Icons.pause_circle_filled, size: 30),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.type, this.text);

  final PowerUpType type;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          PowerUpIcon(type, size: 20),
          if (text.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 3), child: Text(text, style: const TextStyle(fontSize: 14))),
        ]),
      );
}
