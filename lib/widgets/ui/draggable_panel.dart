import 'package:flutter/material.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/ui/preferred_size_widget.dart';
import 'package:samsara/pointer_detector.dart';

import '../../game/ui.dart';

class DraggablePanel extends StatelessWidget {
  final Offset position;
  final double? width, height;
  final double titleHeight;

  final String? title;

  final void Function()? onClose;
  final void Function(DragUpdateDetails details)? onDragUpdate;
  final void Function(Offset tapPosition)? onTapDown;

  final Widget? child;
  final Widget? titleBottomBar;

  const DraggablePanel({
    super.key,
    required this.position,
    this.titleHeight = kToolbarHeight,
    this.width,
    this.height,
    this.title,
    this.onClose,
    this.onDragUpdate,
    this.onTapDown,
    this.child,
    this.titleBottomBar,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            color: GameUI.backgroundColor2,
            // borderRadius: GameUI.borderRadius,
            // border: Border.all(color: Theme.of(context).colorScheme.onSurface),
          ),
          width: width,
          height: height,
          child: Scaffold(
            appBar: CustomPreferredSizeWidget(
              preferredSize: Size.fromHeight(titleHeight),
              bottom: titleBottomBar,
              child: Row(
                children: [
                  Expanded(
                    child: PointerDetector(
                      onTapDown: (pointer, button, details) {
                        onTapDown?.call(details.globalPosition - position);
                      },
                      onDragUpdate: (pointer, button, details) {
                        onDragUpdate?.call(details);
                      },
                      child: Text(
                        title ?? '',
                        textAlign: TextAlign.center,
                        style: GameUI.captionStyle,
                      ),
                    ),
                  ),
                  CloseButton2(
                    onPressed: () {
                      onClose?.call();
                    },
                  ),
                ],
              ),
            ),
            body: child,
          ),
        ),
      ),
    );
  }
}
