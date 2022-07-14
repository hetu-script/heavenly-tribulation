import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import 'battle_card.dart';
// import 'defense_card.dart';

const kEquipmentMaxOffense = 5;
const kEquipmentMaxSupport = 5;
const kEquipmentMaxDefense = 4;
const kEquipmentMaxCompanion = 4;

class BattleCards extends StatelessWidget {
  /// [activatedOffenseIndex] 表示目前正在激活的武器/斗技，表现为一个边框。默认是0，表示没有激活。
  const BattleCards({
    super.key,
    required this.characterData,
    required this.statsData,
    this.activatedOffenseIndex,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
  });

  /// 人物本身的数据，用来获取图片、属性等信息
  final HTStruct characterData;

  /// 战斗数据，用来计算血量变化等信息
  final HTStruct statsData;

  /// 当前正在激活的进攻单位
  final int? activatedOffenseIndex;

  /// 当前正在激活的进攻单位的冷却进度条的值
  final double cooldownValue;

  /// 当前正在激活的进攻单位的冷却进度条的颜色
  final Color cooldownColor;

  @override
  Widget build(BuildContext context) {
    final defenseItems = <Widget>[];
    for (var i = 1; i < kEquipmentMaxDefense; ++i) {
      final equipData = characterData['equipments']['defense'][i];
      final item = equipData != null
          ? engine
              .invoke('getEquipped', positionalArgs: [equipData, characterData])
          : null;
      defenseItems.add(Padding(
        padding: const EdgeInsets.all(5.0),
        child: BattleItemCard(
          size: const Size(48.0, 64.0),
          itemData: item,
          life: statsData['defense'][i]?['life'],
          lifeMax: statsData['defense'][i]?['lifeMax'],
        ),
      ));
    }

    final companions = <Widget>[];
    for (var i = 1; i < kEquipmentMaxCompanion; ++i) {
      final equipData = characterData['equipments']['companion'][i];
      final compnanion = equipData != null
          ? engine
              .invoke('getEquipped', positionalArgs: [equipData, characterData])
          : null;
      companions.add(Padding(
        padding: const EdgeInsets.all(5.0),
        child: BattleItemCard(
          size: const Size(48.0, 64.0),
          itemData: compnanion,
          life: statsData['companion'][i]?['life'],
          lifeMax: statsData['companion'][i]?['lifeMax'],
        ),
      ));
    }

    final offenseItems = <Widget>[];
    for (var i = 1; i < kEquipmentMaxOffense; ++i) {
      final equipData = characterData['equipments']['offense'][i];
      final item = equipData != null
          ? engine
              .invoke('getEquipped', positionalArgs: [equipData, characterData])
          : null;
      offenseItems.add(Padding(
        padding: const EdgeInsets.all(5.0),
        child: BattleItemCard(
          size: const Size(48.0, 120.0),
          itemData: item,
          isSelected: activatedOffenseIndex == i,
          life: statsData['offense'][i]?['life'],
          lifeMax: statsData['offense'][i]?['lifeMax'],
          cooldownValue: activatedOffenseIndex == i ? cooldownValue : 0,
          cooldownColor: cooldownColor,
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: BattleItemCard(
                size: const Size(48.0, 137.0),
                itemData: characterData,
                life: statsData['life'],
                lifeMax: statsData['lifeMax'],
              ),
            ),
            Column(
              children: [
                Row(
                  children: companions,
                ),
                Row(
                  children: defenseItems,
                ),
              ],
            )
          ],
        ),
        Row(
          children: offenseItems,
        ),
      ],
    );
  }
}
