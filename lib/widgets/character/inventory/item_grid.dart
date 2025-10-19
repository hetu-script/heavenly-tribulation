import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:samsara/widgets/ui/rrect_icon.dart';
import 'package:samsara/pointer_detector.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import '../../../ui.dart';

const kDefaultItemGridSize = Size(48.0, 48.0);

class ItemGrid extends StatelessWidget {
  const ItemGrid({
    super.key,
    this.size = kDefaultItemGridSize,
    this.margin,
    this.itemData,
    this.onTapped,
    this.onSecondaryTapped,
    this.onMouseEnter,
    this.onMouseExit,
    this.hasBorder = true,
    this.isSelected = false,
    this.isEquipped = false,
    this.child,
    this.showEquippedIcon = true,
  });

  final Size size;
  final EdgeInsetsGeometry? margin;
  final dynamic itemData;
  final void Function(dynamic itemData, Offset screenPosition)? onTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onSecondaryTapped;
  final void Function(dynamic itemData, Rect rect)? onMouseEnter;
  final void Function()? onMouseExit;
  final bool hasBorder;
  final bool isSelected, isEquipped;
  final Widget? child;
  final bool showEquippedIcon;

  @override
  Widget build(BuildContext context) {
    final String? icon = itemData?['icon'];
    final int stackSize = itemData?['stackSize'] ?? 1;
    // final bool showStack = itemData?['showStack'] ?? false;
    // final entityType = entityData?['entityType'];
    final int rank = itemData?['rank'] ?? 0;

    final isEquipped = itemData?['equippedPosition'] != null;

    return Material(
      type: MaterialType.transparency,
      child: MouseRegion(
        cursor: itemData == null
            ? MouseCursor.defer
            : FlutterCustomMemoryImageCursor(key: 'click'),
        onEnter: (event) {
          if (itemData == null) {
            return;
          }
          final Rect rect = getRenderRect(context);
          onMouseEnter?.call(itemData, rect);
        },
        onExit: (event) {
          onMouseExit?.call();
        },
        child: PointerDetector(
          onTapUp: (pointer, button, details) {
            if (itemData == null) return;
            if (button == kPrimaryButton) {
              onTapped?.call(itemData, details.globalPosition);
            } else if (button == kSecondaryButton) {
              onSecondaryTapped?.call(itemData, details.globalPosition);
            }
          },
          child: Container(
            width: size.width,
            height: size.height,
            margin: margin,
            decoration: hasBorder
                ? BoxDecoration(
                    // color: GameUI.backgroundColor,
                    border: Border.all(
                      color: isSelected
                          ? Colors.yellow
                          : GameUI.foregroundColor.withAlpha(64),
                    ),
                    image: DecorationImage(
                      fit: BoxFit.contain,
                      image:
                          AssetImage('assets/images/item/grid_rank$rank.png'),
                      opacity: 1,
                    ),
                    borderRadius: GameUI.borderRadius,
                  )
                : null,
            child: Stack(
              children: [
                if (icon != null)
                  RRectIcon(
                    image: AssetImage('assets/images/$icon'),
                    size: size,
                    borderRadius: GameUI.borderRadius,
                    borderColor: Colors.transparent,
                    borderWidth: 0.0,
                  ),
                if (child != null) child!,
                if (stackSize > 1)
                  Positioned(
                    right: 0,
                    bottom: -5,
                    child: Text(
                      stackSize.toString(),
                      style: const TextStyle(
                        color: Colors.yellow,
                        shadows: kTextShadow,
                      ),
                    ),
                  ),
                if (showEquippedIcon && isEquipped)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(2.5),
                      child: Image(
                        width: size.width / 3,
                        height: size.height / 3,
                        fit: BoxFit.contain,
                        image:
                            const AssetImage('assets/images/item/equipped.png'),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
