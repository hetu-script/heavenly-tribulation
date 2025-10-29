import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/hover_content.dart';
import '../../../logic/logic.dart';
import '../../common.dart';
import 'item_grid.dart';

export '../../common.dart' show ItemType;

/// 如果是玩家自己的物品栏，则传入characterData
class Inventory extends StatelessWidget {
  Inventory({
    super.key,
    required this.character,
    required this.itemType,
    this.height = 312.0,
    this.minSlotCount = 60,
    this.gridsPerLine = 5,
    this.onItemTapped,
    this.onItemSecondaryTapped,
    this.selectedItemId = const [],
    this.priceFactor,
    this.filter,
  });

  final dynamic character;
  final ItemType itemType;
  final double height;
  final int minSlotCount, gridsPerLine;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;
  final Iterable selectedItemId;
  final dynamic priceFactor;
  final dynamic filter;

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];

    final filteredItems = GameLogic.getFilteredItems(
      character,
      type: itemType,
      filter: filter,
      filterShard: priceFactor?['useShard'] ?? false,
    );

    for (final itemData in filteredItems) {
      grids.add(
        ItemGrid(
          size: kDefaultItemGridSize,
          itemData: itemData,
          margin: const EdgeInsets.all(2.0),
          onMouseEnter: (itemData, rect) {
            switch (itemType) {
              case ItemType.none:
              case ItemType.npc:
              case ItemType.player:
                context.read<HoverContentState>().show(
                      itemData,
                      type: itemType,
                      rect,
                    );
              case ItemType.merchant:
                context.read<HoverContentState>().show(
                      itemData,
                      type: itemType,
                      data2: priceFactor,
                      rect,
                    );
              case ItemType.customer:
                context.read<HoverContentState>().show(
                      itemData,
                      type: itemType,
                      data2: priceFactor,
                      rect,
                    );
            }
          },
          onMouseExit: () {
            context.read<HoverContentState>().hide();
          },
          onTapped: onItemTapped,
          onSecondaryTapped: onItemSecondaryTapped,
          isSelected: selectedItemId.contains(itemData['id']),
        ),
      );
    }

    int gridCount = math.max(
        (grids.length ~/ gridsPerLine + 1) * gridsPerLine, minSlotCount);

    while (grids.length < gridCount) {
      grids.add(
        ItemGrid(margin: const EdgeInsets.all(2.0)),
      );
    }

    return ScrollConfiguration(
      behavior: MaterialScrollBehavior(),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: SizedBox(
            width: (kDefaultItemGridSize.width + 4.0) * gridsPerLine + 20.0,
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
        ),
      ),
    );
  }
}
