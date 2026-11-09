/// Emotes players can flash above their buddy in online matches.
///
/// The first [freeCount] are free; the rest are bought once with coins and
/// owned forever (wallet key `emote:<index>`).
class Emotes {
  Emotes._();

  /// All emotes; the index is what travels over the wire.
  static const List<String> emoji = [
    // Free
    '👍', '😂', '😡', '😎', '🔥', '💣',
    // Premium
    '😭', '🥳', '💀', '👑', '🤡', '🥶',
  ];

  /// Number of free emotes at the start of [emoji].
  static const int freeCount = 6;

  /// Total number of emotes.
  static int get count => emoji.length;

  /// Price of a premium emote in coins.
  static const int price = 120;

  /// Whether emote [i] is free.
  static bool isFree(int i) => i < freeCount;

  /// Wallet key of emote [i].
  static String key(int i) => 'emote:$i';

  /// Whether [i] is a valid emote index.
  static bool valid(int i) => i >= 0 && i < emoji.length;
}
