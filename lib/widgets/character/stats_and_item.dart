import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/menu_builder.dart';

import '../../global.dart';
import 'stats.dart';
import 'inventory/equipment_bar.dart';
import 'inventory/inventory.dart';
import '../dialog/confirm.dart';
import '../../logic/logic.dart';
import '../../data/common.dart';
import '../../data/game.dart';
import '../../ui.dart';
import '../common.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import '../../scene/common.dart';
import '../../extensions.dart';

enum ItemPopUpMenuItems {
  unequip,
  equip,
  use,
  charge,
  discard,
}

class CharacterStatsAndItem extends StatefulWidget {
  const CharacterStatsAndItem({
    super.key,
    this.characterId,
    this.character,
    this.mode = InformationViewMode.view,
  }) : assert(characterId != null || character != null);

  final String? characterId;
  final dynamic character;
  final InformationViewMode mode;

  @override
  State<CharacterStatsAndItem> createState() => _CharacterStatsAndItemState();
}

class _CharacterStatsAndItemState extends State<CharacterStatsAndItem> {
  late final dynamic _characterData;

  @override
  void initState() {
    super.initState();

    if (widget.character != null) {
      _characterData = widget.character!;
    } else {
      _characterData = GameData.getCharacter(widget.characterId!);
    }
  }

  void onItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    showFluentMenu(
      cursor: GameUI.cursor,
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
        if (itemData['isUndroppable'] != true)
          engine.locale('discard'): ItemPopUpMenuItems.discard,
      },
      onSelectedItem: (item) async {
        final isIdentified = itemData['isIdentified'] == true;
        switch (item) {
          case ItemPopUpMenuItems.unequip:
            if (itemData['isCursed'] == true) {
              dialog.pushDialog('hint_cursedEquipment');
              dialog.execute();
              return;
            }
            engine.play('put_item-83043.mp3');
            engine.hetu.invoke('unequip',
                namespace: 'Player', positionalArgs: [itemData]);
            engine.emit(GameEvents.heroPassivesUpdated);
            setState(() {});
          case ItemPopUpMenuItems.equip:
            if (!isIdentified) {
              dialog.pushDialog('hint_unidentifiedItem');
              dialog.execute();
              return;
            }
            final category = itemData['category'];
            if (kRestrictedEquipmentCategories.contains(category)) {
              int equippedCount = engine.hetu.invoke('equippedCategory',
                  namespace: 'Player', positionalArgs: [category]);

              if (equippedCount > 0) {
                final hasUnrestrictedPassive = engine.hetu.invoke('hasPassive',
                    namespace: 'Player',
                    positionalArgs: ['${category}UnrestrictedEquip']);
                if (hasUnrestrictedPassive == null) {
                  dialog.pushDialog('hint_restrictedEquipment',
                      interpolations: [engine.locale(category)]);
                  dialog.execute();
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
              dialog.pushDialog('hint_unidentifiedItem');
              dialog.execute();
              return;
            }
            GameLogic.onUseItem(itemData);
            setState(() {});
          case ItemPopUpMenuItems.charge:
            if (!isIdentified) {
              dialog.pushDialog('hint_unidentifiedItem');
              dialog.execute();
              return;
            }
            GameLogic.onChargeItem(itemData);
            setState(() {});
          case ItemPopUpMenuItems.discard:
            final value = await showDialog<bool>(
              context: context,
              builder: (context) => ConfirmDialog(
                  description: engine.locale('dangerOperationPrompt')),
            );
            if (value != true) return;
            engine.play('break06-36414.mp3');
            engine.hetu.invoke('lose',
                namespace: 'Player', positionalArgs: [itemData]);
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
                character: _characterData,
                onItemSecondaryTapped: onItemSecondaryTapped,
                style: EquipmentBarStyle.vertical,
              ),
              CharacterStats(
                character: _characterData,
                height: 312,
              ),
              Inventory(
                height: (kDefaultItemGridSize.height + 4.0) * 7,
                character: _characterData,
                itemType: ItemType.player,
                gridsPerLine: 6,
                onItemSecondaryTapped: onItemSecondaryTapped,
              ),
            ],
          ),
          // Padding(
          //   padding: const EdgeInsets.only(top: 10.0, right: 30.0),
          //   child: Row(
          //     mainAxisAlignment: MainAxisAlignment.end,
          //     children: [
          //       fluent.Button(
          //         onPressed: () {},
          //         child: Text(engine.locale('orderBy')),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}

class CharacterStatsAndItemView extends StatelessWidget {
  const CharacterStatsAndItemView({
    super.key,
    this.characterId,
    this.character,
  }) : assert(characterId != null || character != null);

  final String? characterId;
  final dynamic character;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: GameUI.profileWindowSize.x,
      height: GameUI.profileWindowSize.y,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('information')),
          actions: [CloseButton2()],
        ),
        body: CharacterStatsAndItem(
          characterId: characterId,
          character: character,
        ),
      ),
    );
  }
}
