import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:provider/provider.dart';
// import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import '../character/inventory/equipment_bar.dart';
import '../../game/data.dart';
import '../ui/close_button2.dart';
import '../../state/view_panels.dart';
import '../character/inventory/inventory.dart';
import '../character/inventory/material.dart';
// import '../character/inventory/item_grid.dart';
// import '../ui/bordered_icon_button.dart';
import '../common.dart';

class WorkbenchDialog extends StatefulWidget {
  const WorkbenchDialog({
    super.key,
  });

  @override
  State<WorkbenchDialog> createState() => _WorkbenchDialogState();
}

class _WorkbenchDialogState extends State<WorkbenchDialog> {
  final Set<String> _selectedWorkTargetId = {};
  final Set<String> _selectedItemId = {};
  dynamic _selectedWorkTargetItemData;
  String? selectedMaterialId;

  static final List<Tab> _tabs = [
    Tab(text: engine.locale('craft_item')),
    Tab(text: engine.locale('modify_item')),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: 600.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('workshop')),
          actions: [
            CloseButton2(
              onPressed: () {
                engine.context
                    .read<ViewPanelState>()
                    .toogle(ViewPanels.workbench);
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
                child: DefaultTabController(
                  length: _tabs.length,
                  child: Column(
                    children: [
                      PreferredSize(
                        preferredSize:
                            const Size.fromHeight(kToolbarTabBarHeight),
                        child: TabBar(
                          tabs: _tabs,
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            SizedBox.shrink(),
                            SizedBox.shrink(),
                          ],
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
                    selectedItemId: _selectedWorkTargetId,
                    onItemTapped: (itemData, screenPosition) {
                      if (_selectedWorkTargetId.contains(itemData['id'])) {
                        _selectedWorkTargetId.remove(itemData['id']);
                      } else {
                        _selectedWorkTargetId.clear();
                        _selectedWorkTargetId.add(itemData['id']);
                      }
                      setState(() {});
                    },
                    onItemMouseEnter: (itemData, rect) {},
                    onItemMouseExit: () {},
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Inventory(
                      character: GameData.hero,
                      type: ItemType.none,
                      height: 260.0,
                      gridsPerLine: 6,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: MaterialStorage(
                      entity: GameData.hero,
                      height: 98.0,
                      width: 308.0,
                      filter: [
                        'leather',
                        'timber',
                        'ore',
                      ],
                      selectedItem: selectedMaterialId,
                      onSelectedItem: (id) {
                        if (selectedMaterialId == id) {
                          selectedMaterialId = null;
                        } else {
                          selectedMaterialId = id;
                        }
                        setState(() {});
                      },
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
