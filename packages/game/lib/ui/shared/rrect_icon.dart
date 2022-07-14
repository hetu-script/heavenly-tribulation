import 'package:flutter/material.dart';

import '../../global.dart';

class RRectIcon extends StatelessWidget {
  const RRectIcon({
    super.key,
    required this.image,
    this.size = const Size(48.0, 48.0),
    required this.borderRadius,
    this.borderColor = kForegroundColor,
    this.borderWidth = 1.0,
  });

  final ImageProvider<Object> image;

  final Size size;

  final BorderRadius borderRadius;

  final Color borderColor;

  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: image,
          ),
          borderRadius: borderRadius,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
      ),
    );
  }
}
