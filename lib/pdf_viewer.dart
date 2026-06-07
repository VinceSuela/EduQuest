import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/constant.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';
import 'package:flutter_pomodoro/widgets/my_dialog.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import 'package:flutter_pomodoro/services/quiz_service.dart';

class PinchPage extends StatefulWidget {
  const PinchPage({super.key});

  @override
  State<PinchPage> createState() => _PinchPageState();
}

enum DocShown { sample, tutorial, hello, password }

class _PinchPageState extends State<PinchPage> {
  int initialPage = 1;
  PdfControllerPinch? _pdfControllerPinch;
  late Uint8List bytes;
  late Timer timer;
  late Timer timerDisplay;
  final Duration duration = Duration(seconds: 5);
  late DateTime endTime = DateTime.now().add(learnDuration);
  String remainingTime = '';
  bool hideFloatingButton = false;
  Timer? _pageChangeDebounce;
  MyFile? _fileProvider;

  PomodoroPreset _getCurrentPomodoroPreset() {
  final settings = QuizStorageService();

    final savedLabel = settings.loadPomodoroPreset();

    return pomodoroPresets.firstWhere(
      (preset) => preset.label == savedLabel,
      orElse: () => pomodoroPresets.first,
    );
  }

  @override
  @override
  void initState() {
    super.initState();

    // Listen to MyFile provider to know when bytes are ready, then initialize PDF controller
    _fileProvider = Provider.of<MyFile>(
      NavigationService.navigatorKey.currentContext!,
      listen: false,
    );
    _fileProvider!.addListener(_onFileProviderChanged);

    // Start timers and basic logic
    startTimer();

    // Initialize PDF safely
    _preparePdf();
  }

  void _onFileProviderChanged() {
    if (_pdfControllerPinch == null && 
        (_fileProvider?.bytes.isNotEmpty ?? false )) {
      _preparePdf();
    }
  }

  Future<void> _preparePdf() async {
    final fileProvider = _fileProvider ?? Provider.of<MyFile>(
      NavigationService.navigatorKey.currentContext!,
      listen: false,
    );

    if (fileProvider.isLoading || fileProvider.bytes.isEmpty) return;

    // Always use bytes — covers web, Android, iOS, and Firestore blobs
    final controller = PdfControllerPinch(
      document: PdfDocument.openData(fileProvider.bytes),
      initialPage: fileProvider.page,
    );
    controller.addListener(_onPageChanged);

    if (mounted) {
      setState(() => _pdfControllerPinch = controller);
    }
  }

  // void _onBytesReady() {
  //   final navContext = NavigationService.navigatorKey.currentContext!;
  //   final fileProvider = Provider.of<MyFile>(navContext, listen: false);
  //   if (!fileProvider.isLoading && fileProvider.bytes.isNotEmpty) {
  //     fileProvider.removeListener(_onBytesReady);
  //     _preparePdf();
  //   }
  // }

