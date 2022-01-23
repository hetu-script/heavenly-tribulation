import 'package:flutter/material.dart';

class ColoredPreferredSizeWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const ColoredPreferredSizeWidget({
    Key? key,
    this.color,
    required this.child,
  }) : super(key: key);

  final Color? color;
  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) => Material(
        color: color ?? Theme.of(context).backgroundColor,
        child: child,
      );
}
