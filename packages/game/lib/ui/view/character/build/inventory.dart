import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../entity_grid.dart';
import '../../entity_info.dart';
import '../../../../global.dart';
import '../../../../event/events.dart';

const _kInventorySlotCount = 18;

/// 如果是玩家自己的物品栏，则传入characterData
class InventoryView extends StatefulWidget {
  const InventoryView({
    super.key,
    required this.inventoryData,
    this.isHeroInventory = true,
  });

  final HTStruct inventoryData;
  final bool isHeroInventory;

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  void _onItemTapped(
      BuildContext context, HTStruct itemData, Offset screenPosition) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        Widget? action;
        final hero = engine.invoke('getHero');
        if (widget.isHeroInventory) {
          if (itemData['isConsumable'] ?? false) {
            action = ElevatedButton(
              onPressed: () {
                engine.invoke('characterConsume',
                    positionalArgs: [hero, itemData]);
                Navigator.of(context).pop();
                engine.broadcast(const UIEvent.needRebuildUI());
                setState(() {});
              },
              child: Text(engine.locale['consume']),
            );
          } else if (itemData['isEquippable'] != null) {
            if (itemData['equippedPosition'] == null) {
              action = ElevatedButton(
                onPressed: () {
                  engine.invoke('characterEquip',
                      positionalArgs: [hero, itemData]);
                  Navigator.of(context).pop();
                  engine.broadcast(const UIEvent.needRebuildUI());
                  setState(() {});
                },
                child: Text(engine.locale['equip']),
              );
            } else {
              action = ElevatedButton(
                onPressed: () {
                  engine.invoke('characterUnequip',
                      positionalArgs: [hero, itemData]);
                  Navigator.of(context).pop();
                  engine.broadcast(const UIEvent.needRebuildUI());
                  setState(() {});
                },
                child: Text(engine.locale['unequip']),
              );
            }
          }
        } else {
          action = ElevatedButton(
            onPressed: () {
              engine.invoke('characterSteal', positionalArgs: [hero, itemData]);
              Navigator.of(context).pop();
              engine.broadcast(const UIEvent.needRebuildUI());
              setState(() {});
            },
            child: Text(engine.locale['steal']),
          );
        }

        return EntityInfo(
          entityData: itemData,
          left: screenPosition.dx,
          actions: [
            if (action != null)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: action,
              ),
          ],
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
        var isEquipped = false;
        if (itemData['isEquippable'] ?? false) {
          if (itemData['equippedPosition'] != null) {
            isEquipped = true;
          }
        }

        grids.add(Padding(
          padding: const EdgeInsets.all(5.0),
          child: EntityGrid(
            entityData: itemData,
            isEquipped: isEquipped,
            onSelect: (item, screenPosition) =>
                _onItemTapped(context, item, screenPosition),
          ),
        ));
      } else {
        grids.add(Padding(
          padding: const EdgeInsets.all(5.0),
          child: EntityGrid(
            onSelect: (item, screenPosition) =>
                _onItemTapped(context, item, screenPosition),
          ),
        ));
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Wrap(
                children: grids,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
