import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:samsara/widgets/ui/empty_placeholder.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../ui.dart';
// import '../../data/game.dart';

const _kCharacterBondsSubTableColumns = {
  'name': 80.0,
  'relationshipOfTarget': 180.0,
  'favorScoreToTarget': 60.0,
};

const _kHeroBondsSubTableColumns = {
  'name': 80.0,
  'relationshipOfTarget': 180.0,
  'favorScoreToHero': 60.0,
};

class CharacterBondsView extends StatelessWidget {
  const CharacterBondsView({
    super.key,
    this.isHero = false,
    required this.bondsData,
    this.onPressed,
    this.onSecondaryPressed,
  });

  final bool isHero;

  final dynamic bondsData;

  final void Function(dynamic bondData)? onPressed;
  final void Function(dynamic bondData)? onSecondaryPressed;

  // String buildRelationshipText(dynamic bondData) {
  //   final targetId = bondData['id'];
  //   final target = GameData.getCharacter(targetId);
  //   final items = <String>[];
  //   for (final data in relationships) {
  //     items.add(engine.locale(e));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return DataTable2(
      cursor: GameUI.cursor,
      sortColumnIndex: 0,
      empty: EmptyPlaceholder(engine.locale('empty')),
      columns: (isHero
              ? _kHeroBondsSubTableColumns
              : _kCharacterBondsSubTableColumns)
          .entries
          .map(
            (entry) => DataColumn2(
              minWidth: entry.value,
              label: fluent.Button(
                style: FluentButtonStyles.column,
                onPressed: () {},
                child: Text(
                  engine.locale(entry.key),
                ),
              ),
            ),
          )
          .toList(),
      rows: List<DataRow>.from(bondsData.values
          .map(
            (bondData) => DataRow2(
              cells: [
                DataCell(
                  Text(bondData['name']),
                ),
                DataCell(
                  Text(
                    (bondData['relationships'] as Iterable).isEmpty
                        ? engine.locale('none')
                        : (bondData['relationships'] as Iterable)
                            .map((e) => engine.locale(e))
                            .join(','),
                  ),
                ),
                DataCell(
                  Text(bondData['score']?.toInt().toString() ??
                      engine.locale('none')),
                ),
              ],
              onTap: () {
                onPressed?.call(bondData);
              },
              onSecondaryTap: () {
                onSecondaryPressed?.call(bondData);
              },
            ),
          )
          .toList()),
    );
  }
}
