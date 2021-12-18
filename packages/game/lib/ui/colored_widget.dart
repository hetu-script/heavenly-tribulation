import 'package:flutter/material.dart';

class ColoredPreferredSizeWidget extends StatelessWidget
    implements PreferredSizeWidget {
  const ColoredPreferredSizeWidget({
    Key? key,
    required this.backgroundColor,
    required this.child,
  }) : super(key: key);

  final Color backgroundColor;
  final PreferredSizeWidget child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) => Material(
        color: backgroundColor,
        child: child,
      );
}
