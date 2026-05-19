import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flutter_pomodoro/constant.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';

import 'games/flappy/game.dart';

class FlappyBirdPage extends StatefulWidget {
  const FlappyBirdPage({super.key});

  @override
  State<FlappyBirdPage> createState() => _FlappyBirdPageState();
}

class _FlappyBirdPageState extends State<FlappyBirdPage> {
  // final FlappyBirdGame game = FlappyBirdGame();
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
    timer = Timer(gameBreak, () {
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
          game: FlappyBirdGame(),
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
