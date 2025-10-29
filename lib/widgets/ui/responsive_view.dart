import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../ui.dart';

class ResponsiveView extends StatelessWidget {
  const ResponsiveView({
    super.key,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(0.0),
    this.margin,
    this.borderRadius = 5.0,
    this.borderColor = GameUI.borderColor,
    this.borderWidth = 2.0,
    this.backgroundColor = Colors.transparent,
    this.barrierColor = Colors.transparent,
    this.barrierDismissible = true,
    this.onBarrierDismissed,
    this.cursor = GameUI.cursor,
    this.child,
    this.children = const [],
  });

  final AlignmentGeometry alignment;
  final double? width, height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final Color? barrierColor;
  final bool barrierDismissible;
  final void Function()? onBarrierDismissed;
  final MouseCursor cursor;
  final Widget? child;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            if (barrierColor != null)
              ModalBarrier(
                color: barrierColor,
                onDismiss: () {
                  if (barrierDismissible) {
                    if (onBarrierDismissed != null) {
                      onBarrierDismissed!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  }
                },
              ),
            Align(
              alignment: alignment,
              child: Container(
                width: width,
                height: height,
                padding: padding,
                margin: margin,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: borderRadius != null
                      ? BorderRadius.circular(borderRadius!)
                      : null,
                  border: borderWidth > 0
                      ? Border.fromBorderSide(
                          BorderSide(
                            color: borderColor,
                            width: borderWidth,
                          ),
                        )
                      : null,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: fluent.Acrylic(
                        luminosityAlpha: 0.4,
                        blurAmount: 5.0,
                      ),
                    ),
                    if (child != null) child!,
                  ],
                ),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
