import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../item_grid.dart';

class CharacterSkillsView extends StatelessWidget {
  const CharacterSkillsView({
    Key? key,
    required this.data,
  }) : super(key: key);

  final HTStruct data;

  @override
  Widget build(BuildContext context) {
    final HTStruct knowledges = data['knowledges'];

    final equippedArcanePowerData =
        knowledges[data['equipments']['arcanePowerId']];
    final equippedMartialArtsData =
        knowledges[data['equipments']['martialArtsId']];
    final equippedEscapeSkillData =
        knowledges[data['equipments']['escapeSkillId']];

    final skillsCount = data['length'];
    final skills = <ItemGrid>[];
    for (var i = 0; i < skillsCount; ++i) {
      if (i < knowledges.length) {
        skills.add(ItemGrid(data: data['knowledges'].values.elementAt(i)));
      } else {
        skills.add(const ItemGrid());
      }
    }

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ItemGrid(
              data: equippedArcanePowerData,
              verticalMargin: 40,
            ),
            ItemGrid(
              data: equippedMartialArtsData,
              verticalMargin: 40,
            ),
            ItemGrid(
              data: equippedEscapeSkillData,
              verticalMargin: 40,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            children: <Widget>[
              Align(
                alignment: Alignment.topCenter,
                child: Wrap(
                  children: skills,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
