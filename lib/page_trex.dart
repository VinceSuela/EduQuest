import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_pomodoro/constant.dart';
import 'package:flutter_pomodoro/games/trex/trex_game.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';

class TrexGamePage extends StatefulWidget {
  const TrexGamePage({super.key});

  @override
  State<TrexGamePage> createState() => _TrexGamePageState();
}

class _TrexGamePageState extends State<TrexGamePage> {
  final TRexGame game = TRexGame();
  late Timer timer;

  void startTimer() {
    BuildContext navContext = NavigationService.navigatorKey.currentContext!;
    timer = Timer(gameDuration, () {
      Navigator.pushReplacementNamed(navContext, '/pdfViewer');
    });
  }

  @override
  void initState() {
    startTimer();
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

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
