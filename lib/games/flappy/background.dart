import 'package:flame/components.dart';

class Background extends SpriteComponent {
  Background() : super(size: Vector2(288, 512));
  late Sprite day;
  late Sprite night;

  @override
  Future<void> onLoad() async {
    // 288x512
    day = await Sprite.load('flappy/background-day.png');
    night = await Sprite.load('flappy/background-night.png');

    sprite = day;
  }

  void setTime(bool timeOfDay) {
    sprite = timeOfDay ? day : night;
  }
}
