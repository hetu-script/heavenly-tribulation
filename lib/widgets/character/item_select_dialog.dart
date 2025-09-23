import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/ui/responsive_view.dart';

import 'inventory/inventory.dart';
import '../../engine.dart';
import '../../game/logic.dart';
import '../../game/ui.dart';
import '../../state/states.dart';
import '../ui/close_button2.dart';

class ItemSelectDialog extends StatefulWidget {
  const ItemSelectDialog({
    super.key,
    required this.character,
    this.title,
    this.height = 360.0,
    this.type = ItemType.none,
    this.filter,
    this.multiSelect = false,
    this.onSelect,
    this.selectedItemsData,
  });

  final String? title;
  final dynamic character;
  final double height;
  final ItemType type;
  final dynamic filter;
  final bool multiSelect;
  final void Function(Iterable itemsData)? onSelect;
  final Iterable? selectedItemsData;

  @override
  State<ItemSelectDialog> createState() => _ItemSelectDialogState();
}

class _ItemSelectDialogState extends State<ItemSelectDialog> {
  final Map<String, dynamic> _selectedItemsData = {};

  @override
  void initState() {
    super.initState();

    if (widget.selectedItemsData != null) {
      for (final item in widget.selectedItemsData!) {
        _selectedItemsData[item['id']] = item;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 450.0,
      height: 500.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('workshop')),
          actions: [
            CloseButton2(
              onPressed: () {
                context.read<ItemSelectState>().close();
                widget.onSelect?.call([]);
              },
            )
          ],
        ),
        body: SizedBox(
          width: 450.0,
          height: 500.0,
          child: Column(
            children: [
              Inventory(
                type: ItemType.player,
                character: widget.character,
                height: widget.height,
                filter: widget.filter,
                onItemTapped: (data, offset) {
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
                    child: fluent.FilledButton(
                      onPressed: () {
                        context.read<ItemSelectState>().close();
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
                    child: fluent.FilledButton(
                      onPressed: () {
                        _selectedItemsData.clear();
                        final filteredItems = GameLogic.getFilteredItems(
                          widget.character,
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
                    child: fluent.FilledButton(
                      onPressed: () {
                        context.read<ItemSelectState>().close();
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
      ),
    );
  }
}
