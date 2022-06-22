import 'package:flutter/material.dart';

class Label extends StatelessWidget {
  const Label(
    this.text, {
    super.key,
    this.width,
    this.height = 20.0,
    this.padding = const EdgeInsets.only(left: 5.0),
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

class LabelsWrap extends StatelessWidget {
  const LabelsWrap(
    this.text, {
    super.key,
    this.minWidth = 0.0,
    this.minHeight = 0.0,
    this.padding,
    this.children = const <Widget>[],
  });

  final String text;

  final double minWidth, minHeight;

  final EdgeInsetsGeometry? padding;

  final Iterable<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: minHeight,
      ),
      child: Wrap(
        children: [
          Label(text),
          ...children,
        ],
      ),
    );
  }
}
