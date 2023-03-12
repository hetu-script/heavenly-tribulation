import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:samsara/flutter_ui/empty_placeholder.dart';
import 'package:samsara/flutter_ui/responsive_window.dart';

import '../../global.dart';

const _kCharacterVisitTableColumns = [
  'name',
  'haveMet',
  'talk',
  'gift',
  'practiceDuel',
  'consult',
  'request',
  'insult',
  'steal'
];

class CharacterVisitDialog extends StatelessWidget {
  static Future<dynamic> show({
    required BuildContext context,
    required Iterable<dynamic> characterIds,
  }) async {
    assert(characterIds.isNotEmpty);
    return await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CharacterVisitDialog(
          characterIds: characterIds,
        );
      },
    );
  }

  final Iterable<dynamic> characterIds;

  const CharacterVisitDialog({
    super.key,
    required this.characterIds,
  });

  @override
  Widget build(BuildContext context) {
    final hero = engine.fetch('hero');
    final activitiesData = engine.invoke('getPlayerMonthlyActivities');

    final layout = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(engine.locale['visit']),
        actions: const [CloseButton()],
      ),
      body: DataTable2(
        minWidth: 760,
        scrollController: ScrollController(),
        empty: EmptyPlaceholder(engine.locale['empty']),
        columns: _kCharacterVisitTableColumns
            .map((title) => DataColumn(
                  label: TextButton(
                    onPressed: () {},
                    child: Text(engine.locale[title]),
                  ),
                ))
            .toList(),
        rows: characterIds.map((id) {
          final character =
              engine.invoke('getCharacterById', positionalArgs: [id]);
          final haveMet =
              engine.invoke('haveMet', positionalArgs: [hero, character]);
          return DataRow2(
              onTap: () {
                Navigator.pop(context, id);
              },
              cells: [
                DataCell(
                  Text(character['name']),
                ),
                DataCell(
                  Text(haveMet
                      ? engine.locale['checked']
                      : engine.locale['unchecked']),
                ),
                DataCell(
                  Text(activitiesData['talked'].contains(id)
                      ? engine.locale['checked']
                      : engine.locale['unchecked']),
                ),
                DataCell(
                  Text(activitiesData['gifted'].contains(id)
                      ? engine.locale['checked']
                      : engine.locale['unchecked']),
                ),
                DataCell(
                  Text(activitiesData['practiced'].contains(id)
                      ? engine.locale['checked']
                      : engine.locale['unchecked']),
                ),
                DataCell(
                  Text(activitiesData['consulted'].contains(id)
                      ? engine.locale['checked']
                      : engine.locale['unchecked']),
                ),
                DataCell(
                  Text(activitiesData['requested'].contains(id)
                      ? engine.locale['checked']
                      : engine.locale['unchecked']),
                ),
                DataCell(
                  Text(activitiesData['insulted'].contains(id)
                      ? engine.locale['checked']
                      : engine.locale['unchecked']),
                ),
                DataCell(
                  Text(activitiesData['stolen'].contains(id)
                      ? engine.locale['checked']
                      : engine.locale['unchecked']),
                )
              ]);
        }).toList(),
      ),
    );

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      child: layout,
    );
  }
}
