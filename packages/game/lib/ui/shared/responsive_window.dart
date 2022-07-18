import 'package:flutter/material.dart';

import '../../global.dart';

class ResponsiveWindow extends StatelessWidget {
  const ResponsiveWindow({
    super.key,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
    this.size,
    this.margin = const EdgeInsets.all(50.0),
  });

  final Widget child;

  final AlignmentGeometry alignment;

  final Size? size;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (Global.orientationMode == OrientationMode.landscape) {
      return Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: alignment,
          children: [
            Container(
              width: size?.width,
              height: size?.height,
              margin: margin,
              alignment: Alignment.topCenter,
              decoration: BoxDecoration(
                borderRadius: kBorderRadius,
                border: Border.all(color: kForegroundColor),
              ),
              child: ClipRRect(
                borderRadius: kBorderRadius,
                child: child,
              ),
            ),
          ],
        ),
      );
    } else {
      return child;
    }
  }
}
