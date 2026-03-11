import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_pomodoro/games/trex/trex_game.dart';

class TrexGamePage extends StatelessWidget {
  final TRexGame game = TRexGame();
  TrexGamePage({super.key});

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
