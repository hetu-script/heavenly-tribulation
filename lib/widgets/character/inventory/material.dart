import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/empty_placeholder.dart';
import 'package:samsara/ui/mouse_region2.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import '../../../game/ui.dart';
import '../../../game/logic.dart';
import '../../../engine.dart';
import '../../../state/hover_content.dart';
import '../../../common.dart';

class MaterialStorage extends StatelessWidget {
  const MaterialStorage({
    super.key,
    this.width = 255.0,
    this.height,
    required this.entity,
    this.priceFactor,
    this.filter,
    this.isSell = false,
    this.selectedItem,
    this.onSelectedItem,
  });

  final double width;
  final double? height;
  final dynamic entity;
  final dynamic priceFactor;
  final List? filter;
  final bool isSell;
  final String? selectedItem;
  final void Function(String)? onSelectedItem;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (final key in kOtherMaterialKinds) {
      if (key == 'money') continue;
      int amount = 0;
      if (filter != null) {
        if (filter!.isNotEmpty && !filter!.contains(key)) continue;
      } else {
        amount = entity['materials'][key] ?? 0;
        if (amount <= 0) continue;
      }

      final unitPrice = GameLogic.calculateMaterialPrice(key,
          priceFactor: priceFactor, isSell: isSell);

      widgets.add(
        MouseRegion2(
          cursor: FlutterCustomMemoryImageCursor(key: 'click'),
          onTapUp: () {
            onSelectedItem?.call(key);
          },
          onMouseEnter: (rect) {
            context.read<HoverContentState>().show(
                '${engine.locale(key)}: ${engine.locale('${key}_description')}\n'
                '${priceFactor != null ? '${engine.locale('unitPrice')}: $unitPrice' : ''}',
                rect);
          },
          onMouseExit: () {
            context.read<HoverContentState>().hide();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 2.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(
                  color: selectedItem == key
                      ? GameUI.selectedColorOpaque
                      : GameUI.foregroundColor),
              color: selectedItem == key
                  ? GameUI.focusedColor
                  : Colors.transparent,
            ),
            padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 5.0),
            child: Row(
              children: [
                Image(
                  width: 20,
                  height: 20,
                  image: AssetImage('assets/images/item/material/$key.png'),
                ),
                Text(
                  // '${engine.locale(key)} ${'${engine.locale('unitPrice')}: $unitPrice'}',
                  engine.locale(key),
                  style: TextStyle(
                    color: selectedItem == key
                        ? GameUI.selectedColorOpaque
                        : Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  '${engine.locale('amount')}: ${amount.toString().padLeft(8)}',
                  style: TextStyle(
                    color: selectedItem == key
                        ? GameUI.selectedColorOpaque
                        : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: GameUI.foregroundColor),
      ),
      child: widgets.isEmpty
          ? EmptyPlaceholder(engine.locale('empty'))
          : Column(children: widgets),
    );
  }
}
