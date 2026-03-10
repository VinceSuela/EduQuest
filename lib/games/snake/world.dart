import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pomodoro/games/snake/background.dart';
import 'package:flutter_pomodoro/games/snake/constant.dart';
import 'package:flutter_pomodoro/games/snake/food.dart';
import 'package:flutter_pomodoro/games/snake/player.dart';
import 'package:flutter_pomodoro/games/snake/playground.dart';

class SnakeWorld extends World
    with DragCallbacks, HasGameReference, KeyboardHandler {
  late final JoystickComponent joystick;
  late Player player;
  late Food food;
  late Vector2 snakeDirection;
  late TimerComponent timer;
  late TextBoxComponent scoreBox;
  late TextBoxComponent message;
  Random random = Random();
  Moves direction = Moves();
  bool isGameOver = false;
  bool isGameStarted = true;
  int score = 0;

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    snakeDirection = direction.right;
    game.camera.backdrop.add(Background());
    game.camera.viewfinder.position = Vector2(0, gridSize * 2);

    scoreBox = TextBoxComponent(
      text: 'Your score is $score',
      align: .center,
      anchor: .center,
      position: Vector2(0, gridSize * gridCountX * -.5),
      boxConfig: TextBoxConfig(timePerChar: 0.05),
    );

    _addJoystick();

    add(Playground());
    add(food = Food(location: Vector2.all(0)));
    add(player = Player());

    add(
      timer = TimerComponent(
        period: 0.3,
        repeat: true,
        autoStart: true,
        onTick: () {
          player.moveSnake(snakeDirection, food.location);
        },
      ),
    );
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
      setMove(direction.right);
      return false;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
      setMove(direction.down);
      return false;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) {
      setMove(direction.left);
      return false;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
      setMove(direction.up);
      return false;
    }
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      startGame();
      return false;
    }
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!joystick.delta.isZero()) {
      setDirection(joystick.direction);
    }
  }

  void setDirection(JoystickDirection joystickDirection) {
    switch (joystickDirection) {
      case JoystickDirection.right:
      case JoystickDirection.downRight:
        setMove(direction.right);
      case JoystickDirection.down:
      case JoystickDirection.downLeft:
        setMove(direction.down);
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
        setMove(direction.left);
      case JoystickDirection.up:
      case JoystickDirection.upRight:
        setMove(direction.up);
      default:
    }
    // if (joystickDirection.right ) {
    //   setDirection(direction.)
    // }
  }

  void _addJoystick() {
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 20,
        // anchor: .center,
        paint: Paint()..color = Color.fromARGB(255, 170, 71, 188),
      ),
      knobRadius: 40,
      background: CircleComponent(
        radius: 40,
        // anchor: .center,
        paint: Paint()..color = Color.fromARGB(255, 206, 147, 216),
      ),
      // margin: const EdgeInsets.only(left: 128, bottom: 32),
      position: Vector2(gameScreen.x * 0.5, gameScreen.y - 55),
    );
    game.camera.viewport.add(joystick); // Add to viewport for fixed position
  }

  void setMove(Vector2 direction) {
    Vector2 nextLocation = player.snakeTrack[0] + direction;
    bool canMove = nextLocation != player.snakeTrack[1];
    if (canMove) {
      snakeDirection = direction;
    }
  }

  void spawnFood() {
    int randomX = random.nextInt((gridCountX / 2).toInt());
    int randomY = random.nextInt((gridCountX / 2).toInt());
    Vector2 newLocation = Vector2(randomX.toDouble(), randomY.toDouble());
    if (player.snakeTrack.contains(newLocation)) {
      return spawnFood();
    }

    food.updatePosition(Vector2(randomX.toDouble(), randomY.toDouble()));
  }

  void gameOver() {
    isGameOver = true;
    isGameStarted = false;
    int score = player.snakeTrack.length - 3;
    // timer.removeFromParent();
    scoreBox = TextBoxComponent(
      text: 'Your score is $score',
      align: .center,
      anchor: .center,
      position: Vector2(0, gridSize * gridCountX * -0.5),
      boxConfig: TextBoxConfig(timePerChar: 0.02),
      textRenderer: TextPaint(style: TextStyle(color: Colors.black)),
    );
    message = TextBoxComponent(
      text: 'Tap play area to play again',
      align: .center,
      anchor: .center,
      position: Vector2(0, gridSize * gridCountX * -0.4),
      boxConfig: TextBoxConfig(timePerChar: 0.01),
      textRenderer: TextPaint(style: TextStyle(color: Colors.black)),
    );
    add(scoreBox);
    add(message);
    remove(timer);
  }

  void startGame() {
    isGameOver = false;
    isGameStarted = true;
    snakeDirection = direction.right;
    player.resetSnake();
    spawnFood();
    remove(scoreBox);
    remove(message);
    add(timer);
  }
}
