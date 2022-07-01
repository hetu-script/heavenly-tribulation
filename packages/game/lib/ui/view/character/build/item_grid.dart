import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../../global.dart';
import 'cooldown.dart';

class ItemGrid extends StatelessWidget {
  const ItemGrid({
    super.key,
    this.size = const Size(48.0, 48.0),
    this.verticalMargin = 5.0,
    this.horizontalMargin = 5.0,
    this.data,
    required this.onSelect,
    this.isSelected = false,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
  });

  final Size size;
  final double verticalMargin;
  final double horizontalMargin;
  final HTStruct? data;
  final void Function(HTStruct item, Offset screenPosition) onSelect;
  final bool isSelected;
  final double cooldownValue;
  final Color cooldownColor;

  @override
  Widget build(BuildContext context) {
    final iconAssetKey = data?['icon'];

    return GestureDetector(
      onTapUp: (TapUpDetails details) {
        if (data != null) {
          onSelect(data!, details.globalPosition);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: data?['name'] ?? '',
          child: Container(
              width: size.width,
              height: size.height,
              margin: EdgeInsets.symmetric(
                  vertical: verticalMargin, horizontal: horizontalMargin),
              decoration: BoxDecoration(
                color: kBackgroundColor,
                border: Border.all(
                  color: Colors.white.withOpacity(isSelected ? 1 : 0.25),
                  width: 2,
                ),
                // image: const DecorationImage(
                //   fit: BoxFit.contain,
                //   image: AssetImage('assets/images/icon/item/grid.png'),
                // ),
                borderRadius: kBorderRadius,
              ),
              child: Stack(
                children: [
                  if (iconAssetKey != null)
                    Image(
                      fit: BoxFit.contain,
                      image: AssetImage('assets/images/$iconAssetKey'),
                    ),
                  CustomPaint(
                    size: size,
                    painter: CoolDownPainter(
                      value: cooldownValue,
                      color: cooldownColor,
                    ),
                  )
                ],
              )),
        ),
      ),
    );
  }
}
