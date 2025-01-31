import 'package:brick_breaker/src/components/power_up.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import '../config.dart';
import 'ball.dart';
import 'bat.dart';

class Brick extends RectangleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  Color _currentColor;
  double _timeElapsed = 0.0;

  Brick({required super.position, required Color color})
      : _currentColor = color,
        super(
          size: Vector2(brickWidth, brickHeight),
          anchor: Anchor.center,
          paint: Paint()
            ..color = color
            ..style = PaintingStyle.fill,
          children: [RectangleHitbox()],
        );

  @override
  void update(double dt) {
    super.update(dt);
    _timeElapsed += dt;

    if (_timeElapsed >= 3.0) {
      _shuffleColor();
      _timeElapsed = 0.0; // Reset the timer after each color change
    }
  }

  void _shuffleColor() {
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
    ];

    _currentColor = colors[game.rand.nextInt(colors.length)];

    // Update the brick color
    paint.color = _currentColor;
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    removeFromParent();
    game.score.value++;

    // Chance to spawn a power-up
    if (game.rand.nextDouble() < 0.3) {
      // 30% chance
      final powerUp = PowerUp(
        type: PowerUpType.values[game.rand.nextInt(PowerUpType.values.length)],
        position: position,
        radius: game.size.x * 0.02,
      );
      game.world.add(powerUp);
    }

    if (game.world.children.query<Brick>().length == 1) {
      game.playState = PlayState.won;
      game.world.removeAll(game.world.children.query<Ball>());
      game.world.removeAll(game.world.children.query<Bat>());
    }
  }
}
