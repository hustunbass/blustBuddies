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
  static String hat(AppLocalizations l, int i) => switch (i) {
        0 => l.hatName0,
        1 => l.hatName1,
        2 => l.hatName2,
        3 => l.hatName3,
        4 => l.hatName4,
        5 => l.hatName5,
        6 => l.hatName6,
        _ => l.hatName7,
      };

  /// Face name.
  static String face(AppLocalizations l, int i) => switch (i) {
        0 => l.faceName0,
        1 => l.faceName1,
        2 => l.faceName2,
        3 => l.faceName3,
        4 => l.faceName4,
        _ => l.faceName5,
      };

  /// Achievement title.
  static String achievement(AppLocalizations l, String id) => switch (id) {
        'firstBlood' => l.ach_firstBlood,
        'firstWin' => l.ach_firstWin,
        'bomber' => l.ach_bomber,
        'demolition' => l.ach_demolition,
        'collector' => l.ach_collector,
        'chapter' => l.ach_chapter,
        'stars30' => l.ach_stars30,
        'exterminator' => l.ach_exterminator,
        'champion' => l.ach_champion,
        'online1' => l.ach_online1,
        'boss1' => l.ach_boss1,
        'perfectionist' => l.ach_perfectionist,
        'explorer' => l.ach_explorer,
        'online10' => l.ach_online10,
        'bosses4' => l.ach_bosses4,
        _ => l.ach_legend,
      };

  /// Achievement description with goal [n].
  static String achievementDesc(AppLocalizations l, String id, int n) => switch (id) {
        'firstBlood' => l.achDesc_firstBlood(n),
        'firstWin' => l.achDesc_firstWin(n),
        'bomber' => l.achDesc_bomber(n),
        'demolition' => l.achDesc_demolition(n),
        'collector' => l.achDesc_collector(n),
        'chapter' => l.achDesc_chapter(n),
        'stars30' => l.achDesc_stars30(n),
        'exterminator' => l.achDesc_exterminator(n),
        'champion' => l.achDesc_champion(n),
        'online1' => l.achDesc_online1(n),
        'boss1' => l.achDesc_boss1(n),
        'perfectionist' => l.achDesc_perfectionist(n),
        'explorer' => l.achDesc_explorer(n),
        'online10' => l.achDesc_online10(n),
        'bosses4' => l.achDesc_bosses4(n),
        _ => l.achDesc_legend(n),
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
