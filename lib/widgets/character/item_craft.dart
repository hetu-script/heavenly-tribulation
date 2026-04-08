import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'inventory/inventory.dart';
import '../../global.dart';
import '../../data/game.dart';
import '../../game_events.dart';
import '../../ui.dart';

class ItemCraft extends StatefulWidget {
  const ItemCraft({
    super.key,
    required this.position,
    this.width,
    this.height,
    this.title,
    this.rank,
  });

  final Offset position;
  final double? width, height;
  final String? title;
  final int? rank;

  @override
  State<ItemCraft> createState() => _ItemCraftState();
}

class _ItemCraftState extends State<ItemCraft> {
  dynamic _selectedItemData;

  final Map<String, dynamic> filter = {'kind': 'craft_material'};

  @override
  void initState() {
    super.initState();

    if (widget.rank != null) {
      filter['rank'] = widget.rank;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: GameUI.boxDecoration,
          width: widget.width,
          height: widget.height,
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
                          filter: filter,
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
                      Padding(
                        padding:
                            const EdgeInsets.only(right: 35.0, bottom: 15.0),
                        child: fluent.Button(
                          onPressed: _selectedItemData != null
                              ? () {
                                  engine.emit(GameEvents.craftMaterialSelected,
                                      _selectedItemData);
                                }
                              : null,
                          child: Label(
                            engine.locale('use'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
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
