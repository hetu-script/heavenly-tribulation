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
  }) : assert(characterData != null);

  final dynamic characterData;
  final Size gridSize;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.from(
            (characterData['equipments'].values as Iterable).map(
              (itemId) => Padding(
                padding: const EdgeInsets.all(5.0),
                child: ItemGrid(
                  itemData: itemId != null
                      ? characterData['inventory'][itemId]
                      : null,
                  size: gridSize,
                  backgroundImage:
                      const AssetImage('assets/images/item/grid.png'),
                  showEquippedIcon: false,
                  onTapped: onItemTapped,
                  onSecondaryTapped: onItemSecondaryTapped,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
