import 'package:flutter/material.dart';

class MyTitle extends StatelessWidget {
  const MyTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: .bottomCenter,
      height: 80,
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFF5E5E5E),
          fontSize: 25,
          shadows: [
            Shadow(
              color: Color.fromARGB(100, 255, 213, 0),
              offset: Offset(1, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
