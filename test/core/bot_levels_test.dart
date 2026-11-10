import 'dart:math';

import 'package:blast_buddies/features/game/logic/bot_brain.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:flutter_test/flutter_test.dart';

/// Plays [seeds] matches of one decent "human" (a normal-level brain) against
/// three bots of [level] and counts how often the human dies.
({int humanDied, int matches}) _humanVersus(BotLevel level, Iterable<int> seeds) {
  var died = 0, n = 0;
  for (final seed in seeds) {
    final w = GameWorld.battle(humans: 1, bots: 3, seed: seed, botLevel: level);
    final human = BotBrain(Random(seed * 7), BotLevel.normal);
    var time = 0.0;
    var humanDead = false;
    while (w.status == WorldStatus.playing && time < 180) {
      human.update(w, w.players[0], 1 / 60);
      w.tick(1 / 60);
      time += 1 / 60;
      for (final e in w.drainEvents()) {
        if (e.type == GameEventType.playerHit && e.id == 0) humanDead = true;
      }
    }
    n++;
    if (humanDead) died++;
  }
  return (humanDied: died, matches: n);
}

/// One bot against an idle human: the human never bombs, so any bot death is
/// the bot's own doing.
int _loneBotDeaths(BotLevel level, Iterable<int> seeds) {
  var deaths = 0;
  for (final seed in seeds) {
    final w = GameWorld.battle(humans: 1, bots: 1, seed: seed, botLevel: level);
    var time = 0.0;
    while (w.status == WorldStatus.playing && time < 150) {
      w.tick(1 / 60);
      time += 1 / 60;
      for (final e in w.drainEvents()) {
        if (e.type == GameEventType.playerHit && e.id == 1) deaths++;
      }
    }
  }
  return deaths;
}

void main() {
  group('bot difficulty levels', () {
    test('each level is clearly faster, quicker to react and more aggressive than the one below', () {
      const l = BotLevel.values;
      for (var i = 1; i < l.length; i++) {
        expect(l[i].speed, greaterThan(l[i - 1].speed), reason: l[i].name);
        expect(l[i].thinkEvery, lessThan(l[i - 1].thinkEvery), reason: l[i].name);
        expect(l[i].hunt, greaterThanOrEqualTo(l[i - 1].hunt), reason: l[i].name);
        expect(l[i].bombChance, greaterThan(l[i - 1].bombChance), reason: l[i].name);
      }
      expect(BotLevel.easy.speed, lessThan(3.6), reason: 'easy bots are slower than the player');
      expect(BotLevel.hard.speed, greaterThan(3.6), reason: 'hard bots are faster than the player');
    });

    test('bots no longer blow themselves up (any level)', () {
      // Before the rewrite a lone bot died to its own bomb in roughly one match
      // in four (normal) to three (hard).
      for (final level in BotLevel.values) {
        final deaths = _loneBotDeaths(level, List.generate(60, (i) => i + 1));
        expect(deaths, lessThanOrEqualTo(2), reason: '${level.name}: $deaths self-kills in 60 matches');
      }
    });

    test('a decent player is hunted down far more often on hard than on normal than on easy', () {
      final seeds = List.generate(40, (i) => i + 1);
      final easy = _humanVersus(BotLevel.easy, seeds).humanDied;
      final normal = _humanVersus(BotLevel.normal, seeds).humanDied;
      final hard = _humanVersus(BotLevel.hard, seeds).humanDied;
      expect(easy, lessThan(normal), reason: 'easy $easy vs normal $normal');
      expect(normal, lessThan(hard), reason: 'normal $normal vs hard $hard');
      expect(easy, lessThanOrEqualTo(8), reason: 'easy bots are harmless ($easy of 40)');
      expect(hard - easy, greaterThanOrEqualTo(15), reason: 'a clear gap between easy and hard');
    });

    test('bots all start at different moments, not on the very first frame', () {
      final w = GameWorld.battle(humans: 0, bots: 7, seed: 4);
      for (var i = 0; i < 3; i++) {
        w.tick(1 / 60);
      }
      expect(w.bombs, isEmpty, reason: 'nobody drops a bomb in the first instants');
      // Within a few seconds they do get going.
      var bombs = 0;
      for (var i = 0; i < 60 * 8; i++) {
        w.tick(1 / 60);
        bombs += w.drainEvents().where((e) => e.type == GameEventType.bombPlaced).length;
      }
      expect(bombs, greaterThan(3));
    });
  });
}
