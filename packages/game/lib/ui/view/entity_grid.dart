import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../global.dart';

const kDefaultGridSize = Size(48.0, 48.0);

class EntityGrid extends StatelessWidget {
  const EntityGrid({
    super.key,
    this.size = kDefaultGridSize,
    this.entityData,
    required this.onSelect,
    this.hasBorder = true,
    this.isSelected = false,
    this.isEquipped = false,
    this.child,
    this.backgroundImage,
  });

  final Size size;
  final HTStruct? entityData;
  final void Function(HTStruct item, Offset screenPosition) onSelect;
  final bool hasBorder;
  final bool isSelected, isEquipped;
  final Widget? child;
  final ImageProvider<Object>? backgroundImage;

  @override
  Widget build(BuildContext context) {
    final String? iconAssetKey = entityData?['icon'];
    final int stackSize = entityData?['stackSize'] ?? 1;

    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        if (entityData != null) {
          onSelect(entityData!, details.globalPosition);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: entityData?['name'] ?? '',
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
                    ),
                  if (isEquipped)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Image(
                        width: size.width / 3,
                        height: size.height / 3,
                        fit: BoxFit.contain,
                        image: const AssetImage(
                            'assets/images/icon/item/equipped.png'),
                      ),
                    )
                ],
              )),
        ),
      ),
    );
  }
}
