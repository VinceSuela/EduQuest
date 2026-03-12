import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';
import 'package:flutter_pomodoro/widgets/my_dialog.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

class PinchPage extends StatefulWidget {
  const PinchPage({super.key});

  @override
  State<PinchPage> createState() => _PinchPageState();
}

enum DocShown { sample, tutorial, hello, password }

class _PinchPageState extends State<PinchPage> {
  int initialPage = 1;
  late PdfControllerPinch _pdfControllerPinch;
  late Uint8List bytes;
  late Timer timer;
  late Timer timerDisplay;
  final Duration duration = Duration(seconds: 5);
  DateTime startTime = DateTime.now();
  late DateTime endTime = DateTime.now().add(duration);
  String remainingTime = '';

  @override
  void initState() {
    BuildContext navContext = NavigationService.navigatorKey.currentContext!;

    bytes = Provider.of<MyFile>(navContext).bytes;

    startTimer();
    initialPage = Provider.of<MyFile>(navContext).page;
    if (kIsWeb) {
      _pdfControllerPinch = PdfControllerPinch(
        document: PdfDocument.openData(bytes),
        initialPage: initialPage,
      );
    } else {
      _pdfControllerPinch = PdfControllerPinch(
        document: PdfDocument.openFile(Provider.of<MyFile>(navContext).path),
        initialPage: initialPage,
      );
    }
    _pdfControllerPinch.addListener(() {
      Provider.of<MyFile>(
        navContext,
        listen: false,
      ).setPage(_pdfControllerPinch.page);
    });
    super.initState();
  }

  void startTimer() {
    BuildContext navContext = NavigationService.navigatorKey.currentContext!;
    startTime = DateTime.now();
    endTime = DateTime.now().add(duration);
    timer = Timer(duration, () {
      showBreakTime(navContext);
    });
    timerDisplay = Timer.periodic(Duration(seconds: 1), (currentTime) {
      setState(() {
        int remaining = endTime.difference(DateTime.now()).inSeconds;
        if (remaining < 1) {
          timerDisplay.cancel();
        }
        remainingTime = formatDuration(remaining).toString();
      });
    });
  }

  String formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes;
    final seconds = totalSeconds % 60;

    final minutesString = '$minutes'.padLeft(2, '0');
    final secondsString = '$seconds'.padLeft(2, '0');

    return '$minutesString:$secondsString';
  }

  @override
  void dispose() {
    timer.cancel();
    _pdfControllerPinch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Provider.of<MyFile>(context).name.isEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Column(
          children: [
            FittedBox(
              fit: .scaleDown,
              child: Text(Provider.of<MyFile>(context).name),
            ),
            FittedBox(fit: .scaleDown, child: Text('$remainingTime')),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: () {
              _pdfControllerPinch.previousPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
            },
          ),
          PdfPageNumber(
            controller: _pdfControllerPinch,
            builder: (_, loadingState, page, pagesCount) => Container(
              alignment: Alignment.center,
              child: Text(
                '$page/${pagesCount ?? 0}',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            onPressed: () {
              _pdfControllerPinch.nextPage(
                curve: Curves.ease,
                duration: const Duration(milliseconds: 100),
              );
            },
          ),
        ],
      ),
      body: PdfViewPinch(
        builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          pageLoaderBuilder: (_) =>
              const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, error) => Center(child: Text(error.toString())),
        ),
        controller: _pdfControllerPinch,
      ),
    );
  }

  Future<String?> showBreakTime(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => MyDialog(
        title: 'Have a break?',
        child: Column(
          children: [
            MyButton(
              label: 'Flappy Bird',
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(context, '/flappy');
              },
              isActive: false,
            ),
            MyButton(
              label: 'Snake',
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(context, '/snake');
              },
              isActive: false,
            ),
            MyButton(
              label: 'Trex',
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushReplacementNamed(context, '/trex');
              },
              isActive: false,
            ),
            MyButton(
              label: 'Not Now',
              onPressed: () {
                Navigator.pop(dialogContext);
                startTimer();
              },
              isActive: true,
            ),
            MyButton(
              label: 'Quiz Now',
              isActive: true,
              onPressed: () async {
                final myFile = Provider.of<MyFile>(context, listen: false);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await Provider.of<GeminiQuizService>(
                    NavigationService.navigatorKey.currentContext!,
                    listen: false,
                  ).generateQuizFromBytes(myFile.bytes, debug: true);
                  // final quizService = GeminiQuizService();
                  // final List<QuizQuestion> questions = await quizService
                  //     .generateQuizFromBytes(myFile.bytes);
                  // print(questions);
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    Navigator.pushReplacementNamed(
                      NavigationService.navigatorKey.currentContext!,
                      '/quiz',
                    );
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to generate quiz: $e")),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
