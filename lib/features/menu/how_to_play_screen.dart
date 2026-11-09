import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/features/game/render/powerup_art.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Rules and power-up legend. Power-ups are drawn exactly like in the arena.
class HowToPlayScreen extends StatelessWidget {
  /// Creates the screen.
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rules = <(IconData, String)>[
      (Icons.gamepad_rounded, l.howMove),
      (Icons.circle, l.howBomb),
      (Icons.grid_view_rounded, l.howBlocks),
      (Icons.smart_toy_rounded, l.howEnemies),
      (Icons.timer_rounded, l.howTime),
      (Icons.star_rounded, l.howStars),
      (Icons.local_fire_department_rounded, l.howBoss),
      (Icons.groups_rounded, l.howBattle),
    ];
    final powers = <(PowerUpType, String)>[
      (PowerUpType.bomb, l.powerBomb),
      (PowerUpType.range, l.powerRange),
      (PowerUpType.speed, l.powerSpeed),
      (PowerUpType.shield, l.powerShield),
      (PowerUpType.kick, l.powerKick),
      (PowerUpType.detonator, l.howDetonator),
      (PowerUpType.ghost, l.howGhost),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.howToPlay)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                FilledButton.icon(
                  onPressed: () => context.push('/tutorial'),
                  icon: const Icon(Icons.school_rounded),
                  label: Text(l.howToTutorial),
                ),
                _SectionTitle(l.howRules),
                for (final (icon, text) in rules) _RuleCard(icon: icon, text: text),
                const SizedBox(height: 10),
                _SectionTitle(l.howPowerUps),
                for (final (type, label) in powers) _PowerRow(type: type, label: label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
        child: Semantics(
          header: true,
          child: Text(
            text.toUpperCase(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: BuddyColors.gold),
          ),
        ),
      );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: BuddyColors.panel, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: BuddyColors.panelLight, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: BuddyColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.35))),
        ]),
      );
}

class _PowerRow extends StatelessWidget {
  const _PowerRow({required this.type, required this.label});

  final PowerUpType type;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: BuddyColors.panel, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          PowerUpIcon(type, size: 38),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3))),
        ]),
      );
}
