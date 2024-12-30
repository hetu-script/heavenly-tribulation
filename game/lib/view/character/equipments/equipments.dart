import 'package:flutter/material.dart';

import 'item_grid.dart';
// import '../../../config.dart';
// import '../../../common.dart';

class EquipmentsView extends StatelessWidget {
  const EquipmentsView({
    super.key,
    required this.equipmentsData,
    this.onMouseEnterItemGrid,
    this.onMouseExitItemGrid,
    this.onItemTapped,
    this.onItemSecondaryTapped,
  });

  final dynamic equipmentsData;
  final void Function(dynamic entityData, Rect gridRenderBox)?
      onMouseEnterItemGrid;
  final void Function()? onMouseExitItemGrid;
  final void Function(dynamic entityData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic entityData, Offset screenPosition)?
      onItemSecondaryTapped;

  @override
  Widget build(BuildContext context) {
    final equipmentsGrid = List<Widget>.from(
      equipmentsData.map(
        (data) => Padding(
          padding: const EdgeInsets.all(5.0),
          child: EntityGrid(
            entityData: data,
            // onItemTapped: onItemTapped,
            backgroundImage: const AssetImage('assets/images/item/grid.png'),
            showEquippedIcon: false,
            onMouseEnterItemGrid: onMouseEnterItemGrid,
            onMouseExitItemGrid: onMouseExitItemGrid,
            onTapped: onItemTapped,
            onSecondaryTapped: onItemSecondaryTapped,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: equipmentsGrid,
        ),
      ],
    );
  }
}
