import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import 'stats.dart';
import 'inventory/equipment_bar.dart';
import 'inventory/inventory.dart';
import '../ui/menu_builder.dart';
import '../dialog/confirm.dart';
// import '../../state/character.dart';
import '../../scene/game_dialog/game_dialog_content.dart';
import '../../game/logic.dart';
import '../../common.dart';
import '../../state/hover_content.dart';
import '../../game/event_ids.dart';
import '../../game/data.dart';
import '../../game/ui.dart';
import '../common.dart';

const Set<String> kMaterials = {
  'money',
  'shard',
  'worker',
  'herb',
  'timber',
  'stone',
  'ore',
};

enum ItemPopUpMenuItems {
  unequip,
  equip,
  use,
  charge,
  discard,
}

class CharacterDetails extends StatefulWidget {
  const CharacterDetails({
    super.key,
    this.characterId,
    this.characterData,
    this.mode = InformationViewMode.view,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;
  final dynamic characterData;
  final InformationViewMode mode;

  @override
  State<CharacterDetails> createState() => _CharacterDetailsState();
}

class _CharacterDetailsState extends State<CharacterDetails> {
  late final dynamic _characterData;

  @override
  void initState() {
    super.initState();

    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      _characterData = GameData.getCharacter(widget.characterId!);
    }
  }

  void onItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    showFluentMenu(
      position: screenPosition,
      items: {
        if (itemData['equippedPosition'] != null)
          engine.locale('unequip'): ItemPopUpMenuItems.unequip,
        if (itemData['isEquippable'] == true)
          engine.locale('equip'): ItemPopUpMenuItems.equip,
        if (itemData['isUsable'] == true)
          engine.locale('use'): ItemPopUpMenuItems.use,
        if (itemData['chargeData'] != null)
          engine.locale('charge'): ItemPopUpMenuItems.charge,
        '___': null,
        if (itemData['isUndroppable'] != true)
          engine.locale('discard'): ItemPopUpMenuItems.discard,
      },
      onSelectedItem: (item) async {
        final isIdentified = itemData['isIdentified'] == true;
        switch (item) {
          case ItemPopUpMenuItems.unequip:
            if (itemData['isCursed'] == true) {
              GameDialogContent.show(
                  context, engine.locale('hint_cursedEquipment'));
              return;
            }
            engine.play('put_item-83043.mp3');
            engine.hetu.invoke('unequip',
                namespace: 'Player', positionalArgs: [itemData]);
            engine.emit(GameEvents.heroPassivesUpdated);
            setState(() {});
          case ItemPopUpMenuItems.equip:
            if (!isIdentified) {
              GameDialogContent.show(
                  context, engine.locale('hint_unidentifiedItem'));
              return;
            }
            final category = itemData['category'];
            if (kRestrictedEquipmentTypes.contains(category)) {
              int equippedCount = engine.hetu.invoke('equippedCategory',
                  namespace: 'Player', positionalArgs: [category]);

              if (equippedCount > 0) {
                final hasUnrestrictedPassive = engine.hetu.invoke('hasPassive',
                    namespace: 'Player',
                    positionalArgs: ['${category}UnrestrictedEquip']);
                if (hasUnrestrictedPassive == null) {
                  GameDialogContent.show(
                      context,
                      engine.locale('hint_restrictedEquipment',
                          interpolations: [engine.locale(category)]));
                  return;
                }
              }
            }
            engine.play('sword-sheathed-178549.mp3');
            engine.hetu.invoke('equip',
                namespace: 'Player', positionalArgs: [itemData]);
            engine.emit(GameEvents.heroPassivesUpdated);
            setState(() {});
          case ItemPopUpMenuItems.use:
            if (!isIdentified) {
              GameDialogContent.show(
                  context, engine.locale('hint_unidentifiedItem'));
              return;
            }
            GameLogic.onUseItem(itemData);
            setState(() {});
          case ItemPopUpMenuItems.charge:
            if (!isIdentified) {
              GameDialogContent.show(
                  context, engine.locale('hint_unidentifiedItem'));
              return;
            }
            GameLogic.onChargeItem(itemData);
            setState(() {});
          case ItemPopUpMenuItems.discard:
            engine.play('break06-36414.mp3');
            final value = await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmDialog(
                  description: engine.locale('dangerOperationPrompt')),
            );
            if (value != true) return;
            engine.hetu.invoke('destroy', positionalArgs: [itemData]);
            setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, bottom: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EquipmentBar(
                type: ItemType.player,
                characterData: _characterData,
                onItemSecondaryTapped: onItemSecondaryTapped,
                isVertical: true,
              ),
              CharacterStats(
                characterData: _characterData,
                isHero: true,
                height: 312,
              ),
              Inventory(
                height: 312,
                characterData: _characterData,
                type: ItemType.player,
                minSlotCount: 60,
                gridsPerLine: 5,
                onSecondaryTapped: onItemSecondaryTapped,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, right: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Padding(
                //   padding: const EdgeInsets.only(right: 10.0),
                //   child: fluent.FilledButton(
                //     onPressed: () {},
                //     child: Text(engine.locale('identify')),
                //   ),
                // ),
                fluent.FilledButton(
                  onPressed: () {},
                  child: Text(engine.locale('orderBy')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterDetailsView extends StatelessWidget {
  const CharacterDetailsView({
    super.key,
    this.characterId,
    this.characterData,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;
  final dynamic characterData;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      alignment: AlignmentDirectional.center,
      backgroundColor: GameUI.backgroundColor2,
      width: GameUI.profileWindowSize.x,
      height: GameUI.profileWindowSize.y,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('information')),
          actions: [CloseButton2()],
        ),
        body: CharacterDetails(
          characterId: characterId,
          characterData: characterData,
        ),
      ),
    );
  }
}
