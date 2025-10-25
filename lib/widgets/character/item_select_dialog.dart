import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'inventory/inventory.dart';
import '../../engine.dart';
import '../../logic/logic.dart';
import '../../state/states.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';

class ItemSelectDialog extends StatefulWidget {
  const ItemSelectDialog({
    super.key,
    required this.character,
    this.title,
    this.type = ItemType.none,
    this.filter,
    this.multiSelect = false,
    this.onSelect,
    this.selectedItemsData,
  });

  final String? title;
  final dynamic character;
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
      width: 380.0,
      height: 480.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('selectItem')),
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
          width: 380.0,
          height: 480.0,
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              Inventory(
                itemType: ItemType.player,
                character: widget.character,
                height: 364.0,
                gridsPerLine: 6,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 35.0, bottom: 15.0),
                    child: fluent.Button(
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
                  if (widget.multiSelect)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: fluent.Button(
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
                    )
                  else
                    const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 35.0, bottom: 15.0),
                    child: fluent.Button(
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
