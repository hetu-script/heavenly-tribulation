import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import 'item_grid.dart';

const kInventorySlotCount = 18;

class InventoryView extends StatelessWidget {
  const InventoryView({
    super.key,
    required this.data,
    required this.onSelect,
  });

  final HTStruct data;

  final void Function(HTStruct item, Offset screenPosition) onSelect;

  @override
  Widget build(BuildContext context) {
    final List inventory = data['inventory'];

    final items = <ItemGrid>[];
    for (var i = 0; i < math.max(kInventorySlotCount, inventory.length); ++i) {
      if (i < inventory.length) {
        items.add(ItemGrid(
          data: inventory[i],
          onSelect: onSelect,
        ));
      } else {
        items.add(ItemGrid(
          onSelect: onSelect,
        ));
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemGrid(
              verticalMargin: 40,
              data: data['equipments'][1],
              onSelect: onSelect,
            ),
            ItemGrid(
              verticalMargin: 40,
              data: data['equipments'][2],
              onSelect: onSelect,
            ),
            ItemGrid(
              verticalMargin: 40,
              data: data['equipments'][3],
              onSelect: onSelect,
            ),
            ItemGrid(
              verticalMargin: 40,
              data: data['equipments'][4],
              onSelect: onSelect,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Wrap(
                  children: items,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
