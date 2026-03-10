import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_pomodoro/games/snake/constant.dart';
import 'package:flutter_pomodoro/games/snake/world.dart';

class Moves {
  Vector2 up = Vector2(0, -1);
  Vector2 right = Vector2(1, 0);
  Vector2 down = Vector2(0, 1);
  Vector2 left = Vector2(-1, 0);
}

class Player extends Component with HasWorldReference, HasGameReference {
  List<Vector2> snakeTrackInitial = [
    Vector2(-1, -3),
    Vector2(-2, -3),
    Vector2(-3, -3),
  ];
  List<Vector2> snakeTrack = [
    Vector2(-1, -3),
    Vector2(-2, -3),
    Vector2(-3, -3),
  ];
  Vector2 direction = Vector2(1, 0);
  Player() : super();
  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    updateSnake();
  }

  void resetSnake() {
    snakeTrack = [...snakeTrackInitial];
    updateSnake();
  }

  void moveSnake(Vector2 move, Vector2 food) {
    direction = move;
    Vector2 nextLocation = snakeTrack[0] + move;
    // print(nextLocation);
    bool x = nextLocation.x.abs().compareTo((gridCountX / 2)) < 0;
    bool y = nextLocation.y.abs().compareTo((gridCountY / 2)) < 0;

    bool canMove = nextLocation != snakeTrack[1];
    bool isSelf =
        snakeTrack.contains(nextLocation) && nextLocation != snakeTrack.last;
    // print(canMove ? 'can Move' : 'cant Move');
    // print(isSelf ? 'not self' : 'is self');
    // print(x && y ? 'is inside' : 'is outside');
    if (canMove && x && y && !isSelf) {
      if (food == nextLocation) {
        (parent as SnakeWorld).spawnFood();
      } else {
        snakeTrack.removeLast();
      }
      snakeTrack.insert(0, nextLocation);
      updateSnake();
    } else if (!x || !y || isSelf) {
      (parent as SnakeWorld).gameOver();
    } else {
      (parent as SnakeWorld).gameOver();
    }
  }

  void updateSnake() {
    // print(snakeTrack);
    removeAll(children);
    for (var i = 0; i < snakeTrack.length; i++) {
      Vector2 track = snakeTrack[i];
      Vector2 translate = Vector2(gridSize * track.x, gridSize * track.y);
      // track.x = track.x * gridSize;
      // track.y = track.y * gridSize;

      if (i == 0) {
        add(Head(position: translate, direction: direction));
      } else if (i == snakeTrack.length - 1) {
        Vector2 tailDirection = track - snakeTrack[i - 1];
        add(Tail(position: translate, direction: tailDirection));
      } else {
        Vector2 bodyDirection = track - snakeTrack[i - 1];
        Vector2 tailDirection = track - snakeTrack[i + 1];
        add(
          Body(
            position: translate,
            bodyDirection: bodyDirection,
            tailDirection: tailDirection,
          ),
        );
      }
    }
  }
}

class Head extends SpriteComponent {
  late Vector2 direction;
  Head({super.position, required this.direction})
    : super(size: .all(gridSize), anchor: .center);

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    sprite = await Sprite.load('snake/head.png');
    direction = direction;

    if (direction == Vector2(0, 1)) {
      angle = 90 * degrees2Radians;
    }
    if (direction == Vector2(-1, 0)) {
      angle = 180 * degrees2Radians;
    }
    if (direction == Vector2(0, -1)) {
      angle = 270 * degrees2Radians;
    }
    if (direction == Vector2(1, 0)) {
      angle = 0 * degrees2Radians;
    }
  }
}

class Body extends SpriteComponent {
  late Vector2 bodyDirection;
  late Vector2 tailDirection;
  late Sprite body;
  late Sprite curve;

  Body({
    super.position,
    required this.bodyDirection,
    required this.tailDirection,
  }) : super(size: .all(gridSize), anchor: .center);
  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    body = await Sprite.load('snake/body.png');
    curve = await Sprite.load('snake/body-curve.png');
    sprite = body;

    Vector2 computedDirection = (bodyDirection + tailDirection);

    if (computedDirection == Vector2.all(0)) {
      sprite = body;
      if (bodyDirection == Vector2(0, 1)) {
        angle = 90 * degrees2Radians;
      }
      if (bodyDirection == Vector2(-1, 0)) {
        angle = 180 * degrees2Radians;
      }
      if (bodyDirection == Vector2(0, -1)) {
        angle = 270 * degrees2Radians;
      }
      if (bodyDirection == Vector2(1, 0)) {
        angle = 0 * degrees2Radians;
      }
    } else {
      sprite = curve;

      // angle = 270 * degrees2Radians;
      if (computedDirection == Vector2(1, 1)) {
        angle = 270 * degrees2Radians; //
      }
      if (computedDirection == Vector2(-1, -1)) {
        angle = 90 * degrees2Radians;
      }
      if (computedDirection == Vector2(1, -1)) {
        angle = 180 * degrees2Radians; //
      }
      if (computedDirection == Vector2(-1, 1)) {
        angle = 0 * degrees2Radians; //
      }
    }
  }
}

class Tail extends SpriteComponent {
  late Vector2 direction;

  Tail({super.position, required this.direction})
    : super(size: .all(gridSize), anchor: .center);
  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    sprite = await Sprite.load('snake/tail.png');

    if (direction == Vector2(0, 1)) {
      angle = 270 * degrees2Radians;
    }
    if (direction == Vector2(-1, 0)) {
      angle = 0 * degrees2Radians;
    }
    if (direction == Vector2(0, -1)) {
      angle = 90 * degrees2Radians;
    }
    if (direction == Vector2(1, 0)) {
      angle = 180 * degrees2Radians;
    }
  }
}
