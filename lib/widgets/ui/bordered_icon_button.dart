import 'package:flutter/material.dart';
import 'package:samsara/paint/paint.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import '../../game/ui.dart';

class BorderedIconButton extends StatelessWidget {
  BorderedIconButton({
    this.cursor,
    this.size = const Size(24.0, 24.0),
    this.child,
    this.padding = const EdgeInsets.all(0.0),
    this.borderRadius = 0.0,
    this.borderWidth = 1.0,
    this.onPressed,
    this.onEnter,
    this.onExit,
    this.isSelected = false,
    this.isEnabled = true,
  }) : super(key: GlobalKey());

  final MouseCursor? cursor;
  final Size size;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderWidth;
  final bool isSelected;
  final bool isEnabled;

  final Function()? onPressed;
  final Function(Rect rect)? onEnter;
  final Function()? onExit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          mouseCursor: cursor ?? FlutterCustomMemoryImageCursor(key: 'click'),
          onTapUp: (details) {
            if (!isEnabled) return;
            onPressed?.call();
          },
          onHover: (hovering) {
            if (hovering) {
              if (onEnter == null) return;

              final renderBox = context.findRenderObject() as RenderBox;
              final Size size = renderBox.size;
              final Offset offset = renderBox.localToGlobal(Offset.zero);
              final Rect rect =
                  Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
              onEnter!.call(rect);
            } else {
              onExit?.call();
            }
          },
          child: Container(
            width: size.width,
            height: size.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  isSelected ? GameUI.focusedColorOpaque : Colors.transparent,
              borderRadius: BorderRadius.circular(borderRadius),
              border: borderWidth > 0
                  ? Border.all(
                      color: isSelected
                          ? GameUI.selectedColorOpaque
                          : GameUI.outlineColor,
                      width: borderWidth,
                    )
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: isEnabled
                  ? child
                  : ColorFiltered(
                      colorFilter: kColorFilterGreyscale,
                      child: child,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
