import 'package:flutter/material.dart';

class LinearPainter extends CustomPainter {
  LinearPainter({
    required this.beginPosition,
    required this.endPosition,
    this.beginColor = const Color.fromARGB(0, 255, 255, 255),
    this.endColor = const Color.fromARGB(255, 255, 255, 255),
  });

  final AlignmentGeometry beginPosition, endPosition;
  final Color beginColor, endColor;

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect =
        Rect.fromPoints(const Offset(0, 0), Offset(size.width, size.height));
    LinearGradient lg = LinearGradient(
      begin: beginPosition,
      end: endPosition,
      colors: const [
        //create 2 white colors, one transparent
        Color.fromARGB(0, 255, 255, 255),
        Color.fromARGB(255, 255, 255, 255),
      ],
    );
    Paint paint = Paint()..shader = lg.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(LinearPainter linePainter) => false;
}
