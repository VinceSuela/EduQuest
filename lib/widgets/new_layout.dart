import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    const LinearGradient gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFFFEE533), Color(0xFF47B9FF), Color(0xFF2A37FF)],
      stops: [0.0, 0.90, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(rect);
    final linePaint = Paint()..color = Colors.white;

    final path = Path();
    path.moveTo((size.width / 2) - 5, 10);
    path.quadraticBezierTo(size.width / 2, 0, (size.width / 2) + 5, 10);
    path.lineTo(size.width, size.height - 10);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - 10,
      size.height,
    );
    path.lineTo(10, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 10);
    path.close();

    canvas.drawPath(path, paint);

    canvas.clipPath(path);
    canvas.drawShadow(path, const Color.fromARGB(100, 0, 0, 0), 2, true);
    canvas.drawLine(Offset((size.width / 2), 40), Offset(0, 40), linePaint);
    canvas.drawLine(
      Offset((size.width / 2), 40 * 2),
      Offset(0, 40 * 2),
      linePaint,
    );

    canvas.drawLine(
      Offset((size.width / 2), 40 * 3),
      Offset(0, 40 * 3),
      linePaint,
    );
    canvas.drawLine(
      Offset((size.width / 2), 40 * 4),
      Offset(0, 40 * 4),
      linePaint,
    );
    canvas.drawLine(
      Offset((size.width / 2), 40 * 5),
      Offset(0, 40 * 5),
      linePaint,
    );
    canvas.drawLine(
      Offset((size.width / 2), 40 * 6),
      Offset(0, 40 * 6),
      linePaint,
    );
    canvas.drawLine(
      Offset((size.width / 2), 40 * 8),
      Offset(0, 40 * 8),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
