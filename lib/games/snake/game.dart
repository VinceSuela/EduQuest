import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter_pomodoro/games/snake/constant.dart';
import 'package:flutter_pomodoro/games/snake/world.dart';

class SnakeGame extends FlameGame with HasKeyboardHandlerComponents {
  SnakeGame()
    : super(
        world: SnakeWorld(),
        camera: CameraComponent(
          viewport: FixedResolutionViewport(resolution: gameScreen),
          viewfinder: Viewfinder(),
        ),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport.position.x = gridSize * -10;
  }
}
