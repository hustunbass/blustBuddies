import 'package:blast_buddies/features/game/logic/entities.dart';

/// Unlockable looks. Items are unlocked by total story stars.
class CosmeticItem {
  /// Creates an item that needs [stars] total stars.
  const CosmeticItem(this.stars, [this.color]);

  /// Stars needed.
  final int stars;

  /// Body colour (ARGB) for colour items.
  final int? color;
}

/// Catalogue of hats, faces and body colours.
class Cosmetics {
  Cosmetics._();

  /// Hats: none, cap, party, cowboy, crown, wizard, halo, horns.
  static const List<CosmeticItem> hats = [
    CosmeticItem(0),
    CosmeticItem(3),
    CosmeticItem(8),
    CosmeticItem(15),
    CosmeticItem(25),
    CosmeticItem(40),
    CosmeticItem(60),
    CosmeticItem(90),
  ];

  /// Faces: classic, happy, cool, angry, wink, star eyes.
  static const List<CosmeticItem> faces = [
    CosmeticItem(0),
    CosmeticItem(5),
    CosmeticItem(12),
    CosmeticItem(22),
    CosmeticItem(35),
    CosmeticItem(55),
  ];

  /// Body colours; index 0 keeps the slot colour.
  static const List<CosmeticItem> colors = [
    CosmeticItem(0),
    CosmeticItem(2, 0xFFE53935),
    CosmeticItem(5, 0xFFFB8C00),
    CosmeticItem(10, 0xFF8E24AA),
    CosmeticItem(14, 0xFF00ACC1),
    CosmeticItem(20, 0xFFC0CA33),
    CosmeticItem(35, 0xFFFFD54F),
    CosmeticItem(50, 0xFF546E7A),
    CosmeticItem(70, 0xFFECEFF1),
  ];

  /// Builds a [Skin] from catalogue indices (out-of-range = default).
  static Skin skin(int hat, int face, int color) => Skin(
        hat: hat.clamp(0, hats.length - 1),
        face: face.clamp(0, faces.length - 1),
        color: colors[color.clamp(0, colors.length - 1)].color,
      );
}
