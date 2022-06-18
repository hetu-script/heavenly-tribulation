import 'package:flutter/material.dart';

import '../../global.dart';

class ResponsiveRoute extends StatelessWidget {
  const ResponsiveRoute({
    Key? key,
    required this.child,
    this.alignment = AlignmentDirectional.topStart,
    this.size,
    this.margin = const EdgeInsets.all(50.0),
  }) : super(key: key);

  final Widget child;

  final AlignmentDirectional alignment;

  final Size? size;

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (GlobalConfig.orientationMode == OrientationMode.landscape) {
      return Stack(
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
      );
    } else {
      return child;
    }
  }
}
