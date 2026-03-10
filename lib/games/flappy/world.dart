import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter_pomodoro/games/flappy/background.dart';
import 'package:flutter_pomodoro/games/flappy/bird.dart';
import 'package:flutter_pomodoro/games/flappy/constant.dart';
import 'package:flutter_pomodoro/games/flappy/gameover.dart';
import 'package:flutter_pomodoro/games/flappy/ground.dart';
import 'package:flutter_pomodoro/games/flappy/message.dart';
import 'package:flutter_pomodoro/games/flappy/pipes.dart';
import 'package:flutter_pomodoro/games/flappy/score.dart';
import 'package:flutter_pomodoro/games/flappy/sounds.dart';
import 'package:flutter/src/services/hardware_keyboard.dart';

class FlappyBirdWorld extends World
    with
        TapCallbacks,
        HasCollisionDetection,
        HasGameReference,
        KeyboardHandler {
  late Background background;
  late Bird bird;
  late Ground ground;
  late Gameover gameover;
  late Message message;
  late Score scoreDisplay100;
  late Score scoreDisplay10;
  late Score scoreDisplay1;
  late Sounds gameSounds;
  late Pipes pipesManager;

  Random random = Random();
  bool isDay = true;
  int score = 10;
  int highScore = 0;
  bool isGameOver = false;
  bool isGameStarted = false;
  int pipeIndex = 0; // To alternate between pipe pairs
  double pipeSpacing = 288 / 2; // Horizontal spacing between pipe pairs
  Vector2 screen = Vector2(288, 512);

  @override
  Future<void> onLoad() async {
    gameSounds = Sounds();
    background = Background();
    pipesManager = Pipes();
    ground = Ground();
    bird = Bird();
    gameover = Gameover();
    message = Message();
    scoreDisplay100 = Score(position: Vector2(-24, -512 / 2 + 30));
    scoreDisplay10 = Score(position: Vector2(0, -512 / 2 + 30));
    scoreDisplay1 = Score(position: Vector2(24, -512 / 2 + 30));

    scoreDisplay100.setVisible(false);
    scoreDisplay10.setVisible(false);
    scoreDisplay1.setVisible(false);

    game.camera.backdrop.add(background);
    add(gameSounds);
    add(pipesManager);
    add(ground);
    add(bird);
    add(gameover);
    add(message);
    add(scoreDisplay100);
    add(scoreDisplay10);
    add(scoreDisplay1);

    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameStarted && !isGameOver) {
      incrementScore();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (!isGameStarted && !isGameOver) {
      startGame();
      return;
    }
    if (isGameOver) {
      resetGame();
      return;
    }
    bird.flap();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      if (!isGameStarted && !isGameOver) {
        startGame();
      } else if (isGameOver) {
        resetGame();
      } else {
        bird.flap();
      }

      return false;
    }
    return true;
  }

  void resetGame() {
    score = 0;
    isGameOver = false;
    isGameStarted = false;
    bird.reset();
    message.toggle(true);
    gameover.toggle(false);
    pipeIndex = 0;

    resetPipes(false);
    gameSounds.swoosh();
    // swoosh.start(); // Play the swoosh sound
    for (var i = 0; i < 3; i++) {
      pipesManager.generatePipes(i);
    }
  }

  void startGame() {
    isDay = random.nextBool();
    background.setTime(isDay);
    isGameStarted = true;
    isGameOver = false;
    pipeIndex = 0;
    score = 0;
    bird.reset();
    bird.flap();
    message.toggle(false);
    ground.start();
    // swoosh.start();
    gameSounds.swoosh();
    updateScoreDisplay();
    resetPipes(true);

    for (var i = 0; i < 3; i++) {
      pipesManager.generatePipes(i);
    }
  }

  void resetPipes(bool isMoving) {
    pipesManager.resetPipes(isMoving);
  }

  void gameOver() {
    isGameOver = true;
    isGameStarted = false;
    pipeIndex = 0;
    gameover.toggle(true);
    ground.stop();
    pipesManager.stop();
    bird.die();
  }

  void incrementScore() {
    int currentPipeIndex = pipeIndex % 3;
    Pipe currentPipeTop = pipesManager.pipes[currentPipeIndex][0];
    double birdLeftEdge = bird.position.x - (bird.size.x / 2);
    double pipeRightEdge =
        currentPipeTop.position.x + (currentPipeTop.size.x / 2);

    if (birdLeftEdge > pipeRightEdge) {
      pipeIndex++;
      score++;
      updateScoreDisplay();
      gameSounds.point();
      pipesManager.generatePipes(currentPipeIndex + 2);
    }
    if (score > highScore) {
      highScore = score;
    }
    if (pipeIndex == 30) {
      pipeIndex = 0;
    }
  }

  void updateScoreDisplay() {
    int hundreds = (score ~/ 100) % 10;
    int tens = (score ~/ 10) % 10;
    int ones = score % 10;
    double topY = (gameScreen.y * -0.5) + 50;

    scoreDisplay100.updateScore(hundreds);
    scoreDisplay10.updateScore(tens);
    scoreDisplay1.updateScore(ones);

    scoreDisplay100.setVisible(hundreds > 0);
    scoreDisplay10.setVisible(tens > 0);
    scoreDisplay1.setVisible(ones >= 0);

    if (score > 99) {
      scoreDisplay100.position = Vector2(-24, topY);
      scoreDisplay10.position = Vector2(0, topY);
      scoreDisplay1.position = Vector2(24, topY);
    } else if (score > 9) {
      scoreDisplay10.position = Vector2(-12, topY);
      scoreDisplay1.position = Vector2(12, topY);
    } else {
      scoreDisplay1.position = Vector2(0, topY);
    }
  }
}
