/// A Coin pack sold as a consumable in-app purchase.
class CoinPackage {
  /// Creates a package.
  const CoinPackage({
    required this.id,
    required this.amount,
    required this.fallbackPrice,
    this.bonusPercent = 0,
    this.popular = false,
    this.bestValue = false,
  });

  /// Store product id (same in App Store Connect and Play Console).
  final String id;

  /// Coin granted.
  final int amount;

  /// Price text used until the store returns the localised one.
  final String fallbackPrice;

  /// Marketing bonus compared with the smallest pack.
  final int bonusPercent;

  /// Highlight as most popular.
  final bool popular;

  /// Highlight as best value.
  final bool bestValue;
}

/// Catalogue of Coin packs, smallest first.
const List<CoinPackage> coinPackages = [
  CoinPackage(id: 'coin_500', amount: 500, fallbackPrice: '₺29,99'),
  CoinPackage(
    id: 'coin_1500',
    amount: 1500,
    fallbackPrice: '₺69,99',
    bonusPercent: 25,
  ),
  CoinPackage(
    id: 'coin_4000',
    amount: 4000,
    fallbackPrice: '₺149,99',
    bonusPercent: 40,
    popular: true,
  ),
  CoinPackage(
    id: 'coin_10000',
    amount: 10000,
    fallbackPrice: '₺329,99',
    bonusPercent: 80,
    bestValue: true,
  ),
];

/// Product id of the non-consumable "remove ads" purchase.
const removeAdsProductId = 'remove_ads';

/// Product id of the one-time starter pack.
const starterPackProductId = 'starter_pack';

/// Coins inside the starter pack (lives are refilled as well).
const starterPackCoins = 1000;

/// How long the starter pack is offered after the first launch.
const starterOfferDuration = Duration(hours: 48);

/// Price text of the starter pack until the store returns the localised one.
const starterPackFallbackPrice = '₺39,99';

/// The first coin pack ever bought pays this much extra (as many coins as the
/// pack contains, capped here).
const firstPurchaseBonusCap = 1500;

/// Every product id the store has to know.
Set<String> get allProductIds => {
      for (final p in coinPackages) p.id,
      removeAdsProductId,
      starterPackProductId,
    };
