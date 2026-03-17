import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:flutter_pomodoro/games/trex/background/horizon.dart';
import 'package:flutter_pomodoro/games/trex/constant.dart';
import 'package:flutter_pomodoro/games/trex/game_over.dart';
import 'package:flutter_pomodoro/games/trex/player.dart';

enum GameState { playing, intro, gameOver }

class TRexGame extends FlameGame with KeyboardEvents {
  final Random random = Random();
  late final Image spriteImage;
  GameState state = GameState.intro;
  bool get isPlaying => state == GameState.playing;
  bool get isGameOver => state == GameState.gameOver;
  bool get isIntro => state == GameState.intro;

  int _score = 0;
  int _highScore = 0;
  int get score => _score;
  double currentSpeed = 0.0;
  double timePlaying = 0.0;
  double _distanceTraveled = 0;

  TRexGame()
    : super(
        world: TRexGameWorld(),
        camera: CameraComponent(
          // viewport: FixedResolutionViewport(resolution: gameScreen),
          viewfinder: Viewfinder(),
        ),
      );

  @override
  Color backgroundColor() => const Color(0xFFFFFFFF);

  @override
  Future<void> onLoad() async {
    spriteImage = await Flame.images.load('trex.png');
    camera.viewport.position.x = size.x * -0.5;
    camera.viewport.position.y = size.y * -0.5;
    // camera.viewport.anchor = .topLeft;
    return super.onLoad();
  }
}

class TRexGameWorld extends World
    with
        TapCallbacks,
        HasCollisionDetection,
        KeyboardHandler,
        HasGameReference<TRexGame> {
  late final player = Player();
  late final horizon = Horizon();
  late final gameOverPanel = GameOverPanel();
  late final TextComponent scoreText;

  set score(int newScore) {
    game._score = newScore;
    scoreText.text =
        '${scoreString(game._score)}  HI ${scoreString(game._highScore)}';
  }

  String scoreString(int score) => score.toString().padLeft(5, '0');

  @override
  Future<void> onLoad() async {
    add(horizon);
    add(player);
    add(gameOverPanel);

    const chars = '0123456789HI ';
    final renderer = SpriteFontRenderer.fromFont(
      SpriteFont(
        source: game.spriteImage,
        size: 23,
        ascent: 23,
        glyphs: [
          for (var i = 0; i < chars.length; i++)
            Glyph(chars[i], left: 954.0 + 20 * i, top: 0, width: 20),
        ],
      ),
      letterSpacing: 2,
    );
    add(
      scoreText = TextComponent(
        position: Vector2(20, 20),
        textRenderer: renderer,
      ),
    );
    score = 0;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.enter) ||
        keysPressed.contains(LogicalKeyboardKey.space)) {
      onAction();
      return false;
    }
    return true;
  }

  @override
  void onTapDown(TapDownEvent event) {
    onAction();
  }

  void onAction() {
    if (game.isGameOver || game.isIntro) {
      restart();
      return;
    }
    player.jump(game.currentSpeed);
  }

  void gameOver() {
    gameOverPanel.visible = true;
    game.state = GameState.gameOver;
    player.current = PlayerState.crashed;
    game.currentSpeed = 0.0;
  }

  void restart() {
    game.state = GameState.playing;
    player.reset();
    horizon.reset();
    game.currentSpeed = startSpeed;
    gameOverPanel.visible = false;
    game.timePlaying = 0.0;
    if (game.score > game._highScore) {
      game._highScore = game.score;
    }
    score = 0;
    game._distanceTraveled = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.isGameOver) {
      return;
    }

    if (game.isPlaying) {
      game.timePlaying += dt;
      game._distanceTraveled += dt * game.currentSpeed;
      score = game._distanceTraveled ~/ 50;

      if (game.currentSpeed < maxSpeed) {
        game.currentSpeed += acceleration * dt;
      }
    }
  }
}
