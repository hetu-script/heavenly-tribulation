import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../engine.dart';
import 'inventory/stats.dart';
import 'inventory/equipment_bar.dart';
import 'inventory/inventory.dart';
import '../menu_item_builder.dart';
import '../dialog/confirm.dart';
import '../../state/character.dart';
import '../../scene/game_dialog/game_dialog_content.dart';
import '../../game/logic.dart';
import '../../common.dart';
import '../../state/hoverinfo.dart';

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

List<PopupMenuEntry<ItemPopUpMenuItems>> buildItemPopUpMenuItems({
  bool enableUnequip = false,
  bool enableEquip = false,
  bool enableUse = false,
  bool enableCharge = false,
  bool enableDiscard = true,
  void Function(ItemPopUpMenuItems item)? onSelectedItem,
}) {
  return <PopupMenuEntry<ItemPopUpMenuItems>>[
    if (enableUnequip) ...[
      buildMenuItem(
        item: ItemPopUpMenuItems.unequip,
        name: engine.locale('unequip'),
        onSelectedItem: onSelectedItem,
        width: 80.0,
      ),
      buildMenuItem(
        item: ItemPopUpMenuItems.charge,
        name: engine.locale('charge'),
        onSelectedItem: onSelectedItem,
        width: 80.0,
        enabled: enableCharge,
      ),
    ] else ...[
      buildMenuItem(
        item: ItemPopUpMenuItems.equip,
        name: engine.locale('equip'),
        onSelectedItem: onSelectedItem,
        width: 80.0,
        enabled: enableEquip,
      ),
      buildMenuItem(
        item: ItemPopUpMenuItems.use,
        name: engine.locale('use'),
        onSelectedItem: onSelectedItem,
        width: 80.0,
        enabled: enableUse,
      ),
      buildMenuItem(
        item: ItemPopUpMenuItems.charge,
        name: engine.locale('charge'),
        onSelectedItem: onSelectedItem,
        width: 80.0,
        enabled: enableCharge,
      ),
      const PopupMenuDivider(),
      buildMenuItem(
        item: ItemPopUpMenuItems.discard,
        name: engine.locale('discard'),
        onSelectedItem: onSelectedItem,
        width: 80.0,
        enabled: enableDiscard,
      ),
    ],
  ];
}

class CharacterDetails extends StatefulWidget {
  const CharacterDetails({
    super.key,
    this.characterId,
    this.characterData,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;
  final dynamic characterData;

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
      _characterData = engine.hetu
          .invoke('getCharacterById', positionalArgs: [widget.characterId]);
    }
  }

  void onItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    final menuPosition = RelativeRect.fromLTRB(
        screenPosition.dx, screenPosition.dy, screenPosition.dx, 0.0);
    final items = buildItemPopUpMenuItems(
      enableUnequip: itemData['equippedPosition'] != null,
      enableEquip: itemData['isEquippable'] == true,
      enableUse: itemData['isUsable'] == true,
      enableCharge: itemData['chargeData'] != null,
      enableDiscard: itemData['isUndroppable'] != true,
      onSelectedItem: (item) async {
        final isIdentified = itemData['isIdentified'] == true;
        switch (item) {
          case ItemPopUpMenuItems.unequip:
            if (itemData['isCursed'] == true) {
              GameDialogContent.show(
                  context, engine.locale('hint_cursedEquipment'));
            } else {
              engine.play('put_item-83043.mp3');
              engine.hetu.invoke('unequip',
                  namespace: 'Player', positionalArgs: [itemData]);
              setState(() {
                context.read<HeroState>().update();
              });
            }
          case ItemPopUpMenuItems.equip:
            if (!isIdentified) {
              GameDialogContent.show(
                  context, engine.locale('hint_unidentifiedItem'));
              return;
            }
            final category = itemData['category'];
            if (kRestrictedEquipmentTypes.contains(category)) {
              int equippedCount = engine.hetu.invoke('hasEquipped',
                  namespace: 'Player', positionalArgs: [category]);

              if (equippedCount > 0) {
                final hasUnrestrictedPassive = engine.hetu.invoke('hasPassive',
                    namespace: 'Player',
                    positionalArgs: ['${category}UnrestrictedEquip']);
                if (!hasUnrestrictedPassive) {
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
            setState(() {
              context.read<HeroState>().update();
            });
          case ItemPopUpMenuItems.use:
            if (!isIdentified) {
              GameDialogContent.show(
                  context, engine.locale('hint_unidentifiedItem'));
              return;
            }
            setState(() {
              GameLogic.onUseItem(itemData);
            });
          case ItemPopUpMenuItems.charge:
            if (!isIdentified) {
              GameDialogContent.show(
                  context, engine.locale('hint_unidentifiedItem'));
              return;
            }
            GameLogic.onChargeItem(itemData);
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
    showMenu(
      context: context,
      position: menuPosition,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EquipmentBar(
              type: HoverType.player,
              characterData: _characterData,
              onItemSecondaryTapped: onItemSecondaryTapped,
              isVertical: true,
            ),
            CharacterStats(
              characterData: _characterData,
              isHero: true,
            ),
            Column(
              children: [
                Container(
                  width: 300.0,
                  height: 60.0,
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Padding(
                      //   padding: const EdgeInsets.only(right: 10.0),
                      //   child: ElevatedButton(
                      //     onPressed: () {},
                      //     child: Text(engine.locale('identify')),
                      //   ),
                      // ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text(engine.locale('orderBy')),
                      ),
                    ],
                  ),
                ),
                Inventory(
                  height: 350,
                  characterData: _characterData,
                  type: HoverType.player,
                  minSlotCount: 60,
                  gridsPerLine: 5,
                  onSecondaryTapped: onItemSecondaryTapped,
                ),
              ],
            )
          ],
        ),
      ],
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
      width: 400.0,
      height: 480.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('information')),
          actions: [CloseButton2()],
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CharacterStats(
              characterData: characterData,
              isHero: true,
            ),
            EquipmentBar(
              type: HoverType.npc,
              characterData: characterData,
              isVertical: true,
            ),
          ],
        ),
      ),
    );
  }
}
