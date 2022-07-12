import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../entity_grid.dart';
import '../../../global.dart';
import '../entity_info.dart';
import '../character/character.dart';
import '../../shared/dynamic_color_progressbar.dart';

class DefenseItemCard extends StatelessWidget {
  const DefenseItemCard({
    super.key,
    this.itemData,
    this.life,
    this.lifeMax,
    this.size = const Size(60.0, 80.0),
    this.isActivated = false,
  });

  final HTStruct? itemData;

  final int? life, lifeMax;

  final Size size;

  final bool isActivated;

  void _onItemTapped(
      BuildContext context, HTStruct item, Offset screenPosition) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          if (item['entityType'] == kEntityTypeItem ||
              item['entityType'] == kEntityTypeSkill ||
              item['entityType'] == kEntityTypeNpc) {
            return EntityInfo(
              entityData: item,
              left: screenPosition.dx,
            );
          } else if (item['entityType'] == kEntityTypeCharacter) {
            return CharacterView(
              characterData: item,
            );
          }
          throw '错误的游戏对象数据（并非物品或人物）：\n$item';
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        border: Border.all(
          color: Colors.white.withOpacity(isActivated ? 1 : 0.25),
          width: 2,
        ),
        borderRadius: kBorderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (life != null && lifeMax != null)
            DynamicColorProgressBar(
              width: size.width - 12.0,
              height: 12.0,
              value: life!,
              max: lifeMax!,
              showNumber: false,
              colors: const <Color>[Colors.red, Colors.green],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: EntityGrid(
              entityData: itemData,
              hasBorder: false,
              onSelect: (item, screenPosition) =>
                  _onItemTapped(context, item, screenPosition),
            ),
          ),
        ],
      ),
    );
  }
}
