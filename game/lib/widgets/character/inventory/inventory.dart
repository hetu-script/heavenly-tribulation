import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'item_grid.dart';
import '../../common.dart';

/// 如果是玩家自己的物品栏，则传入characterData
class Inventory extends StatefulWidget {
  const Inventory({
    super.key,
    required this.characterData,
    required this.type,
    this.filter,
    required this.height,
    this.priceFactor = 1.0,
    this.minSlotCount = 35,
    this.gridsPerLine = 5,
    this.onTapped,
    this.onSecondaryTapped,
    this.onSelect,
  });

  final dynamic characterData;
  final InventoryType type;
  final String? filter;
  final double height;
  final double priceFactor;
  final int minSlotCount, gridsPerLine;
  final void Function(dynamic itemData, Offset screenPosition)? onTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onSecondaryTapped;
  final void Function(dynamic itemData)? onSelect;

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  int _selectedGrid = -1;

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];

    final inventoryData = widget.characterData['inventory'];

    for (var i = 0; i < inventoryData.length; ++i) {
      final itemData = (inventoryData.values as Iterable).elementAt(i);
      if (itemData['equippedPosition'] != null) {
        continue;
      }
      if (widget.filter != null && itemData['category'] != widget.filter) {
        continue;
      }

      final index = i;
      grids.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ItemGrid(
            characterData: widget.characterData,
            itemData: itemData,
            onTapped: (data, position) {
              if (widget.type == InventoryType.select) {
                setState(() {
                  _selectedGrid = index;
                });
                widget.onSelect?.call(data);
              }
              widget.onTapped?.call(data, position);
            },
            onSecondaryTapped: widget.onSecondaryTapped,
            isSelected: _selectedGrid == index,
          ),
        ),
      );
    }

    int gridCount = math.max(
        (grids.length ~/ widget.gridsPerLine + 1) * widget.gridsPerLine,
        widget.minSlotCount);

    while (grids.length < gridCount) {
      grids.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: ItemGrid(),
        ),
      );
    }

    return SingleChildScrollView(
      child: SizedBox(
        width: 60.0 * widget.gridsPerLine,
        height: widget.height,
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
