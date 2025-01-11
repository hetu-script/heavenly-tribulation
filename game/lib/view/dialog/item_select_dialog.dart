import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';

import '../character/inventory/inventory.dart';
import '../common.dart';
import '../../engine.dart';
import '../draggable_panel.dart';
import '../../state/view_panels.dart';

class ItemSelectDialog extends StatelessWidget {
  const ItemSelectDialog({
    super.key,
    this.args = const {},
    required this.title,
    required this.inventoryData,
    required this.type,
    this.height = 360.0,
    this.filter,
  });

  final Map<String, dynamic> args;

  final String title;
  final dynamic inventoryData;
  final InventoryType type;
  final double height;
  final String? filter;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return DraggablePanel(
      title: title,
      position: Offset(
          screenSize.width / 2 - 450 / 2, screenSize.height / 2 - height / 2),
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
              type: type,
              inventoryData: inventoryData,
              height: height,
              filter: filter,
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
                    onPressed: () {},
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
