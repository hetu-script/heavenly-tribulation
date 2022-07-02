import 'package:flutter/material.dart';

import 'shared/rrect_icon.dart';
import '../global.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.name,
    this.margin = const EdgeInsets.all(5.0),
    this.onPressed,
    this.avatarAssetKey,
    this.size = const Size(100.0, 100.0),
    this.radius = 10.0,
    this.borderColor = kForegroundColor,
    this.borderWidth = 2.0,
  });

  final String? name;

  final EdgeInsetsGeometry margin;

  final VoidCallback? onPressed;

  final String? avatarAssetKey;

  final Size size;

  final double radius;

  final Color borderColor;

  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          margin: margin,
          width: size.width,
          height: size.height,
          child: Stack(
            children: [
              if (avatarAssetKey != null)
                RRectIcon(
                  avatarAssetKey: avatarAssetKey!,
                  size: size,
                  radius: radius,
                  borderColor: borderColor,
                  borderWidth: borderWidth,
                ),
              if (name != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(radius)),
                      color: Colors.white.withOpacity(0.5),
                    ),
                    child: Text(
                      name!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kBackgroundColor),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
