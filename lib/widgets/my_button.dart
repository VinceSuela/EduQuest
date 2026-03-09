import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  const MyButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      width: .infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: .infinite,
          backgroundColor: isActive
              ? Color.fromARGB(100, 71, 184, 255)
              : Color.fromARGB(100, 172, 172, 155),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
          ),
        ),
        onPressed: () => {onPressed()},
        child: FittedBox(
          fit: .scaleDown,
          child: Text(
            label,
            style: TextStyle(fontSize: 20, color: Color(0xFF696969)),
          ),
        ),
      ),
    );
  }
}
