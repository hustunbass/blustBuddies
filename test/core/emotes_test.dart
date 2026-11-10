import 'package:blast_buddies/core/emotes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('twelve emotes: three free, nine premium at a flat 10K, all distinct', () {
    expect(Emotes.count, 12);
    expect(Emotes.emoji.toSet().length, 12);
    expect(List.generate(12, Emotes.isFree).where((f) => f).length, 3);
    expect([for (var i = 0; i < 12; i++) if (Emotes.isFree(i)) i], [0, 1, 3]);
    expect(Emotes.freeCount, 3);
    expect(Emotes.isFree(5), isFalse);
    expect(Emotes.price, 10000);
    expect(Emotes.valid(11), isTrue);
    expect(Emotes.valid(12), isFalse);
    expect(Emotes.valid(-1), isFalse);
    expect(Emotes.key(8), 'emote:8');
  });
}
