import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/extensions.dart';
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

class AlchemyDialog extends StatefulWidget {
  const AlchemyDialog({
    super.key,
    required this.locationData,
    this.development,
  });

  final dynamic locationData;
  final int? development;

  @override
  State<AlchemyDialog> createState() => _AlchemyDialogState();
}

class _AlchemyDialogState extends State<AlchemyDialog> {
  String selectedCraftKind = 'heal';
  final Set<String> _availableCraftRarities = {};

  int selectedCraftRank = 0;
  dynamic selectedCraftItemRequirements;
  dynamic craftedPotion;

  final potionKindItems = <String, dynamic>{};

  @override
  void initState() {
    super.initState();

    if (widget.locationData != null) {
      craftedPotion = widget.locationData['craftedPotion'];
    }

    if (widget.locationData == null && widget.development == null) {
      _availableCraftRarities.addAll(kRarities);
    } else {
      for (final rarity in kRarities) {
        final rank = kRaritiesToRank[rarity] as int;
        if (widget.locationData != null) {
          if (widget.locationData['development'] >= rank) {
            _availableCraftRarities.add(rarity);
          }
        } else if (widget.development != null) {
          if (widget.development! >= rank) {
            _availableCraftRarities.add(rarity);
          }
        }
      }
    }

    updateSelectedCraftItemRequirements();
    updatePotionKinds();
  }

  void updateSelectedCraftItemRequirements() {
    selectedCraftItemRequirements =
        utils.deepCopy(GameData.craftables['potion']);
    for (final materialId in kMaterialKinds) {
      if (selectedCraftItemRequirements[materialId] != null) {
        final baseValue = selectedCraftItemRequirements[materialId];
        selectedCraftItemRequirements[materialId] =
            baseValue * (selectedCraftRank * selectedCraftRank + 1);
      }
    }
  }

  void close() {
    engine.context.read<ViewPanelState>().hide(ViewPanels.alchemy);
  }

  void updatePotionKinds() {
    potionKindItems.clear();
    for (final key in kPotionKinds.keys) {
      final rank = kRaritiesToRank[key] as int;
      if (rank > selectedCraftRank) continue;

      final kinds = kPotionKinds[key] as Iterable;
      final items = <String, String>{};
      for (final kind in kinds) {
        items[engine.locale(kind)] = kind;
      }
      potionKindItems[engine.locale(key)] = items;
    }
  }

  void craftPotion() {
    final result =
        GameLogic.heroExhaustMaterials(selectedCraftItemRequirements);

    if (!result) {
      dialog.pushDialog('hint_notEnoughMaterial');
      dialog.execute();
      return;
    }

    final potion = engine.hetu.invoke('Potion', namedArgs: {
      'kind': selectedCraftKind,
      'rank': selectedCraftRank,
    });

    engine.play(GameSound.anvil);

    craftedPotion = potion;
    if (widget.locationData != null) {
      widget.locationData['craftedPotion'] = potion;
    }

    setState(() {});
  }

  void pickupCraftedPotion() {
    if (craftedPotion == null) return;

    engine.hetu.invoke('acquire',
        namespace: 'Player', positionalArgs: [craftedPotion]);
    engine.play(GameSound.pickup);

    if (widget.locationData != null) {
      widget.locationData['craftedPotion'] = null;
    }
    craftedPotion = null;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 800.0,
      height: 420.0,
      onBarrierDismissed: close,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('workshop')),
          actions: [CloseButton2(onPressed: close)],
        ),
        body: Container(
          width: 800.0,
          height: 420.0,
          padding: const EdgeInsets.only(
              top: 10.0, bottom: 10.0, left: 20.0, right: 20.0),
          child: Row(
            children: [
              Container(
                width: 400.0,
                padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                child: Column(
                  children: [
                    Container(
                      width: 360.0,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                      child: ItemGrid(
                        itemData: craftedPotion,
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
                          pickupCraftedPotion();
                        },
                      ),
                    ),
                    Container(
                      width: 360.0,
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: fluent.Button(
                        onPressed: craftedPotion == null ? craftPotion : null,
                        child: Text(engine.locale('craft')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: SizedBox(
                        width: 360.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 178.0,
                              child: fluent.DropDownButton(
                                cursor: GameUI.cursor,
                                style: FluentButtonStyles.small,
                                title: Text(
                                  '${engine.locale('kind')}: ${engine.locale('potion_$selectedCraftKind')}',
                                  textAlign: TextAlign.end,
                                ),
                                items: buildFluentMenuItems(
                                  items: potionKindItems,
                                  onSelectedItem: (String value) {
                                    selectedCraftKind =
                                        value.replaceAll('potion_', '');
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
                                title: Text(
                                  '${engine.locale('rarity')}: ${engine.locale(kRankToRarity[selectedCraftRank])}',
                                  textAlign: TextAlign.end,
                                ),
                                items: buildFluentMenuItems(
                                  items: {
                                    for (final key in _availableCraftRarities)
                                      engine.locale(key): key,
                                  },
                                  onSelectedItem: (String value) {
                                    selectedCraftRank =
                                        kRaritiesToRank[value] as int;
                                    updateSelectedCraftItemRequirements();
                                    updatePotionKinds();
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
                      height: 150.0,
                      width: 360.0,
                      requirements: selectedCraftItemRequirements,
                      entity: GameData.hero,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Inventory(
                  character: GameData.hero,
                  inventoryType: InventoryType.none,
                  itemTypes: null,
                  filter: {'category': 'potion'},
                  gridsPerLine: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
