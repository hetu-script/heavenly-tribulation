import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../grid/entity_grid.dart';
import 'cooldown.dart';
import '../../../../config.dart';
import '../../grid/entity_info.dart';
import 'package:samsara/ui/flutter/dynamic_color_progressbar.dart';

class BattleItemCard extends StatelessWidget {
  const BattleItemCard({
    super.key,
    this.size = const Size(64.0, 64.0),
    this.itemData,
    this.life,
    this.maxLife,
    this.isSelected = false,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
  });

  final Size size;

  final HTStruct? itemData;

  final num? life, maxLife;

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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kBackgroundColor,
        border: Border.all(
          color: kForegroundColor.withOpacity(isSelected ? 1 : 0.25),
          width: 2,
        ),
        borderRadius: kBorderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (life != null && maxLife != null)
            DynamicColorProgressBar(
              width: size.width - 4,
              height: 8.0,
              value: life!.toDouble(),
              max: maxLife!.toDouble(),
              showNumber: false,
              colors: const <Color>[Colors.red, Colors.green],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: EntityGrid(
              size: const Size(45.0, 45.0),
              entityData: itemData,
              hasBorder: false,
              showEquippedIcon: false,
              onItemTapped: (item, screenPosition) =>
                  _onItemTapped(context, item, screenPosition),
              child: CustomPaint(
                size: size,
                painter: CoolDownPainter(
                  value: isSelected ? cooldownValue : 0,
                  color: cooldownColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
