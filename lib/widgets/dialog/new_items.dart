import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../ui.dart';
import '../../engine.dart';
import '../../state/hover_content.dart';
import '../../state/new_prompt.dart';
import '../character/inventory/item_grid.dart';

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
      backgroundColor: GameUI.backgroundColor,
      width: 400.0,
      height: 300.0,
      alignment: Alignment.center,
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
                  child: Container(
                    color: Colors.black,
                    width: 320.0,
                    height: 160.0,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Wrap(
                          alignment: WrapAlignment.start,
                          children: List<Widget>.from(
                            itemsData
                                .map(
                                  (data) => ItemGrid(
                                    itemData: data,
                                    margin: const EdgeInsets.all(2.5),
                                    onMouseEnter: (itemData, rect) {
                                      context
                                          .read<HoverContentState>()
                                          .show(itemData, rect);
                                    },
                                    onMouseExit: () {
                                      context.read<HoverContentState>().hide();
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              fluent.FilledButton(
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
