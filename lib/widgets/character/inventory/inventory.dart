import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/hover_info.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../../logic/logic.dart';
import '../../common.dart';
import 'item_grid.dart';
import '../../../global.dart';
import '../../../ui.dart';

export '../../common.dart' show InventoryType;

const kDefaultInventoryItemTypes = {
  'all',
  'equipment',
  'consumable',
  'craftmaterial',
  'miscellaneous',
};

/// 如果是玩家自己的物品栏，则传入characterData
class Inventory extends StatefulWidget {
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
    this.itemTypes = kDefaultInventoryItemTypes,
  }) : assert(itemTypes == null || itemTypes.isNotEmpty,
            'itemTypes cannot be empty');

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
  /// - `type`（String）：物品类型，如 `'equipment'`、`'craftmaterial'` 等
  /// - `category`（String）：物品类别，如 `'weapon'`、`'armor'` 等
  /// - `kind`（String）：物品种类，如 `'sword'`、`'shard'` 等
  /// - `id`（String）：物品唯一 ID
  /// - `isIdentified`（bool）：是否已鉴定
  ///
  /// 所有字段均可选，为 null 时不过滤该维度。
  /// 已装备的物品始终被排除。
  final dynamic filter;
  final Iterable? itemTypes;

  @override
  State<Inventory> createState() => _InventoryState();
}

class _InventoryState extends State<Inventory> {
  final _scrollController = ScrollController();

  late dynamic filter;

  @override
  void initState() {
    super.initState();

    filter = widget.filter ?? {};
    if (widget.itemTypes != null) {
      filter['type'] = widget.itemTypes!.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];

    final hoverState = context.read<HoverContentState>();

    final filteredItems = GameLogic.getFilteredItems(
      widget.character,
      inventoryType: widget.inventoryType,
      filter: filter,
      filterShard: widget.priceFactor?['useShard'] ?? false,
    );
    for (final itemData in filteredItems) {
      grids.add(
        ItemGrid(
          size: kDefaultItemGridSize,
          itemData: itemData,
          margin: const EdgeInsets.all(2.0),
          onMouseEnter: (itemData, rect) {
            widget.onMouseEnterItemGrid?.call(itemData);
            final priceFactor =
                widget.inventoryType == InventoryType.merchant ||
                        widget.inventoryType == InventoryType.customer
                    ? widget.priceFactor
                    : null;
            hoverState.show(
              rect: rect,
              contentBuilder: (isDetailed) => buildItemHoverInfo(
                itemData,
                inventoryType: widget.inventoryType,
                isDetailed: isDetailed,
                priceFactor: priceFactor,
              ),
            );
          },
          onMouseExit: () {
            context.read<HoverContentState>().hide();
          },
          onTapped: widget.onItemTapped,
          onSecondaryTapped: widget.onItemSecondaryTapped,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.filter == null && widget.itemTypes != null)
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Row(
              children: widget.itemTypes!
                  .map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: fluent.Button(
                          style: FluentButtonStyles.slim,
                          child: Text(
                            engine.locale(type),
                            style: TextStyles.bodySmall,
                          ),
                          onPressed: () {
                            filter['type'] = type == 'all' ? null : type;
                            setState(() {});
                          }),
                    ),
                  )
                  .toList(),
            ),
          ),
        ScrollConfiguration(
          behavior: MaterialScrollBehavior(),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                width:
                    (kDefaultItemGridSize.width + 4.0) * widget.gridsPerLine +
                        20.0,
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
        ),
      ],
    );
  }
}
