import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../grid/entity_grid.dart';
import '../../grid/entity_info.dart';
import '../../../../global.dart';
import '../../../../event/events.dart';
import '../../../shared/integer_input_field.dart';

const _kMinSlotCount = 30;
const _kGridPerLine = 6;

enum InventoryType {
  player,
  npc,
  merchant,
  customer,
}

/// 如果是玩家自己的物品栏，则传入characterData
class InventoryView extends StatefulWidget {
  InventoryView({
    super.key,
    required this.inventoryData,
    this.characterName,
    this.style = GridStyle.icon,
    // this.money,
    this.type = InventoryType.player,
    this.priceFactor = 1.0,
    this.onBuy,
    this.onSell,
    this.onEquipChanged,
    List<dynamic> filter = const [],
  }) : filter = List<String>.from(filter);

  final HTStruct inventoryData;
  final GridStyle style;
  final String? characterName;
  // final int? money;
  final InventoryType type;
  final double priceFactor;
  final void Function(HTStruct item, int quantity)? onBuy, onSell;
  final VoidCallback? onEquipChanged;
  final List<String> filter;

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final _scrollController = ScrollController();
  final _textEditingController = TextEditingController();

  void _onItemTapped(HTStruct itemData, Offset screenPosition) {
    final sellable = itemData['isUnsellable'] != true;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        final List<Widget> actions = [];
        final hero = engine.fetch('hero');
        switch (widget.type) {
          case InventoryType.player:
            if (itemData['isConsumable'] ?? false) {
              actions.add(
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      engine.invoke('characterConsume',
                          positionalArgs: [hero, itemData]);
                      Navigator.of(context).pop();
                      engine.broadcast(const UIEvent.needRebuildUI());
                      setState(() {});
                    },
                    child: Text(engine.locale['consume']),
                  ),
                ),
              );
            } else if (itemData['isEquippable'] != null) {
              if (itemData['equippedPosition'] == null) {
                actions.add(
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        engine.invoke('characterEquip',
                            positionalArgs: [hero, itemData]);
                        Navigator.of(context).pop();
                        engine.broadcast(const UIEvent.needRebuildUI());
                        if (widget.onEquipChanged != null) {
                          widget.onEquipChanged!();
                        }
                      },
                      child: Text(engine.locale['equip']),
                    ),
                  ),
                );
              } else {
                actions.add(
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        engine.invoke('characterUnequip',
                            positionalArgs: [hero, itemData]);
                        Navigator.of(context).pop();
                        engine.broadcast(const UIEvent.needRebuildUI());
                        if (widget.onEquipChanged != null) {
                          widget.onEquipChanged!();
                        }
                      },
                      child: Text(engine.locale['unequip']),
                    ),
                  ),
                );
              }
            }
            break;
          case InventoryType.npc:
            actions.add(
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: ElevatedButton(
                  onPressed: () {
                    engine.invoke('characterSteal',
                        positionalArgs: [hero, itemData]);
                    Navigator.of(context).pop();
                    engine.broadcast(const UIEvent.needRebuildUI());
                    setState(() {});
                  },
                  child: Text(engine.locale['steal']),
                ),
              ),
            );
            break;
          case InventoryType.merchant:
            _textEditingController.text = '1';
            actions.addAll(
              [
                Material(
                  type: MaterialType.transparency,
                  child: SizedBox(
                    width: 120.0,
                    child: IntegerInputField(
                      min: 1,
                      max: itemData['stackSize'],
                      controller: _textEditingController,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      var quantity =
                          int.tryParse(_textEditingController.text) ?? 1;
                      if (quantity <= 0) {
                        quantity = 1;
                      }
                      if (widget.onBuy != null) {
                        widget.onBuy!(itemData, quantity);
                      }
                    },
                    child: Text(engine.locale['buy']),
                  ),
                ),
              ],
            );
            break;
          case InventoryType.customer:
            if (sellable) {
              _textEditingController.text = itemData['stackSize'].toString();
              actions.addAll(
                [
                  Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      width: 120.0,
                      child: IntegerInputField(
                        min: 1,
                        max: itemData['stackSize'],
                        controller: _textEditingController,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        var quantity =
                            int.tryParse(_textEditingController.text) ?? 1;
                        if (quantity <= 0) {
                          quantity = 1;
                        }
                        if (widget.onSell != null) {
                          widget.onSell!(itemData, quantity);
                        }
                      },
                      child: Text(engine.locale['sell']),
                    ),
                  ),
                ],
              );
            }
            break;
        }

        return EntityInfo(
          entityData: itemData,
          left: screenPosition.dx,
          actions: actions,
          priceFactor:
              widget.type == InventoryType.merchant ? widget.priceFactor : 1.0,
          showPrice: (widget.type == InventoryType.merchant ||
                  widget.type == InventoryType.customer) &&
              sellable,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];
    var index = -1;
    int maxGridCount;
    if (widget.inventoryData.length < _kMinSlotCount) {
      maxGridCount = _kMinSlotCount;
    } else {
      if (widget.style == GridStyle.icon) {
        maxGridCount = widget.inventoryData.length ~/ _kGridPerLine + 1;
      } else {
        maxGridCount = widget.inventoryData.length;
      }
    }
    do {
      ++index;
      if (index < widget.inventoryData.length) {
        final itemData = widget.inventoryData.values.elementAt(index);
        if (widget.type == InventoryType.merchant) {
          if (itemData['category'] == kEntityCategoryMoney) {
            continue;
          }

          if (itemData['equippedPosition'] != null) {
            continue;
          }
        }

        if (widget.type == InventoryType.customer) {
          if (itemData['equippedPosition'] != null) {
            continue;
          }
        }

        final isEquipped = itemData['isEquippable'] == true &&
            itemData['equippedPosition'] != null;

        grids.add(
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: EntityGrid(
              entityData: itemData,
              style: widget.style,
              isEquipped: isEquipped,
              onItemTapped: _onItemTapped,
            ),
          ),
        );
      } else {
        grids.add(
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: EntityGrid(
              style: widget.style,
            ),
          ),
        );
      }
    } while (grids.length < maxGridCount);

    return Column(
      children: [
        if (widget.characterName != null)
          Row(
            children: [
              if (widget.characterName != null) Text(widget.characterName!),
            ],
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: ListView(
              shrinkWrap: true,
              children: [
                widget.style == GridStyle.icon
                    ? Wrap(
                        alignment: WrapAlignment.center,
                        children: grids,
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: grids,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
