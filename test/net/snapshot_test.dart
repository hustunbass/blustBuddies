import 'dart:convert';

import 'package:blast_buddies/core/grid/grid_model.dart';
import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/net/snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snapshot round-trips the visible world state through JSON', () {
    final server = GameWorld.battle(humans: 4, bots: 0, seed: 11, teams: true);
    final client = GameWorld.battle(humans: 4, bots: 0, seed: 11, teams: true);
    server.setMove(0, Dir.right);
    for (var i = 0; i < 20; i++) {
      server.tick(1 / 60);
    }
    server.requestBomb(1);
    server.tick(1 / 60);
    server.players[2].stats.canKick = true;
    server.grid.setType(3, 3, CellType.empty);
    server.flameTime[5 * GridModel.cols + 5] = 0.3;
    final events = server.drainEvents();

    final wire = jsonDecode(jsonEncode(encodeSnapshot(server, events))) as Map<String, dynamic>;
    applySnapshot(client, wire);

    for (var i = 0; i < 4; i++) {
      expect(client.players[i].x, closeTo(server.players[i].x, 0.01));
      expect(client.players[i].y, closeTo(server.players[i].y, 0.01));
      expect(client.players[i].alive, server.players[i].alive);
    }
    expect(client.players[0].moveDir, Dir.right);
    expect(client.players[2].stats.canKick, isTrue);
    expect(client.bombs.single.cell, server.bombs.single.cell);
    expect(client.bombs.single.ownerId, 1);
    expect(client.grid.typeAt(3, 3), CellType.empty);
    expect(client.isBurning(5, 5), isTrue);
    expect(client.timeLeft, closeTo(server.timeLeft, 0.01));
    expect(client.drainEvents().map((e) => e.type), events.map((e) => e.type));
  });

  test('2v2: teammates share a team and the last team standing wins', () {
    final w = GameWorld.battle(humans: 1, bots: 3, seed: 5, teams: true);
    expect(w.teams, isTrue);
    expect([for (final p in w.players) p.teamId], [0, 1, 0, 1]);
    w.players[1].alive = false;
    w.tick(0.01);
    expect(w.status, WorldStatus.playing, reason: 'team 1 still has player 3');
    w.players[3].alive = false;
    w.tick(0.01);
    expect(w.status, WorldStatus.battleOver);
    expect(w.winnerTeam, 0);
    expect([0, 2], contains(w.winnerId));
  });

  test('teams are ignored unless there are four players', () {
    final w = GameWorld.battle(humans: 1, bots: 2, seed: 5, teams: true);
    expect(w.teams, isFalse);
    expect([for (final p in w.players) p.teamId], [0, 1, 2]);
  });

  test('free-for-all winner team equals winner id', () {
    final w = GameWorld.battle(humans: 2, bots: 1, seed: 2);
    w.players[0].alive = false;
    w.players[2].alive = false;
    w.tick(0.01);
    expect(w.winnerId, 1);
    expect(w.winnerTeam, 1);
  });
}
