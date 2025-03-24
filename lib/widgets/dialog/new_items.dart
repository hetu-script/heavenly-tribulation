import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../game/ui.dart';
import '../../engine.dart';
import '../../state/hoverinfo.dart';
import '../../state/new_prompt.dart';
import '../character/inventory/item_grid.dart';
import '../../game/data.dart';

class NewItems extends StatelessWidget {
  const NewItems({
    super.key,
    required this.itemsData,
  });

  final Iterable itemsData;

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
                    width: 350.0,
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
                                    characterData: GameData.heroData,
                                    itemData: data,
                                    margin: const EdgeInsets.all(5.0),
                                    onMouseEnter: (itemData, rect) {
                                      context
                                          .read<HoverInfoContentState>()
                                          .set(itemData, rect);
                                    },
                                    onMouseExit: () {
                                      context
                                          .read<HoverInfoContentState>()
                                          .hide();
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
              ElevatedButton(
                onPressed: () {
                  context.read<NewItemsState>().update();
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
