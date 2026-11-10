import 'package:blast_buddies/features/game/logic/entities.dart';

/// Unlockable looks. Every kind starts with a few free items; the rest are
/// bought with coins, dearer the rarer the item.
class CosmeticItem {
  /// A paid item whose rarity is [stars] (higher = rarer = dearer).
  const CosmeticItem(this.stars, [this.color]) : free = false;

  /// An item every player owns from the start.
  const CosmeticItem.free([this.color])
      : stars = 0,
        free = true;

  /// Rarity rank (also the legacy star unlock threshold).
  final int stars;

  /// Owned by every player from the start.
  final bool free;

  /// Price in Coin (0 = free): 1K for the cheapest items up to 5K for the rarest.
  int get price {
    if (free) return 0;
    if (stars <= 12) return 1000;
    if (stars <= 20) return 2000;
    if (stars <= 35) return 3000;
    if (stars <= 55) return 4000;
    return 5000;
  }

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
    CosmeticItem.free(),
    CosmeticItem.free(),
    CosmeticItem(8),
    CosmeticItem(15),
    CosmeticItem(25),
    CosmeticItem(40),
    CosmeticItem(60),
    CosmeticItem(90),
    CosmeticItem.free(),
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
    CosmeticItem.free(),
    CosmeticItem.free(),
    CosmeticItem(12),
    CosmeticItem(22),
    CosmeticItem(35),
    CosmeticItem(55),
    CosmeticItem.free(),
    CosmeticItem(14),
    CosmeticItem(28),
    CosmeticItem(18),
    CosmeticItem(42),
    CosmeticItem(65),
  ];

  /// Body colours; index 0 keeps the slot colour.
  static const List<CosmeticItem> colors = [
    CosmeticItem.free(),
    CosmeticItem.free(0xFFE53935),
    CosmeticItem.free(0xFFFB8C00),
    CosmeticItem(10, 0xFF8E24AA),
    CosmeticItem(14, 0xFF00ACC1),
    CosmeticItem(20, 0xFFC0CA33),
    CosmeticItem(35, 0xFFFFD54F),
    CosmeticItem(50, 0xFF546E7A),
    CosmeticItem(70, 0xFFECEFF1),
    CosmeticItem.free(0xFF26A69A),
    CosmeticItem(9, 0xFFEC407A),
    CosmeticItem(16, 0xFF9CCC65),
    CosmeticItem(25, 0xFF3949AB),
    CosmeticItem(30, 0xFF8D6E63),
    CosmeticItem(60, 0xFF212121),
    CosmeticItem(80, 0xFFE8A598),
  ];

  /// Catalogue indices of [items] from cheapest to most expensive (the free
  /// items first); ties keep catalogue order. The wardrobe shows this order.
  static List<int> byPrice(List<CosmeticItem> items) =>
      List<int>.generate(items.length, (i) => i)..sort((a, b) {
        final byPrice = items[a].price.compareTo(items[b].price);
        if (byPrice != 0) return byPrice;
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
