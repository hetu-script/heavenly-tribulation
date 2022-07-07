import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../../global.dart';

const kItemGridDefaultSize = Size(48.0, 48.0);

class ItemGrid extends StatelessWidget {
  const ItemGrid({
    super.key,
    this.size = kItemGridDefaultSize,
    this.itemData,
    required this.onSelect,
    this.hasBorder = true,
    this.isSelected = false,
    this.child,
    this.backgroundImage,
  });

  final Size size;
  final HTStruct? itemData;
  final void Function(HTStruct item, Offset screenPosition) onSelect;
  final bool hasBorder;
  final bool isSelected;
  final Widget? child;
  final ImageProvider<Object>? backgroundImage;

  @override
  Widget build(BuildContext context) {
    final String? iconAssetKey = itemData?['icon'];
    final int stackSize = itemData?['stackSize'] ?? 1;

    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        if (itemData != null) {
          onSelect(itemData!, details.globalPosition);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: itemData?['name'] ?? '',
          child: Container(
              width: size.width,
              height: size.height,
              decoration: hasBorder
                  ? BoxDecoration(
                      color: kBackgroundColor,
                      border: Border.all(
                        color: Colors.white.withOpacity(isSelected ? 1 : 0.25),
                        width: 2,
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
                    Image(
                      width: size.width,
                      height: size.height,
                      fit: BoxFit.fill,
                      image: AssetImage('assets/images/$iconAssetKey'),
                    ),
                  if (child != null) child!,
                  if (stackSize > 1)
                    Align(
                      alignment: AlignmentDirectional.bottomEnd,
                      child: Text(stackSize.toString()),
                    )
                ],
              )),
        ),
      ),
    );
  }
}
