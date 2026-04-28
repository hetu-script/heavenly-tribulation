import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/hover_info.dart';

import '../../global.dart';
import '../../state/new_prompt.dart';
import '../character/inventory/item_grid.dart';
import '../ui/responsive_view.dart';
import '../../data/game.dart';
import '../common.dart';

const _kItemCountMax = 18;

class NewItems extends StatelessWidget {
  const NewItems({
    super.key,
    required this.itemsData,
    this.completer,
  });

  final Iterable itemsData;
  final Completer? completer;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierColor: null,
      width: 400.0,
      height: 300.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('newItems')),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 320.0,
                height: 160.0,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.start,
                      children: List.generate(_kItemCountMax, (index) {
                        return ItemGrid(
                          itemData: index < itemsData.length
                              ? itemsData.elementAt(index)
                              : null,
                          margin: const EdgeInsets.all(2.0),
                          onMouseEnter: (itemData, rect) {
                            context.read<HoverContentState>().show(
                                  rect: rect,
                                  data: buildItemHoverInfo(itemData,
                                      inventoryType: InventoryType.none),
                                );
                          },
                          onMouseExit: () {
                            context.read<HoverContentState>().hide();
                          },
                        );
                      }),
                    )
                  ],
                ),
              ),
              const Spacer(),
              fluent.Button(
                onPressed: () {
                  completer?.complete();
                  context.read<ItemsPromptState>().update();
                  engine.play(GameSound.pickup);
                },
                child: Text(
                  engine.locale('confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
