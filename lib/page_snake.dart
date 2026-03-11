import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_pomodoro/games/snake/game.dart';

class SnakeGamePage extends StatelessWidget {
  final SnakeGame game = SnakeGame();
  SnakeGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.lightBlue,
        child: GameWidget(game: game),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {
          Navigator.pushReplacementNamed(context, '/pdfViewer'),
        },
        tooltip: 'Close Game',
        child: const Icon(Icons.close),
      ),
    );
  }
}
