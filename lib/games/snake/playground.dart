import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/games/snake/constant.dart';
import 'package:flutter_pomodoro/games/snake/world.dart';

class Playground extends RectangleComponent
    with TapCallbacks, HasWorldReference {
  Playground()
    : super(
        size: Vector2((gridCountX - 1) * gridSize, (gridCountY - 1) * gridSize),
        paint: Paint()..color = Color.fromARGB(255, 200, 246, 248),
        anchor: .center,
        // position: Vector2(0, (gridSize * -3)),
      );

  @override
  void onTapUp(TapUpEvent event) {
    SnakeWorld snakeWorld = (parent as SnakeWorld);
    if (snakeWorld.isGameOver) {
      snakeWorld.startGame();
    }
    super.onTapUp(event);
  }
}
