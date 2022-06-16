import 'package:flutter/material.dart';

import '../../global.dart';

class ButtonClose extends StatelessWidget {
  const ButtonClose({Key? key, this.color, this.onPressed}) : super(key: key);

  final Color? color;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.close),
      color: color,
      tooltip: engine.locale['close'],
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.maybePop(context);
        }
      },
    );
  }
}
