import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:hetu_script/utils/collection.dart' as utils;
import 'package:samsara/widgets/ui/menu_builder.dart';
import 'package:samsara/hover_info.dart';
import 'package:samsara/widgets/ui/empty_placeholder.dart';

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
import '../ui/bordered_icon_button.dart';

class WorkshopDialog extends StatefulWidget {
  const WorkshopDialog({
    super.key,
    this.locationData,
    this.development,
  });

  final dynamic locationData;
  final int? development;

  @override
  State<WorkshopDialog> createState() => _WorkshopDialogState();
}

class _WorkshopDialogState extends State<WorkshopDialog> {
  int _tabIndex = 0;

  String _selectedCraftKind = kItemEquipmentKinds.first;
  Set<String> get _availableCraftRarities {
    if (widget.locationData == null && widget.development == null) {
      return kRarities;
    }

    final rarities = <String>{};
    for (final rarity in kRarities) {
      final rank = kRaritiesToRank[rarity] as int;
      if (widget.locationData != null) {
        if (widget.locationData['development'] >= rank) {
          rarities.add(rarity);
        }
      } else if (widget.development != null) {
        if (widget.development! >= rank) {
          rarities.add(rarity);
        }
      }
    }
    return rarities;
  }

  String _selectedCraftRarity = kRarities.first;
  dynamic _selectedCraftItemRequirements;
  int _extraAffixCount = 0;
  final List<dynamic> _selectedAffixesForCraft =
      List.generate(6, (index) => null);

  dynamic _selectedEquipment;
  bool get isExtracting => _selectedEquipment != null;

  List _selectedEquipmentAffixes = [];
  dynamic _selectedAffix;

  List selectedItemIds = [];

  @override
  void initState() {
    super.initState();

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
    _selectedAffixesForCraft.fillRange(0, kMaxAffixCount, null);
  }

  void onInventoryItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    assert(itemData['type'] == 'equipment');
    if (_tabIndex == 0) {
      if (itemData['category'] == kItemCategoryExtractedAffix) {
        bool isUnselected = true;
        for (var i = 0; i < _extraAffixCount; ++i) {
          if (_selectedAffixesForCraft[i] == itemData['affixes'][0]) {
            _selectedAffixesForCraft[i] = null;
            isUnselected = false;
            updateInfo();
            setState(() {});
            break;
          }
        }
        if (isUnselected) {
          for (var i = 0; i < _extraAffixCount; ++i) {
            if (_selectedAffixesForCraft[i] == null) {
              engine.play('sword-sheathed-178549.mp3');
              _selectedAffixesForCraft[i] = itemData['affixes'][0];
              updateInfo();
              setState(() {});
              break;
            }
          }
        }
      }
    } else if (_tabIndex == 1) {
      if (itemData['category'] != kItemCategoryExtractedAffix) {
        engine.play('sword-sheathed-178549.mp3');
        _selectedEquipment = itemData;
        _selectedEquipmentAffixes = (itemData['affixes'] as List).sublist(1);
        updateInfo();
        setState(() {});
      }
    }
  }

  void close() {
    engine.context.read<ViewPanelState>().toogle(ViewPanels.workbench);
  }

  void craftEquipment() {
    final result =
        GameLogic.heroExhaustMaterials(_selectedCraftItemRequirements);

    if (!result) return;

    final selectedAffixes =
        _selectedAffixesForCraft.where((affix) => affix != null);

    final affixes = [];
    for (final affixItem in selectedAffixes) {
      final affix = affixItem['affixes'][0];
      assert(affix != null);
      affixes.add(affix);
    }

    final equipment = engine.hetu.invoke('Equipment', namedArgs: {
      'kind': _selectedCraftKind,
      'rank': kRaritiesToRank[_selectedCraftRarity],
      'affixes': affixes,
    });

    engine.play(GameSound.anvil);

    engine.hetu
        .invoke('acquire', namespace: 'Player', positionalArgs: [equipment]);

    setState(() {});
  }

  void extractAffix() {
    final extractedAffix = engine.hetu.invoke('ExtractedAffix', namedArgs: {
      'affix': _selectedAffix,
      'rank': _selectedEquipment['rank'],
    });
    engine.hetu.invoke('lose', namespace: 'Player', positionalArgs: [
      _selectedEquipment,
    ]);
    engine.hetu.invoke('acquire', namespace: 'Player', positionalArgs: [
      extractedAffix,
    ]);
    engine.play(GameSound.anvil);

    _selectedEquipment = null;
    _selectedEquipmentAffixes.clear();
    _selectedAffix = null;

    updateInfo();
    setState(() {});
  }

  void updateInfo() {
    selectedItemIds.clear();
    if (_selectedEquipment != null) {
      selectedItemIds.add(_selectedEquipment['id']);
    }
    int affixCount = 0;
    for (final affix in _selectedAffixesForCraft) {
      if (affix != null) {
        ++affixCount;
        selectedItemIds.add(affix['id']);
      }
    }

    int shardCost = GameLogic.calculateShardCostForCrafting(affixCount);

    if (shardCost > 0) {
      _selectedCraftItemRequirements['shard'] = shardCost;
    } else {
      _selectedCraftItemRequirements.remove('shard');
    }
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
                          engine.locale('craft'),
                          style: TextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        body: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 5.0, bottom: 5.0),
                              child: Row(
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
                                          for (final key
                                              in _availableCraftRarities)
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
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Text(
                                  '${engine.locale('days_needed')} ${_selectedCraftItemRequirements['day']}'),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: MaterialList(
                                height: 150.0,
                                requirements: _selectedCraftItemRequirements,
                                entity: GameData.hero,
                              ),
                            ),
                            if (_extraAffixCount > 0) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0),
                                child: Text(engine.locale('extra_affixes')),
                              ),
                            ],
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  kMaxAffixCount,
                                  (index) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.5),
                                    child: ItemGrid(
                                      itemData: _selectedAffixesForCraft[index],
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
                                        if (_selectedAffixesForCraft[index] !=
                                            null) {
                                          engine.play(GameSound.put);
                                          _selectedAffixesForCraft[index] =
                                              null;
                                          updateInfo();
                                          setState(() {});
                                        }
                                      },
                                    ),
                                  ),
                                ).sublist(0, _extraAffixCount),
                              ),
                            ),
                            const Spacer(),
                            fluent.Button(
                              onPressed: craftEquipment,
                              child: Text(engine.locale('craft')),
                            ),
                          ],
                        ),
                      ),
                      fluent.Tab(
                        text: Text(
                          engine.locale('extract'),
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
                                        engine.play(GameSound.put);
                                        _selectedEquipment = null;
                                        _selectedEquipmentAffixes = [];
                                        updateInfo();
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
                                  engine.locale(isExtracting
                                      ? 'extract_hint'
                                      : 'workshop_hint'),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _selectedEquipmentAffixes.isEmpty
                                  ? EmptyPlaceholder(
                                      engine.locale('noExtractableAffixes'))
                                  : Column(
                                      children: _selectedEquipmentAffixes
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
                                          ),
                                        );
                                      }).toList(),
                                    ),
                              const Spacer(),
                              fluent.Button(
                                onPressed: _selectedAffix != null
                                    ? extractAffix
                                    : null,
                                child: Text(engine.locale('extract')),
                              )
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
                  selectedItemIds: selectedItemIds,
                  inventoryType: InventoryType.none,
                  itemTypes: null,
                  filter: {'type': 'equipment'},
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
