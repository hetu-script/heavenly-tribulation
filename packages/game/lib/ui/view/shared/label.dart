import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label(
    this.text, {
    super.key,
    this.width,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 5.0),
  });

  final String text;

  final double? width, height;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      child: Text(text),
    );
  }
}
