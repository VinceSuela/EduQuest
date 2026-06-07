import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_pomodoro/constant.dart';
import 'package:flutter_pomodoro/games/snake/game.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage> {
  // final SnakeGame game = SnakeGame();
  late Timer timer;

  PomodoroPreset _getCurrentPomodoroPreset() {
    final settings = QuizStorageService();

    final savedLabel = settings.loadPomodoroPreset();

    return pomodoroPresets.firstWhere(
      (preset) => preset.label == savedLabel,
      orElse: () => pomodoroPresets.first,
    );
  }
  
  void startTimer() {
    BuildContext navContext = NavigationService.navigatorKey.currentContext!;
    final preset = _getCurrentPomodoroPreset();
    final gameBreak = preset.breakDuration;
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
        child: GameWidget(
          game: SnakeGame(),
          loadingBuilder: (_) => const Center(child: Text('Loading')),
        ),
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
