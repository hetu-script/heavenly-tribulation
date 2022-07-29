import 'package:flutter/material.dart';

import '../../global.dart';

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({
    super.key,
    this.size = const Size(24.0, 24.0),
    this.iconSize = 24.0,
    required this.icon,
    this.tooltip,
    this.padding = const EdgeInsets.all(0.0),
    this.borderRadius = 5.0,
    required this.onPressed,
  });

  final Size size;

  final double iconSize;

  final Widget icon;

  final String? tooltip;

  final EdgeInsetsGeometry padding;

  final double borderRadius;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GestureDetector(
        onTap: onPressed,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: size.width,
            height: size.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: kForegroundColor),
              // shape: BoxShape.rectangle,
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.grey.withOpacity(0.5),
              //     spreadRadius: 3,
              //     blurRadius: 6,
              //     offset: const Offset(0, 2), // changes position of shadow
              //   ),
              // ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
