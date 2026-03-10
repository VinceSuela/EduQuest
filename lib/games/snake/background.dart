import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/games/snake/constant.dart';

class Background extends RectangleComponent {
  Background()
    : super(
        size: gameScreen,
        paint: Paint()..color = Color.fromARGB(255, 244, 246, 248),
      );
}
