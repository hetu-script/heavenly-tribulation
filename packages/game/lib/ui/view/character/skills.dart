import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../engine/engine.dart';
import '../../shared/constants.dart';
import '../item_grid.dart';

class CharacterSkillsView extends StatelessWidget {
  const CharacterSkillsView({
    Key? key,
    required this.data,
  }) : super(key: key);

  final HTStruct data;

  @override
  Widget build(BuildContext context) {
    final equippedArcanePowerData =
        data['arcanePowers'][data['equipments']['arcanePower']];
    final equippedMartialArtsData =
        data['martialArts'][data['equipments']['martialArts']];
    final equippedEscapeSkillData =
        data['escapeSkills'][data['equipments']['escapeSkill']];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Column(
          children: <Widget>[
            ItemGrid(
              data: equippedArcanePowerData,
              margin: 20,
            ),
            Column(
              children: <Widget>[],
            ),
          ],
        ),
        Column(
          children: <Widget>[
            ItemGrid(
              data: equippedMartialArtsData,
              margin: 20,
            ),
            Column(
              children: <Widget>[],
            ),
          ],
        ),
        Column(
          children: <Widget>[
            ItemGrid(
              data: equippedEscapeSkillData,
              margin: 20,
            ),
            Column(
              children: <Widget>[],
            ),
          ],
        ),
      ],
    );
  }
}
