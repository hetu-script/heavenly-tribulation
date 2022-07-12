import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../entity_grid.dart';
import 'cooldown.dart';
import '../../../global.dart';
import '../entity_info.dart';

class OffenseItemCard extends StatelessWidget {
  const OffenseItemCard({
    super.key,
    this.itemData,
    this.size = const Size(60.0, 140.0),
    this.isSelected = false,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
  });

  final HTStruct? itemData;

  final Size? size;

  final bool isSelected;

  final double cooldownValue;

  final Color cooldownColor;

  void _onItemTapped(
      BuildContext context, HTStruct item, Offset screenPosition) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return EntityInfo(
            entityData: item,
            left: screenPosition.dx,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size?.width,
      height: size?.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        border: Border.all(
          color: Colors.white.withOpacity(isSelected ? 1 : 0.25),
          width: 2,
        ),
        borderRadius: kBorderRadius,
      ),
      child: EntityGrid(
        entityData: itemData,
        hasBorder: false,
        onSelect: (item, screenPosition) =>
            _onItemTapped(context, item, screenPosition),
        child: CustomPaint(
          size: kDefaultGridSize,
          painter: CoolDownPainter(
            value: isSelected ? cooldownValue : 0,
            color: cooldownColor,
          ),
        ),
      ),
    );
  }
}
