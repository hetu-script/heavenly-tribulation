import 'package:flutter/material.dart';

import '../../global.dart';

class RRectIcon extends StatelessWidget {
  const RRectIcon({
    super.key,
    required this.avatarAssetKey,
    this.size = const Size(48.0, 48.0),
    this.radius = 5.0,
    this.borderColor = kForegroundColor,
    this.borderWidth = 1.0,
  });

  final String avatarAssetKey;

  final Size size;

  final double radius;

  final Color borderColor;

  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fill,
            image: AssetImage(avatarAssetKey),
          ),
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
      ),
    );
  }
}
