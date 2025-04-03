import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';

import 'inventory/inventory.dart';
import '../../engine.dart';
import '../draggable_panel.dart';
import '../../game/logic.dart';
import '../../state/states.dart';

class ItemSelectDialog extends StatefulWidget {
  const ItemSelectDialog({
    super.key,
    required this.characterData,
    this.title,
    this.height = 360.0,
    this.type = ItemType.none,
    this.filter,
    this.multiSelect = false,
    this.onSelect,
  });

  final String? title;
  final dynamic characterData;
  final double height;
  final ItemType type;
  final dynamic filter;
  final bool multiSelect;
  final void Function(Iterable itemsData)? onSelect;

  @override
  State<ItemSelectDialog> createState() => _ItemSelectDialogState();
}

class _ItemSelectDialogState extends State<ItemSelectDialog> {
  final Map<String, dynamic> _selectedItemsData = {};

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return DraggablePanel(
      title: widget.title ?? engine.locale('selectItem'),
      position: Offset(
          screenSize.width / 2 - 450 / 2, screenSize.height / 2 - 500 / 2),
      width: 450,
      height: 500,
      onClose: () {
        context.read<ViewPanelState>().hide(ViewPanels.itemSelect);
        widget.onSelect?.call([]);
      },
      child: Align(
        alignment: Alignment.center,
        child: Column(
          children: [
            Inventory(
              type: ItemType.player,
              characterData: widget.characterData,
              height: widget.height,
              filter: widget.filter,
              onTapped: (data, offset) {
                final itemId = data['id'];
                if (_selectedItemsData.containsKey(itemId)) {
                  _selectedItemsData.remove(itemId);
                } else {
                  if (!widget.multiSelect) {
                    _selectedItemsData.clear();
                  }
                  _selectedItemsData[itemId] = data;
                }
                setState(() {});
              },
              selectedItemId: _selectedItemsData.keys.toSet(),
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
                      widget.onSelect?.call([]);
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
                      _selectedItemsData.clear();
                      final filteredItems = GameLogic.getFilteredItems(
                        widget.characterData,
                        type: widget.type,
                        filter: widget.filter,
                      );
                      for (final item in filteredItems) {
                        _selectedItemsData[item['id']] = item;
                      }
                      setState(() {});
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
                      widget.onSelect?.call(_selectedItemsData.values);
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
