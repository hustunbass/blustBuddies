import 'dart:math';

import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/core/grid/map_generator.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('start cells', () {
    test('seven distinct, open cells; the first four are the classic corners', () {
      expect(MapGenerator.spawnPoints.length, MapGenerator.maxPlayers);
      expect(MapGenerator.spawnPoints.toSet().length, 7);
      expect(MapGenerator.spawnPoints.take(4).toList(), MapGenerator.corners);
      for (final p in MapGenerator.spawnPoints) {
        expect(GridModel.isFixedWall(p.x, p.y), isFalse, reason: '$p is a pillar');
      }
    });

    test('every layout keeps every start area free and connected, for 2..7 players', () {
      for (final layout in MapLayout.values) {
        for (var seed = 0; seed < 25; seed++) {
          for (var players = 2; players <= MapGenerator.maxPlayers; players++) {
            final map = MapGenerator.generate(
              rng: Random(seed),
              withExit: false,
              layout: layout,
              players: players,
            );
            final reason = '$layout seed $seed players $players';
            expect(map.spawns.length, max(4, players), reason: reason);
            for (final s in map.spawns) {
              for (final c in MapGenerator.safeZoneOf(s)) {
                expect(map.grid.typeAt(c.x, c.y), CellType.empty, reason: '$reason start $s cell $c');
              }
            }
            // Every start can reach every other one (blocks can be blasted,
            // pillars cannot be crossed).
            final seen = <GridPos>{map.spawns.first};
            final todo = [map.spawns.first];
            while (todo.isNotEmpty) {
              final c = todo.removeLast();
              for (final n in [GridPos(c.x + 1, c.y), GridPos(c.x - 1, c.y), GridPos(c.x, c.y + 1), GridPos(c.x, c.y - 1)]) {
                if (map.grid.typeAt(n.x, n.y) != CellType.wall && seen.add(n)) todo.add(n);
              }
            }
            expect(map.spawns.every(seen.contains), isTrue, reason: reason);
          }
        }
      }
    });

    test('maps of 2..4 players are unchanged by the new start cells', () {
      for (var seed = 0; seed < 10; seed++) {
        final a = MapGenerator.generate(rng: Random(seed), withExit: false);
        final b = MapGenerator.generate(rng: Random(seed), withExit: false, players: 4);
        expect([for (var y = 0; y < GridModel.rows; y++) for (var x = 0; x < GridModel.cols; x++) a.grid.typeAt(x, y)],
            [for (var y = 0; y < GridModel.rows; y++) for (var x = 0; x < GridModel.cols; x++) b.grid.typeAt(x, y)]);
      }
    });
  });

  group('battle with up to seven buddies', () {
    test('every player count from 2 to 7 is supported, more is clamped', () {
      for (var n = 2; n <= 7; n++) {
        final w = GameWorld.battle(humans: 1, bots: n - 1, seed: n);
        expect(w.players.length, n);
        expect({for (final p in w.players) p.spawn}.length, n);
      }
      expect(GameWorld.battle(humans: 1, bots: 12, seed: 1).players.length, 7);
    });

    test('teams stay a four-player option', () {
      expect(GameWorld.battle(humans: 1, bots: 6, seed: 1, teams: true).teams, isFalse);
      expect(GameWorld.battle(humans: 1, bots: 3, seed: 1, teams: true).teams, isTrue);
    });

    test('seven bots fight without trouble and every one of them moves', () {
      for (var seed = 0; seed < 12; seed++) {
        final w = GameWorld.battle(humans: 0, bots: 7, seed: seed);
        final start = [for (final p in w.players) (p.x, p.y)];
        final moved = List<bool>.filled(7, false);
        var bombs = 0;
        for (var i = 0; i < 60 * 20; i++) {
          w.tick(1 / 60);
          bombs += w.drainEvents().where((e) => e.type == GameEventType.bombPlaced).length;
          for (final p in w.players) {
            if ((p.x, p.y) != start[p.id]) moved[p.id] = true;
          }
        }
        expect(bombs, greaterThan(5), reason: 'seed $seed');
        for (final p in w.players) {
          // (A bot may wander back to its start cell, so check "ever moved".)
          expect(moved[p.id], isTrue, reason: 'seed $seed bot ${p.id}');
        }
      }
    });
  });

  test('room shapes: 2..7 players, teams only with exactly four', () {
    for (var n = 2; n <= 7; n++) {
      expect(validRoomShape(n, false), isTrue, reason: '$n');
    }
    expect(validRoomShape(1, false), isFalse);
    expect(validRoomShape(8, false), isFalse);
    expect(validRoomShape(4, true), isTrue);
    expect(validRoomShape(6, true), isFalse);
  });
}
