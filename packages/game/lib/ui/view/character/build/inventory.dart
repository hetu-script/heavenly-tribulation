import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../item_grid.dart';

const kInventorySlotCount = 20;

class InventoryView extends StatelessWidget {
  const InventoryView({
    Key? key,
    required this.data,
  }) : super(key: key);

  final HTStruct data;

  @override
  Widget build(BuildContext context) {
    final List inventory = data['inventory'];

    final items = <ItemGrid>[];
    for (var i = 0; i < kInventorySlotCount; ++i) {
      if (i < inventory.length) {
        items.add(ItemGrid(data: inventory[i]));
      } else {
        items.add(const ItemGrid());
      }
    }

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            ItemGrid(
              verticalMargin: 40,
            ),
            ItemGrid(
              verticalMargin: 40,
            ),
            ItemGrid(
              verticalMargin: 40,
            ),
            ItemGrid(
              verticalMargin: 40,
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
