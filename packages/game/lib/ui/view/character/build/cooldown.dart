import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../util.dart';

class CoolDownPainter extends CustomPainter {
  const CoolDownPainter({
    required this.value,
    required this.radius,
  });

  final double value, radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (value >= 1.0) return;
    final x = size.width / 2;
    final y = size.height / 2;
    assert(radius < x && radius < y);
    final path = Path();
    var p = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..strokeWidth = 1;
    path.moveTo(x, y);
    path.relativeLineTo(0, -y);
    path.relativeLineTo(x - radius, 0);
    path.relativeArcToPoint(Offset(radius, radius),
        radius: Radius.circular(radius));
    path.relativeLineTo(0, y - radius);
    path.relativeLineTo(-x, 0);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class CooldownIndicator extends StatefulWidget {
  const CooldownIndicator({
    super.key,
    this.size = const Size(48.0, 48.0),
  });

  final Size size;

  @override
  State<CooldownIndicator> createState() => _CooldownIndicatorState();
}

class _CooldownIndicatorState extends State<CooldownIndicator> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: widget.size,
      painter: const CoolDownPainter(value: 0.4, radius: 5.0),
    );
  }
}
