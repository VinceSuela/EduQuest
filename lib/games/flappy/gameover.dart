import 'package:flame/components.dart';
import 'package:flutter_pomodoro/games/flappy/constant.dart';

class Gameover extends SpriteComponent {
  bool isGameover = false;
  double targetY = -42;

  Gameover()
    : super(
        anchor: Anchor.bottomCenter,
        size: Vector2(192, 42),
        position: Vector2(0, -512 / 2),
      );

  @override
  Future<void> onLoad() async {
    // 192x42
    sprite = await Sprite.load('flappy/gameover.png');

    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameover && position.y < targetY) {
      position.y += 1500 * dt;
    }
  }

  void toggle(bool visible) {
    isGameover = visible;
    if (!visible) {
      position.y = gameScreen.y * -0.5;
    }
  }
}
