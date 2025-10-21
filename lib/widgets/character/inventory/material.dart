import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/empty_placeholder.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';

import '../../../ui.dart';
import '../../../logic/logic.dart';
import '../../../engine.dart';
import '../../../state/hover_content.dart';
import '../../../data/common.dart';

enum MaterialListType {
  inventory,
  sell,
  craft,
}

class MaterialList extends StatelessWidget {
  MaterialList({
    super.key,
    this.width = 255.0,
    this.height,
    required this.entity,
    this.requirements,
    this.priceFactor,
    this.filter,
    this.materialListType = MaterialListType.inventory,
    this.selectedItem,
    this.onSelectedItem,
  });

  final double width;
  final double? height;
  final dynamic entity;
  final dynamic requirements;
  final dynamic priceFactor;
  final List? filter;
  final MaterialListType materialListType;
  final String? selectedItem;
  final void Function(String)? onSelectedItem;

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (final key in kMaterialKinds) {
      if (materialListType != MaterialListType.craft && key == 'money') {
        continue;
      }
      int amount = 0;
      int? requiredAmount;
      if (filter != null && filter!.isNotEmpty) {
        if (!filter!.contains(key)) continue;
      } else {
        amount = entity?['materials']?[key] ?? 0;
        if (requirements != null) {
          requiredAmount = requirements[key] ?? 0;
          if (requiredAmount! <= 0) continue;
        } else {
          if (amount <= 0) continue;
        }
      }

      int? unitPrice;
      if (priceFactor != null) {
        unitPrice = GameLogic.calculateMaterialPrice(
          key,
          priceFactor: priceFactor,
          isSell: materialListType == MaterialListType.sell,
        );
      }

      widgets.add(
        MouseRegion2(
          cursor: GameUI.cursor.resolve({WidgetState.hovered}),
          onEnter: (rect) {
            context.read<HoverContentState>().show(
                '<grey>${engine.locale(key)}: ${engine.locale('${key}_description')}</>'
                '${priceFactor != null ? '\n \n<yellow>${engine.locale('unitPrice')}: $unitPrice ${engine.locale('money2')}</>' : ''}',
                rect);
          },
          onExit: () {
            context.read<HoverContentState>().hide();
          },
          child: GestureDetector(
            onTap: () {
              onSelectedItem?.call(key);
            },
            child: Container(
              margin: const EdgeInsets.only(
                  left: 2.0, right: 2.0, top: 1.0, bottom: 1.0),
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(
                    color: selectedItem == key
                        ? GameUI.selectedColor
                        : GameUI.foregroundColor),
                color: selectedItem == key
                    ? GameUI.focusColor
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Image(
                    width: 20,
                    height: 20,
                    image: AssetImage('assets/images/item/material/$key.png'),
                  ),
                  Text(
                    engine.locale(key),
                    style: TextStyle(
                      color: selectedItem == key
                          ? GameUI.selectedColor
                          : Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    requiredAmount != null
                        ? '$requiredAmount/$amount'.padLeft(8)
                        : amount.toString().padLeft(8),
                    style: TextStyle(
                      color: requiredAmount != null
                          ? (amount < requiredAmount
                              ? Colors.red
                              : Colors.white)
                          : (selectedItem == key
                              ? GameUI.selectedColor
                              : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: MaterialScrollBehavior(),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Container(
            height: height,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: GameUI.foregroundColor),
            ),
            child: widgets.isEmpty
                ? EmptyPlaceholder(engine.locale('empty'))
                : Column(children: widgets),
          ),
        ),
      ),
    );
  }
}
