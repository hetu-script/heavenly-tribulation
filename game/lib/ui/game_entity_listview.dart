import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:samsara/flutter_ui/empty_placeholder.dart';
import 'package:data_table_2/data_table_2.dart';

import '../global.dart';

class GameEntityListView extends StatefulWidget {
  const GameEntityListView({
    super.key,
    required this.columns,
    required this.tableData,
    this.onTap,
  });

  final List<String> columns;

  final List<List<String>> tableData;

  final void Function(String dataId)? onTap;

  @override
  State<GameEntityListView> createState() => _GameEntityListViewState();
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
        empty: EmptyPlaceholder(engine.locale['empty']),
        columns: widget.columns
            .map((title) => DataColumn(
                  label: TextButton(
                    onPressed: () {},
                    child: Text(
                      engine.locale[title],
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ))
            .toList(),
        rows: widget.tableData
            .map((line) => DataRow2(
                  cells: line
                      .take(widget.columns.length)
                      .map(
                        (field) => DataCell(Text(
                          field,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                        )),
                      )
                      .toList(),
                  onTap: () {
                    if (widget.onTap != null) {
                      widget.onTap!(line.last);
                    }
                  },
                ))
            .toList(),
      ),
    );
  }
}
