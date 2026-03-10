import 'package:flame/game.dart';

Vector2 gameScreen = Vector2(288, 512);
double worldSpeed = 100;
double groundHeight = 112;
double playAreaHeight = 512 - 112 - 24;
double playAreaWidth = 288;

double pipeSpacing = 288 / 2;
double pipeGap = 150;

Vector2 birdSize = Vector2(34, 24);
double gravity = 150;
double flapStrength = 500;
double flapDuration = 0.2;
double groundY = 256 - 112 - 24 / 2;
