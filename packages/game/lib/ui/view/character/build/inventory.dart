import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import 'item_grid.dart';
import 'item_info.dart';

const _kInventorySlotCount = 18;

class InventoryView extends StatelessWidget {
  const InventoryView({
    super.key,
    required this.inventoryData,
  });

  final List<dynamic> inventoryData;

  void _onItemTapped(
      BuildContext context, HTStruct item, Offset screenPosition) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return ItemInfo(
            itemData: item,
            left: screenPosition.dx,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final grids = <ItemGrid>[];
    for (var i = 0;
        i < math.max(_kInventorySlotCount, inventoryData.length);
        ++i) {
      if (i < inventoryData.length) {
        grids.add(ItemGrid(
          itemData: inventoryData[i],
          onSelect: (item, screenPosition) =>
              _onItemTapped(context, item, screenPosition),
        ));
      } else {
        grids.add(ItemGrid(
          onSelect: (item, screenPosition) =>
              _onItemTapped(context, item, screenPosition),
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