  void startTimer() {
    BuildContext navContext =
        NavigationService.navigatorKey.currentContext!;

    final preset = _getCurrentPomodoroPreset();

    final studyDuration = preset.studyDuration;

    endTime = DateTime.now().add(learnDuration);

    timer = Timer(learnDuration, () {
      showBreakTime(navContext);

      setState(() {
        hideFloatingButton = true;
      });
    });

    timerDisplay = Timer.periodic(
      const Duration(seconds: 1),
      (currentTime) {
        setState(() {
          int remaining =
              endTime.difference(DateTime.now()).inSeconds;

          if (remaining < 1) {
            timerDisplay.cancel();
          }

          remainingTime =
              formatDuration(remaining).toString();
        });
      },
    );

    setState(() {
      hideFloatingButton = false;
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
    _fileProvider?.removeListener(_onFileProviderChanged);
    _fileProvider = null;
    _pageChangeDebounce?.cancel();
    timer.cancel();
    timerDisplay.cancel();
    _pdfControllerPinch?.removeListener(_onPageChanged);
    _pdfControllerPinch?.dispose();
    super.dispose();
  }
  
  void _onPageChanged() {
    _pageChangeDebounce?.cancel();
    _pageChangeDebounce = Timer(const Duration(milliseconds: 300), () {
      _fileProvider?.setPage(_pdfControllerPinch!.page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = Provider.of<MyFile>(context);

    // If provider has an error, show it
    if (file.hasError) {
      return Scaffold(
        body: Center(child: Text(file.errorMessage ?? 'Something went wrong')),
      );
    }

    if (file.isLoading || _pdfControllerPinch == null) {
      return const Scaffold(
        backgroundColor: Colors.grey,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // If no name yet, show loading (happens during background fetch)
    if (file.name.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            FittedBox(fit: .scaleDown, child: _TimerDisplay(endTime: endTime),),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: _pdfControllerPinch == null
                ? null
                : () => _pdfControllerPinch!.previousPage(
                    curve: Curves.ease,
                    duration: const Duration(milliseconds: 100),
                  ),
          ),
          PdfPageNumber(
            controller: _pdfControllerPinch!,
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
            onPressed: _pdfControllerPinch == null
                ? null
                : () => _pdfControllerPinch?.nextPage(
                    curve: Curves.ease,
                    duration: const Duration(milliseconds: 100),
                  ),
          ),
        ],
      ),
      body: _pdfControllerPinch == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : PdfViewPinch(
              builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                options: const DefaultBuilderOptions(),
                documentLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                pageLoaderBuilder: (_) =>
                    const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, error) =>
                    Center(child: Text(error.toString())),
              ),
              controller: _pdfControllerPinch!,
            ),
      floatingActionButton: Visibility(
        visible: !hideFloatingButton,

        child: FloatingActionButton(
          tooltip: 'Test your knowledge',
          onPressed: () async {
            await generateQuizFromPdf(context);
          },
          child: Icon(Icons.quiz),
        ),
      ),
    );
  }

  Future<String?> showBreakTime(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => MyDialog(
        title: 'Have a break?',
        child: Column(
          children: [
            Expanded(
              child: SizedBox(
                height: .infinity,
                child: Center(
                  child: GridView(
                    shrinkWrap: true,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.75,
                    ),
                    children: [
                      Card(
                        elevation: 8,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Navigator.pushReplacementNamed(context, '/flappy');
                          },
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: .infinity,
                                    height: .infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(30),
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/bird-icon.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(child: Text('Flappy Bird')),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 8,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Navigator.pushReplacementNamed(context, '/snake');
                          },
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: .infinity,
                                    height: .infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(30),
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/snake-icon.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(child: Center(child: Text('Snake'))),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 8,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            Navigator.pushReplacementNamed(context, '/trex');
                          },
                          child: Column(
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    width: .infinity,
                                    height: .infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(30),
                                      ),
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/trex-icon.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(child: Center(child: Text('Trex'))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            MyButton(
              label: 'Continue Learning',
              onPressed: () {
                Navigator.pop(dialogContext);
                startTimer();
              },
              isActive: true,
            ),
            MyButton(
              label: 'Test your knowledge',
              isActive: true,
              onPressed: () async {
                await generateQuizFromPdf(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerDisplay extends StatefulWidget {
  final DateTime endTime;
  const _TimerDisplay({required this.endTime});

  @override
  State<_TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<_TimerDisplay> {
  late Timer _ticker;
  String _remaining = '';

  @override
  void initState() {
    super.initState();
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(_TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.endTime != widget.endTime) {
      _tick();
    }
  }

  void _tick() {
    final secs = widget.endTime.difference(DateTime.now()).inSeconds;
    if (mounted) setState(() => _remaining = _format(secs.clamp(0, 9999)));
  }

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(_remaining, style: const TextStyle(fontSize: 14));
}