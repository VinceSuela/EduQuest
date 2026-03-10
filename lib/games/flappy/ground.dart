import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter_pomodoro/games/flappy/constant.dart';

class Ground extends SpriteComponent with CollisionCallbacks {
  double groundX = 0; // X position of the ground
  bool isMoving = false; // Flag to control movement

  Ground()
    : super(
        anchor: Anchor.bottomCenter,
        size: Vector2(336, 112),
        position: Vector2(0, 512 / 2),
      );

  @override
  Future<void> onLoad() async {
    // 336x112
    sprite = await Sprite.load('flappy/base.png');
    add(RectangleHitbox());

    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isMoving) {
      position.x -= worldSpeed * dt;
    }
    // Move the world to the left at a speed of 100 pixels per second

    if (position.x <= -12) {
      position.x = 12; // Reset the world position to create a looping effect
    }
  }

  void start() {
    isMoving = true;
  }

  void stop() {
    isMoving = false;
  }
}
