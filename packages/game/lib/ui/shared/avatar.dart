import 'package:flutter/material.dart';

import 'rrect_icon.dart';
import '../../global.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    Key? key,
    this.name,
    this.onPressed,
    this.margin,
    this.avatarAssetKey,
    this.size = const Size(100.0, 100.0),
    this.radius = 10.0,
    this.borderColor = kForegroundColor,
    this.borderWidth = 2.0,
  }) : super(key: key);

  final String? name;

  final VoidCallback? onPressed;

  final EdgeInsetsGeometry? margin;

  final String? avatarAssetKey;

  final Size size;

  final double radius;

  final Color borderColor;

  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final stacked = <Widget>[
      if (avatarAssetKey != null)
        RRectIcon(
          margin: margin,
          avatarAssetKey: avatarAssetKey!,
          size: size,
          radius: radius,
          borderColor: borderColor,
          borderWidth: borderWidth,
        ),
      if (name != null)
        Positioned(
          top: size.height - 15.0,
          child: Container(
            color: Colors.blueGrey,
            child: Text(name!),
          ),
        )
    ];

    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: stacked,
          ),
        ),
      ),
    );
  }
}
