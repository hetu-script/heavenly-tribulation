import 'package:flutter/material.dart';

class InkImageButton extends StatelessWidget {
  final double width, height;

  final Widget? child;

  final void Function() onPressed;

  final String? tooltip;

  const InkImageButton({
    Key? key,
    this.width = 40,
    this.height = 40,
    this.tooltip,
    this.child,
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
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            width: 2,
            color: Colors.lightBlue.withOpacity(0.5),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Tooltip(
            textStyle: const TextStyle(fontSize: 20.0),
            message: tooltip,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
