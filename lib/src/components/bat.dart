import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';

class Bat extends PositionComponent
    with DragCallbacks, HasGameReference<BrickBreaker> {
  Bat({
    required this.cornerRadius,
    required super.position,
    required super.size,
  }) : super(
          anchor: Anchor.center,
          children: [RectangleHitbox()],
        );

  final Radius cornerRadius;

  final Paint _paint = Paint()
    ..color = const Color.fromARGB(255, 0, 95, 150)
    ..style = PaintingStyle.fill;

  late final Vector2 _defaultSize; // Use late initialization

  // Track active size effects
  bool _isEnlargeActive = false;
  bool _isShrinkActive = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // Initialize _defaultSize only after the size is set
    _defaultSize = size.clone();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size.toSize(), cornerRadius),
      _paint,
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    // Check if the game is in the 'gameOver' state
    if (game.playState != PlayState.gameOver) {
      // Clamp both x and y to make the bat draggable within the screen bounds
      position.x = (position.x + event.localDelta.x).clamp(0, game.width);
      position.y = (position.y + event.localDelta.y).clamp(0, game.height);
    }
  }

  void moveBy(double dx) {
    // Check if the game is in the 'gameOver' state
    if (game.playState != PlayState.gameOver) {
      add(MoveToEffect(
        Vector2((position.x + dx).clamp(0, game.width), position.y),
        EffectController(duration: 0.1),
      ));
    }
  }

  void enlargeBat({required double factor, required double duration}) {
    if (_isShrinkActive) {
      // Cancel shrink effect if active
      _isShrinkActive = false;
    }

    if (!_isEnlargeActive) {
      _isEnlargeActive = true;
      add(ScaleEffect.to(
        Vector2(size.x * factor, size.y),
        EffectController(duration: duration, reverseDuration: 0),
        onComplete: () {
          _isEnlargeActive = false;
          _resetIfNoEffectsActive();
        },
      ));
    }
  }

  void shrinkBat({required double factor, required double duration}) {
    if (_isEnlargeActive) {
      // Cancel enlarge effect if active
      _isEnlargeActive = false;
    }

    if (!_isShrinkActive) {
      _isShrinkActive = true;
      add(ScaleEffect.to(
        Vector2(size.x / factor, size.y),
        EffectController(duration: duration, reverseDuration: 0),
        onComplete: () {
          _isShrinkActive = false;
          _resetIfNoEffectsActive();
        },
      ));
    }
  }

  void _resetIfNoEffectsActive() {
    if (!_isEnlargeActive && !_isShrinkActive) {
      size = _defaultSize.clone();
    }
  }
}
