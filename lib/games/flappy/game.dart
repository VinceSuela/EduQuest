import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter_pomodoro/games/flappy/world.dart';

class FlappyBirdGame extends FlameGame with HasKeyboardHandlerComponents {
  FlappyBirdGame()
    : super(
        world: FlappyBirdWorld(),
        camera: CameraComponent(
          viewport: FixedResolutionViewport(resolution: Vector2(288, 512)),
          // backdrop: Background(),
        ),
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }
}
