import 'package:flutter/material.dart';

import 'item_grid.dart';
// import '../../../config.dart';
// import '../../../common.dart';

class EquipmentBar extends StatelessWidget {
  const EquipmentBar({
    super.key,
    required this.characterData,
    this.gridSize = kDefaultItemGridSize,
    this.onItemTapped,
    this.onItemSecondaryTapped,
    this.isVertical = false,
  }) : assert(characterData != null);

  final dynamic characterData;
  final Size gridSize;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;
  final bool isVertical;

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>.from(
      (characterData['equipments'].values as Iterable).map(
        (itemId) => Padding(
          padding: const EdgeInsets.all(5.0),
          child: ItemGrid(
            characterData: characterData,
            itemData:
                itemId != null ? characterData['inventory'][itemId] : null,
            size: gridSize,
            showEquippedIcon: false,
            onTapped: onItemTapped,
            onSecondaryTapped: onItemSecondaryTapped,
          ),
        ),
      ),
    );

    return isVertical ? Column(children: children) : Row(children: children);
  }
}
