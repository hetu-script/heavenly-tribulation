import 'package:flutter/material.dart';
import 'bordered_icon_button.dart';

import '../../game/ui.dart';

class CloseButton2 extends StatelessWidget {
  const CloseButton2({
    super.key,
    this.color,
    this.onPressed,
    this.tooltip,
    this.child,
  });

  final Color? color;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return BorderedIconButton(
      size: GameUI.infoButtonSize,
      padding: const EdgeInsets.all(2),
      borderRadius: 5.0,
      onPressed: () {
        if (onPressed != null) {
          onPressed!();
        } else {
          Navigator.maybePop(context, null);
        }
      },
      onEnter: (rect) {},
      onExit: () {},
      child: const Icon(Icons.close),
    );
  }
}
