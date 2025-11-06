import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/hover_info.dart';

import '../../global.dart';
import '../../state/new_prompt.dart';
import '../character/inventory/item_grid.dart';
import '../ui/responsive_view.dart';

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
    final List<Widget> itemWidgets = [];
    for (var i = 0; i < _kItemCountMax; ++i) {
      final grid = ItemGrid(
        itemData: i < itemsData.length ? itemsData.elementAt(i) : null,
        margin: const EdgeInsets.all(2.5),
        onMouseEnter: (itemData, rect) {
          context.read<HoverContentState>().show(itemData, rect);
        },
        onMouseExit: () {
          context.read<HoverContentState>().hide();
        },
      );
      itemWidgets.add(grid);
    }

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
              ScrollConfiguration(
                behavior: MaterialScrollBehavior(),
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 320.0,
                    height: 160.0,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.start,
                          children: itemWidgets,
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              fluent.Button(
                onPressed: () {
                  completer?.complete();
                  context.read<ItemsPromptState>().update();
                  engine.play('pickup_item-64282.mp3');
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
