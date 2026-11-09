import 'package:blast_buddies/features/game/logic/entities.dart';

/// Unlockable looks. Items are unlocked by total story stars.
class CosmeticItem {
  /// Creates an item that needs [stars] total stars.
  const CosmeticItem(this.stars, [this.color]);

  /// Legacy unlock threshold in stars (also scales the price).
  final int stars;

  /// Price in Coin (0 = free from the start).
  int get price => stars * 10;

  /// Body colour (ARGB) for colour items.
  final int? color;
}

/// Catalogue of hats, faces and body colours.
class Cosmetics {
  Cosmetics._();

  /// Hats. The index travels over the wire (and is saved), so only append.
  /// 0 none, 1 cap, 2 party, 3 cowboy, 4 crown, 5 wizard, 6 halo, 7 horns,
  /// 8 beanie, 9 chef, 10 pirate, 11 viking, 12 cat ears, 13 bunny ears,
  /// 14 top hat, 15 daisy, 16 headphones, 17 propeller cap, 18 santa,
  /// 19 ninja band, 20 flame hair, 21 jester, 22 laurel wreath, 23 rainbow afro.
  static const List<CosmeticItem> hats = [
    CosmeticItem(0),
    CosmeticItem(3),
    CosmeticItem(8),
    CosmeticItem(15),
    CosmeticItem(25),
    CosmeticItem(40),
    CosmeticItem(60),
    CosmeticItem(90),
    CosmeticItem(4),
    CosmeticItem(6),
    CosmeticItem(11),
    CosmeticItem(17),
    CosmeticItem(5),
    CosmeticItem(7),
    CosmeticItem(22),
    CosmeticItem(9),
    CosmeticItem(13),
    CosmeticItem(20),
    CosmeticItem(30),
    CosmeticItem(26),
    CosmeticItem(48),
    CosmeticItem(36),
    CosmeticItem(55),
    CosmeticItem(80),
  ];

  /// Faces: 0 classic, 1 happy, 2 cool, 3 angry, 4 wink, 5 star eyes,
  /// 6 sleepy, 7 surprised, 8 heart eyes, 9 silly, 10 robot visor, 11 cyclops.
  static const List<CosmeticItem> faces = [
    CosmeticItem(0),
    CosmeticItem(5),
    CosmeticItem(12),
    CosmeticItem(22),
    CosmeticItem(35),
    CosmeticItem(55),
    CosmeticItem(8),
    CosmeticItem(14),
    CosmeticItem(28),
    CosmeticItem(18),
    CosmeticItem(42),
    CosmeticItem(65),
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
    CosmeticItem(7, 0xFF26A69A),
    CosmeticItem(9, 0xFFEC407A),
    CosmeticItem(16, 0xFF9CCC65),
    CosmeticItem(25, 0xFF3949AB),
    CosmeticItem(30, 0xFF8D6E63),
    CosmeticItem(60, 0xFF212121),
    CosmeticItem(80, 0xFFE8A598),
  ];

  /// Catalogue indices of [items] from cheapest to most expensive (the free
  /// default first); ties keep catalogue order. The wardrobe shows this order.
  static List<int> byPrice(List<CosmeticItem> items) =>
      List<int>.generate(items.length, (i) => i)..sort((a, b) {
        final byStars = items[a].stars.compareTo(items[b].stars);
        return byStars != 0 ? byStars : a.compareTo(b);
      });

  /// Builds a [Skin] from catalogue indices (out-of-range = default).
  static Skin skin(int hat, int face, int color) => Skin(
    hat: hat.clamp(0, hats.length - 1),
    face: face.clamp(0, faces.length - 1),
    color: colors[color.clamp(0, colors.length - 1)].color,
  );
}
