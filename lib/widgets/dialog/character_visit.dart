import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:samsara/ui/empty_placeholder.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/data.dart';

const _kCharacterVisitTableColumns = [
  'name',
  'haveMet',
  'gift',
  'attack',
  'steal',
  'friendRelationship',
  'romanceRelationship',
  'familyRelationship',
  'sectRelationship',
];

class CharacterVisitDialog extends StatelessWidget {
  static Future<String?> show({
    required BuildContext context,
    required Iterable<dynamic> characterIds,
    bool heroResidesHere = false,
  }) async {
    assert(characterIds.isNotEmpty);
    return await showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return CharacterVisitDialog(
            characterIds: characterIds, heroResidesHere: heroResidesHere);
      },
    );
  }

  final Iterable<dynamic> characterIds;

  final bool heroResidesHere;

  const CharacterVisitDialog({
    super.key,
    required this.characterIds,
    this.heroResidesHere = true,
  });

  @override
  Widget build(BuildContext context) {
    final activitiesData =
        engine.hetu.fetch('playerMonthly', namespace: 'game');

    final List<DataRow2> tableData = [];

    if (heroResidesHere) {
      tableData.add(DataRow2(
          onTap: () {
            Navigator.of(context).pop(GameData.heroData['id']);
          },
          cells: [
            DataCell(Text(engine.locale('heroHome'))),
            const DataCell(Text('—')),
            const DataCell(Text('—')),
            const DataCell(Text('—')),
            const DataCell(Text('—')),
            const DataCell(Text('—')),
            const DataCell(Text('—')),
            const DataCell(Text('—')),
            const DataCell(Text('—')),
          ]));
    }

    tableData.addAll(characterIds.map((id) {
      final character =
          engine.hetu.invoke('getCharacterById', positionalArgs: [id]);
      final haveMet = engine.hetu
          .invoke('haveMet', positionalArgs: [GameData.heroData, character]);
      final isFriend = engine.hetu
          .invoke('isFriend', positionalArgs: [GameData.heroData, character]);
      final isRomance = engine.hetu
          .invoke('isRomance', positionalArgs: [GameData.heroData, character]);
      final isFamily = engine.hetu
          .invoke('isFamily', positionalArgs: [GameData.heroData, character]);
      final isSect = engine.hetu
          .invoke('isSect', positionalArgs: [GameData.heroData, character]);

      return DataRow2(
          onTap: () {
            Navigator.of(context).pop(id);
          },
          cells: [
            DataCell(
              Text(character['name']),
            ),
            DataCell(
              Text((haveMet != null)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['gifted'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['attacked'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['stolen'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(isFriend
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(isRomance
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(isFamily
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(isSect
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
          ]);
    }));

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      margin: const EdgeInsets.fromLTRB(50.0, 50.0, 50.0, 50.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('visit')),
          actions: const [CloseButton2()],
        ),
        body: DataTable2(
          minWidth: 760,
          scrollController: ScrollController(),
          empty: EmptyPlaceholder(engine.locale('empty')),
          columns: _kCharacterVisitTableColumns
              .map((title) => DataColumn(
                    label: TextButton(
                      onPressed: () {},
                      child: Text(engine.locale(title)),
                    ),
                  ))
              .toList(),
          rows: tableData,
        ),
      ),
    );
  }
}
