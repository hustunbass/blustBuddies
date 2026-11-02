import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Rules and power-up legend.
class HowToPlayScreen extends StatelessWidget {
  /// Creates the screen.
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rules = [l.howMove, l.howBomb, l.howBlocks, l.howEnemies, l.howTime, l.howBattle];
    final powers = <(IconData, Color, String)>[
      (Icons.circle, Colors.blueGrey.shade200, l.powerBomb),
      (Icons.add, Colors.deepOrangeAccent, l.powerRange),
      (Icons.bolt, Colors.yellow, l.powerSpeed),
      (Icons.shield, Colors.lightBlueAccent, l.powerShield),
      (Icons.sports_soccer, Colors.purpleAccent, l.powerKick),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.howToPlay), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final r in rules)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(r, style: const TextStyle(fontSize: 16, height: 1.3)),
              ),
            const Divider(),
            for (final (icon, color, label) in powers)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: BuddyColors.floorA,
                  child: Icon(icon, color: color),
                ),
                title: Text(label),
              ),
          ],
        ),
      ),
    );
  }
}
