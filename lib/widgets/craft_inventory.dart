import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'character/inventory/inventory.dart';
import '../global.dart';
import 'ui/responsive_view.dart';
import '../data/game.dart';

class CraftInventory extends StatefulWidget {
  const CraftInventory({
    super.key,
    this.title,
    this.filter,
    this.onSelect,
    this.selectedItemData,
  });

  final String? title;
  final dynamic filter;
  final void Function(Iterable itemsData)? onSelect;
  final dynamic selectedItemData;

  @override
  State<CraftInventory> createState() => _CraftInventoryState();
}

class _CraftInventoryState extends State<CraftInventory> {
  dynamic _selectedItemData;

  @override
  void initState() {
    super.initState();

    if (widget.selectedItemData != null) {
      _selectedItemData = widget.selectedItemData;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      alignment: Alignment.centerLeft,
      width: 380.0,
      height: 480.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('craft')),
        ),
        body: SizedBox(
          width: 380.0,
          height: 480.0,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Inventory(
                  inventoryType: InventoryType.player,
                  character: GameData.hero,
                  height: 364.0,
                  gridsPerLine: 6,
                  filter: widget.filter,
                  onItemTapped: (data, offset) {
                    if (_selectedItemData == data) {
                      _selectedItemData = null;
                    } else {
                      _selectedItemData = data;
                    }
                    setState(() {});
                  },
                  selectedItemId: _selectedItemData != null
                      ? [_selectedItemData['id']]
                      : [],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 35.0, bottom: 15.0),
                    child: fluent.Button(
                      onPressed: () {
                        widget.onSelect?.call([]);
                      },
                      child: Label(
                        engine.locale('cancel'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 35.0, bottom: 15.0),
                    child: fluent.Button(
                      onPressed: _selectedItemData != null
                          ? () {
                              widget.onSelect?.call([_selectedItemData]);
                            }
                          : null,
                      child: Label(
                        engine.locale('use'),
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
