import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/hover_content.dart';
import 'item_grid.dart';
import '../../../game/logic.dart';

export '../../../common.dart' show ItemType;

/// 如果是玩家自己的物品栏，则传入characterData
class Inventory extends StatefulWidget {
  const Inventory({
    super.key,
    required this.character,
    required this.type,
    this.height = 312.0,
    this.minSlotCount = 30,
    this.gridsPerLine = 5,
    this.onTapped,
    this.onSecondaryTapped,
    this.selectedItemId = const [],
    this.priceFactor,
    this.filter,
  });

  final dynamic character;
  final ItemType type;
  final double height;
  final int minSlotCount, gridsPerLine;
  final void Function(dynamic itemData, Offset screenPosition)? onTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onSecondaryTapped;
  final Iterable selectedItemId;
  final dynamic priceFactor;
  final dynamic filter;

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();

    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];

    final filteredItems = GameLogic.getFilteredItems(widget.character,
        type: widget.type, filter: widget.filter);

    for (final itemData in filteredItems) {
      grids.add(
        ItemGrid(
          size: kDefaultItemGridSize,
          itemData: itemData,
          margin: const EdgeInsets.all(2.0),
          onMouseEnter: (itemData, rect) {
            switch (widget.type) {
              case ItemType.none:
              case ItemType.npc:
              case ItemType.player:
                context.read<HoverContentState>().show(
                      itemData,
                      type: widget.type,
                      rect,
                    );
              case ItemType.merchant:
                context.read<HoverContentState>().show(
                      itemData,
                      type: widget.type,
                      data2: widget.priceFactor,
                      rect,
                    );
              case ItemType.customer:
                context.read<HoverContentState>().show(
                      itemData,
                      type: widget.type,
                      data2: widget.priceFactor,
                      rect,
                    );
            }
          },
          onMouseExit: () {
            context.read<HoverContentState>().hide();
          },
          onTapped: widget.onTapped,
          onSecondaryTapped: widget.onSecondaryTapped,
          isSelected: widget.selectedItemId.contains(itemData['id']),
        ),
      );
    }

    int gridCount = math.max(
        (grids.length ~/ widget.gridsPerLine + 1) * widget.gridsPerLine,
        widget.minSlotCount);

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
            width: (kDefaultItemGridSize.width + 4.0) * widget.gridsPerLine,
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
        ),
      ),
    );
  }
}
