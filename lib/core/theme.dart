import 'package:flutter/material.dart';

/// Shared colour palette for the original "buddy" art style.
class BuddyColors {
  BuddyColors._();

  /// Player colours (P1..P4).
  static const List<Color> players = [
    Color(0xFF29B6F6),
    Color(0xFFF06292),
    Color(0xFF66BB6A),
    Color(0xFFFFCA28),
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
}

/// Application theme.
ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BuddyColors.accent,
    brightness: Brightness.dark,
  );
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
  );
}
