import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../engine.dart';
import 'inventory/stats.dart';
import 'inventory/equipment_bar.dart';
import 'inventory/inventory.dart';
import '../menu_item_builder.dart';
import '../dialog/confirm_dialog.dart';
import '../../state/hero.dart';
import '../common.dart';

const Set<String> kMaterials = {
  // 'money',
  // 'jade',
  'food',
  'water',
  'stone',
  'ore',
  'timber',
  'paper',
  'herb',
};

enum ItemPopUpMenuItems {
  use,
  equip,
  unequip,
  // discard,
  destroy,
}

List<PopupMenuEntry<ItemPopUpMenuItems>> buildItemPopUpMenuItems({
  bool showEquip = true,
  bool showUnequip = false,
  bool enableUse = true,
  bool enableDiscard = true,
  bool enableDestroy = true,
  void Function(ItemPopUpMenuItems item)? onSelectedItem,
}) {
  return <PopupMenuEntry<ItemPopUpMenuItems>>[
    if (showUnequip)
      buildMenuItem(
        item: ItemPopUpMenuItems.unequip,
        name: engine.locale('unequip'),
        onSelectedItem: onSelectedItem,
        width: 80.0,
      )
    else ...[
      buildMenuItem(
        item: ItemPopUpMenuItems.use,
        name: engine.locale('use'),
        onSelectedItem: onSelectedItem,
        width: 80.0,
        enabled: enableUse,
      ),
      if (showEquip)
        buildMenuItem(
          item: ItemPopUpMenuItems.equip,
          name: engine.locale('equip'),
          onSelectedItem: onSelectedItem,
          width: 80.0,
        ),
      // buildMenuItem(
      //   item: ItemPopUpMenuItems.discard,
      //   name: engine.locale('discard'),
      //   onItemPressed: onItemPressed,
      //   width: 80.0,
      //   enabled: enableDiscard,
      // ),
      const PopupMenuDivider(),
      buildMenuItem(
        item: ItemPopUpMenuItems.destroy,
        name: engine.locale('destroy'),
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
    this.showInventory = true,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;
  final dynamic characterData;
  final bool showInventory;

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
      showUnequip: itemData['equippedPosition'] != null,
      showEquip: itemData['category'] == 'equipment',
      enableUse: itemData['category'] == 'consumable',
      onSelectedItem: (item) {
        switch (item) {
          case ItemPopUpMenuItems.use:
          case ItemPopUpMenuItems.equip:
            engine.play('sword-sheathed-178549.mp3');
            engine.hetu.invoke('equip',
                namespace: 'Player', positionalArgs: [itemData]);
            setState(() {
              context.read<HeroState>().update();
            });
          case ItemPopUpMenuItems.unequip:
            engine.play('put_item-83043.mp3');
            engine.hetu.invoke('unequip',
                namespace: 'Player', positionalArgs: [itemData]);
            setState(() {
              context.read<HeroState>().update();
            });
          case ItemPopUpMenuItems.destroy:
            engine.play('break06-36414.mp3');
            showDialog<bool>(
              context: context,
              builder: (context) => ConfirmDialog(
                  description: engine.locale('dangerOperationPrompt')),
            ).then((bool? value) {
              if (value == true) {
                engine.hetu.invoke('destroy', positionalArgs: [itemData]);
                setState(() {});
              }
            });
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
              characterData: _characterData,
              onItemSecondaryTapped: onItemSecondaryTapped,
              isVertical: true,
            ),
            StatsView(
              characterData: _characterData,
              isHero: true,
            ),
            if (widget.showInventory)
              Inventory(
                height: 406,
                characterData: _characterData,
                type: InventoryType.player,
                minSlotCount: 60,
                gridsPerLine: 5,
                onSecondaryTapped: onItemSecondaryTapped,
              ),
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
      width: 400,
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
            StatsView(
              characterData: characterData,
              isHero: true,
            ),
            EquipmentBar(
              characterData: characterData,
              isVertical: true,
            ),
          ],
        ),
      ),
    );
  }
}
