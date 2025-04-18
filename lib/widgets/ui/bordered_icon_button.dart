import 'package:flutter/material.dart';
import 'package:samsara/ui/mouse_region2.dart';
import 'package:samsara/paint/paint.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

class BorderedIconButton extends StatelessWidget {
  const BorderedIconButton({
    super.key,
    this.cursor,
    this.size = const Size(24.0, 24.0),
    this.child,
    this.padding = const EdgeInsets.all(0.0),
    this.borderRadius = 0.0,
    this.borderColor = Colors.white54,
    this.borderWidth = 1.0,
    this.onTapUp,
    this.onMouseEnter,
    this.onMouseExit,
    this.isSelected = false,
    this.isEnabled = true,
  });

  final MouseCursor? cursor;
  final Size size;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final bool isSelected;
  final bool isEnabled;

  final Function()? onTapUp;
  final Function(Rect rect)? onMouseEnter;
  final Function()? onMouseExit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          mouseCursor: MouseCursor.defer,
          onTapUp: (details) {
            if (!isEnabled) return;
            onTapUp?.call();
          },
          child: MouseRegion2(
            cursor: cursor ?? FlutterCustomMemoryImageCursor(key: 'click'),
            onMouseEnter: (rect) {
              onMouseEnter?.call(rect);
            },
            onMouseExit: () {
              onMouseExit?.call();
            },
            child: Container(
              width: size.width,
              height: size.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
                borderRadius: BorderRadius.circular(borderRadius),
                border: borderWidth > 0
                    ? Border.all(
                        color: borderColor,
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
      ),
    );
  }
}
