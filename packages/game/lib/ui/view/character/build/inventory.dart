import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import 'item_grid.dart';

const kInventorySlotCount = 20;

class InventoryView extends StatelessWidget {
  const InventoryView({
    Key? key,
    required this.data,
    required this.onSelect,
  }) : super(key: key);

  final HTStruct data;

  final void Function(HTStruct item, Offset screenPosition) onSelect;

  @override
  Widget build(BuildContext context) {
    final List inventory = data['inventory'];

    final items = <ItemGrid>[];
    for (var i = 0; i < kInventorySlotCount; ++i) {
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
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
            children: <Widget>[
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
