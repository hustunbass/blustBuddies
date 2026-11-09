import 'package:blast_buddies/core/grid/map_generator.dart';
import 'package:blast_buddies/core/theme.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Asks which kind of quick match to join. Resolves to the player count
/// (2, 4 or 7), or null when dismissed.
Future<int?> showQuickMatchDialog(BuildContext context) =>
    showDialog<int>(context: context, builder: (_) => const _QuickMatchDialog());

class _QuickMatchDialog extends StatelessWidget {
  const _QuickMatchDialog();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: BuddyColors.gold.withValues(alpha: .18), shape: BoxShape.circle),
                child: const Icon(Icons.bolt_rounded, color: BuddyColors.gold, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.quickMatch,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ]),
            const SizedBox(height: 10),
            Text(l.quickHint, style: const TextStyle(fontSize: 14, height: 1.35, color: Colors.white70)),
            const SizedBox(height: 16),
            _Option(players: 2, title: l.quick1v1, description: l.quickDuelDesc),
            const SizedBox(height: 10),
            _Option(players: 4, title: l.quick4, description: l.quickBrawlDesc),
            const SizedBox(height: 10),
            _Option(
              players: MapGenerator.maxPlayers,
              title: l.quickParty(MapGenerator.maxPlayers),
              description: l.quickPartyDesc,
            ),
            const SizedBox(height: 6),
            Align(
              child: TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.players, required this.title, required this.description});

  final int players;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title. $description',
        child: Material(
          color: BuddyColors.panelLight,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.pop(context, players),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ExcludeSemantics(
                child: Row(children: [
                  _PlayerDots(players),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(description, style: const TextStyle(fontSize: 12.5, height: 1.25, color: Colors.white60)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                ]),
              ),
            ),
          ),
        ),
      );
}

/// One little buddy-coloured dot per player.
class _PlayerDots extends StatelessWidget {
  const _PlayerDots(this.count);

  final int count;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 52,
        height: 52,
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (var i = 0; i < count; i++)
                Container(
                  width: count > 4 ? 12 : 16,
                  height: count > 4 ? 12 : 16,
                  decoration: BoxDecoration(color: BuddyColors.players[i % BuddyColors.players.length], shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      );
}
