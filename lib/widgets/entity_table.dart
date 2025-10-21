import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/empty_placeholder.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/gestures.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../engine.dart';
import '../ui.dart';

class EntityTable extends StatefulWidget {
  const EntityTable({
    super.key,
    required this.columns,
    required this.tableData,
    this.onColumnPressed,
    this.onItemPressed,
    this.onItemSecondaryPressed,
  });

  // column名字会转换为本地化字符串
  final Map<String, double> columns;

  final List<List<String>> tableData;

  final void Function(String id)? onColumnPressed;

  final void Function(Offset position, String id)? onItemPressed,
      onItemSecondaryPressed;

  @override
  State<EntityTable> createState() => _EntityTableState();
}

class _EntityTableState extends State<EntityTable>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Offset _mousePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return MouseRegion(
      onHover: (PointerHoverEvent details) => _mousePosition = details.position,
      child: DataTable2(
        cursor: GameUI.cursor,
        scrollController: ScrollController(),
        empty: EmptyPlaceholder(engine.locale('empty')),
        columns: widget.columns.entries.map((entry) {
          return DataColumn2(
            minWidth: entry.value,
            label: fluent.Button(
              onPressed: () => widget.onColumnPressed?.call(entry.key),
              child: Text(
                engine.locale(entry.key),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          );
        }).toList(),
        rows: widget.tableData
            .map(
              (line) => DataRow2(
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
                onTap: () =>
                    widget.onItemPressed?.call(_mousePosition, line.last),
                onSecondaryTap: () => widget.onItemSecondaryPressed
                    ?.call(_mousePosition, line.last),
              ),
            )
            .toList(),
      ),
    );
  }
}
