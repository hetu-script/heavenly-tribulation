import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/extensions.dart';
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
  int tabIndex = 0;

  String selectedCraftKind = kItemEquipmentKinds.first;
  final Set<String> availableCraftRarities = {};

  String selectedCraftRarity = kRarities.first;
  dynamic selectedCraftItemRequirements;
  int extraAffixCount = 0;
  final List<dynamic> selectedAffixesForCraft =
      List.generate(6, (index) => null);

  dynamic craftedEquipment;
  dynamic extractedAffix;

  dynamic selectedEquipment;
  bool get isExtracting => selectedEquipment != null;

  List selectedEquipmentAffixes = [];
  dynamic selectedAffix;

  List selectedItemIds = [];

  @override
  void initState() {
    super.initState();

    updateSelectedCraftItemRequirements();

    if (widget.locationData != null) {
      craftedEquipment = widget.locationData['craftedEquipment'];
      extractedAffix = widget.locationData['extractedAffix'];
    }

    if (widget.locationData == null && widget.development == null) {
      availableCraftRarities.addAll(kRarities);
    } else {
      for (final rarity in kRarities) {
        final rank = kRaritiesToRank[rarity] as int;
        if (widget.locationData != null) {
          if (widget.locationData['development'] >= rank) {
            availableCraftRarities.add(rarity);
          }
        } else if (widget.development != null) {
          if (widget.development! >= rank) {
            availableCraftRarities.add(rarity);
          }
        }
      }
    }
  }

  void updateSelectedCraftItemRequirements() {
    selectedCraftItemRequirements =
        utils.deepCopy(GameData.craftables[selectedCraftKind]);
    final rank = kRaritiesToRank[selectedCraftRarity] as int;
    for (final materialId in kMaterialKinds) {
      if (selectedCraftItemRequirements[materialId] != null) {
        final baseValue = selectedCraftItemRequirements[materialId];
        selectedCraftItemRequirements[materialId] =
            baseValue * (rank * rank + 1);
      }
    }
    final extraAffixConfig = GameLogic.getMinMaxExtraAffixCount(rank);
    extraAffixCount = extraAffixConfig['maxExtra'] as int;
    selectedAffixesForCraft.fillRange(0, kMaxAffixCount, null);
  }

  void onInventoryItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    assert(itemData['type'] == 'equipment');
    if (tabIndex == 0) {
      if (itemData['category'] == kItemCategoryExtractedAffix) {
        bool isUnselected = true;
        for (var i = 0; i < extraAffixCount; ++i) {
          if (selectedAffixesForCraft[i] == itemData['affixes'][0]) {
            selectedAffixesForCraft[i] = null;
            isUnselected = false;
            updateInfo();
            setState(() {});
            break;
          }
        }
        if (isUnselected) {
          for (var i = 0; i < extraAffixCount; ++i) {
            if (selectedAffixesForCraft[i] == null) {
              engine.play('sword-sheathed-178549.mp3');
              selectedAffixesForCraft[i] = itemData['affixes'][0];
              updateInfo();
              setState(() {});
              break;
            }
          }
        }
      }
    } else if (tabIndex == 1) {
      if (itemData['category'] != kItemCategoryExtractedAffix) {
        engine.play('sword-sheathed-178549.mp3');
        selectedEquipment = itemData;
        selectedEquipmentAffixes = (itemData['affixes'] as List).sublist(1);
        updateInfo();
        setState(() {});
      }
    }
  }

  void close() {
    engine.context.read<ViewPanelState>().hide(ViewPanels.workbench);
  }

  void craftEquipment() {
    final result =
        GameLogic.heroExhaustMaterials(selectedCraftItemRequirements);

    if (!result) {
      dialog.pushDialog('hint_notEnoughMaterial');
      dialog.execute();
      return;
    }

    final selectedAffixes =
        selectedAffixesForCraft.where((affix) => affix != null);

    final affixes = [];
    for (final affixItem in selectedAffixes) {
      final affix = affixItem['affixes'][0];
      assert(affix != null);
      affixes.add(affix);
    }

    final equipment = engine.hetu.invoke('Equipment', namedArgs: {
      'kind': selectedCraftKind,
      'rank': kRaritiesToRank[selectedCraftRarity],
      'affixes': affixes,
    });

    engine.play(GameSound.anvil);

    craftedEquipment = equipment;
    if (widget.locationData != null) {
      widget.locationData['craftedEquipment'] = equipment;
    }

    selectedAffixesForCraft.fillRange(0, kMaxAffixCount, null);
    updateInfo();
    setState(() {});
  }

  void pickupCraftedEquipment() {
    if (craftedEquipment == null) return;

    engine.hetu.invoke('acquire',
        namespace: 'Player', positionalArgs: [craftedEquipment]);
    engine.play(GameSound.pickup);

    if (widget.locationData != null) {
      widget.locationData['craftedEquipment'] = null;
    }
    craftedEquipment = null;

    setState(() {});
  }

  void extractAffix() {
    final item = engine.hetu.invoke('ExtractedAffix', namedArgs: {
      'affix': selectedAffix,
      'rank': selectedEquipment['rank'],
    });
    engine.hetu.invoke('lose', namespace: 'Player', positionalArgs: [
      selectedEquipment,
    ]);
    engine.play(GameSound.anvil);

    extractedAffix = item;
    if (widget.locationData != null) {
      widget.locationData['extractedAffix'] = item;
    }

    selectedEquipment = null;
    selectedEquipmentAffixes.clear();
    selectedAffix = null;

    updateInfo();
    setState(() {});
  }

  void pickupExtractedAffix() {
    if (extractedAffix == null) return;

    engine.hetu.invoke('acquire',
        namespace: 'Player', positionalArgs: [extractedAffix]);
    engine.play(GameSound.pickup);

    if (widget.locationData != null) {
      widget.locationData['extractedAffix'] = null;
    }
    extractedAffix = null;

    setState(() {});
  }

  void updateInfo() {
    selectedItemIds.clear();
    if (selectedEquipment != null) {
      selectedItemIds.add(selectedEquipment['id']);
    }
    int affixCount = 0;
    for (final affix in selectedAffixesForCraft) {
      if (affix != null) {
        ++affixCount;
        selectedItemIds.add(affix['id']);
      }
    }

    int shardCost = GameLogic.calculateShardCostForCrafting(affixCount);

    if (shardCost > 0) {
      selectedCraftItemRequirements['shard'] = shardCost;
    } else {
      selectedCraftItemRequirements.remove('shard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 800.0,
      height: 500.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('workshop')),
          actions: [CloseButton2(onPressed: close)],
        ),
        body: Container(
          width: 800.0,
          height: 500.0,
          padding: const EdgeInsets.only(
              top: 10.0, bottom: 10.0, left: 20.0, right: 20.0),
          child: Row(
            children: [
              SizedBox(
                width: 400.0,
                child: fluent.TabView(
                  currentIndex: tabIndex,
                  onChanged: (index) => setState(() => tabIndex = index),
                  closeButtonVisibility: fluent.CloseButtonVisibilityMode.never,
                  tabs: [
                    fluent.Tab(
                      text: Text(
                        engine.locale('craft'),
                        style: TextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      body: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 360.0,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.only(
                                    top: 20.0, bottom: 20.0),
                                child: ItemGrid(
                                  itemData: craftedEquipment,
                                  onMouseEnter: (itemData, rect) {
                                    if (itemData == null) return;
                                    context.read<HoverContentState>().show(
                                          rect: rect,
                                          contentBuilder: (isDetailed) =>
                                              buildItemHoverInfo(
                                            itemData,
                                            inventoryType: InventoryType.none,
                                            isDetailed: isDetailed,
                                          ),
                                        );
                                  },
                                  onMouseExit: () {
                                    context.read<HoverContentState>().hide();
                                  },
                                  onSecondaryTapped: (_, __) {
                                    pickupCraftedEquipment();
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: SizedBox(
                                  width: 360.0,
                                  height: 50.0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      kMaxAffixCount,
                                      (index) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: ItemGrid(
                                          itemData:
                                              selectedAffixesForCraft[index],
                                          onMouseEnter: (itemData, rect) {
                                            context
                                                .read<HoverContentState>()
                                                .show(
                                                  rect: rect,
                                                  contentBuilder:
                                                      (isDetailed) =>
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
                                            if (selectedAffixesForCraft[
                                                    index] !=
                                                null) {
                                              engine.play(GameSound.put);
                                              selectedAffixesForCraft[index] =
                                                  null;
                                              updateInfo();
                                              setState(() {});
                                            }
                                          },
                                        ),
                                      ),
                                    ).sublist(0, extraAffixCount),
                                  ),
                                ),
                              ),
                              Container(
                                width: 360.0,
                                padding: const EdgeInsets.only(bottom: 5.0),
                                child: fluent.Button(
                                  onPressed: craftedEquipment == null
                                      ? craftEquipment
                                      : null,
                                  child: Text(engine.locale('craft')),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 5.0),
                                child: SizedBox(
                                  width: 360.0,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      SizedBox(
                                        width: 178.0,
                                        child: fluent.DropDownButton(
                                          cursor: GameUI.cursor,
                                          style: FluentButtonStyles.small,
                                          placement: fluent
                                              .FlyoutPlacementMode.rightTop,
                                          title: Text(
                                            '${engine.locale('kind')}: ${engine.locale(selectedCraftKind)}',
                                            textAlign: TextAlign.end,
                                          ),
                                          items: buildFluentMenuItems(
                                            items: {
                                              for (final key
                                                  in kItemEquipmentKinds)
                                                engine.locale(key): key,
                                            },
                                            onSelectedItem: (String value) {
                                              selectedCraftKind = value;
                                              updateSelectedCraftItemRequirements();
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 178.0,
                                        child: fluent.DropDownButton(
                                          cursor: GameUI.cursor,
                                          style: FluentButtonStyles.small,
                                          placement: fluent
                                              .FlyoutPlacementMode.rightTop,
                                          title: Text(
                                            '${engine.locale('rarity')}: ${engine.locale(selectedCraftRarity)}',
                                            textAlign: TextAlign.end,
                                          ),
                                          items: buildFluentMenuItems(
                                            items: {
                                              for (final key
                                                  in availableCraftRarities)
                                                engine.locale(key): key,
                                            },
                                            onSelectedItem: (String value) {
                                              selectedCraftRarity = value;
                                              updateSelectedCraftItemRequirements();
                                              setState(() {});
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              MaterialList(
                                height: 160.0,
                                width: 360.0,
                                requirements: selectedCraftItemRequirements,
                                entity: GameData.hero,
                              ),
                            ],
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
                      body: Column(
                        children: [
                          Container(
                            width: 360.0,
                            alignment: Alignment.center,
                            padding:
                                const EdgeInsets.only(top: 20.0, bottom: 10.0),
                            child: ItemGrid(
                              itemData: extractedAffix ?? selectedEquipment,
                              onMouseEnter: (itemData, rect) {
                                context.read<HoverContentState>().show(
                                      rect: rect,
                                      contentBuilder: (isDetailed) =>
                                          buildItemHoverInfo(
                                        itemData,
                                        inventoryType: InventoryType.none,
                                        isDetailed: isDetailed,
                                      ),
                                    );
                              },
                              onMouseExit: () {
                                context.read<HoverContentState>().hide();
                              },
                              onSecondaryTapped: (_, __) {
                                if (extractedAffix != null) {
                                  pickupExtractedAffix();
                                } else {
                                  engine.play(GameSound.put);
                                  selectedEquipment = null;
                                  selectedEquipmentAffixes = [];
                                  updateInfo();
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                          Text(
                            engine.locale(extractedAffix != null
                                ? 'pickup_hint'
                                : isExtracting
                                    ? 'extract_hint'
                                    : 'workshop_hint'),
                            textAlign: TextAlign.center,
                          ),
                          Container(
                            width: 360.0,
                            padding:
                                const EdgeInsets.only(top: 10.0, bottom: 5.0),
                            child: fluent.Button(
                              onPressed: extractedAffix == null &&
                                      selectedAffix != null
                                  ? extractAffix
                                  : null,
                              child: Text(
                                engine.locale('extract'),
                              ),
                            ),
                          ),
                          selectedEquipmentAffixes.isEmpty
                              ? Container(
                                  height: 200.0,
                                  alignment: Alignment.center,
                                  child: EmptyPlaceholder(
                                    engine.locale('noExtractableAffixes'),
                                  ),
                                )
                              : Column(
                                  children:
                                      selectedEquipmentAffixes.map((affixData) {
                                    return BorderedIconButton(
                                      size: const Size(400.0, 30.0),
                                      isSelected: selectedAffix == affixData,
                                      onPressed: () {
                                        selectedAffix = affixData;
                                        setState(() {});
                                      },
                                      child: Text(
                                        engine.locale(affixData['description'],
                                            interpolations: [
                                              affixData['value'],
                                            ]),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Inventory(
                  character: GameData.hero,
                  selectedItemIds: selectedItemIds,
                  inventoryType: InventoryType.none,
                  itemTypes: null,
                  filter: {'type': 'equipment'},
                  gridsPerLine: 6,
                  height: 416.0,
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
