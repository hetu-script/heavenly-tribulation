import 'package:flutter/material.dart';

class InkImageButton extends StatelessWidget {
  final double? width, height;

  final Widget? child;

  final void Function() onPressed;

  final String? tooltip;

  final double borderRadius;

  const InkImageButton({
    Key? key,
    this.width,
    this.height,
    this.tooltip,
    this.child,
    this.borderRadius = 50,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Ink(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            width: 2,
            color: Colors.lightBlue,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Tooltip(
            decoration: BoxDecoration(
              color: Theme.of(context).backgroundColor,
            ),
            textStyle: const TextStyle(fontSize: 20.0),
            message: tooltip ?? '',
            child: InkWell(
              // customBorder: const CircleBorder(),
              onTap: onPressed,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
