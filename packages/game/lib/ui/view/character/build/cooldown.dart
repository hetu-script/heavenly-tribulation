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
    // assert(0 < value && value <= 1.0);
    // final p = Paint()
    //   ..color = Colors.white.withOpacity(0.4)
    //   ..style = PaintingStyle.fill
    //   ..strokeWidth = 2;
    // final x = size.width / 2;
    // final y = size.height / 2;
    // assert(radius < x && radius < y);
    // final path = Path();
    // path.moveTo(x, y);
    // path.moveTo(x, -radius);
    // // between '\ |'
    // const eighth1 = 1.0 * 1 / 8;
    // double d, v;
    // if (value < eighth1) {
    //   d = (eighth1 - value) * 8 * x;
    //   path.relativeLineTo(d, 0);
    //   path.lineTo(x, y);
    // }

    final x = size.width / 2;
    final y = size.height / 2;
    assert(radius < x && radius < y);
    var p = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    canvas.drawLine(Offset(x, -radius), Offset(x * 2, -radius), p);
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
