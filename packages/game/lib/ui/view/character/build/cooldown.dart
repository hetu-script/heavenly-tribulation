import 'package:flutter/material.dart';

class CoolDownPainter extends CustomPainter {
  const CoolDownPainter({
    required this.value,
    required this.radius,
    this.color = Colors.white,
  });

  final double value, radius;
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

class CooldownIndicator extends StatelessWidget {
  const CooldownIndicator({
    super.key,
    this.size = const Size(48.0, 48.0),
    this.value = 0.0,
    this.color = Colors.white,
  });

  final Size size;

  final double value;

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: CoolDownPainter(
        value: value,
        radius: 5.0,
        color: color,
      ),
    );
  }
}
