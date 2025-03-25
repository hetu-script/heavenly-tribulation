import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'item_grid.dart';
import '../../../state/hoverinfo.dart';
// import '../../../config.dart';
// import '../../../common.dart';

class EquipmentBar extends StatelessWidget {
  const EquipmentBar({
    super.key,
    required this.characterData,
    required this.type,
    this.gridSize = kDefaultItemGridSize,
    this.onItemTapped,
    this.onItemSecondaryTapped,
    this.isVertical = false,
  })  : assert(characterData != null),
        assert(type == ItemType.player || type == ItemType.npc);

  final dynamic characterData;
  final ItemType type;
  final Size gridSize;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>.from(
      (characterData['equipments'].values as Iterable).map(
        (itemId) => ItemGrid(
          characterData: characterData,
          itemData: itemId != null ? characterData['inventory'][itemId] : null,
          size: gridSize,
          margin: const EdgeInsets.all(5.0),
          showEquippedIcon: false,
          onTapped: onItemTapped,
          onSecondaryTapped: onItemSecondaryTapped,
          onMouseEnter: (itemData, rect) {
            switch (type) {
              case ItemType.player:
                context
                    .read<HoverInfoContentState>()
                    .set(itemData, type: type, data2: characterData, rect);
              default:
                context
                    .read<HoverInfoContentState>()
                    .set(itemData, type: type, rect);
            }
          },
          onMouseExit: () {
            context.read<HoverInfoContentState>().hide();
          },
        ),
      ),
    );

    return isVertical ? Column(children: children) : Row(children: children);
  }
}
