import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:pdfx/pdfx.dart';
import 'package:docx_file_viewer/docx_file_viewer.dart';
import 'package:provider/provider.dart';

class BottomNavigation extends StatelessWidget {
  final bool hideBottomNav;
  final bool hideBackButton;

  const BottomNavigation({
    super.key,
    required this.hideBottomNav,
    this.hideBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: !hideBottomNav ? 100 : 60,
      clipBehavior: .none,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/images/bottom-bar.png'),
          fit: .cover,
          alignment: .topCenter,
        ),
      ),
      child: !hideBottomNav ? renderButtons() : renderBackButton(context),
      //SizedBox(width: .infinity),
    );
  }

  Transform renderButtons() {
    return Transform.translate(
      offset: Offset(0, 0),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        crossAxisAlignment: .end,
        children: [
          GenerateQuiz(),
          StartLearning(),
          ReviewQuizes(),
        ],
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
              Navigator.pop(context);
            }
          },
          child: Text('Back', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class ReviewQuizes extends StatelessWidget {
  const ReviewQuizes({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: GestureDetector(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('asset/images/review-button.png'),
        ),
      ),
    );
  }
}

class GenerateQuiz extends StatelessWidget {
  const GenerateQuiz({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 3,
      child: GestureDetector(
        onTap: () {Navigator.pushNamed(context, '/pdfViewer');},
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'asset/images/generate-button.png',
            fit: .contain,
          ),
        ),
      ),
    );
  }
}

class StartLearning extends StatefulWidget {

  const StartLearning({
    super.key,
  });

  @override
  State<StartLearning> createState() => _StartLearningState();
}

class _StartLearningState extends State<StartLearning> {
  late PdfControllerPinch pdfPinchController;
  bool showpdf = false;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: 8,
      child: GestureDetector(
        onTap: () async {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'docx'],
          );

          if (result != null) {
            File file = File(result.files.single.path!);
            Provider.of<MyFile>(NavigationService.navigatorKey.currentContext!, listen: false).setFile(file);
            Navigator.pushNamed(NavigationService.navigatorKey.currentContext!, '/pdfViewer');
          } 
          else {
            return;
          }
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Image.asset('asset/images/start-button.png'),
        ),
      ),
    );
  }
}
