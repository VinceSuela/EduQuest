import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_pomodoro/games/snake/constant.dart';

class Food extends SpriteComponent {
  Vector2 location;

  Food({required this.location})
    : super(size: .all(gridSize), anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    sprite = await Sprite.load('snake/food.png');
    position = Vector2(location.x * gridSize, location.y * gridSize);
  }

  void updatePosition(Vector2 newPosition) {
    location = newPosition;
    position = Vector2(location.x * gridSize, location.y * gridSize);
  }
}
