import 'package:flutter/material.dart';

class ColoredPreferredSizeWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const ColoredPreferredSizeWidget({
    super.key,
    this.color,
    required this.child,
  });

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
