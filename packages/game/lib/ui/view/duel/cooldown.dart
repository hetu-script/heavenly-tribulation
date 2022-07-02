import 'package:flutter/material.dart';

class CoolDownPainter extends CustomPainter {
  const CoolDownPainter({
    required this.value,
    this.color = Colors.white,
  });

  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (value == 0.0) return;
    var p = Paint()
      ..color = color
      ..strokeWidth = 4;
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width * value, size.height), p);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
