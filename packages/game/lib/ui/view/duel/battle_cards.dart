import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import 'offense_card.dart';
// import 'defense_card.dart';

// const _kDefenseItemMax = 4;
const _kOffenseItemMax = 5;

class BattleCards extends StatelessWidget {
  /// [activatedIndex] 表示目前正在激活的武器/斗技，表现为一个边框。默认是0，表示没有激活。
  const BattleCards({
    super.key,
    required this.characterData,
    this.activatedIndex,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
  });

  final HTStruct characterData;

  final int? activatedIndex;

  final double cooldownValue;

  final Color cooldownColor;

  @override
  Widget build(BuildContext context) {
    // final defenseItems = <Widget>[];
    // defenseItems.add(Padding(
    //   padding: const EdgeInsets.all(5.0),
    //   child: DefenseItemCard(
    //     itemData: characterData,
    //   ),
    // ));
    // for (var i = 1; i < _kDefenseItemMax; ++i) {
    //   final equipData = characterData['equipments']['defense'][i];
    //   final item = equipData != null
    //       ? engine.invoke('getEquippedEntity',
    //           positionalArgs: [equipData, characterData])
    //       : null;
    //   defenseItems.add(Padding(
    //     padding: const EdgeInsets.all(5.0),
    //     child: DefenseItemCard(
    //       itemData: item,
    //     ),
    //   ));
    // }

    final offenseItems = <Widget>[];
    for (var i = 1; i < _kOffenseItemMax; ++i) {
      final equipData = characterData['equipments']['offense'][i];
      final item = equipData != null
          ? engine.invoke('getEquippedEntity',
              positionalArgs: [equipData, characterData])
          : null;
      offenseItems.add(Padding(
        padding: const EdgeInsets.all(5.0),
        child: OffenseItemCard(
          itemData: item,
          isSelected: activatedIndex == i,
          cooldownValue: activatedIndex == i ? cooldownValue : 0,
          cooldownColor: cooldownColor,
        ),
      ));
    }

    return Column(
      children: [
        Row(
          children: offenseItems,
        ),
      ],
    );
  }
}
