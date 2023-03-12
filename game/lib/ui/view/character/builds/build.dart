import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../grid/entity_info.dart';
import '../../../../event/events.dart';
import 'package:samsara/flutter_ui/close_button.dart';
import '../../../../global.dart';
import 'equipments.dart';
import 'inventory.dart';
import 'package:samsara/flutter_ui/responsive_window.dart';
import '../../grid/entity_grid.dart';

const _kBuildTabNames = [
  'inventory',
  'skill',
  'companion',
];

enum BuildViewType {
  player,
  npc,
}

class BuildView extends StatefulWidget {
  const BuildView({
    super.key,
    required this.characterData,
    this.tabIndex = 0,
    this.type = BuildViewType.player,
  });

  final HTStruct characterData;
  final int tabIndex;
  final BuildViewType type;

  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView> {
  // with SingleTickerProviderStateMixin {
  static final List<Tab> _tabs = _kBuildTabNames
      .map(
        (title) => Tab(
          iconMargin: const EdgeInsets.all(5.0),
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.inventory),
              ),
              Text(engine.locale[title]),
            ],
          ),
        ),
      )
      .toList();

  // late TabController _tabController;

  // String _title = engine.locale['items'];

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(vsync: this, length: _tabs.length);
    // _tabController.addListener(() {
    //   setState(() {
    //     if (_tabController.index == 0) {
    //       _title = engine.locale['items'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale['skills'];
    //     }
    //   });
    // });
    // _tabController.index = widget.tabIndex;
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(HTStruct itemData, Offset screenPosition) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        final List<Widget> actions = [];
        final hero = engine.invoke('getHero');
        switch (widget.type) {
          case BuildViewType.player:
            if (itemData['isConsumable'] ?? false) {
              actions.add(
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      engine
                          .invoke('consume', positionalArgs: [hero, itemData]);
                      Navigator.of(context).pop();
                      engine.broadcast(const UIEvent.needRebuildUI());
                      setState(() {});
                    },
                    child: Text(engine.locale['consume']),
                  ),
                ),
              );
            } else if (itemData['isEquippable'] != null) {
              if (itemData['equippedPosition'] == null) {
                actions.add(
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        engine
                            .invoke('equip', positionalArgs: [hero, itemData]);
                        Navigator.of(context).pop();
                        engine.broadcast(const UIEvent.needRebuildUI());
                        setState(() {});
                      },
                      child: Text(engine.locale['equip']),
                    ),
                  ),
                );
              } else {
                actions.add(
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        engine.invoke('unequip',
                            positionalArgs: [hero, itemData]);
                        Navigator.of(context).pop();
                        engine.broadcast(const UIEvent.needRebuildUI());
                        setState(() {});
                      },
                      child: Text(engine.locale['unequip']),
                    ),
                  ),
                );
              }
            }
            break;
          case BuildViewType.npc:
            actions.add(
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: ElevatedButton(
                  onPressed: () {
                    engine.invoke('characterSteal',
                        positionalArgs: [hero, itemData]);
                    Navigator.of(context).pop();
                    engine.broadcast(const UIEvent.needRebuildUI());
                    setState(() {});
                  },
                  child: Text(engine.locale['steal']),
                ),
              ),
            );
            break;
        }

        return EntityInfo(
          entityData: itemData,
          left: screenPosition.dx,
          actions: actions,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // final charId = widget.characterId ??
    //     ModalRoute.of(context)!.settings.arguments as String;

    // final characterData =
    //     engine.invoke('getCharacterById', positionalArgs: [charId]);

    return ResponsiveWindow(
      alignment: AlignmentDirectional.topCenter,
      size: const Size(400.0, 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.characterData['name']),
          actions: const [CloseButton2()],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            EquipmentsView(
              characterData: widget.characterData,
              onItemTapped: _onItemTapped,
            ),
            SizedBox(
              height: 290.0,
              child: DefaultTabController(
                length: _tabs.length, // 物品栏通过tabs过滤不同种类的物品
                child: Column(
                  children: [
                    TabBar(
                      // controller: _tabController,
                      tabs: _tabs,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: TabBarView(
                          // controller: _tabController,
                          children: [
                            InventoryView(
                              inventoryData: widget.characterData['inventory'],
                              type: widget.type == BuildViewType.npc
                                  ? InventoryType.npc
                                  : InventoryType.player,
                              onEquipChanged: () => setState(() {}),
                            ),
                            InventoryView(
                              inventoryData: widget.characterData['skills'],
                              type: widget.type == BuildViewType.npc
                                  ? InventoryType.npc
                                  : InventoryType.player,
                              style: GridStyle.card,
                              onEquipChanged: () => setState(() {}),
                            ),
                            InventoryView(
                              inventoryData: widget.characterData['companions'],
                              type: widget.type == BuildViewType.npc
                                  ? InventoryType.npc
                                  : InventoryType.player,
                              style: GridStyle.card,
                              onEquipChanged: () => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
