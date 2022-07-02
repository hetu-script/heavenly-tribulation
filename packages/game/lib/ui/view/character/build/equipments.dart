import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import 'item_grid.dart';
import 'item_info.dart';

class EquipmentsView extends StatelessWidget {
  const EquipmentsView({
    super.key,
    required this.equipmentsData,
    this.verticalMargin = 5.0,
    this.horizontalMargin = 10.0,
    this.selectedIndex = 0,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
  });

  final HTStruct equipmentsData;

  final double verticalMargin, horizontalMargin;

  final int selectedIndex;

  final double cooldownValue;

  final Color cooldownColor;

  void _onItemTapped(
      BuildContext context, HTStruct item, Offset screenPosition) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return ItemInfo(
            itemData: item,
            left: screenPosition.dx,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390.0,
      height: 390.0,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemGrid(
                itemData: equipmentsData['offense'][1],
                onSelect: (item, screenPosition) =>
                    _onItemTapped(context, item, screenPosition),
                isSelected: selectedIndex == 1,
              ),
              ItemGrid(
                itemData: equipmentsData['offense'][2],
                onSelect: (item, screenPosition) =>
                    _onItemTapped(context, item, screenPosition),
                isSelected: selectedIndex == 2,
              ),
              ItemGrid(
                itemData: equipmentsData['offense'][3],
                onSelect: (item, screenPosition) =>
                    _onItemTapped(context, item, screenPosition),
                isSelected: selectedIndex == 3,
              ),
              ItemGrid(
                itemData: equipmentsData['offense'][4],
                onSelect: (item, screenPosition) =>
                    _onItemTapped(context, item, screenPosition),
                isSelected: selectedIndex == 4,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemGrid(
                itemData: equipmentsData['defense'][1],
                onSelect: (item, screenPosition) =>
                    _onItemTapped(context, item, screenPosition),
              ),
              ItemGrid(
                itemData: equipmentsData['defense'][2],
                onSelect: (item, screenPosition) =>
                    _onItemTapped(context, item, screenPosition),
              ),
              ItemGrid(
                itemData: equipmentsData['defense'][3],
                onSelect: (item, screenPosition) =>
                    _onItemTapped(context, item, screenPosition),
              ),
              ItemGrid(
                itemData: equipmentsData['defense'][4],
                onSelect: (item, screenPosition) =>
                    _onItemTapped(context, item, screenPosition),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
