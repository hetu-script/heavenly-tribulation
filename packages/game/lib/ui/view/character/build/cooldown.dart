import 'package:flutter/material.dart';

class CoolDownPainter extends CustomPainter {
  const CoolDownPainter({
    required this.value,
    required this.radius,
  });

  final double value, radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (value == 0.0) return;
    var p = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 4;
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width * value, size.height), p);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CooldownIndicator extends StatefulWidget {
  const CooldownIndicator({
    super.key,
    this.size = const Size(48.0, 48.0),
    this.value = 0.0,
  });

  final Size size;

  final double value;

  @override
  State<CooldownIndicator> createState() => _CooldownIndicatorState();
}

class _CooldownIndicatorState extends State<CooldownIndicator> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: CoolDownPainter(value: widget.value, radius: 5.0),
    );
  }
}
