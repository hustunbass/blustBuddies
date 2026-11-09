import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';

/// Localised names for catalogue entries (generated lookups).
class Names {
  Names._();

  /// Arena colour theme name.
  static String map(AppLocalizations l, int i) => switch (i % 7) {
        0 => l.mapName0,
        1 => l.mapName1,
        2 => l.mapName2,
        3 => l.mapName3,
        4 => l.mapName4,
        5 => l.mapName5,
        _ => l.mapName6,
      };

  /// Story blurb of world [w] (0-based).
  static String story(AppLocalizations l, int w) => switch (w % 10) {
        0 => l.worldStory0,
        1 => l.worldStory1,
        2 => l.worldStory2,
        3 => l.worldStory3,
        4 => l.worldStory4,
        5 => l.worldStory5,
        6 => l.worldStory6,
        7 => l.worldStory7,
        8 => l.worldStory8,
        _ => l.worldStory9,
      };

  /// Hat name.
  static String hat(AppLocalizations l, int i) => [
        l.hatName0,
        l.hatName1,
        l.hatName2,
        l.hatName3,
        l.hatName4,
        l.hatName5,
        l.hatName6,
        l.hatName7,
        l.hatName8,
        l.hatName9,
        l.hatName10,
        l.hatName11,
        l.hatName12,
        l.hatName13,
        l.hatName14,
        l.hatName15,
        l.hatName16,
        l.hatName17,
        l.hatName18,
        l.hatName19,
        l.hatName20,
        l.hatName21,
        l.hatName22,
        l.hatName23,
      ][i.clamp(0, 23)];

  /// Face name.
  static String face(AppLocalizations l, int i) => [
        l.faceName0,
        l.faceName1,
        l.faceName2,
        l.faceName3,
        l.faceName4,
        l.faceName5,
        l.faceName6,
        l.faceName7,
        l.faceName8,
        l.faceName9,
        l.faceName10,
        l.faceName11,
      ][i.clamp(0, 11)];

  static const _roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'];

  /// Achievement title: series name plus rank, e.g. "Bomber III".
  static String achievement(AppLocalizations l, Achievement a) {
    final series = switch (a.stat) {
        'kills' => l.achSeries_kills,
        'blocks' => l.achSeries_blocks,
        'bombs' => l.achSeries_bombs,
        'powerups' => l.achSeries_powerups,
        'levels' => l.achSeries_levels,
        'stars' => l.achSeries_stars,
        'perfect' => l.achSeries_perfect,
        'bosses' => l.achSeries_bosses,
        'wins' => l.achSeries_wins,
        'onlineWins' => l.achSeries_onlineWins,
        'onlineGames' => l.achSeries_onlineGames,
        'games' => l.achSeries_games,
        'emotes' => l.achSeries_emotes,
        'ads' => l.achSeries_ads,
        'owned' => l.achSeries_owned,
        'invites' => l.achSeries_invites,
        'streak' => l.achSeries_streak,
        _ => a.stat,
      };
    return '$series ${_roman[(a.rank - 1).clamp(0, _roman.length - 1)]}';
  }

  /// Achievement description.
  static String achievementDesc(AppLocalizations l, Achievement a) => goalDesc(l, a.stat, a.goal);

  /// "Do [n] of [stat]" text, shared by achievements and daily quests.
  static String goalDesc(AppLocalizations l, String stat, int n) => switch (stat) {
        'kills' => l.achStat_kills(n),
        'blocks' => l.achStat_blocks(n),
        'bombs' => l.achStat_bombs(n),
        'powerups' => l.achStat_powerups(n),
        'levels' => l.achStat_levels(n),
        'stars' => l.achStat_stars(n),
        'perfect' => l.achStat_perfect(n),
        'bosses' => l.achStat_bosses(n),
        'wins' => l.achStat_wins(n),
        'onlineWins' => l.achStat_onlineWins(n),
        'onlineGames' => l.achStat_onlineGames(n),
        'games' => l.achStat_games(n),
        'emotes' => l.achStat_emotes(n),
        'ads' => l.achStat_ads(n),
        'owned' => l.achStat_owned(n),
        'invites' => l.achStat_invites(n),
        'streak' => l.achStat_streak(n),
        _ => '$n',
      };

  /// Statistic label.
  static String stat(AppLocalizations l, String key) => switch (key) {
        'kills' => l.stat_kills,
        'blocks' => l.stat_blocks,
        'bombs' => l.stat_bombs,
        'wins' => l.stat_wins,
        'onlineWins' => l.stat_onlineWins,
        'levels' => l.stat_levels,
        'bosses' => l.stat_bosses,
        'stars' => l.stat_stars,
        'powerups' => l.stat_powerups,
        _ => l.stat_perfect,
      };
}
