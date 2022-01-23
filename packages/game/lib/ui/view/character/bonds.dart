import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../engine/engine.dart';
import '../../shared/empty_placeholder.dart';
import '../../shared/constants.dart';

const kCharacterBondsCategoryNum = 5;

const kBondsTableColumns = [
  'name',
  'impressionOfThem',
];

class CharacterBondsView extends StatelessWidget {
  const CharacterBondsView({
    Key? key,
    required this.data,
  }) : super(key: key);

  final HTStruct data;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: kCharacterBondsCategoryNum,
      child: Column(
        children: <Widget>[
          PreferredSize(
            preferredSize: const Size.fromHeight(kNestedTabBarHeight),
            child: TabBar(
              tabs: <Widget>[
                Tab(text: engine.locale['character']),
                Tab(text: engine.locale['organization']),
                Tab(text: engine.locale['talisman']),
                Tab(text: engine.locale['location']),
                Tab(text: engine.locale['nation']),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height - kNestedTabBarHeight,
            child: TabBarView(
              children: data.keys
                  .map(
                    (key) => DataTable2(
                      scrollController: ScrollController(),
                      empty: const EmptyPlaceholder(),
                      columns: kBondsTableColumns
                          .map((title) => DataColumn(
                                label: TextButton(
                                  onPressed: () {},
                                  child: Text(engine.locale[title]),
                                ),
                              ))
                          .toList(),
                      rows: data[key] != null
                          ? (data[key] as HTStruct)
                              .values
                              .map((object) => DataRow2(cells: [
                                    DataCell(
                                      Text(object['name']),
                                    ),
                                    DataCell(
                                      Text(object['score'].toStringAsFixed(2)),
                                    ),
                                  ]))
                              .toList()
                          : const [],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
