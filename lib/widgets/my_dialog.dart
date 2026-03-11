import 'package:flutter/material.dart';

class MyDialog extends StatelessWidget {
  final Widget child;
  final String title;

  const MyDialog({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Color(0xFF47B9FF),
      child: SizedBox(
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 25,
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
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}
