import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import 'ball.dart';
import 'bat.dart';

enum PowerUpType {
  enlargeBat,
  shrinkBat,
  slowBall,
  multiplyBalls,
  gameOverRedBall
}

class PowerUp extends CircleComponent
    with CollisionCallbacks, HasGameReference<BrickBreaker> {
  PowerUp({
    required this.type,
    required super.position,
    required double radius,
  }) : super(
          radius: radius,
          anchor: Anchor.center,
          paint: Paint()
            ..color = _getPowerUpColor(type)
            ..style = PaintingStyle.fill,
          children: [CircleHitbox()],
        );

  final PowerUpType type;

  static final Map<PowerUpType, int> powerUpCounts = {};

  @override
  void update(double dt) {
    super.update(dt);
    position.y += 200 * dt; // Power-ups fall down at a constant speed.

    if (position.y > game.size.y) {
      removeFromParent(); // Remove if it goes off-screen.
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Bat) {
      if (type == PowerUpType.gameOverRedBall) {
        // Trigger game over if red power-up is caught.
        game.gameOver(); // This will call the gameOver method in BrickBreaker
      } else {
        applyEffect();
      }
      removeFromParent(); // Remove the power-up after it has been used.
    }
    super.onCollision(intersectionPoints, other);
  }

  void applyEffect() {
    switch (type) {
      case PowerUpType.enlargeBat:
        _applyBatEffect(1.5, duration: 5);
        break;
      case PowerUpType.shrinkBat:
        _applyBatEffect(0.5, duration: 5);
        break;
      case PowerUpType.slowBall:
        _applySlowBall();
        break;
      case PowerUpType.multiplyBalls:
        _multiplyBalls(3);
        break;
      case PowerUpType.gameOverRedBall:
        // Game over will be handled in onCollision
        break;
    }
  }

  void _applyBatEffect(double scaleFactor, {required int duration}) {
    final bat = game.world.children.query<Bat>().first;
    final originalWidth = bat.size.x;
    bat.size.x *= scaleFactor;

    Future.delayed(Duration(seconds: duration), () {
      if (bat.isMounted) bat.size.x = originalWidth;
    });
  }

  void _applySlowBall() {
    final ball = game.world.children.query<Ball>().first;
    ball.velocity.scale(0.5);
    Future.delayed(const Duration(seconds: 5), () {
      ball.velocity.scale(2.0); // Reset the ball speed.
    });
  }

  void _multiplyBalls(int factor) {
    final existingBalls = game.world.children.query<Ball>();
    for (final ball in existingBalls) {
      for (int i = 0; i < factor - 1; i++) {
        final newBall = Ball(
          velocity: ball.velocity.clone()..scale(1 + 0.2 * i),
          position: ball.position.clone(),
          radius: ball.radius,
          difficultyModifier: ball.difficultyModifier,
        );
        game.world.add(newBall);
      }
    }
  }

  static Color _getPowerUpColor(PowerUpType type) {
    switch (type) {
      case PowerUpType.enlargeBat: //  Bat Enlargement
        return Colors.greenAccent;
      case PowerUpType.shrinkBat:
        return const Color.fromARGB(255, 0, 0, 0);
      case PowerUpType.slowBall: // Slow the Ball
        return Colors.blueAccent;
      case PowerUpType.multiplyBalls: // Multiply the Ball
        return Colors.orangeAccent;
      case PowerUpType.gameOverRedBall:
        return Colors.red; // Red color for the "game over" power-up
      // Removed fireball color case
      // ignore: unreachable_switch_default
      default:
        return Colors.purple;
    }
  }

  static bool canSpawn(PowerUpType type) {
    final currentCount = powerUpCounts[type] ?? 0;
    return currentCount <
        3; // Allow spawning only if there are fewer than 3 power-ups of the same type.
  }

  static void incrementPowerUpCount(PowerUpType type) {
    powerUpCounts[type] = (powerUpCounts[type] ?? 0) + 1;
  }

  static void decrementPowerUpCount(PowerUpType type) {
    powerUpCounts[type] = (powerUpCounts[type] ?? 1) - 1;
    if (powerUpCounts[type]! <= 0) {
      powerUpCounts.remove(type);
    }
  }
}

extension on BrickBreaker {
  // ignore: unused_element
  void gameOver() {
    playState = PlayState.gameOver;
    overlays.add(PlayState.gameOver.name); // Show the Game Over overlay
  }

  // Call this method to spawn a power-up, ensuring the limit is respected.
  // ignore: unused_element
  void spawnPowerUp(PowerUpType type, Vector2 position, double radius) {
    if (PowerUp.canSpawn(type)) {
      final powerUp = PowerUp(type: type, position: position, radius: radius);
      PowerUp.incrementPowerUpCount(type); // Increase count for this type
      world.add(powerUp);
    }
  }
}
