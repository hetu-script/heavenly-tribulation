import 'package:flutter/material.dart';

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({
    Key? key,
    this.size = const Size(24.0, 24.0),
    this.iconSize = 24.0,
    required this.icon,
    this.tooltip,
    this.margin,
    this.borderRadius = 5.0,
    required this.onPressed,
  }) : super(key: key);

  final Size size;

  final double iconSize;

  final Widget icon;

  final String? tooltip;

  final EdgeInsetsGeometry? margin;

  final double borderRadius;

  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      margin: margin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.white),
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
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onPressed,
            child: icon,
          ),
        ),
      ),
    );
  }
}
