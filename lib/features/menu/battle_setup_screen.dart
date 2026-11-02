import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Battle mode setup: one human against 1–3 bots.
class BattleSetupScreen extends StatefulWidget {
  /// Creates the screen.
  const BattleSetupScreen({super.key});

  @override
  State<BattleSetupScreen> createState() => _BattleSetupScreenState();
}

class _BattleSetupScreenState extends State<BattleSetupScreen> {
  static const _humans = 1;
  int _bots = 1;
  bool _teams = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final total = _humans + _bots;
    final teams = _teams && total == 4;
    return Scaffold(
      appBar: AppBar(title: Text(l.battleSetup), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Picker(
                    label: l.botPlayers,
                    value: _bots,
                    min: 1,
                    max: 3,
                    onChanged: (v) => setState(() => _bots = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < total; i++)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: teams ? BuddyColors.teams[i % 2] : Colors.transparent,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: BuddyColors.players[i],
                              child: Text(
                                i < _humans ? l.playerN(i + 1) : 'AI',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SwitchListTile(
                    title: Text(l.teamsLabel),
                    value: teams,
                    onChanged: total == 4 ? (v) => setState(() => _teams = v) : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.battleHint,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => context.pushReplacement(
                            '/game',
                            extra: GameArgs.battle(humans: _humans, bots: _bots, teams: teams),
                          ),
                    child: Text(l.startBattle),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 18))),
      IconButton(
        tooltip: '-',
        onPressed: value > min ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      Semantics(
        label: '$label $value',
        child: ExcludeSemantics(
          child: Text('$value', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
      ),
      IconButton(
        tooltip: '+',
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}
