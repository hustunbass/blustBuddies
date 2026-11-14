import 'package:blast_buddies/core/rank/rank.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:flutter/material.dart';

/// Localised league name.
String leagueName(AppLocalizations l, League league) => switch (league) {
      League.bronze => l.leagueBronze,
      League.silver => l.leagueSilver,
      League.gold => l.leagueGold,
      League.diamond => l.leagueDiamond,
      League.champion => l.leagueChampion,
    };

/// Colour of a league.
Color leagueColor(League league) => switch (league) {
      League.bronze => const Color(0xFFCD7F32),
      League.silver => const Color(0xFFC0C7D1),
      League.gold => const Color(0xFFFFC107),
      League.diamond => const Color(0xFF4FC3F7),
      League.champion => const Color(0xFFAB47BC),
    };

IconData _leagueIcon(League league) => switch (league) {
      League.bronze => Icons.looks_3,
      League.silver => Icons.looks_two,
      League.gold => Icons.looks_one,
      League.diamond => Icons.diamond,
      League.champion => Icons.emoji_events,
    };

/// Shield badge for a league. [league] null = still placing (grey, "?").
class LeagueBadge extends StatelessWidget {
  /// Creates a badge.
  const LeagueBadge({super.key, required this.league, this.size = 56});

  /// League, or null while placing.
  final League? league;

  /// Width and height.
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = league == null ? Colors.blueGrey : leagueColor(league!);
    return Semantics(
      label: league == null ? '?' : leagueName(AppLocalizations.of(context), league!),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          Icon(Icons.shield, size: size, color: color),
          Icon(Icons.shield_outlined, size: size, color: Colors.black38),
          if (league == null)
            Text('?', style: TextStyle(fontSize: size * .42, fontWeight: FontWeight.w900, color: Colors.black87))
          else
            Icon(_leagueIcon(league!), size: size * .46, color: Colors.black87),
        ]),
      ),
    );
  }
}

/// Badge, league name and TP / placement progress of [rank].
class RankCard extends StatelessWidget {
  /// Creates the card.
  const RankCard({super.key, required this.rank});

  /// The player's rank.
  final PublicRank rank;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final placing = rank.placing;
    final progress = placing
        ? rank.games / rank.placement
        : (rank.league == League.champion ? 1.0 : (rank.tp / RankRules.promotionTp).clamp(0.0, 1.0));
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          LeagueBadge(league: placing ? null : rank.league, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                placing ? l.placementProgress(rank.games, rank.placement) : leagueName(l, rank.league),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: placing ? Colors.blueGrey : leagueColor(rank.league),
                  backgroundColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                placing
                    ? l.placementHint(rank.placement)
                    : rank.promotion
                        ? '${l.promotionMatch}: ${l.promotionHint}'
                        : l.tpLabel(rank.tp),
                style: TextStyle(color: rank.promotion ? Colors.amberAccent : Colors.white70),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Dialog listing the leaderboard (asks the server when opened).
Future<void> showLeaderboard(BuildContext context, OnlineClient client) {
  client.requestLeaderboard();
  return showDialog<void>(
    context: context,
    builder: (_) => ListenableBuilder(
      listenable: client,
      builder: (context, _) {
        final l = AppLocalizations.of(context);
        final rows = client.leaderboard;
        return AlertDialog(
          title: Text(l.leaderboard),
          content: SizedBox(
            width: 360,
            child: rows.isEmpty
                ? Text(l.noLeaderboard)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final r = rows[i];
                      return ListTile(
                        dense: true,
                        leading: SizedBox(
                          width: 64,
                          child: Row(children: [
                            Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 8),
                            LeagueBadge(league: r.league, size: 28),
                          ]),
                        ),
                        title: Text(r.name, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${leagueName(l, r.league)} · ${l.tpLabel(r.tp)}'),
                        trailing: Text('${r.wins}/${r.games}'),
                      );
                    },
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close))],
        );
      },
    ),
  );
}

/// Result block of a ranked game: league badge, TP change and what happened
/// (promotion, demotion, placement ...).
class RankChangeView extends StatelessWidget {
  /// Creates the block.
  const RankChangeView({super.key, required this.result});

  /// What the game did to the rank.
  final RankResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final after = result.after;
    final League? shown = after.placing ? null : after.league;
    final note = result.promoted
        ? l.rankPromoted(leagueName(l, after.league))
        : result.demoted
            ? l.rankDemoted(leagueName(l, after.league))
            : result.promotionFailed
                ? l.rankPromotionFailed
                : result.promotionOffered
                    ? l.rankPromotionOffered
                    : result.placed
                        ? l.rankPlaced(leagueName(l, after.league))
                        : null;
    final delta = result.tpDelta;
    final showDelta = !after.placing && !result.promoted && !result.demoted && !result.placed;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      LeagueBadge(league: shown, size: 72),
      const SizedBox(height: 6),
      Text(
        after.placing ? l.placementProgress(after.games, after.placement) : leagueName(l, after.league),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      if (showDelta)
        Text(
          '${delta >= 0 ? '+' : ''}$delta TP',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: delta > 0 ? Colors.greenAccent : (delta < 0 ? Colors.redAccent : Colors.white70),
          ),
        ),
      if (note != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(note,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.amberAccent)),
        ),
    ]);
  }
}
