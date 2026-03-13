import 'dart:async';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/widgets/my_quiz_dialog.dart';
import 'package:flutter_pomodoro/widgets/paint.dart';
import 'package:provider/provider.dart';

class BottomNavigation extends StatelessWidget {
  final bool hideBottomNav;
  final bool hideBackButton;
  final String backUrl;

  const BottomNavigation({
    super.key,
    this.hideBottomNav = false,
    this.hideBackButton = false,
    this.backUrl = '/home',
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NavPainter(),
      child: Container(
        height: !hideBottomNav ? 100 : 60,
        clipBehavior: .none,
        // decoration: BoxDecoration(
        //   image: DecorationImage(
        //     image: AssetImage('assets/images/bottom-bar.png'),
        //     fit: .cover,
        //     alignment: .topCenter,
        //   ),
        // ),
        child: !hideBottomNav ? renderButtons() : renderBackButton(context),
        //SizedBox(width: .infinity),
      ),
    );
  }

  Transform renderButtons() {
    return Transform.translate(
      offset: Offset(0, 0),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        crossAxisAlignment: .end,
        children: [GenerateQuiz(), StartLearning(), ReviewQuizes()],
      ),
    );
  }

  Widget renderBackButton(BuildContext context) {
    return SizedBox(
      width: .infinity,
      child: Visibility(
        visible: !hideBackButton,
        child: TextButton(
          style: ButtonStyle(overlayColor: WidgetStateColor.transparent),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pushReplacementNamed(context, backUrl);
            }
          },
          child: Text('Back', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class ReviewQuizes extends StatelessWidget {
  const ReviewQuizes({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: GestureDetector(
        onTap: () {
          showQuiz(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/review-button.png'),
        ),
      ),
    );
  }

  Future<String?> showQuiz(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => MyQuizDialog(
        child: Center(
          child: Text(
            'Content here',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}

class GenerateQuiz extends StatelessWidget {
  const GenerateQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: GestureDetector(
        onTap: () {
          if (Provider.of<MyFile>(
            NavigationService.navigatorKey.currentContext!,
            listen: false,
          ).name.isNotEmpty) {
            Navigator.pushReplacementNamed(
              NavigationService.navigatorKey.currentContext!,
              '/pdfViewer',
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/generate-button.png',
            fit: .contain,
          ),
        ),
      ),
    );
  }
}

class StartLearning extends StatelessWidget {
  const StartLearning({super.key});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 8,
      child: GestureDetector(
        onTap: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            withData: true,
          );

          if (result != null) {
            if (!context.mounted) return;
            PlatformFile file = result.files.single;
            Provider.of<MyFile>(
              NavigationService.navigatorKey.currentContext!,
              listen: false,
            ).setFile(file, result.files.single.name);
            Navigator.of(
              NavigationService.navigatorKey.currentContext!,
            ).pushReplacementNamed('/pdfViewer');
          } else {
            return;
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Image.asset('assets/images/start-button.png'),
        ),
      ),
    );
  }
}
