import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../config.dart';
import 'battle_item_card.dart';
// import 'defense_card.dart';
import 'package:samsara/ui/dynamic_color_progressbar.dart';
import '../avatar.dart';
import '../../common.dart';

// const kEquipmentMaxOffense = 5;
// const kEquipmentMaxSupport = 5;
// const kEquipmentMaxDefense = 4;
// const kEquipmentMaxCompanion = 4;

const kStatsBarWidth = 120.0;

class BattlePanel extends StatelessWidget {
  /// [activatedOffenseIndex] 表示目前正在激活的武器/斗技，表现为一个边框。默认是0，表示没有激活。
  const BattlePanel({
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
    final equipments = <Widget>[];
    for (var i = 1; i < kEquipmentMax; ++i) {
      final equipData = characterData['equipments'][i];
      final item = equipData != null
          ? engine.hetu
              .invoke('getEquipped', positionalArgs: [equipData, characterData])
          : null;
      equipments.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: BattleItemCard(
            size: const Size(40.0, 64.0),
            itemData: item,
            isSelected: activatedOffenseIndex == i,
            life: statsData['equipments'][i]?['life'],
            lifeMax: statsData['equipments'][i]?['lifeMax'],
            cooldownValue: cooldownValue,
            cooldownColor: cooldownColor,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: Avatar(
                displayName: characterData['name'],
                image: AssetImage('assets/images/${characterData['icon']}'),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale('life')}: ',
                    value: statsData['life'],
                    max: statsData['lifeMax'],
                    width: kStatsBarWidth,
                    height: 20.0,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.red, Colors.red],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale('stamina')}: ',
                    value: statsData['stamina'],
                    max: statsData['staminaMax'],
                    width: kStatsBarWidth,
                    height: 20.0,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.blue, Colors.blue],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale('mana')}: ',
                    value: statsData['mana'],
                    max: statsData['manaMax'],
                    width: kStatsBarWidth,
                    height: 20.0,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.yellow, Colors.yellow],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5.0),
                  child: DynamicColorProgressBar(
                    title: '${engine.locale('spirit')}: ',
                    value: statsData['spirit'],
                    max: statsData['spiritMax'],
                    width: kStatsBarWidth,
                    height: 20.0,
                    showNumberAsPercentage: false,
                    colors: const <Color>[Colors.green, Colors.green],
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: equipments,
        ),
      ],
    );
  }
}
