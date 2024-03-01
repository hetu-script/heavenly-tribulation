import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../config.dart';
import 'package:samsara/ui/flutter/rrect_icon.dart';
import '../../common.dart';

enum GridStyle {
  icon,
  card,
}

class EntityGrid extends StatelessWidget {
  const EntityGrid({
    super.key,
    this.style = GridStyle.icon,
    this.size = const Size(48.0, 48.0),
    this.entityData,
    this.onItemTapped,
    this.hasBorder = true,
    this.isSelected = false,
    this.isEquipped = false,
    this.child,
    this.backgroundImage,
    this.showEquippedIcon = true,
  });

  final GridStyle style;
  final Size size;
  final HTStruct? entityData;
  final void Function(HTStruct item, Offset screenPosition)? onItemTapped;
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

    final List? equippedSupportsData = entityData?['equippedSupports'];
    var supportedCount = equippedSupportsData?.length ?? 0;

    // String? levelString;
    // String? expString;
    // if (entityType == kEntityTypeSkill) {
    //   final int level = entityData!['level'];
    //   final int levelMax = entityData!['levelMax'];
    //   final int exp = entityData!['exp'];
    //   final int expForNextLevel = entityData!['expForNextLevel'];
    //   levelString = '${level + 1}/${levelMax + 1}';
    //   expString = '$exp/$expForNextLevel';
    // }

    switch (style) {
      case GridStyle.icon:
        return GestureDetector(
          onTapUp: (TapUpDetails details) {
            if (entityData != null && onItemTapped != null) {
              onItemTapped!(entityData!, details.globalPosition);
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
                            color: kForegroundColor
                                .withOpacity(isSelected ? 1 : 0.25),
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
                          image: AssetImage('assets/images/icon/$iconAssetKey'),
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
                      if (supportedCount > 0)
                        Container(
                          alignment: AlignmentDirectional.bottomEnd,
                          padding: const EdgeInsets.all(2.5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              for (var i = 0; i < supportedCount; ++i)
                                Image(
                                  width: size.width / 4,
                                  height: size.height / 4,
                                  fit: BoxFit.contain,
                                  image: const AssetImage(
                                      'assets/images/icon/item/supported.png'),
                                ),
                              // const Text(
                              //   '+',
                              //   style: TextStyle(
                              //     fontSize: 16.0,
                              //     color: Colors.blue,
                              //   ),
                              // )
                            ],
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
                              image: const AssetImage(
                                  'assets/images/icon/item/equipped.png'),
                            ),
                          ),
                        )
                    ],
                  )),
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
              GestureDetector(
                onTapUp: (TapUpDetails details) {
                  if (entityData != null && onItemTapped != null) {
                    onItemTapped!(entityData!, details.globalPosition);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
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
                                    'assets/images/icon/item/equipped.png'),
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
                            Text('${engine.locale['stackSize']}: $stackSize'),
                          // if (entityType == kEntityTypeSkill)
                          //   Text('${engine.locale['level']}: $levelString'),
                          if (entityType == kEntityTypeCharacter ||
                              entityType == kEntityTypeNpc)
                            Text(
                                '${engine.locale['coordination']}: ${entityData?['coordination']}'),
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
