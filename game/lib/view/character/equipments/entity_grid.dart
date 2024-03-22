import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:samsara/ui/rrect_icon.dart';
import 'package:samsara/widget/pointer_detector.dart';

import '../../../config.dart';
import '../../../common.dart';

enum GridStyle {
  icon,
  card,
}

class EntityGrid extends StatelessWidget {
  EntityGrid({
    this.style = GridStyle.icon,
    this.size = const Size(48.0, 48.0),
    this.entityData,
    this.onMouseEnterItemGrid,
    this.onMouseExitItemGrid,
    this.onTapped,
    this.onSecondaryTapped,
    this.hasBorder = true,
    this.isSelected = false,
    this.isEquipped = false,
    this.child,
    this.backgroundImage,
    this.showEquippedIcon = true,
  }) : super(key: GlobalKey());

  final GridStyle style;
  final Size size;
  final dynamic entityData;
  final void Function(dynamic entityData, Rect gridRenderBox)?
      onMouseEnterItemGrid;
  final void Function(dynamic entityData, Rect gridRenderBox)?
      onMouseExitItemGrid;
  final void Function(dynamic entityData, Offset screenPosition)? onTapped;
  final void Function(dynamic entityData, Offset screenPosition)?
      onSecondaryTapped;
  final bool hasBorder;
  final bool isSelected, isEquipped;
  final Widget? child;
  final ImageProvider<Object>? backgroundImage;
  final bool showEquippedIcon;

