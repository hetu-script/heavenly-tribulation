import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/game.dart';
import '../../state/view_panels.dart';
import '../ui/close_button2.dart';
import '../character/inventory/equipment_bar.dart';
import '../character/inventory/inventory.dart';

class AlchemyDialog extends StatefulWidget {
  const AlchemyDialog({
    super.key,
  });

  @override
  State<AlchemyDialog> createState() => _AlchemyDialogState();
}

class _AlchemyDialogState extends State<AlchemyDialog> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  void onInventoryItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    if (_tabIndex == 0) {
    } else if (_tabIndex == 1) {}
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: 500.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('workshop')),
          actions: [
            CloseButton2(
              onPressed: () {
                context.read<ViewPanelState>().toogle(ViewPanels.alchemy);
              },
            )
          ],
        ),
        body: Container(
          width: 800.0,
          height: 600.0,
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 40.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                width: 400.0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                  child: fluent.TabView(
                    currentIndex: _tabIndex,
                    onChanged: (index) => setState(() => _tabIndex = index),
                    closeButtonVisibility:
                        fluent.CloseButtonVisibilityMode.never,
                    tabs: [
                      fluent.Tab(
                        text: Text(engine.locale('craft_potion')),
                        body: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Column(
                            children: [
                              const Spacer(),
                              fluent.FilledButton(
                                onPressed: () {},
                                child: Text(engine.locale('craft_item')),
                              ),
                            ],
                          ),
                        ),
                      ),
                      fluent.Tab(
                        text: Text(engine.locale('craft_battle_potion')),
                        body: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Column(
                            children: [
                              const Spacer(),
                              fluent.FilledButton(
                                onPressed: () {},
                                child: Text(engine.locale('craft_item')),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                children: [
                  EquipmentBar(
                    character: GameData.hero,
                    onItemSecondaryTapped: onInventoryItemSecondaryTapped,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Inventory(
                      character: GameData.hero,
                      itemType: ItemType.none,
                      gridsPerLine: 6,
                      onItemSecondaryTapped: onInventoryItemSecondaryTapped,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
