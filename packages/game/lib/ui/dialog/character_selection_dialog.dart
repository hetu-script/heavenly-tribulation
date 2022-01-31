import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';

import '../shared/empty_placeholder.dart';
import '../shared/constants.dart';
import '../../engine/engine.dart';

class CharacterSelectionDialog extends StatelessWidget {
  static Future<dynamic> show(
    BuildContext context,
    Iterable<dynamic> characterIds,
  ) async {
    assert(characterIds.isNotEmpty);
    return await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return CharacterSelectionDialog(characterIds: characterIds);
      },
      barrierDismissible: false,
    );
  }

  final Iterable<dynamic> characterIds;

  const CharacterSelectionDialog({
    Key? key,
    required this.characterIds,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hero = engine.hetu.invoke('getHero');
    final activitiesData = engine.hetu.invoke('getMonthlyActivities');

    return
        // Material(
        //   type: MaterialType.transparency,
        //   child:
        Container(
      padding: const EdgeInsets.all(50),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale['characterSelection']),
        ),
        body: DataTable2(
          minWidth: 760,
          scrollController: ScrollController(),
          empty: const EmptyPlaceholder(),
          columns: kCharacterSelectionTableColumns
              .map((title) => DataColumn(
                    label: TextButton(
                      onPressed: () {},
                      child: Text(engine.locale[title]),
                    ),
                  ))
              .toList(),
          rows: characterIds.map((id) {
            final character =
                engine.hetu.invoke('getCharacterById', positionalArgs: [id]);
            final haveMet = engine.hetu
                .invoke('haveMet', positionalArgs: [hero, character]);
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
                  ),
                  DataCell(
                    Text(activitiesData['peeped'].contains(id)
                        ? engine.locale['checked']
                        : engine.locale['unchecked']),
                  ),
                ]);
          }).toList(),
        ),
      ),
      // ),
    );
  }
}