import 'dart:convert';

import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/net/online_client.dart';
import 'package:blast_buddies/net/protocol.dart';
import 'package:blast_buddies/net/snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

/// Server world + client mirror connected by a link with [oneWay] latency.
class _Link {
  _Link() {
    client = OnlineMatch(
      seed: seed,
      capacity: 2,
      teams: false,
      localId: 0,
      names: const ['A', 'B'],
      send: (m) => _up.add((t + oneWay, m)),
      latency: () => oneWay * 2,
    );
  }

  static const seed = 7;
  final double oneWay = 0.1;
  final server = GameWorld.battle(humans: 2, bots: 0, seed: seed);
  late final OnlineMatch client;
  final _up = <(double, Map<String, dynamic>)>[];
  final _down = <(double, Map<String, dynamic>)>[];
  double t = 0;
  int _ticks = 0;

  void step([double dt = 1 / 60]) {
    t += dt;
    while (_up.isNotEmpty && _up.first.$1 <= t) {
      final m = _up.removeAt(0).$2;
      if (m['t'] == Msg.input) server.setMove(0, Dir.values[m['d'] as int]);
    }
    server.tick(dt);
    if (++_ticks % 2 == 0) {
      final snap = jsonDecode(jsonEncode(encodeSnapshot(server, server.drainEvents()))) as Map<String, dynamic>;
      _down.add((t + oneWay, snap));
    }
    while (_down.isNotEmpty && _down.first.$1 <= t) {
      client.apply(_down.removeAt(0).$2);
    }
    client.advance(dt);
  }

  double get cx => client.world.players[0].x;
  double get cy => client.world.players[0].y;
  double get sx => server.players[0].x;
  double get sy => server.players[0].y;
}

void main() {
  test('local player moves immediately and converges with the server', () {
    final l = _Link();
    for (var i = 0; i < 20; i++) {
      l.step();
    }
    final y0 = l.cy;
    l.client.move(Dir.down);
    l.step();
    expect(l.cy, greaterThan(y0), reason: 'predicted move on the first frame');
    expect(l.sy, closeTo(y0, 1e-9), reason: 'server has not seen the input yet');

    var prev = l.cy;
    for (var i = 0; i < 30; i++) {
      l.step();
      expect(l.cy, greaterThanOrEqualTo(prev - 1e-3), reason: 'no rubber-banding');
      prev = l.cy;
    }
    l.client.move(Dir.none);
    for (var i = 0; i < 60; i++) {
      l.step();
    }
    expect(l.cx, closeTo(l.sx, 0.02));
    expect(l.cy, closeTo(l.sy, 0.02));
  });

  test('large disagreement snaps the local player to the server', () {
    final l = _Link();
    for (var i = 0; i < 20; i++) {
      l.step();
    }
    l.server.players[0]
      ..x = 5.5
      ..y = 5.5;
    for (var i = 0; i < 30; i++) {
      l.step();
    }
    expect(l.cx, closeTo(5.5, 0.02));
    expect(l.cy, closeTo(5.5, 0.02));
  });

  test('other players are still smoothed from snapshots', () {
    final l = _Link();
    for (var i = 0; i < 20; i++) {
      l.step();
    }
    l.server.setMove(1, Dir.up);
    for (var i = 0; i < 60; i++) {
      l.step();
    }
    final other = l.client.world.players[1];
    expect(other.y, lessThan(l.server.players[1].y + 1));
    l.server.setMove(1, Dir.none);
    for (var i = 0; i < 60; i++) {
      l.step();
    }
    expect(other.x, closeTo(l.server.players[1].x, 0.02));
    expect(other.y, closeTo(l.server.players[1].y, 0.02));
  });
}
