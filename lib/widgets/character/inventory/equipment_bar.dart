import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/hover_info.dart';

import 'item_grid.dart';
import '../../common.dart';
import '../../../data/common.dart';
import '../../../ui.dart';

enum EquipmentBarStyle {
  vertical,
  horizontal,
  split,
}

class EquipmentBar extends StatelessWidget {
  const EquipmentBar({
    super.key,
    this.style = EquipmentBarStyle.horizontal,
    required this.character,
    this.inventoryType = InventoryType.none,
    this.gridSize = kDefaultItemGridSize,
    this.selectedItemId = const [],
    this.onItemTapped,
    this.onItemSecondaryTapped,
  });

  final EquipmentBarStyle style;
  final dynamic character;
  final InventoryType inventoryType;
  final Size gridSize;
  final Iterable selectedItemId;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;

  @override
  Widget build(BuildContext context) {
    final hoverState = context.read<HoverContentState>();

    final equipments = character['equipments'] as Map;
    // 装备栏固定显示全部格子，超出当前境界可用数量的格子为锁定态
    final int unlockedSlotCount = equipmentSlotCount(character['rank'] ?? 0);

    final children = <Widget>[];
    var index = 0;
    for (final itemId in equipments.values) {
      final isLocked = index >= unlockedSlotCount;
      children.add(
        ItemGrid(
          itemData: itemId != null ? character['inventory'][itemId] : null,
          size: gridSize,
          margin: const EdgeInsets.all(2),
          showEquippedIcon: false,
          isSelected: selectedItemId.contains(itemId),
          onTapped: onItemTapped,
          onSecondaryTapped: onItemSecondaryTapped,
          // TODO: 锁定格的美术资源后续补充，目前先简单置灰
          child: isLocked
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: GameUI.borderRadius,
                    color: Colors.black54,
                  ),
                )
              : null,
          onMouseEnter: (itemData, rect) {
            hoverState.show(
              rect: rect,
              contentBuilder: (isDetailed) => buildItemHoverInfo(
                itemData,
                inventoryType: inventoryType,
                isDetailed: isDetailed,
              ),
            );
          },
          onMouseExit: () {
            context.read<HoverContentState>().hide();
          },
        ),
      );
      ++index;
    }

    return switch (style) {
      EquipmentBarStyle.vertical => SizedBox(
          height: (gridSize.width + 4.0) * equipments.length,
          child: Column(children: children),
        ),
      EquipmentBarStyle.horizontal => SizedBox(
          width: (gridSize.width + 4.0) * equipments.length,
          child: Row(children: children),
        ),
      EquipmentBarStyle.split => SizedBox.shrink(),
    };
  }
}
