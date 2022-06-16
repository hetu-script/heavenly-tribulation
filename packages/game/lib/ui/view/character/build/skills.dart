import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../item_grid.dart';

const kSkillSlotCount = 20;

class SkillsView extends StatelessWidget {
  const SkillsView({
    Key? key,
    required this.data,
  }) : super(key: key);

  final HTStruct data;

  @override
  Widget build(BuildContext context) {
    final List knowledges = data['inventory'];

    final skills = <ItemGrid>[];
    for (var i = 0; i < kSkillSlotCount; ++i) {
      if (i < knowledges.length) {
        skills.add(ItemGrid(data: knowledges[i]));
      } else {
        skills.add(const ItemGrid());
      }
    }

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            ItemGrid(
              verticalMargin: 40,
            ),
            ItemGrid(
              verticalMargin: 40,
            ),
            ItemGrid(
              verticalMargin: 40,
            ),
            ItemGrid(
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
