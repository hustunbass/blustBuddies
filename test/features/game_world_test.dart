import 'package:blast_buddies/core/combat/powerups.dart';
import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/entities.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/logic/level_config.dart';
import 'package:flutter_test/flutter_test.dart';

GridModel arena() {
  final g = GridModel();
  for (var y = 0; y < GridModel.rows; y++) {
    for (var x = 0; x < GridModel.cols; x++) {
      if (GridModel.isFixedWall(x, y)) g.setType(x, y, CellType.wall);
    }
  }
  return g;
}

GameWorld world({
  GridModel? grid,
  List<Player>? players,
  List<Enemy> enemies = const [],
  GridPos? exit,
  GameMode mode = GameMode.story,
}) =>
    GameWorld.custom(
      grid: grid ?? arena(),
      players: players ?? [Player(id: 0, spawn: const GridPos(1, 1))],
      enemies: enemies,
      exit: exit,
      mode: mode,
    );

void run(GameWorld w, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    w.tick(1 / 60);
  }
}

void main() {
  group('player movement', () {
    test('moves in 4 directions at its speed', () {
      final w = world();
      final p = w.players.first;
      w.setMove(0, Dir.right);
      run(w, 0.5);
      expect(p.x, closeTo(1.5 + 0.5 * p.stats.speed, 0.1));
      w.setMove(0, Dir.down);
      run(w, 0.25);
      expect(p.y, greaterThan(1.5));
    });

    test('cannot pass walls', () {
      final w = world();
      final p = w.players.first;
      w.setMove(0, Dir.left);
      run(w, 2);
      expect(p.x, greaterThanOrEqualTo(1 + GameWorld.half - 0.001));
      w.setMove(0, Dir.up);
      run(w, 2);
      expect(p.y, greaterThanOrEqualTo(1 + GameWorld.half - 0.001));
    });

    test('cannot pass breakable blocks', () {
      final g = arena()..setType(3, 1, CellType.block);
      final w = world(grid: g);
      w.setMove(0, Dir.right);
      run(w, 3);
      expect(w.players.first.x, lessThan(3 - GameWorld.half + 0.001));
    });

    test('slides around a corner when slightly off-lane', () {
      final w = world();
      final p = w.players.first..x = 2.5..y = 1.5;
      w.setMove(0, Dir.down);
      run(w, 0.2);
      // (2,2) is a wall: column 2 is blocked, but player is centred so stays.
      expect(p.y, lessThanOrEqualTo(2 - GameWorld.half + 0.01));
      p
        ..x = 2.9
        ..y = 1.5;
      run(w, 1.0);
      expect(p.x, greaterThan(2.9)); // nudged into column 3 lane
      expect(p.y, greaterThan(2.0));
    });
  });

  group('bombs', () {
    test('explodes after 3 seconds and kills the owner outside shelter', () {
      final w = world();
      w.requestBomb(0);
      run(w, 0.1);
      expect(w.bombs.length, 1);
      run(w, 2.8);
      expect(w.bombs.length, 1);
      run(w, 0.3);
      expect(w.bombs, isEmpty);
      expect(w.players.first.lives, 2);
    });

    test('respects maxBombs and one bomb per cell', () {
      final w = world();
      w.requestBomb(0);
      run(w, 0.05);
      w.requestBomb(0);
      run(w, 0.05);
      expect(w.bombs.length, 1);
    });

    test('owner can walk off a fresh bomb, then it is solid', () {
      final w = world();
      final p = w.players.first;
      w.requestBomb(0);
      w.setMove(0, Dir.right);
      run(w, 0.6);
      expect(p.x, greaterThan(2.9));
      w.setMove(0, Dir.left);
      run(w, 1);
      expect(p.x, greaterThan(2 + GameWorld.half - 0.01)); // blocked by bomb at col 1
    });

    test('destroys blocks and stops at walls', () {
      final g = arena()..setType(3, 1, CellType.block);
      final w = world(grid: g, players: [Player(id: 0, spawn: const GridPos(1, 1))]);
      final p = w.players.first..x = 1.5;
      w.requestBomb(0);
      run(w, 0.05);
      // Hide: put the player away so it survives.
      p
        ..x = 9.5
        ..y = 9.5;
      run(w, 3.1);
      expect(w.grid.typeAt(3, 1), CellType.empty);
      expect(w.grid.typeAt(2, 2), CellType.wall);
      expect(w.players.first.score, 10);
    });

    test('chain reaction triggers other bombs immediately', () {
      final w = world(players: [
        Player(id: 0, spawn: const GridPos(1, 1)),
        Player(id: 1, spawn: const GridPos(11, 9)),
      ]);
      w.players[0]
        ..stats.maxBombs = 2
        ..x = 1.5
        ..y = 1.5;
      w.requestBomb(0);
      run(w, 0.05);
      w.players[0].x = 3.5;
      w.requestBomb(0);
      run(w, 0.05);
      expect(w.bombs.length, 2);
      w.bombs.first.fuse = 0.01; // trigger the first only
      w.players[0]
        ..x = 9.5
        ..y = 9.5;
      run(w, 0.1);
      expect(w.bombs, isEmpty);
    });

    test('kick slides a bomb until blocked', () {
      final w = world();
      final p = w.players.first
        ..stats.canKick = true
        ..x = 4.5
        ..y = 1.5;
      w.bombs.add(Bomb(col: 5, row: 1, range: 1, ownerId: 0, passIds: {}));
      p.activeBombs = 1;
      w.setMove(0, Dir.right);
      run(w, 0.5);
      w.setMove(0, Dir.none);
      expect(w.bombs.first.slideDir, isNot(Dir.none));
      run(w, 1.2);
      expect(w.bombs.first.col, 11);
    });

    test('shield prevents damage', () {
      final w = world();
      w.players.first.stats.apply(PowerUpType.shield);
      w.requestBomb(0);
      run(w, 3.2);
      expect(w.players.first.lives, 3);
    });
  });

  group('power-ups', () {
    test('are collected and applied', () {
      final w = world();
      w.powerUps[const GridPos(2, 1)] = PowerUpType.range;
      w.setMove(0, Dir.right);
      run(w, 0.5);
      expect(w.powerUps, isEmpty);
      expect(w.players.first.stats.range, 3);
    });

    test('are destroyed by blasts', () {
      final w = world();
      w.powerUps[const GridPos(1, 3)] = PowerUpType.bomb;
      w.bombs.add(Bomb(col: 1, row: 4, range: 2, ownerId: 0, passIds: {}, fuse: 0.01));
      w.players.first.activeBombs = 1;
      run(w, 0.1);
      expect(w.powerUps, isEmpty);
    });
  });

  group('enemies', () {
    test('wanderer moves and never enters solid cells', () {
      final e = Enemy(type: EnemyType.wanderer, cell: const GridPos(5, 5), speed: 2);
      final w = world(enemies: [e]);
      w.players.first
        ..x = 1.5
        ..y = 1.5;
      for (var i = 0; i < 1200; i++) {
        w.tick(1 / 60);
        expect(w.grid.isSolid(e.x.floor(), e.y.floor()), isFalse);
      }
    });

    test('chaser approaches the player', () {
      final e = Enemy(type: EnemyType.chaser, cell: const GridPos(9, 1), speed: 2);
      final w = world(enemies: [e]);
      w.players.first.stats.shield = 999;
      final d0 = (e.x - 1.5).abs();
      run(w, 2);
      expect((e.x - w.players.first.x).abs(), lessThan(d0 - 2));
    });

    test('blast kills enemies and awards points', () {
      final e = Enemy(type: EnemyType.chaser, cell: const GridPos(3, 1), speed: 0.01);
      final w = world(enemies: [e]);
      w.players.first.stats.shield = 99;
      w.requestBomb(0);
      run(w, 3.2);
      expect(e.alive, isFalse);
      expect(w.players.first.score, greaterThanOrEqualTo(200));
    });

    test('touching an enemy costs a life', () {
      final e = Enemy(type: EnemyType.wanderer, cell: const GridPos(1, 1), speed: 0.01);
      final w = world(enemies: [e]);
      run(w, 0.1);
      expect(w.players.first.lives, 2);
      expect(w.players.first.invuln, greaterThan(0));
    });
  });

  group('exit and level flow', () {
    test('exit opens when all enemies die and completes the level', () {
      final g = arena()..setType(3, 1, CellType.block);
      final e = Enemy(type: EnemyType.wanderer, cell: const GridPos(9, 9), speed: 0.01);
      final w = world(grid: g, enemies: [e], exit: const GridPos(3, 1));
      final p = w.players.first;
      p.stats.shield = 999;
      w.requestBomb(0);
      run(w, 3.2);
      expect(w.exitRevealed, isTrue);
      expect(w.exitOpen, isFalse);
      expect(w.status, WorldStatus.playing);
      e.alive = false;
      p
        ..x = 3.5
        ..y = 1.5;
      run(w, 0.1);
      expect(w.status, WorldStatus.levelComplete);
      expect(p.score, greaterThan(500));
    });

    test('game over when lives run out', () {
      final w = world();
      final p = w.players.first
        ..lives = 1;
      w.requestBomb(0);
      run(w, 3.2);
      expect(p.alive, isFalse);
      expect(w.status, WorldStatus.gameOver);
    });

    test('game over when time runs out', () {
      final w = GameWorld.custom(
        grid: arena(),
        players: [Player(id: 0, spawn: const GridPos(1, 1))],
        timeLeft: 0.2,
      );
      run(w, 0.5);
      expect(w.status, WorldStatus.gameOver);
    });

    test('level configs get harder and there are at least 10', () {
      expect(LevelConfig.totalLevels, greaterThanOrEqualTo(100));
      var prev = 0.0;
      for (var l = 1; l <= LevelConfig.totalLevels; l++) {
        final c = LevelConfig.forLevel(l);
        expect(c.enemySpeedScale, greaterThan(prev));
        expect(c.enemyCount, lessThanOrEqualTo(10));
        prev = c.enemySpeedScale;
      }
      expect(LevelConfig.forLevel(1).enemies[EnemyType.chaser], 0);
      expect(LevelConfig.forLevel(100).enemies[EnemyType.chaser], greaterThan(0));
      expect(LevelConfig.forLevel(100).enemies[EnemyType.speedster], greaterThan(0));
    });

    test('story factory builds a playable level with all enemy types', () {
      final w = GameWorld.story(level: 40, seed: 4);
      expect(w.enemies.length, LevelConfig.forLevel(40).enemyCount);
      expect(w.enemies.map((e) => e.type).toSet().length, 3);
      expect(w.status, WorldStatus.playing);
    });
  });

  group('battle', () {
    test('last survivor wins', () {
      final w = world(
        mode: GameMode.battle,
        players: [
          Player(id: 0, spawn: const GridPos(1, 1), lives: 1),
          Player(id: 1, spawn: const GridPos(11, 9), lives: 1),
        ],
      );
      w.requestBomb(0);
      run(w, 3.2);
      expect(w.status, WorldStatus.battleOver);
      expect(w.winnerId, 1);
    });

    test('bots survive and place bombs without suiciding quickly', () {
      final w = GameWorld.battle(humans: 0, bots: 4, seed: 11);
      var bombsSeen = 0;
      for (var i = 0; i < 60 * 30; i++) {
        w.tick(1 / 60);
        bombsSeen += w.drainEvents().where((e) => e.type == GameEventType.bombPlaced).length;
      }
      expect(bombsSeen, greaterThan(5));
      expect(w.players.where((p) => p.alive).length, greaterThanOrEqualTo(2));
    });

    test('bot in a boxed-in spawn corner still starts moving', () {
      final g = arena()
        ..setType(3, 1, CellType.block)
        ..setType(1, 3, CellType.block);
      final w = world(
        grid: g,
        mode: GameMode.battle,
        players: [
          Player(id: 0, spawn: const GridPos(1, 1), isBot: true, lives: 1),
          Player(id: 1, spawn: const GridPos(11, 9), lives: 1),
        ],
      );
      var bombs = 0;
      for (var i = 0; i < 60 * 3; i++) {
        w.tick(1 / 60);
        bombs += w.drainEvents().where((e) => e.type == GameEventType.bombPlaced).length;
      }
      expect(bombs, greaterThan(0));
      expect(w.players.first.alive, isTrue);
    });

    test('every bot moves within the first seconds', () {
      for (var seed = 0; seed < 40; seed++) {
        final w = GameWorld.battle(humans: 1, bots: 3, seed: seed);
        final start = [for (final p in w.players) (p.x, p.y)];
        run(w, 3);
        for (final p in w.players.where((p) => p.isBot)) {
          expect((p.x, p.y), isNot(start[p.id]), reason: 'seed $seed bot ${p.id}');
        }
      }
    });
  });
}
