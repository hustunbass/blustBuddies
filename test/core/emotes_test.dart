import 'package:blast_buddies/core/emotes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('twelve emotes: six free, six premium, all distinct', () {
    expect(Emotes.count, 12);
    expect(Emotes.emoji.toSet().length, 12);
    expect(List.generate(12, Emotes.isFree).where((f) => f).length, 6);
    expect(Emotes.isFree(5), isTrue);
    expect(Emotes.isFree(6), isFalse);
    expect(Emotes.valid(11), isTrue);
    expect(Emotes.valid(12), isFalse);
    expect(Emotes.valid(-1), isFalse);
    expect(Emotes.key(8), 'emote:8');
  });
}
