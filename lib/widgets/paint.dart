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

class PoligonPainter extends CustomPainter {
  final Color color;

  PoligonPainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Color(0xFF47B9FF);

    final path = Path();
    path.moveTo((size.width / 2) - 10, 3);
    path.quadraticBezierTo(size.width / 2, 0, (size.width / 2) + 10, 3);
    path.lineTo(size.width - 5, (size.height / 2) - 7);
    path.quadraticBezierTo(
      size.width,
      (size.height / 2),
      size.width - 3,
      (size.height / 2) + 7,
    );
    path.lineTo(size.width - 10, size.height);
    path.lineTo(10, size.height);
    path.lineTo(3, (size.height / 2) + 7);
    path.quadraticBezierTo(0, (size.height / 2), 5, (size.height / 2) - 7);
    path.close();

    canvas.drawPath(path, paint);

    canvas.clipPath(path);
  }

  @override
  bool shouldRepaint(covariant PoligonPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class NavPainter extends CustomPainter {
  final Color color;

  NavPainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    const LinearGradient gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF47B9FF), Color(0xFF2E3AFE)],
      stops: [0.0, 1.0],
    );
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(rect);

    final path = Path();
    path.moveTo((size.width / 2) - 10, 3);
    path.quadraticBezierTo(size.width / 2, 0, (size.width / 2) + 10, 3);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.lineTo(0, size.height / 2);
    path.close();

    canvas.drawPath(path, paint);

    canvas.clipPath(path);
  }

  @override
  bool shouldRepaint(covariant NavPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
