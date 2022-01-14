import 'package:flutter/material.dart';

class InkImageButton extends StatelessWidget {
  final double? width, height;

  final Widget? child;

  const InkImageButton({Key? key, this.width, this.height, this.child})
      : super(key: key);

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
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {},
            child: child,
          ),
        ),
      ),
    );
  }
}
