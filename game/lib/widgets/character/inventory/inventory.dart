import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/hoverinfo.dart';
import 'item_grid.dart';

/// 如果是玩家自己的物品栏，则传入characterData
class Inventory extends StatefulWidget {
  const Inventory({
    super.key,
    required this.characterData,
    required this.type,
    required this.height,
    this.minSlotCount = 30,
    this.gridsPerLine = 5,
    this.onTapped,
    this.onSecondaryTapped,
    this.selectedItemId = const {},
    this.priceFactor,
    this.filter,
  });

  final dynamic characterData;
  final HoverType type;
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

    final inventoryData = widget.characterData['inventory'];

    final String? category = widget.filter?['category'];
    final String? kind = widget.filter?['kind'];
    final String? id = widget.filter?['id'];
    final bool? isIdentified = widget.filter?['isIdentified'];

    for (var i = 0; i < inventoryData.length; ++i) {
      final itemData = (inventoryData.values as Iterable).elementAt(i);
      if (itemData['equippedPosition'] != null) {
        continue;
      }
      if (category != null && category != itemData['category']) {
        continue;
      }
      if (kind != null && kind != itemData['kind']) {
        continue;
      }
      if (id != null && id != itemData['id']) {
        continue;
      }
      if (isIdentified != null && isIdentified != itemData['isIdentified']) {
        continue;
      }

      grids.add(
        ItemGrid(
          characterData: widget.characterData,
          itemData: itemData,
          margin: const EdgeInsets.all(5.0),
          onMouseEnter: (itemData, rect) {
            switch (widget.type) {
              case HoverType.general:
                context
                    .read<HoverInfoContentState>()
                    .set(itemData, type: widget.type, rect);
              case HoverType.player:
              case HoverType.npc:
                context.read<HoverInfoContentState>().set(
                      itemData,
                      type: widget.type,
                      data2: widget.characterData,
                      rect,
                    );
              case HoverType.merchant:
                context.read<HoverInfoContentState>().set(
                      itemData,
                      type: widget.type,
                      data2: widget.priceFactor,
                      rect,
                    );
              case HoverType.customer:
                context.read<HoverInfoContentState>().set(
                      itemData,
                      type: widget.type,
                      data2: widget.priceFactor,
                      rect,
                    );
            }
          },
          onMouseExit: () {
            context.read<HoverInfoContentState>().hide();
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
        ItemGrid(margin: const EdgeInsets.all(5.0)),
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
        ),
      ),
    );
  }
}
