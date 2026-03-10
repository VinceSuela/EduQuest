import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter_pomodoro/games/flappy/constant.dart';
import 'package:flutter_pomodoro/games/flappy/ground.dart';
import 'package:flutter_pomodoro/games/flappy/pipes.dart';
import 'package:flutter_pomodoro/games/flappy/world.dart';

class Bird extends SpriteComponent
    with
        CollisionCallbacks,
        HasVisibility,
        HasWorldReference,
        HasGameReference {
  // late Sounds gameSounds;
  late Timer flapTimer;
  List<List<Sprite>> sprites = [];
  List<String> flaps = [
    'bird-upflap.png',
    'bird-midflap.png',
    'bird-downflap.png',
  ];
  // late AudioPool wing;
  // late AudioPool hit;
  bool isFlapping = false;
  double timeSinceFlap = 0;
  double skyY = (gameScreen.y * -0.5) + (birdSize.y * 0.5);
  double targetY = 0;
  Vector2 defaultPosition = Vector2(0, 0);

  Bird()
    : super(
        size: birdSize,
        anchor: Anchor.center,
        position: Vector2(0, 0),
        angle: 0,
      );

  @override
  Future<void> onLoad() async {
    // 34x24

    for (var i = 0; i < 2; i++) {
      sprites.add([]);
      String color = i == 0 ? 'yellow' : 'blue';
      for (String flap in flaps) {
        sprites[i].add(await Sprite.load('flappy/$color$flap'));
      }
    }

    sprite = getFlap(1);

    isVisible = false;
    add(
      PolygonHitbox.relative([
        Vector2(1, 0.4),
        Vector2(0, -1),
        Vector2(-1, 0),
        Vector2(0, 1),
      ], parentSize: birdSize),
    );

    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // print(dt);
    if (!isFlapping) {
      return;
    }

    _animate();

    double direction = position.y - targetY;
    double timeSinceFlapDelta = DateTime.now().millisecondsSinceEpoch
        .toDouble();
    if (direction < 0) {
      double multiplier = (timeSinceFlapDelta - timeSinceFlap) > 500 ? 1.2 : 1;
      position.y += gravity * (dt * multiplier);
    } else if (direction >= 0) {
      position.y -= flapStrength * dt;
    }
    if (angle < 0.5) {
      angle += 0.05;
    }

    if (targetY > position.y) {
      targetY = groundY;
    }

    if (position.y > groundY) {
      isFlapping = false;
      sprite = getFlap(2);
      angle = 0.5;
    }

    if (_isHeigher(skyY)) {
      position.y = skyY;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    FlappyBirdWorld world = (parent as FlappyBirdWorld);
    if (!world.isGameOver) {
      if (other is Ground) {
        world.gameOver();
        angle = 2;
      } else if (other is Pipe) {
        world.gameOver();
      }
    }
  }

  bool _isHeigher(double target) {
    return position.y < target;
  }

  void _animate() {
    if (angle > 0.2) {
      sprite = getFlap(0);
    } else if (angle > -0.3) {
      sprite = getFlap(2);
    } else {
      sprite = getFlap(1);
    }
  }

  Sprite getFlap(int index) {
    FlappyBirdWorld world = (parent as FlappyBirdWorld);
    return sprites[world.isDay ? 0 : 1][index];
  }

  void flap() {
    sprite = getFlap(0);
    isFlapping = true;
    isVisible = true;
    angle = -0.5; // Rotate the bird upwards
    targetY = position.y - (size.y * 2.5); // Move the bird up by 100 pixels
    if (targetY < skyY) {
      targetY = skyY;
    }

    (parent as FlappyBirdWorld).gameSounds.wing();
    timeSinceFlap = DateTime.now().millisecondsSinceEpoch
        .toDouble(); // Reset the flap timer
  }

  void stop() {
    isFlapping = false;
  }

  void reset() {
    targetY = 512 / 2;
    position = defaultPosition;
    angle = 0;
    sprite = getFlap(1);
    isVisible = false;
  }

  void die() {
    isFlapping = false;
    (parent as FlappyBirdWorld).gameSounds.hit();
  }
}
