import 'package:flutter/material.dart';

import 'package:samsara/ui/flutter/rrect_icon.dart';
import '../config.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.name,
    this.preferNameOnTop = false,
    this.margin,
    this.onPressed,
    this.image,
    this.size = const Size(100.0, 100.0),
    this.radius = 10.0,
    this.borderColor = kForegroundColor,
    this.borderWidth = 2.0,
  });

  final bool preferNameOnTop;

  final String? name;

  final EdgeInsetsGeometry? margin;

  final VoidCallback? onPressed;

  final ImageProvider<Object>? image;

  final Size size;

  final double radius;

  final Color borderColor;

  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final icon = image != null
        ? RRectIcon(
            image: image!,
            size: (name != null && preferNameOnTop)
                ? Size(size.width - 30, size.height - 30)
                : size,
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            borderColor: borderColor,
            borderWidth: borderWidth,
          )
        : null;

    final widgets = <Widget>[];

    if (preferNameOnTop) {
      if (name != null) {
        widgets.add(Align(
          alignment: Alignment.topCenter,
          child: Text(
            name!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      }
      if (icon != null) {
        widgets.add(Positioned(
          top: 30.0,
          child: icon,
        ));
      }
    } else {
      if (icon != null) {
        widgets.add(icon);
      }
      if (name != null) {
        final br = Radius.circular(radius);
        widgets.add(Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: size.width,
            decoration: BoxDecoration(
              color: kForegroundColor.withOpacity(0.75),
              borderRadius: BorderRadius.only(bottomLeft: br, bottomRight: br),
            ),
            child: Text(
              name!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kBackgroundColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }
    }

    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: onPressed != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          // color: Colors.red,
          margin: margin,
          width: size.width,
          height: size.height,
          child: Stack(
            children: widgets,
          ),
        ),
      ),
    );
  }
}
