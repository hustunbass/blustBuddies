import 'package:flutter/material.dart';

/// Shared colour palette for the original "buddy" art style.
class BuddyColors {
  BuddyColors._();

  /// Player colours (P1..P7).
  static const List<Color> players = [
    Color(0xFF29B6F6),
    Color(0xFFF06292),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
    Color(0xFF9575CD),
    Color(0xFFEF5350),
    Color(0xFFFF8A65),
  ];

  /// Team colours (2v2): team 1, team 2.
  static const List<Color> teams = [Color(0xFFFF7043), Color(0xFF26C6DA)];

  /// Floor tiles.
  static const Color floorA = Color(0xFF2E3A59);

  /// Alternate floor tile.
  static const Color floorB = Color(0xFF2A3552);

  /// Indestructible wall.
  static const Color wall = Color(0xFF59607A);

  /// Breakable block.
  static const Color block = Color(0xFFB9773E);

  /// Background.
  static const Color background = Color(0xFF1B2238);

  /// Accent used in UI.
  static const Color accent = Color(0xFFFF7043);

  /// Raised panels: dialogs, sheets, toasts (same navy as the menu gradient).
  static const Color panel = Color(0xFF232C4D);

  /// Fields and chips sitting on a [panel].
  static const Color panelLight = Color(0xFF2E3A63);

  /// Coins and rewards.
  static const Color gold = Color(0xFFFFC53D);
}

/// Colour scheme of one arena. Which one a match uses is derived from the
/// match seed, so online players always see the same one.
class MapTheme {
  MapTheme._(this.name, this.floorA, this.floorB, this.wall, this.block)
      : wallTop = Color.lerp(wall, const Color(0xFFFFFFFF), .22)!,
        wallShade = Color.lerp(wall, const Color(0xFF000000), .38)!,
        blockLight = Color.lerp(block, const Color(0xFFFFFFFF), .25)!,
        blockDark = Color.lerp(block, const Color(0xFF000000), .42)!,
        floorLine = Color.lerp(floorA, const Color(0xFF000000), .22)!;

  /// Display name of the arena.
  final String name;

  /// Floor tile colours (checker).
  final Color floorA, floorB;

  /// Indestructible wall: body, lit top face, shaded base.
  final Color wall, wallTop, wallShade;

  /// Breakable crate: body, highlight, outline/planks.
  final Color block, blockLight, blockDark;

  /// Subtle grout line between floor tiles.
  final Color floorLine;

  /// All arenas.
  static final List<MapTheme> all = [
    MapTheme._('Neon Arena', const Color(0xFF263354), const Color(0xFF222E4C), const Color(0xFF5E6A8C), const Color(0xFFD08A3E)),
    MapTheme._('Jungle Ruins', const Color(0xFF2F5D3A), const Color(0xFF2A5434), const Color(0xFF7C8B72), const Color(0xFFA8743C)),
    MapTheme._('Desert Dunes', const Color(0xFFC6A26A), const Color(0xFFBE9A62), const Color(0xFF8A5E45), const Color(0xFFE08A3C)),
    MapTheme._('Frozen Peak', const Color(0xFF86AEC8), const Color(0xFF7DA5C0), const Color(0xFF486A8A), const Color(0xFFE4F1F8)),
    MapTheme._('Lava Forge', const Color(0xFF2E1F22), const Color(0xFF281A1D), const Color(0xFF6E5A5E), const Color(0xFFC4502E)),
    MapTheme._('Deep Ocean', const Color(0xFF12506A), const Color(0xFF0F4760), const Color(0xFF2E6E86), const Color(0xFFE5795C)),
    MapTheme._('Cosmic Station', const Color(0xFF1F1C3D), const Color(0xFF1A1736), const Color(0xFF50548F), const Color(0xFF9B6BE3)),
  ];

  /// Theme [i] (wraps around).
  static MapTheme of(int i) => all[i % all.length];
}

/// Application theme.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BuddyColors.accent,
    brightness: Brightness.dark,
  );
  const radius = Radius.circular(24);
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: BuddyColors.background,
    useMaterial3: true,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(220, 52),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    // One look for every screen title ("How to Play", "Online battle", ...).
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: .4, color: Colors.white),
    ),
    // Dialogs, sheets and fields share the app's navy instead of the default
    // pinkish Material surface.
    dialogTheme: const DialogThemeData(
      backgroundColor: BuddyColors.panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(radius)),
      titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
      contentTextStyle: TextStyle(fontSize: 15, height: 1.35, color: Colors.white70),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BuddyColors.panel,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: Colors.white24,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: radius)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BuddyColors.panelLight,
      labelStyle: const TextStyle(color: Colors.white70),
      helperStyle: const TextStyle(color: Colors.white54),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: BuddyColors.panelLight,
      selectedColor: scheme.primary,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
      secondaryLabelStyle: TextStyle(fontWeight: FontWeight.w800, color: scheme.onPrimary),
      checkmarkColor: scheme.onPrimary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : Colors.white70,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : BuddyColors.panelLight,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(color: Colors.white12),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary, textStyle: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}
