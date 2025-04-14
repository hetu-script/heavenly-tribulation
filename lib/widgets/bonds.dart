import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:samsara/ui/empty_placeholder.dart';

import '../engine.dart';
import '../game/ui.dart';

const _kCharacterBondsSubTableColumns = [
  'name',
  'relationshipOfTarget',
  'favorScoreToTarget'
];
const _kHeroBondsSubTableColumns = [
  'name',
  'relationshipOfTarget',
  'favorScore'
];

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
      empty: EmptyPlaceholder(engine.locale('empty')),
      columns: (isHero
              ? _kHeroBondsSubTableColumns
              : _kCharacterBondsSubTableColumns)
          .map((title) => DataColumn2(
                size: ColumnSize.L,
                label: TextButton(
                  onPressed: () {},
                  child: Text(
                    engine.locale(title),
                    style: GameUI.textTheme.bodyLarge,
                  ),
                ),
              ))
          .toList(),
      rows: List<DataRow>.from(bondsData.values
          .map((bondData) => DataRow2(
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
                  }))
          .toList()),
    );
  }
}
