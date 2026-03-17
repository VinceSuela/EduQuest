import 'dart:async';

import 'package:flame/camera.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
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
  Color backgroundColor() => Color(0xFF47B9FF);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport.position.x = gridSize * -10;
  }
}
