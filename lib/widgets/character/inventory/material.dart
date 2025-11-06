import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/empty_placeholder.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/hover_info.dart';

import '../../../ui.dart';
import '../../../logic/logic.dart';
import '../../../global.dart';
import '../../../data/common.dart';

enum MaterialListType {
  inventory,
  sell,
  storage,
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
    this.showZeroAmount = false,
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
  final bool showZeroAmount;
  final MaterialListType materialListType;
  final String? selectedItem;
  final void Function(String)? onSelectedItem;

  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    final data = (materialListType == MaterialListType.storage)
        ? entity['storage']
        : entity['materials'];

    for (final key in kMaterialKinds) {
      if (materialListType != MaterialListType.storage && key == 'money') {
        continue;
      }
      int amount = 0;
      int? requiredAmount;
      if (filter != null && filter!.isNotEmpty) {
        if (!filter!.contains(key)) continue;
      } else {
        amount = data[key] ?? 0;
        if (requirements != null) {
          requiredAmount = requirements[key] ?? 0;
          if (requiredAmount! <= 0 && !showZeroAmount) continue;
        } else {
          if (amount <= 0 && !showZeroAmount) continue;
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
          child: fluent.Button(
            style: selectedItem == key
                ? FluentButtonStyles.selected
                : FluentButtonStyles.outlined,
            onPressed: () {
              onSelectedItem?.call(key);
            },
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
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Text(
                  requiredAmount != null
                      ? '$requiredAmount/$amount'.padLeft(8)
                      : amount.toString().padLeft(8),
                  style: TextStyles.bodySmall.copyWith(
                    color: requiredAmount != null
                        ? (amount < requiredAmount ? Colors.red : Colors.white)
                        : Colors.white,
                  ),
                ),
              ],
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
            decoration: GameUI.boxDecoration.copyWith(
              color: GameUI.backgroundColor,
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
