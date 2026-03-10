import 'package:flame/components.dart';

class Score extends SpriteComponent with HasVisibility {
  late Sprite scoreSprite0;
  late Sprite scoreSprite1;
  late Sprite scoreSprite2;
  late Sprite scoreSprite3;
  late Sprite scoreSprite4;
  late Sprite scoreSprite5;
  late Sprite scoreSprite6;
  late Sprite scoreSprite7;
  late Sprite scoreSprite8;
  late Sprite scoreSprite9;

  double targetY = 30;

  int currentScore = 0;

  Score({super.position}) : super(anchor: Anchor.center, size: Vector2(24, 36));

  @override
  Future<void> onLoad() async {
    // 24x36
    scoreSprite0 = await Sprite.load('flappy/0.png');
    scoreSprite1 = await Sprite.load('flappy/1.png');
    scoreSprite2 = await Sprite.load('flappy/2.png');
    scoreSprite3 = await Sprite.load('flappy/3.png');
    scoreSprite4 = await Sprite.load('flappy/4.png');
    scoreSprite5 = await Sprite.load('flappy/5.png');
    scoreSprite6 = await Sprite.load('flappy/6.png');
    scoreSprite7 = await Sprite.load('flappy/7.png');
    scoreSprite8 = await Sprite.load('flappy/8.png');
    scoreSprite9 = await Sprite.load('flappy/9.png');

    sprite = scoreSprite0;
    await super.onLoad();
  }

  void setVisible(bool visible) {
    isVisible = visible;
  }

  void updateScore(int score) {
    currentScore = score;
    int digit = currentScore % 10;
    switch (digit) {
      case 0:
        sprite = scoreSprite0;
        break;
      case 1:
        sprite = scoreSprite1;
        break;
      case 2:
        sprite = scoreSprite2;
        break;
      case 3:
        sprite = scoreSprite3;
        break;
      case 4:
        sprite = scoreSprite4;
        break;
      case 5:
        sprite = scoreSprite5;
        break;
      case 6:
        sprite = scoreSprite6;
        break;
      case 7:
        sprite = scoreSprite7;
        break;
      case 8:
        sprite = scoreSprite8;
        break;
      case 9:
        sprite = scoreSprite9;
        break;
    }
  }
}