  @override
  Widget build(BuildContext context) {
    final String? iconAssetKey = entityData?['icon'];
    final int stackSize = entityData?['stackSize'] ?? 1;
    final entityType = entityData?['entityType'];

    final isEquipped = entityData?['isEquippable'] == true &&
        entityData?['equippedPosition'] != null;

    switch (style) {
      case GridStyle.icon:
        return PointerDetector(
          onTapUp: (int pointer, int buttons, TapUpDetails details) {
            if (entityData == null) return;

            if (buttons == kPrimaryButton) {
              onTapped?.call(entityData, details.globalPosition);
            } else if (buttons == kSecondaryButton) {
              onSecondaryTapped?.call(entityData, details.globalPosition);
            }
          },
          child: MouseRegion(
            cursor: entityData != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            onEnter: (event) {
              if (entityData == null || onMouseEnterItemGrid == null) {
                return;
              }

              final renderBox = (key as GlobalKey)
                  .currentContext!
                  .findRenderObject() as RenderBox;
              final Size size = renderBox.size;
              final Offset offset = renderBox.localToGlobal(Offset.zero);
              final Rect rect =
                  Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

              onMouseEnterItemGrid?.call(entityData, rect);
            },
            onExit: (event) {
              if (entityData == null || onMouseExitItemGrid == null) {
                return;
              }

              final renderBox = (key as GlobalKey)
                  .currentContext!
                  .findRenderObject() as RenderBox;
              final Size size = renderBox.size;
              final Offset offset = renderBox.localToGlobal(Offset.zero);
              final Rect rect =
                  Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);

              onMouseExitItemGrid?.call(entityData, rect);
            },
            child: Container(
              width: size.width,
              height: size.height,
              decoration: hasBorder
                  ? BoxDecoration(
                      color: kBackgroundColor,
                      border: Border.all(
                        color:
                            kForegroundColor.withOpacity(isSelected ? 1 : 0.25),
                      ),
                      image: backgroundImage != null
                          ? DecorationImage(
                              fit: BoxFit.contain,
                              image: backgroundImage!,
                              opacity: 0.2,
                            )
                          : null,
                      borderRadius: kBorderRadius,
                    )
                  : null,
              child: Stack(
                children: [
                  if (iconAssetKey != null)
                    RRectIcon(
                      image: AssetImage('assets/images/$iconAssetKey'),
                      size: size,
                      borderRadius: kBorderRadius,
                      borderColor: Colors.transparent,
                      borderWidth: 0.0,
                    ),
                  if (child != null) child!,
                  if (stackSize > 1)
                    Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Text(stackSize.toString()),
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
                          image: const AssetImage(
                              'assets/images/item/equipped.png'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      case GridStyle.card:
        final iconSize = size.height - 10.0;
        return Container(
          padding: const EdgeInsets.all(10.0),
          decoration: hasBorder
              ? BoxDecoration(
                  color: kBackgroundColor,
                  border: Border.all(
                    color: kForegroundColor.withOpacity(0.75),
                  ),
                  image: backgroundImage != null
                      ? DecorationImage(
                          fit: BoxFit.contain,
                          image: backgroundImage!,
                          opacity: 0.2,
                        )
                      : null,
                  borderRadius: kBorderRadius,
                )
              : null,
          child: Row(
            children: [
              PointerDetector(
                onTapUp: (int pointer, int buttons, TapUpDetails details) {
                  if (entityData == null) return;

                  if (buttons == kPrimaryButton) {
                    onTapped?.call(entityData, details.globalPosition);
                  } else if (buttons == kSecondaryButton) {
                    onSecondaryTapped?.call(entityData, details.globalPosition);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (event) {
                    if (entityData == null || onMouseEnterItemGrid == null) {
                      return;
                    }

                    final renderBox = (key as GlobalKey)
                        .currentContext!
                        .findRenderObject() as RenderBox;
                    final Size size = renderBox.size;
                    final Offset offset = renderBox.localToGlobal(Offset.zero);
                    final Rect rect = Rect.fromLTWH(
                        offset.dx, offset.dy, size.width, size.height);

                    onMouseEnterItemGrid?.call(entityData, rect);
                  },
                  onExit: (event) {
                    if (entityData == null || onMouseExitItemGrid == null) {
                      return;
                    }

                    final renderBox = (key as GlobalKey)
                        .currentContext!
                        .findRenderObject() as RenderBox;
                    final Size size = renderBox.size;
                    final Offset offset = renderBox.localToGlobal(Offset.zero);
                    final Rect rect = Rect.fromLTWH(
                        offset.dx, offset.dy, size.width, size.height);

                    onMouseExitItemGrid?.call(entityData, rect);
                  },
                  child: Container(
                      width: size.height,
                      height: size.height,
                      padding: const EdgeInsets.all(5.0),
                      decoration: BoxDecoration(
                        color: kBackgroundColor,
                        border: Border.all(
                          color: kForegroundColor.withOpacity(0.5),
                        ),
                        image: backgroundImage != null
                            ? DecorationImage(
                                fit: BoxFit.contain,
                                image: backgroundImage!,
                                opacity: 0.2,
                              )
                            : null,
                        borderRadius: kBorderRadius,
                      ),
                      child: Stack(
                        children: [
                          if (iconAssetKey != null)
                            RRectIcon(
                              image: AssetImage(
                                  'assets/images/icon/$iconAssetKey'),
                              size: Size(iconSize, iconSize),
                              borderRadius: kBorderRadius,
                              borderColor: Colors.transparent,
                              borderWidth: 0.0,
                            ),
                          if (showEquippedIcon && isEquipped)
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: Image(
                                width: size.width / 4,
                                height: size.height / 4,
                                fit: BoxFit.contain,
                                image: const AssetImage(
                                    'assets/images/item/equipped.png'),
                              ),
                            )
                        ],
                      )),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entityData?['name'] ?? ''),
                          if (entityType == kEntityTypeItem && stackSize > 1)
                            Text('${engine.locale('stackSize')}: $stackSize'),
                          // if (entityType == kEntityTypeSkill)
                          //   Text('${engine.locale('level']}: $levelString'),
                          // if (entityType == kEntityTypeCharacter ||
                          //     entityType == kEntityTypeNpc)
                          //   Text(
                          //       '${engine.locale('coordination')}: ${entityData?['coordination']}'),
                        ],
                      ),
                      Text(entityData?['description'] ?? ''),
                    ],
                  ),
                ),
              ),
              if (child != null) child!,
            ],
          ),
        );
    }
  }
}
