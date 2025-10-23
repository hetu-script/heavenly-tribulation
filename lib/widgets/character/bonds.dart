import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:samsara/widgets/ui/empty_placeholder.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../ui.dart';

const _kCharacterBondsSubTableColumns = {
  'name': 100.0,
  'relationshipOfTarget': 100.0,
  'favorScoreToTarget': 100.0,
};
const _kHeroBondsSubTableColumns = {
  'name': 100.0,
  'relationshipOfTarget': 100.0,
  'favorScore': 100.0,
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
                  Text(engine.locale(bondData['relationship'])),
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
