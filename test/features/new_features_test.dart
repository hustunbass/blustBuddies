import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/cosmetics.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/settings/stats.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/logic/bot_brain.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';
import 'package:blast_buddies/net/snapshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GridModel arena() {
  final g = GridModel();
  for (var y = 0; y < GridModel.rows; y++) {
    for (var x = 0; x < GridModel.cols; x++) {
      if (GridModel.isFixedWall(x, y)) g.setType(x, y, CellType.wall);
    }
  }
  return g;
}

void run(GameWorld w, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    w.tick(1 / 60);
  }
}

void main() {
  hudTests();
  group('ghost power-up', () {
    test('walks through crates, never through steel, and does not end inside a crate', () {
      final g = arena()..setType(3, 1, CellType.block);
      final p = Player(id: 0, spawn: const GridPos(1, 1));
      final w = GameWorld.custom(grid: g, players: [p]);
      w.setMove(0, Dir.right);
      run(w, 1.5);
      expect(p.x, lessThan(2.6), reason: 'blocked by the crate without ghost');

      p.stats.apply(PowerUpType.ghost);
      run(w, 1.0);
      expect(p.x, greaterThan(3.4), reason: 'ghost passes the crate');
      // Stop inside the crate cell and let the ghost time run out.
      p.x = 3.5;
      w.setMove(0, Dir.none);
      run(w, PlayerStats.ghostDuration + 1);
      expect(p.stats.ghost, greaterThan(0), reason: 'kept ghost while inside a crate');
      w.setMove(0, Dir.right);
      run(w, 1.0);
      expect(g.typeAt(p.cell.x, p.cell.y), isNot(CellType.block));
    });
  });

  group('detonator', () {
    test('explodes own bombs on request, only with the power-up', () {
      final p = Player(id: 0, spawn: const GridPos(1, 1));
      final w = GameWorld.custom(grid: arena(), players: [p]);
      w.requestBomb(0);
      run(w, 0.1);
      expect(w.bombs, hasLength(1));
      w.requestDetonate(0);
      run(w, 0.1);
      expect(w.bombs, hasLength(1), reason: 'no detonator yet');
      p.stats.apply(PowerUpType.detonator);
      w.requestDetonate(0);
      run(w, 0.1);
      expect(w.bombs, isEmpty);
    });
  });

  group('boss levels', () {
    test('every 25th level has a boss with growing health', () {
      final hp = [
        for (final l in [25, 50, 75, 100]) LevelConfig.forLevel(l).bossHp,
      ];
      expect(hp, [3, 4, 5, 6]);
      expect(LevelConfig.forLevel(24).enemies.containsKey(EnemyType.boss), isFalse);
      expect(GameWorld.story(level: 25, seed: 1).enemies.where((e) => e.type == EnemyType.boss), hasLength(1));
    });

    test('takes several hits, one per flame, and then dies', () {
      final boss = Enemy(type: EnemyType.boss, cell: const GridPos(9, 1), speed: 0, hp: 3);
      final p = Player(id: 0, spawn: const GridPos(1, 9));
      final w = GameWorld.custom(grid: arena(), players: [p], enemies: [boss]);
      for (var hit = 1; hit <= 3; hit++) {
        w.flameTime[1 * GridModel.cols + 9] = 0.5;
        run(w, 0.1);
        expect(boss.hp, 3 - hit);
        run(w, 1.2); // hit cool-down passes
      }
      expect(boss.alive, isFalse);
    });
  });

  group('bots', () {
    test('difficulty changes speed and decisions', () {
      final easy = GameWorld.battle(humans: 1, bots: 1, seed: 1, botLevel: BotLevel.easy);
      final hard = GameWorld.battle(humans: 1, bots: 1, seed: 1, botLevel: BotLevel.hard);
      expect(easy.players[1].stats.speed, lessThan(hard.players[1].stats.speed));
      expect(easy.players[0].stats.speed, PlayerStats().speed, reason: 'humans unchanged');
      expect(BotLevel.easy.thinkEvery, greaterThan(BotLevel.hard.thinkEvery));
    });
  });

  group('daily arena', () {
    test('is stable within a day and changes between days', () {
      final a = GameArgs.dailySeed(DateTime(2026, 11, 9, 8));
      expect(GameArgs.dailySeed(DateTime(2026, 11, 9, 23)), a);
      expect(GameArgs.dailySeed(DateTime(2026, 11, 10)), isNot(a));
      final w1 = const GameArgs.battle(humans: 1, bots: 1, daily: true).buildWorld();
      final w2 = const GameArgs.battle(humans: 1, bots: 1, daily: true).buildWorld();
      expect(w1.themeId, w2.themeId);
      expect(w1.layout, w2.layout);
    });
  });

  group('cosmetics', () {
    test('skins clamp to the catalogue', () {
      final s = Cosmetics.skin(99, -3, 99);
      expect(s.hat, Cosmetics.hats.length - 1);
      expect(s.face, 0);
      expect(s.color, Cosmetics.colors.last.color);
      expect(Cosmetics.skin(0, 0, 0).color, isNull);
    });

    test('the local skin is applied to the player', () {
      final w = GameWorld.story(level: 1, seed: 1, skin: const Skin(hat: 4, face: 2));
      expect(w.players.first.skin.hat, 4);
    });
  });

  group('progress and achievements', () {
    Future<ProviderContainer> container([Map<String, Object> prefs = const {}]) async {
      SharedPreferences.setMockInitialValues(prefs);
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(sp)]);
      addTearDown(c.dispose);
      return c;
    }

    test('best star rating per level is kept and persisted', () async {
      final c = await container();
      final n = c.read(progressProvider.notifier);
      await n.recordStars(1, 2);
      await n.recordStars(1, 1);
      await n.recordStars(2, 3);
      expect(c.read(progressProvider).stars, {1: 2, 2: 3});
      expect(c.read(progressProvider).totalStars, 5);
      expect(c.read(progressProvider).perfectLevels, 1);
      expect(c.read(prefsProvider).getString('stars'), '1:2,2:3');
      final again = await container({'stars': '1:2,2:3'});
      expect(again.read(progressProvider).totalStars, 5);
    });

    test('counters unlock achievements exactly once', () async {
      final c = await container();
      final s = c.read(statsProvider.notifier);
      final first = await s.add({'kills': 1, 'games': 1});
      expect(first.map((a) => a.id), containsAll(['kills_1', 'games_1']));
      expect(await s.add({'kills': 1}), isEmpty);
      final more = await s.add({'kills': 120});
      expect(more.map((a) => a.id), ['kills_10', 'kills_50', 'kills_100']);
      expect(c.read(statsProvider).unlocked, containsAll(['kills_1', 'kills_100']));
      expect(c.read(prefsProvider).getInt('stat_kills'), 122);
    });

    test('star based achievements follow story progress', () async {
      final c = await container();
      for (var l = 1; l <= 10; l++) {
        await c.read(progressProvider.notifier).recordStars(l, 3);
      }
      final fresh = await c.read(statsProvider.notifier).check();
      expect(fresh.map((a) => a.id), containsAll(['stars_30', 'perfect_10']));
    });

    test('there are at least 100 uniquely identified achievements with tiered rewards', () {
      expect(achievements.length, greaterThanOrEqualTo(100));
      expect(achievements.map((a) => a.id).toSet().length, achievements.length);
      // Within a series goals grow strictly and rewards never shrink.
      final byStat = <String, List<Achievement>>{};
      for (final a in achievements) {
        byStat.putIfAbsent(a.stat, () => []).add(a);
      }
      for (final list in byStat.values) {
        for (var i = 1; i < list.length; i++) {
          expect(list[i].goal, greaterThan(list[i - 1].goal));
          expect(list[i].tier.index, greaterThanOrEqualTo(list[i - 1].tier.index));
          expect(list[i].rank, i + 1);
        }
      }
      expect(AchTier.easy.coins < AchTier.medium.coins && AchTier.hard.coins < AchTier.legend.coins, isTrue);
    });

    test('rewards are paid once and only for unlocked achievements', () async {
      final c = await container({'walletInit': true, 'coin': 0});
      final s = c.read(statsProvider.notifier);
      final kills1 = achievements.firstWhere((a) => a.id == 'kills_1');
      final kills10 = achievements.firstWhere((a) => a.id == 'kills_10');
      expect(await s.claim(kills1), 0); // locked
      await s.add({'kills': 1});
      expect(s.claimable.map((a) => a.id), ['kills_1']);
      expect(await s.claim(kills1), kills1.reward);
      expect(await s.claim(kills1), 0); // already claimed
      await s.add({'kills': 9});
      expect(await s.claimAll(), kills10.reward);
      expect(c.read(walletProvider).coin, kills1.reward + kills10.reward);
      expect(c.read(statsProvider).claimed, {'kills_1', 'kills_10'});
      final again = await container({'walletInit': true, 'coin': c.read(walletProvider).coin, 'ach': ['kills_1', 'kills_10'], 'achClaimed': ['kills_1', 'kills_10']});
      expect(again.read(statsProvider.notifier).claimable, isEmpty);
    });

    test('buying cosmetics counts towards the wardrobe achievements', () async {
      final c = await container({'walletInit': true, 'coin': 500});
      await c.read(walletProvider.notifier).buy('hat:1', 30);
      final fresh = await c.read(statsProvider.notifier).check();
      expect(fresh.map((a) => a.id), ['owned_1']);
    });
  });

  test('snapshots carry ghost time and the detonator', () {
    final server = GameWorld.battle(humans: 2, bots: 0, seed: 3);
    server.players[0].stats
      ..apply(PowerUpType.ghost)
      ..apply(PowerUpType.detonator);
    final client = GameWorld.battle(humans: 2, bots: 0, seed: 3);
    applySnapshot(client, encodeSnapshot(server, const [], serverTime: 1.5));
    expect(client.players[0].stats.ghost, closeTo(PlayerStats.ghostDuration, 0.01));
    expect(client.players[0].stats.canDetonate, isTrue);
    expect(client.players[1].stats.canDetonate, isFalse);
  });
}

void hudTests() {
  test('HUD follows the local online slot, so slot 2 sees its own detonator', () {
    final w = GameWorld.battle(humans: 2, bots: 0, seed: 5);
    w.players[1].stats.apply(PowerUpType.detonator);
    expect(HudState.from(w).detonate, isFalse);
    expect(HudState.from(w, 1).detonate, isTrue);
  });
}
