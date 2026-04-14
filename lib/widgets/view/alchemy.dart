import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:hetu_script/utils/collection.dart' as utils;
import 'package:samsara/widgets/ui/menu_builder.dart';

import '../../global.dart';
import '../../ui.dart';
import '../../data/game.dart';
import '../../logic/logic.dart';
import '../../state/view_panels.dart';
import '../../data/common.dart';
import '../ui/close_button2.dart';
import '../character/inventory/inventory.dart';
import '../character/inventory/material.dart';
import '../ui/responsive_view.dart';

class AlchemyDialog extends StatefulWidget {
  const AlchemyDialog({
    super.key,
    this.locationData,
    this.development,
  });

  final dynamic locationData;
  final int? development;

  @override
  State<AlchemyDialog> createState() => _AlchemyDialogState();
}

class _AlchemyDialogState extends State<AlchemyDialog> {
  String _selectedCraftKind = 'heal';
  final Set<String> _availableCraftRarities = {};

  String _selectedCraftRarity = kRarities.first;
  dynamic _selectedCraftItemRequirements;

  @override
  void initState() {
    super.initState();

    _updateSelectedCraftItemRequirements();

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
  }

  void _updateSelectedCraftItemRequirements() {
    _selectedCraftItemRequirements =
        utils.deepCopy(GameData.craftables['potion']);
    final rank = kRaritiesToRank[_selectedCraftRarity] as int;
    for (final materialId in kMaterialKinds) {
      if (_selectedCraftItemRequirements[materialId] != null) {
        final baseValue = _selectedCraftItemRequirements[materialId];
        _selectedCraftItemRequirements[materialId] =
            baseValue * (rank * rank + 1);
      }
    }
  }

  void close() {
    engine.context.read<ViewPanelState>().toogle(ViewPanels.alchemy);
  }

  void craftPotion() {
    final result =
        GameLogic.heroExhaustMaterials(_selectedCraftItemRequirements);

    if (!result) return;

    final potion = engine.hetu.invoke('Potion', namedArgs: {
      'kind': _selectedCraftKind,
      'rank': kRaritiesToRank[_selectedCraftRarity],
    });

    engine.play(GameSound.anvil);

    engine.hetu
        .invoke('acquire', namespace: 'Player', positionalArgs: [potion]);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final potionKindItems = <String, dynamic>{};

    for (final key in kPotionKinds.keys) {
      if (!_availableCraftRarities.contains(key)) continue;

      final kinds = kPotionKinds[key] as Iterable;
      final items = <String, String>{};
      for (final kind in kinds) {
        items[engine.locale(kind)] = kind;
      }
      potionKindItems[engine.locale(key)] = items;
    }

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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0, bottom: 5.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                  items: potionKindItems,
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
                                    for (final key in _availableCraftRarities)
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
                      const Spacer(),
                      fluent.Button(
                        onPressed: craftPotion,
                        child: Text(engine.locale('craft')),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Inventory(
                  character: GameData.hero,
                  inventoryType: InventoryType.none,
                  itemTypes: null,
                  filter: {'type': 'potion'},
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
