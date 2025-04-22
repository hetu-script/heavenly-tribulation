import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'item_grid.dart';
import '../../../state/hover_content.dart';

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
    this.type = ItemType.none,
    this.gridSize = kDefaultItemGridSize,
    this.selectedItemId = const [],
    this.onItemTapped,
    this.onItemSecondaryTapped,
    this.onItemMouseEnter,
    this.onItemMouseExit,
  });

  final EquipmentBarStyle style;
  final dynamic character;
  final ItemType type;
  final Size gridSize;
  final Iterable selectedItemId;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;
  final void Function(dynamic itemData, Rect rect)? onItemMouseEnter;
  final void Function()? onItemMouseExit;

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>.from(
      (character['equipments'].values as Iterable).map(
        (itemId) => ItemGrid(
          itemData: itemId != null ? character['inventory'][itemId] : null,
          size: gridSize,
          margin: const EdgeInsets.all(2),
          showEquippedIcon: false,
          isSelected: selectedItemId.contains(itemId),
          onTapped: onItemTapped,
          onSecondaryTapped: onItemSecondaryTapped,
          onMouseEnter: (itemData, rect) {
            if (onItemMouseEnter != null) {
              onItemMouseEnter!(itemData, rect);
            } else {
              context.read<HoverContentState>().show(
                    itemData,
                    type: type,
                    rect,
                  );
            }
          },
          onMouseExit: () {
            if (onItemMouseExit != null) {
              onItemMouseExit!();
            } else {
              context.read<HoverContentState>().hide();
            }
          },
        ),
      ),
    );

    return switch (style) {
      EquipmentBarStyle.vertical => Container(
          height: (gridSize.width + 4.0) * character['equipments'].length,
          child: Column(children: children),
        ),
      EquipmentBarStyle.horizontal => Container(
          width: (gridSize.width + 4.0) * character['equipments'].length,
          child: Row(children: children),
        ),
      EquipmentBarStyle.split => SizedBox.shrink(),
    };
  }
}
