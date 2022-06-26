import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import 'item_grid.dart';
import 'item_info.dart';

class EquipmentsView extends StatelessWidget {
  const EquipmentsView({
    super.key,
    required this.data,
    this.verticalMargin = 40.0,
    this.horizontalMargin = 10.0,
  });

  final HTStruct data;

  final double verticalMargin, horizontalMargin;

  void _onItemTapped(
      BuildContext context, HTStruct item, Offset screenPosition) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return ItemInfo(
            data: item,
            left: screenPosition.dx,
            top: screenPosition.dy - 100.0,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ItemGrid(
          verticalMargin: verticalMargin,
          horizontalMargin: horizontalMargin,
          data: data[1],
          onSelect: (item, screenPosition) =>
              _onItemTapped(context, item, screenPosition),
          cooldownValue: 0.5,
        ),
        ItemGrid(
          verticalMargin: verticalMargin,
          horizontalMargin: horizontalMargin,
          data: data[2],
          onSelect: (item, screenPosition) =>
              _onItemTapped(context, item, screenPosition),
        ),
        ItemGrid(
          verticalMargin: verticalMargin,
          horizontalMargin: horizontalMargin,
          data: data[3],
          onSelect: (item, screenPosition) =>
              _onItemTapped(context, item, screenPosition),
        ),
        ItemGrid(
          verticalMargin: verticalMargin,
          horizontalMargin: horizontalMargin,
          data: data[4],
          onSelect: (item, screenPosition) =>
              _onItemTapped(context, item, screenPosition),
        ),
      ],
    );
  }
}
