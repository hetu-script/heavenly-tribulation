import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/hover_info.dart';

import '../../../logic/logic.dart';
import '../../common.dart';
import 'item_grid.dart';

export '../../common.dart' show InventoryType;

/// 如果是玩家自己的物品栏，则传入characterData
class Inventory extends StatelessWidget {
  Inventory({
    super.key,
    required this.character,
    required this.inventoryType,
    this.height = 312.0,
    this.minSlotCount = 60,
    this.gridsPerLine = 5,
    this.selectedItemId = const [],
    this.priceFactor,
    this.onItemTapped,
    this.onItemSecondaryTapped,
    this.onMouseEnterItemGrid,
    this.filter,
  });

  final dynamic character;
  final InventoryType inventoryType;
  final double height;
  final int minSlotCount, gridsPerLine;
  final Iterable selectedItemId;
  final dynamic priceFactor;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;
  final void Function(dynamic itemData)? onMouseEnterItemGrid;

  /// 物品过滤条件，传入一个 Map/HTStruct，支持以下字段：
  /// - `rank`（int）：精确匹配境界等级
  /// - `minRank`（int）：最低境界等级（含）
  /// - `maxRank`（int）：最高境界等级（含）
  /// - `type`（String）：物品类型，如 `'equipment'`、`'craft_material'` 等
  /// - `category`（String）：物品类别，如 `'weapon'`、`'armor'` 等
  /// - `kind`（String）：物品种类，如 `'sword'`、`'shard'` 等
  /// - `id`（String）：物品唯一 ID
  /// - `isIdentified`（bool）：是否已鉴定
  ///
  /// 所有字段均可选，为 null 时不过滤该维度。
  /// 已装备的物品始终被排除。
  final dynamic filter;

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];

    final isDetailed = context.read<HoverContentState>().isDetailed;

    final filteredItems = GameLogic.getFilteredItems(
      character,
      inventoryType: inventoryType,
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
            onMouseEnterItemGrid?.call(itemData);
            context.read<HoverContentState>().show(
                  buildItemHoverInfo(
                    itemData,
                    inventoryType: inventoryType,
                    isDetailed: isDetailed,
                    priceFactor: inventoryType == InventoryType.merchant ||
                            inventoryType == InventoryType.customer
                        ? priceFactor
                        : null,
                  ),
                  rect,
                );
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
