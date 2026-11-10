/// Emotes players can flash above their buddy in online matches.
///
/// Three emotes are free ([freeIndices]); the rest are bought once with coins
/// and owned forever (wallet key `emote:<index>`).
class Emotes {
  Emotes._();

  /// All emotes; the index is what travels over the wire.
  static const List<String> emoji = [
    '👍', '😂', '😡', '😎', '🔥', '💣', //
    '😭', '🥳', '💀', '👑', '🤡', '🥶',
  ];

  /// The emotes everybody owns: thumbs up, laughing and cool.
  static const Set<int> freeIndices = {0, 1, 3};

  /// Number of free emotes.
  static int get freeCount => freeIndices.length;

  /// Total number of emotes.
  static int get count => emoji.length;

  /// Price of every other emote in coins (they are meant to be a long-term goal).
  static const int price = 10000;

  /// Whether emote [i] is free.
  static bool isFree(int i) => freeIndices.contains(i);

  /// Wallet key of emote [i].
  static String key(int i) => 'emote:$i';

  /// Whether [i] is a valid emote index.
  static bool valid(int i) => i >= 0 && i < emoji.length;
}
