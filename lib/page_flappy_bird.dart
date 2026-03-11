import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import 'games/flappy/game.dart';

class FlappyBirdPage extends StatelessWidget {
  final FlappyBirdGame game = FlappyBirdGame();
  FlappyBirdPage({super.key});

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
