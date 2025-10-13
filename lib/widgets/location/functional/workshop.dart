import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:hetu_script/utils/collection.dart';
import 'package:samsara/ui/empty_placeholder.dart';

import '../../../engine.dart';
import '../../../game/ui.dart';
import '../../../game/game.dart';
import '../../../game/logic/logic.dart';
import '../../../state/view_panels.dart';
import '../../../state/hover_content.dart';
import '../../../game/common.dart';
import '../../ui/close_button2.dart';
import '../../ui/menu_builder.dart';
import '../../character/inventory/equipment_bar.dart';
import '../../character/inventory/inventory.dart';
import '../../character/inventory/material.dart';
import '../../character/inventory/item_grid.dart';
import '../../ui/bordered_icon_button.dart';
import '../../../scene/game_dialog/game_dialog_content.dart';

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

  String _selectedModifyKind = kItemModificationOperations.first;
  dynamic _selectedModifyItem;
  List? _selectedModifyItemAffixes;
  dynamic _selectedAffix;

  void setSelectedModifyItem(dynamic itemData) {
    _selectedModifyItem = itemData;
    if (itemData != null) {
      final List affixes = itemData['affixes'];
      assert(affixes.isNotEmpty);
      _selectedModifyItemAffixes = affixes.sublist(1);
    } else {
      _selectedModifyItemAffixes = null;
    }
    _selectedAffix = null;
  }

  @override
  void initState() {
    super.initState();

    _affixWidgets = List.generate(
      kMaxAffixCount,
      (index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: ItemGrid(
          onMouseEnter: (itemData, rect) {
            context.read<HoverContentState>().show(itemData, rect);
          },
          onMouseExit: () {
            context.read<HoverContentState>().hide();
          },
          onSecondaryTapped: onExtraCraftMaterialSecondaryTapped,
        ),
      ),
    );

    _updateSelectedCraftItemRequirements();
  }

  void _updateSelectedCraftItemRequirements() {
    _selectedCraftItemRequirements =
        deepCopy(GameData.craftables[_selectedCraftKind]);
    final rank = kRaritiesToRank[_selectedCraftRarity] as int;
    for (final materialId in kMaterialKinds) {
      if (_selectedCraftItemRequirements[materialId] != null) {
        final baseValue = _selectedCraftItemRequirements[materialId];
        _selectedCraftItemRequirements[materialId] =
            baseValue * (rank + 1) * (rank + 1);
      }
    }
    final extraAffixConfig = GameLogic.getMinMaxExtraAffixCount(rank);
    _extraAffixCount = extraAffixConfig['maxExtra'] as int;
  }

  void onExtraCraftMaterialSecondaryTapped(
      dynamic itemData, Offset screenPosition) {
    if (itemData == null) return;
    showFluentMenu(
      position: screenPosition,
      items: {
        engine.locale('unselect'): 'unselect',
      },
      onSelectedItem: (item) async {
        if (item == 'unselect') {
          engine.play('put_item-83043.mp3');
          setSelectedModifyItem(null);
          setState(() {});
        }
      },
    );
  }

  void onInventoryItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    final category = itemData['category'];
    if (_tabIndex == 0) {
    } else if (_tabIndex == 1) {
      if (kItemEquipmentCategories.contains(category)) {
        showFluentMenu(
          position: screenPosition,
          items: {
            if (_selectedModifyItem == itemData)
              engine.locale('unselect'): 'unselect'
            else
              engine.locale('select'): 'select',
          },
          onSelectedItem: (item) async {
            final isIdentified = itemData['isIdentified'] == true;
            if (!isIdentified) {
              GameDialogContent.show(
                  context, engine.locale('hint_unidentifiedItem'));
              return;
            }
            if (item == 'select') {
              setSelectedModifyItem(itemData);
              engine.play('sword-sheathed-178549.mp3');
            } else if (item == 'unselect') {
              engine.play('put_item-83043.mp3');
              setSelectedModifyItem(null);
            }
            setState(() {});
          },
        );
      } else {}
    }
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
                context.read<ViewPanelState>().toogle(ViewPanels.workbench);
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
                        text: Text(engine.locale('craft_item')),
                        body: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  SizedBox(
                                    width: 125.0,
                                    height: 30.0,
                                    child: fluent.DropDownButton(
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
                                    width: 125.0,
                                    height: 30.0,
                                    child: fluent.DropDownButton(
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
                                    engine.locale('material_requirements')),
                              ),
                              MaterialList(
                                height: 128.0,
                                requirements: _selectedCraftItemRequirements,
                                entity: GameData.hero,
                              ),
                              if (_extraAffixCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Text(engine.locale('extra_material')),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _affixWidgets.sublist(
                                      0, _extraAffixCount),
                                ),
                              ),
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
                        text: Text(engine.locale('modify_item')),
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
                                      itemData: _selectedModifyItem,
                                      onMouseEnter: (itemData, rect) {
                                        if (itemData == null) return;
                                        context
                                            .read<HoverContentState>()
                                            .show(itemData, rect);
                                      },
                                      onMouseExit: () {
                                        context
                                            .read<HoverContentState>()
                                            .hide();
                                      },
                                      onSecondaryTapped:
                                          onExtraCraftMaterialSecondaryTapped,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 125.0,
                                height: 30.0,
                                child: fluent.DropDownButton(
                                  title: Text(
                                    engine.locale(
                                        'modify_item_$_selectedModifyKind'),
                                    textAlign: TextAlign.end,
                                  ),
                                  items: buildFluentMenuItems(
                                    items: {
                                      for (final key
                                          in kItemModificationOperations)
                                        engine.locale('modify_item_$key'): key,
                                    },
                                    onSelectedItem: (String value) {
                                      _selectedModifyKind = value;
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ),
                              Container(
                                width: 400.0,
                                height: 65.0,
                                padding: const EdgeInsets.only(
                                    top: 10.0, bottom: 10.0),
                                child: Text(
                                  engine.locale(
                                      'modify_item_${_selectedModifyKind}_description'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (_selectedModifyKind == 'upgrade' &&
                                  _selectedModifyItem != null)
                                Text(
                                    '${engine.locale('level2')}: ${_selectedModifyItem['level']}'),
                              if (_selectedModifyKind == 'extract' &&
                                  _selectedModifyItemAffixes != null)
                                _selectedModifyItemAffixes!.isEmpty
                                    ? EmptyPlaceholder(
                                        engine.locale('noUsableItems'))
                                    : Column(
                                        children: _selectedModifyItemAffixes!
                                            .map((affixData) {
                                        return BorderedIconButton(
                                          size: const Size(400.0, 30.0),
                                          isSelected:
                                              _selectedAffix == affixData,
                                          onPressed: () {
                                            _selectedAffix = affixData;
                                            setState(() {});
                                          },
                                          child: Text(
                                            engine.locale(
                                                affixData['description'],
                                                interpolations: [
                                                  affixData['value'],
                                                ]),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: _selectedAffix == affixData
                                                  ? GameUI.selectedColorOpaque
                                                  : GameUI.foregroundColor,
                                            ),
                                          ),
                                        );
                                      }).toList()),
                              const Spacer(),
                              fluent.FilledButton(
                                onPressed: () {},
                                child: Text(engine.locale('execute')),
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
                      selectedItemId: _selectedModifyItem != null
                          ? [_selectedModifyItem['id']]
                          : [],
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
