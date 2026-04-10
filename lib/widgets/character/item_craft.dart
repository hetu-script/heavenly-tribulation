import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'inventory/inventory.dart';
import '../../global.dart';
import '../../data/game.dart';
import '../../ui.dart';
import '../../game_events.dart';

class ItemCraft extends StatefulWidget {
  const ItemCraft({
    super.key,
    this.title,
    this.rank,
  });

  final String? title;
  final int? rank;

  @override
  State<ItemCraft> createState() => _ItemCraftState();
}

class _ItemCraftState extends State<ItemCraft> {
  dynamic _selectedItemData;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> filter = {
      'type': 'craftmaterial',
    };

    if (widget.rank != null) {
      filter['minRank'] = widget.rank;
    }

    return Positioned(
      right: 20.0,
      top: GameUI.toolbarHeight,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: GameUI.boxDecoration,
          width: 540.0,
          height: 480.0,
          child: Stack(
            children: [
              Positioned.fill(
                child: fluent.Acrylic(
                  luminosityAlpha: 0.4,
                  blurAmount: 5.0,
                ),
              ),
              Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(widget.title ?? engine.locale('craftmaterial')),
                ),
                body: SizedBox(
                  width: 540.0,
                  height: 480.0,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Inventory(
                          inventoryType: InventoryType.crafting,
                          character: GameData.hero,
                          height: 364.0,
                          gridsPerLine: 10,
                          minSlotCount: 70,
                          filter: filter,
                          itemTypes: null,
                          selectedItemId: _selectedItemData != null
                              ? [_selectedItemData['id']]
                              : [],
                          // onItemTapped: (data, offset) {
                          //   if (!widget.scrollMode) return;
                          //   if (_selectedItemData == data) {
                          //     _selectedItemData = null;
                          //   } else {
                          //     _selectedItemData = data;
                          //   }
                          //   setState(() {});
                          // },
                          onItemSecondaryTapped: (data, offset) {
                            engine.emit(GameEvents.craftMaterialSelected, data);
                            setState(() {});
                          },
                          // onMouseEnterItemGrid: (data) {
                          //   // if (widget.scrollMode) return;
                          //   if (_selectedItemData != data) {
                          //     _selectedItemData = data;
                          //     setState(() {});
                          //   }
                          // },
                        ),
                      ),
                      // if (widget.scrollMode)
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 10.0),
                      //     child: fluent.Button(
                      //       onPressed: () {},
                      //       child: Text(
                      //         engine.locale('use'),
                      //         textAlign: TextAlign.center,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
