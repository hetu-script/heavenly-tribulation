import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'item_grid.dart';
import '../../common.dart';

/// 如果是玩家自己的物品栏，则传入characterData
class Inventory extends StatelessWidget {
  const Inventory({
    super.key,
    required this.inventoryData,
    required this.type,
    this.filter,
    required this.height,
    this.priceFactor = 1.0,
    this.minSlotCount = 36,
    this.gridsPerLine = 6,
    this.onItemTapped,
    this.onItemSecondaryTapped,
  });

  final dynamic inventoryData;
  final InventoryType type;
  final String? filter;
  final double height;
  final double priceFactor;
  final int minSlotCount, gridsPerLine;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];

    for (final itemData in inventoryData.values) {
      if (itemData['equippedPosition'] != null) {
        continue;
      }
      if (filter != null && itemData['category'] != filter) {
        continue;
      }

      grids.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ItemGrid(
            itemData: itemData,
            onTapped: onItemTapped,
            onSecondaryTapped: onItemSecondaryTapped,
          ),
        ),
      );
    }

    int gridCount = math.max(
        (grids.length ~/ gridsPerLine + 1) * gridsPerLine, minSlotCount);

    while (grids.length < gridCount) {
      grids.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ItemGrid(),
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 5.0, top: 5.0, right: 5.0),
        width: 60.0 * gridsPerLine,
        height: height,
        child: ListView(
          shrinkWrap: true,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              children: grids,
            )
          ],
        ),
      ),
    );
  }
}
