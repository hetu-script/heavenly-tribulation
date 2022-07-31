import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../grid/entity_grid.dart';
import '../../grid/entity_info.dart';
import '../../../../global.dart';
import '../../../../event/events.dart';
import '../../../shared/integer_input_field.dart';

const _kInventorySlotCount = 30;

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
    this.money,
    this.type = InventoryType.player,
    this.priceFactor = 1.0,
    this.onBuy,
    this.onSell,
    this.onEquipChanged,
    List<dynamic> filter = const [],
  }) : filter = List<String>.from(filter);

  final HTStruct inventoryData;
  final String? characterName;
  final int? money;
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
            break;
        }

        return EntityInfo(
          entityData: itemData,
          left: screenPosition.dx,
          actions: actions,
          priceFactor:
              widget.type == InventoryType.merchant ? widget.priceFactor : 1.0,
          showPrice: widget.type == InventoryType.merchant ||
              widget.type == InventoryType.customer,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];
    for (var i = 0;
        i < math.max(_kInventorySlotCount, widget.inventoryData.length);
        ++i) {
      if (i < widget.inventoryData.length) {
        final itemData = widget.inventoryData.values.elementAt(i);
        final isEquipped = itemData['isEquippable'] == true &&
            itemData['equippedPosition'] != null;

        grids.add(Padding(
          padding: const EdgeInsets.all(5.0),
          child: EntityGrid(
            entityData: itemData,
            isEquipped: isEquipped,
            onItemTapped: _onItemTapped,
          ),
        ));
      } else {
        grids.add(Padding(
          padding: const EdgeInsets.all(5.0),
          child: EntityGrid(
            onItemTapped: _onItemTapped,
          ),
        ));
      }
    }

    return Column(
      children: [
        if (widget.characterName != null || widget.money != null)
          Padding(
            padding:
                const EdgeInsets.only(left: 25.0, right: 25.0, bottom: 5.0),
            child: Row(
              children: [
                if (widget.characterName != null) Text(widget.characterName!),
                const Spacer(),
                if (widget.money != null)
                  Text('${engine.locale['money']}: ${widget.money}'),
              ],
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 15.0, right: 15.0),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: ListView(
                shrinkWrap: true,
                children: [
                  Wrap(
                    children: grids,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
