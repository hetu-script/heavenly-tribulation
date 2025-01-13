import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../engine.dart';
import '../../ui.dart';
import 'inventory/stats.dart';
import 'inventory/equipment_bar.dart';
// import 'status_effects.dart';
import 'inventory/inventory.dart';
import '../../view/menu_item_builder.dart';
import '../../state/view_panels.dart';
import '../draggable_panel.dart';
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
  'plank',
  'paper',
  'herb',
  'yinqi',
  'shaqi',
  'yuanqi',
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

class CharacterDetailsView extends StatefulWidget {
  const CharacterDetailsView({
    super.key,
    this.characterId,
    this.characterData,
    this.tabIndex = 0,
    this.type = InventoryType.player,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;

  final dynamic characterData;

  final int tabIndex;

  final InventoryType type;

  @override
  State<CharacterDetailsView> createState() => _CharacterDetailsViewState();
}

class _CharacterDetailsViewState extends State<CharacterDetailsView>
// with SingleTickerProviderStateMixin
{
  // static final List<Tab> _tabs = <Tab>[
  //   Tab(
  //     height: 40,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         const Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 8.0),
  //           child: Icon(Icons.inventory),
  //         ),
  //         Text(engine.locale('build')),
  //       ],
  //     ),
  //   ),
  //   Tab(
  //     height: 40,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         const Padding(
  //           padding: EdgeInsets.symmetric(horizontal: 8.0),
  //           child: Icon(Icons.summarize),
  //         ),
  //         Text(engine.locale('stats')),
  //       ],
  //     ),
  //   ),
  // ];

  // late TabController _tabController;

  late final dynamic _characterData;

  @override
  void initState() {
    super.initState();

    // _tabController = TabController(vsync: this, length: _tabs.length);
    // _tabController.addListener(() {
    //   setState(() {
    //     if (_tabController.index == 0) {
    //       _title = engine.locale('information'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale('bonds'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale('history'];
    //     }
    //   });
    // });
    // _tabController.index = widget.tabIndex;

    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      _characterData = engine.hetu
          .invoke('getCharacterById', positionalArgs: [widget.characterId]);
    }
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  void onItemSecondaryTapped(dynamic itemData, Offset screenPosition) {
    // widget.onMouseExitItem?.call();
    // _hoverEntityData = null;

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
    Offset position =
        context.watch<PanelPositionState>().get(ViewPanels.characterDetails) ??
            GameUI.detailsWindowPosition;

    return DraggablePanel(
      title: engine.locale('build'),
      position: position,
      width: GameUI.profileWindowWidth,
      height: 400.0,
      onTapDown: (offset) {
        context.read<ViewPanelState>().setUpFront(ViewPanels.characterDetails);
      },
      onDragUpdate: (details) {
        context.read<PanelPositionState>().update(
              ViewPanels.characterDetails,
              details.delta,
            );
      },
      onClose: () {
        context.read<ViewPanelState>().hide(ViewPanels.characterDetails);
      },
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatsView(
                  characterData: _characterData,
                  isHero: true,
                ),
                SizedBox(
                  width: 360,
                  height: 380,
                  child: Column(
                    children: [
                      EquipmentBar(
                        characterData: _characterData,
                        onItemSecondaryTapped: onItemSecondaryTapped,
                      ),
                      Inventory(
                        height: 280,
                        inventoryData: _characterData['inventory'],
                        type: widget.type,
                        minSlotCount: 36,
                        onSecondaryTapped: onItemSecondaryTapped,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
