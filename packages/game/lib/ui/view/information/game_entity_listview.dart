import 'dart:ui';

import 'package:flutter/material.dart';
import '../../shared/empty_placeholder.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../../engine/engine.dart';

class GameEntityListView extends StatefulWidget {
  const GameEntityListView(
      {Key? key, required this.columns, required this.data})
      : super(key: key);

  final List<String> columns;

  final List<List<String>> data;

  @override
  _GameEntityListViewState createState() => _GameEntityListViewState();
}

class _GameEntityListViewState extends State<GameEntityListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
        },
      ),
      child: DataTable2(
        scrollController: ScrollController(),
        empty: const EmptyPlaceholder(),
        columns: widget.columns
            .map((title) => DataColumn(
                  label: TextButton(
                    onPressed: () {},
                    child: Text(engine.locale[title]),
                  ),
                ))
            .toList(),
        rows: widget.data
            .map((line) => DataRow2(
                  cells: line
                      .map(
                        (field) => DataCell(Text(field)),
                      )
                      .toList(),
                ))
            .toList(),
      ),
    );
  }
}
