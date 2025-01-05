import 'package:flutter/material.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/preferred_size_widget.dart';
import 'package:samsara/widgets/pointer_detector.dart';

import '../ui.dart';

class DraggablePanel extends StatelessWidget {
  final Offset position;
  final double? width, height;
  final double titleHeight;

  final String? title;

  final Function()? onClose;
  final Function(DragUpdateDetails details)? onDragUpdate;
  final Function(Offset tapPosition)? onTapDown;

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
            color: GameUI.backgroundColor,
            borderRadius: GameUI.borderRadius,
            border: Border.all(color: Theme.of(context).colorScheme.onSurface),
          ),
          width: width,
          height: height,
          child: Scaffold(
            appBar: CustomPreferredSizeWidget(
              preferredSize: Size.fromHeight(titleHeight),
              bottom: titleBottomBar,
              child: PointerDetector(
                onTapDown: (pointer, buttons, details) {
                  onTapDown?.call(details.globalPosition - position);
                },
                onDragUpdate: (pointer, buttons, details) {
                  onDragUpdate?.call(details);
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title ?? '',
                        textAlign: TextAlign.center,
                        style: GameUI.captionStyle,
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
            ),
            body: child,
          ),
        ),
      ),
    );
  }
}
