import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter_pomodoro/games/flappy/constant.dart';
import 'package:flutter_pomodoro/games/flappy/world.dart';

class Pipes extends Component {
  Random random = Random();
  List<List<Pipe>> pipes = [];

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < 3; i++) {
      pipes.add([]);
      double positionX = (playAreaWidth * 0.5) + (pipeSpacing * (i + 1));
      double positionY = (groundHeight * -0.5);
      for (var e = 0; e < 2; e++) {
        bool isTopPipe = e == 0;
        pipes[i].add(
          Pipe(
            position: Vector2(positionX, positionY),
            anchor: Anchor.topCenter,
            scale: Vector2(-1, isTopPipe ? -1 : 1),
            isTopPipe: isTopPipe,
          ),
        );
        (parent as FlappyBirdWorld).add(pipes[i][e]);
        // add(pipes[i][e]);
      }
    }
  }

  void resetPipes(bool isMoving) {
    for (var i = 0; i < pipes.length; i++) {
      for (var e = 0; e < pipes[i].length; e++) {
        pipes[i][e].position.x = playAreaWidth + (pipeSpacing * (i));
        // pipes[i][e].isMoving = isMoving;
        if (isMoving) {
          pipes[i][e].start();
        }
      }
    }
  }

  void generatePipes(int index) {
    int currentPipeIndex = (index) % 3;
    Pipe currentPipeTop = pipes[currentPipeIndex][0];
    Pipe currentPipeBottom = pipes[currentPipeIndex][1];

    double randomMutiplier = random.nextInt(10).toDouble();
    double centerY = ((-120) + (randomMutiplier * 14));

    double topY = centerY - (pipeGap * 0.5);
    double bottomY = centerY + (pipeGap * 0.5);

    currentPipeTop.position.y = topY;
    currentPipeBottom.position.y = bottomY;
  }

  void stop() {
    for (var i = 0; i < pipes.length; i++) {
      for (var e = 0; e < pipes[i].length; e++) {
        pipes[i][e].stop();
      }
    }
  }
}

class Pipe extends SpriteComponent with CollisionCallbacks, HasWorldReference {
  late Sprite _greenSprite;
  late Sprite _redSprite;

  double groundX = 0;
  bool isMoving = false;
  double playAreaHeight = 512 - 112 - 24;
  double playAreaWidth = 288;
  double pipeSpacing = 288 / 2;
  double pipeGap = 125;
  double centerY = (512 - 112 - 24) / 2;
  double pipeWidth = 52;
  bool isTopPipe;
  Random random = Random();

  final double outsideBox = -144 - 26;

  Pipe({super.position, super.anchor, super.scale, required this.isTopPipe})
    : super(size: Vector2(52, 320), angle: 0);

  @override
  Future<void> onLoad() async {
    // 52x320
    _greenSprite = await Sprite.load('flappy/pipe-green.png');
    _redSprite = await Sprite.load('flappy/pipe-red.png');

    sprite = _redSprite;
    add(RectangleHitbox());
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isMoving) {
      position.x -= worldSpeed * dt;
    }

    if (position.x <= outsideBox) {
      reset();
    }
  }

  void reset() {
    position.x = playAreaWidth - (pipeWidth * 0.5);
  }

  void start() {
    FlappyBirdWorld world = (parent as FlappyBirdWorld);
    isMoving = true;
    sprite = world.isDay ? _greenSprite : _redSprite;
  }

  void stop() {
    isMoving = false;
  }
}
