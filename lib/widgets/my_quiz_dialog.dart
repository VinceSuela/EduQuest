import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/paint.dart';

class MyQuizDialog extends StatelessWidget {
  final Widget child;

  const MyQuizDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: SizedBox(
        height: 800,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: .center,
            children: [
              Center(
                child: CustomPaint(
                  painter: PoligonPainter(),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 30,
                      left: 15,
                      right: 15,
                    ),
                    child: Text(
                      'EduQuiz',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 30,
                        shadows: [
                          Shadow(
                            color: const Color.fromARGB(167, 0, 0, 0),
                            offset: Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF47B9FF),
                    borderRadius: BorderRadius.all(.circular(20)),
                  ),
                  child: Padding(
                    padding: .all(8.0),
                    child: Card(
                      child: SizedBox(
                        width: .infinity,
                        height: 200,
                        child: Column(children: [Expanded(child: child)]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
