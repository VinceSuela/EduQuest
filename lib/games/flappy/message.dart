import 'package:flame/components.dart';
import 'package:flutter_pomodoro/games/flappy/constant.dart';

class Message extends SpriteComponent {
  bool isVisible = true;
  double targetY = 0;
  double intialY = 0;
  double hiddenY = (gameScreen.y + 267) * 0.5;

  Message()
    : super(
        anchor: Anchor.center,
        size: Vector2(184, 267),
        position: Vector2(0, gameScreen.y / 2),
      );

  @override
  Future<void> onLoad() async {
    // 184x267
    sprite = await Sprite.load('flappy/message.png');

    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isVisible && position.y > targetY) {
      position.y -= 1000 * dt;
    }
  }

  void toggle(bool visible) {
    isVisible = visible;
    if (!visible) {
      position.y = hiddenY;
    }
  }
}
