import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';

import '../character/inventory/inventory.dart';
import '../common.dart';
import '../../engine.dart';
import '../draggable_panel.dart';
import '../../state/view_panels.dart';

class ItemSelectDialog extends StatefulWidget {
  const ItemSelectDialog({
    super.key,
    this.args = const {},
    required this.title,
    required this.inventoryData,
    this.height = 360.0,
    this.filter,
    this.onSelect,
    this.onSelectAll,
  });

  final Map<String, dynamic> args;

  final String title;
  final dynamic inventoryData;
  final double height;
  final String? filter;
  final void Function(dynamic itemData)? onSelect;
  final void Function()? onSelectAll;

  @override
  State<ItemSelectDialog> createState() => _ItemSelectDialogState();
}

class _ItemSelectDialogState extends State<ItemSelectDialog> {
  dynamic _selectedItemData;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return DraggablePanel(
      title: widget.title,
      position: Offset(screenSize.width / 2 - 450 / 2,
          screenSize.height / 2 - widget.height / 2),
      width: 450,
      height: 500,
      onClose: () {
        context.read<ViewPanelState>().hide(ViewPanels.itemSelect);
      },
      child: Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            Inventory(
              type: InventoryType.select,
              inventoryData: widget.inventoryData,
              height: widget.height,
              filter: widget.filter,
              onSelect: (data) {
                _selectedItemData = data;
              },
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<ViewPanelState>()
                          .hide(ViewPanels.itemSelect);
                    },
                    child: Label(
                      engine.locale('cancel'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<ViewPanelState>()
                          .hide(ViewPanels.itemSelect);
                      widget.onSelectAll?.call();
                    },
                    child: Label(
                      engine.locale('selectAll'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<ViewPanelState>()
                          .hide(ViewPanels.itemSelect);
                      widget.onSelect?.call(_selectedItemData);
                    },
                    child: Label(
                      engine.locale('confirm'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
