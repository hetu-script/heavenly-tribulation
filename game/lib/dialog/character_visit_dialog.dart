import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:samsara/ui/empty_placeholder.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';

import '../config.dart';

const _kCharacterVisitTableColumns = [
  'name',
  'haveMet',
  'talk',
  'gift',
  'request',
  'duel',
  'consult',
  'insult',
  'steal'
];

class CharacterVisitDialog extends StatelessWidget {
  static Future<String?> show({
    required BuildContext context,
    required Iterable<dynamic> characterIds,
    bool hideHero = true,
  }) async {
    assert(characterIds.isNotEmpty);
    return await showDialog<String?>(
      context: context,
      builder: (BuildContext context) {
        return CharacterVisitDialog(
          characterIds: characterIds,
          hideHero: hideHero,
        );
      },
    );
  }

  final Iterable<dynamic> characterIds;

  final bool hideHero;

  const CharacterVisitDialog({
    super.key,
    required this.characterIds,
    this.hideHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final hero = engine.hetu.interpreter.fetch('hero');
    final heroId = hero['id'];
    final activitiesData = engine.hetu.invoke('getPlayerMonthlyActivities');

    final ids = characterIds.toList();
    ids.remove(heroId);

    final List<DataRow2> tableData = [];

    if (!hideHero) {
      tableData.add(DataRow2(
          onTap: () {
            Navigator.of(context).pop(heroId);
          },
          cells: [
            DataCell(
              Text(engine.locale('heroHome')),
            ),
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

    tableData.addAll(ids.map((id) {
      final character =
          engine.hetu.invoke('getCharacterById', positionalArgs: [id]);
      final haveMet =
          engine.hetu.invoke('haveMet', positionalArgs: [hero, character]);
      return DataRow2(
          onTap: () {
            Navigator.of(context).pop(id);
          },
          cells: [
            DataCell(
              Text(character['name']),
            ),
            DataCell(
              Text(haveMet
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['talked'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['gifted'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['practiced'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['consulted'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['requested'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['insulted'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            ),
            DataCell(
              Text(activitiesData['stolen'].contains(id)
                  ? engine.locale('checked')
                  : engine.locale('unchecked')),
            )
          ]);
    }));

    return ResponsiveWindow(
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
