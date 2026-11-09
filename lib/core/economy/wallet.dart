import 'package:blast_buddies/core/cosmetics.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Spendable balance of **Coin** (the in-game currency) plus everything
/// bought with it (cosmetics, premium emotes).
class WalletData {
  /// Creates wallet data.
  const WalletData({this.coin = 0, this.owned = const {}});

  /// Current balance.
  final int coin;

  /// Owned item keys, e.g. `hat:3`, `face:2`, `color:5`, `emote:8`.
  final Set<String> owned;

  /// Whether [key] is owned.
  bool has(String key) => owned.contains(key);
}

/// Persists [WalletData] in shared preferences.
class WalletNotifier extends Notifier<WalletData> {
  /// Welcome gift for new players.
  static const welcomeBonus = 100;

  /// Coin granted for every newly earned story star.
  static const perStar = 10;

  @override
  WalletData build() {
    final p = ref.watch(prefsProvider);
    if (p.getBool('walletInit') != true) {
      // First launch with the wallet: keep everything the player had already
      // unlocked through stars, then add the welcome gift.
      final stars = ref.read(progressProvider).totalStars;
      final owned = <String>{
        for (var i = 0; i < Cosmetics.hats.length; i++)
          if (Cosmetics.hats[i].stars <= stars) 'hat:$i',
        for (var i = 0; i < Cosmetics.faces.length; i++)
          if (Cosmetics.faces[i].stars <= stars) 'face:$i',
        for (var i = 0; i < Cosmetics.colors.length; i++)
          if (Cosmetics.colors[i].stars <= stars) 'color:$i',
      };
      p
        ..setInt('coin', welcomeBonus)
        ..setStringList('owned', owned.toList())
        ..setBool('walletInit', true);
      return WalletData(coin: welcomeBonus, owned: owned);
    }
    return WalletData(
      coin: p.getInt('coin') ?? 0,
      owned: (p.getStringList('owned') ?? const []).toSet(),
    );
  }

  /// Adds [amount] Coin.
  Future<void> earn(int amount) async {
    if (amount <= 0) return;
    state = WalletData(coin: state.coin + amount, owned: state.owned);
    await ref.read(prefsProvider).setInt('coin', state.coin);
  }

  /// Spends [amount]; returns false (and changes nothing) if too poor.
  Future<bool> spend(int amount) async {
    if (amount > state.coin) return false;
    state = WalletData(coin: state.coin - amount, owned: state.owned);
    await ref.read(prefsProvider).setInt('coin', state.coin);
    return true;
  }

  /// Buys item [key] for [price]; returns false if it cannot be afforded.
  Future<bool> buy(String key, int price) async {
    if (state.has(key)) return true;
    if (!await spend(price)) return false;
    final owned = {...state.owned, key};
    state = WalletData(coin: state.coin, owned: owned);
    await ref.read(prefsProvider).setStringList('owned', owned.toList());
    return true;
  }
}

/// Wallet provider.
final walletProvider = NotifierProvider<WalletNotifier, WalletData>(
  WalletNotifier.new,
);
