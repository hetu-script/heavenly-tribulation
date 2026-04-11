import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:hetu_script/utils/collection.dart' as utils;
import 'package:samsara/widgets/ui/menu_builder.dart';
import 'package:samsara/hover_info.dart';

import '../../global.dart';
import '../../ui.dart';
import '../../data/game.dart';
import '../../logic/logic.dart';
import '../../state/view_panels.dart';
import '../../data/common.dart';
import '../ui/close_button2.dart';
import '../character/inventory/inventory.dart';
import '../character/inventory/material.dart';
import '../character/inventory/item_grid.dart';
import '../ui/responsive_view.dart';
import '../common.dart';

class WorkbenchDialog extends StatefulWidget {
  const WorkbenchDialog({
    super.key,
  });

  @override
  State<WorkbenchDialog> createState() => _WorkbenchDialogState();
}

class _WorkbenchDialogState extends State<WorkbenchDialog> {
  int _tabIndex = 0;

  String _selectedCraftKind = kItemEquipmentKinds.first;
  String _selectedCraftRarity = kRarities.first;
  dynamic _selectedCraftItemRequirements;
  int _extraAffixCount = 0;
  late final List<Widget> _affixWidgets;
  dynamic _selectedEquipment;
  bool _isCrafting = false;
  Map<String, dynamic> _filter = {'type': 'equipment'};

  @override
  void initState() {
    super.initState();

    _affixWidgets = List.generate(
      kMaxAffixCount,
      (index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: ItemGrid(
          onMouseEnter: (itemData, rect) {
            context.read<HoverContentState>().show(
                  rect: rect,
                  contentBuilder: (isDetailed) => buildItemHoverInfo(
                    itemData,
                    inventoryType: InventoryType.none,
                    isDetailed: isDetailed,
                  ),
                );
          },
          onMouseExit: () {
            context.read<HoverContentState>().hide();
          },
          onSecondaryTapped: (_, __) {},
        ),
      ),
    );

    _updateSelectedCraftItemRequirements();
  }

  void _updateSelectedCraftItemRequirements() {
    _selectedCraftItemRequirements =
        utils.deepCopy(GameData.craftables[_selectedCraftKind]);
    final rank = kRaritiesToRank[_selectedCraftRarity] as int;
    for (final materialId in kMaterialKinds) {
      if (_selectedCraftItemRequirements[materialId] != null) {
        final baseValue = _selectedCraftItemRequirements[materialId];
        _selectedCraftItemRequirements[materialId] =
            baseValue * (rank * rank + 1);
      }
    }
    final extraAffixConfig = GameLogic.getMinMaxExtraAffixCount(rank);
    _extraAffixCount = extraAffixConfig['maxExtra'] as int;
  }

  void onInventoryItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    if (_tabIndex == 1) {
      if (_isCrafting) {
        assert(itemData['category'] == 'affix_crafting_material');
      } else {
        assert(itemData['type'] == 'equipment');
        _isCrafting = true;
        _filter = {'category': 'affix_crafting_material'};
        engine.play('sword-sheathed-178549.mp3');
        _selectedEquipment = itemData;
        setState(() {});
      }
    }
  }

  void close() {
    engine.context.read<ViewPanelState>().toogle(ViewPanels.workbench);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 800.0,
      height: 550.0,
      onBarrierDismissed: close,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('workshop')),
          actions: [CloseButton2(onPressed: close)],
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
                        text: Text(
                          engine.locale('craft_item'),
                          style: TextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        body: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    width: 140.0,
                                    child: fluent.DropDownButton(
                                      cursor: GameUI.cursor,
                                      style: FluentButtonStyles.small,
                                      title: Text(
                                        '${engine.locale('kind')}: ${engine.locale(_selectedCraftKind)}',
                                        textAlign: TextAlign.end,
                                      ),
                                      items: buildFluentMenuItems(
                                        items: {
                                          for (final key in kItemEquipmentKinds)
                                            engine.locale(key): key,
                                        },
                                        onSelectedItem: (String value) {
                                          _selectedCraftKind = value;
                                          _updateSelectedCraftItemRequirements();
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 140.0,
                                    child: fluent.DropDownButton(
                                      cursor: GameUI.cursor,
                                      style: FluentButtonStyles.small,
                                      title: Text(
                                        '${engine.locale('rarity')}: ${engine.locale(_selectedCraftRarity)}',
                                        textAlign: TextAlign.end,
                                      ),
                                      items: buildFluentMenuItems(
                                        items: {
                                          for (final key in kRarities)
                                            engine.locale(key): key,
                                        },
                                        onSelectedItem: (String value) {
                                          _selectedCraftRarity = value;
                                          _updateSelectedCraftItemRequirements();
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 10.0, bottom: 10.0),
                                child: Text(
                                    '${engine.locale('days_needed')} ${_selectedCraftItemRequirements['day']}'),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(engine.locale('base_material')),
                              ),
                              MaterialList(
                                height: 150.0,
                                requirements: _selectedCraftItemRequirements,
                                entity: GameData.hero,
                              ),
                              if (_extraAffixCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5.0),
                                  child: Text(engine.locale('extra_material')),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _affixWidgets.sublist(
                                      0, _extraAffixCount),
                                ),
                              ),
                              const Spacer(),
                              fluent.Button(
                                onPressed: () {},
                                child: Text(engine.locale('craft_item')),
                              ),
                            ],
                          ),
                        ),
                      ),
                      fluent.Tab(
                        text: Text(
                          engine.locale('modify_item'),
                          style: TextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        body: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 10.0, bottom: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ItemGrid(
                                      itemData: _selectedEquipment,
                                      onMouseEnter: (itemData, rect) {
                                        context.read<HoverContentState>().show(
                                              rect: rect,
                                              contentBuilder: (isDetailed) =>
                                                  buildItemHoverInfo(
                                                itemData,
                                                inventoryType:
                                                    InventoryType.none,
                                                isDetailed: isDetailed,
                                              ),
                                            );
                                      },
                                      onMouseExit: () {
                                        context
                                            .read<HoverContentState>()
                                            .hide();
                                      },
                                      onSecondaryTapped: (_, __) {
                                        _isCrafting = false;
                                        _filter = {'type': 'equipment'};
                                        engine.play(GameSound.put);
                                        _selectedEquipment = null;
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 400.0,
                                height: 65.0,
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  engine.locale('workshop_hint'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Inventory(
                  character: GameData.hero,
                  selectedItemId: _selectedEquipment != null
                      ? [_selectedEquipment['id']]
                      : [],
                  inventoryType: InventoryType.none,
                  itemTypes: null,
                  filter: _filter,
                  gridsPerLine: 6,
                  onItemSecondaryTapped: onInventoryItemSecondaryTapped,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
