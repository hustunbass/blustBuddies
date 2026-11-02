import 'dart:ui';

import 'package:blast_buddies/core/grid/grid_pos.dart';
import 'package:blast_buddies/features/game/application/game_state.dart';
import 'package:blast_buddies/features/game/logic/game_world.dart';
import 'package:blast_buddies/features/game/render/particles.dart';
import 'package:blast_buddies/features/game/ui/blast_game.dart';
import 'package:flame/extensions.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

BlastGame makeGame({int humans = 1, GameWorld? world, void Function(WorldStatus)? onFinished}) =>
    BlastGame(
      sim: world ?? GameWorld.story(level: 1, seed: 3),
      humans: humans,
      onEvent: (_) {},
      onFinished: onFinished ?? (_) {},
    );

void main() {
  group('BlastGame (Flame)', () {
    testWithGame<BlastGame>('keyboard moves the player and bomb key places a bomb', makeGame,
        (game) async {
      final p = game.sim.players.first;
      final x0 = p.x;
      game.onKeyEvent(const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      ), {LogicalKeyboardKey.arrowRight});
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      expect(p.x, greaterThan(x0));
      game.onKeyEvent(const KeyUpEvent(
        physicalKey: PhysicalKeyboardKey.arrowRight,
        logicalKey: LogicalKeyboardKey.arrowRight,
        timeStamp: Duration.zero,
      ), {});
      game.onKeyEvent(const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.space,
        logicalKey: LogicalKeyboardKey.space,
        timeStamp: Duration.zero,
      ), {LogicalKeyboardKey.space});
      game.update(1 / 60);
      expect(game.sim.bombs.length, 1);
      final xStop = p.x;
      game.update(1 / 60);
      expect(p.x, xStop);
    });

    testWithGame<BlastGame>('touch controls drive player 1', makeGame, (game) async {
      game.touchDir = Dir.down;
      game.update(0.05);
      expect(game.sim.players.first.moveDir, Dir.down);
      game.touchBomb();
      game.update(0.02);
      expect(game.sim.bombs, isNotEmpty);
    });

    testWithGame<BlastGame>('renders every frame without throwing', makeGame, (game) async {
      game.onGameResize(Vector2(390, 400));
      game.sim.requestBomb(0);
      for (var i = 0; i < 200; i++) {
        game.update(1 / 60);
        final rec = PictureRecorder();
        game.render(Canvas(rec));
        rec.endRecording();
      }
    });

    testWithGame<BlastGame>('reports finish once when game ends', () {
      return makeGame(
        world: GameWorld.story(level: 1, seed: 1)..timeLeft = 0.1,
        onFinished: (s) => finished.add(s),
      );
    }, (game) async {
      for (var i = 0; i < 20; i++) {
        game.update(1 / 60);
      }
      expect(finished, [WorldStatus.gameOver]);
    });

    testWithGame<BlastGame>('HUD notifier updates only on change', makeGame, (game) async {
      var n = 0;
      game.hud.addListener(() => n++);
      game.update(0.001);
      game.update(0.001);
      expect(n, lessThanOrEqualTo(1));
    });
  });

  test('ParticleSystem is a bounded pool', () {
    final ps = ParticleSystem(capacity: 50);
    for (var i = 0; i < 10; i++) {
      ps.burst(1, 1, 40, const [Color(0xFFFFFFFF)]);
    }
    expect(ps.alive, lessThanOrEqualTo(50));
    for (var i = 0; i < 100; i++) {
      ps.update(0.1);
    }
    expect(ps.alive, 0);
  });

  test('HudState equality', () {
    expect(const HudState(), const HudState());
    expect(const HudState(), isNot(const HudState(score: 5)));
  });
}

final List<WorldStatus> finished = [];
