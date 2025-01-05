import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/common.dart';
import 'package:provider/provider.dart';

import '../../engine.dart';
import '../../ui.dart';
import 'equipments/stats.dart';
import 'equipments/equipments.dart';
// import 'status_effects.dart';
import 'equipments/inventory.dart';
import 'equipments/item_info.dart';
import '../../view/menu_item_builder.dart';
import '../common.dart';
import '../../state/windows.dart';
import '../draggable_panel.dart';

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
      ),
    if (!showUnequip) ...[
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
    this.onClose,
    this.onDragUpdate,
    this.onTapDown,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;

  final dynamic characterData;

  final int tabIndex;

  final InventoryType type;

  final Function()? onClose;
  final Function(DragUpdateDetails details)? onDragUpdate;
  final Function(Offset tapPosition)? onTapDown;

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

  double? _infoPosX, _infoPosY;

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

  dynamic _hoverEntityData;
  Rect? _hoverGridRect;

  void onMouseEnterItemGrid(dynamic entityData, Rect gridRenderBox) {
    setState(() {
      _hoverEntityData = entityData;
      _hoverGridRect = gridRenderBox;
    });
  }

  void onMouseExitItemGrid() {
    setState(() {
      _hoverEntityData = null;
      _hoverGridRect = null;
    });
  }

  void onItemSecondaryTapped(dynamic entityData, Offset screenPosition) {
    _hoverEntityData = null;

    final menuPosition = RelativeRect.fromLTRB(
        screenPosition.dx, screenPosition.dy, screenPosition.dx, 0.0);
    final items = buildItemPopUpMenuItems(
      showUnequip: entityData['equippedPosition'] != null,
      showEquip: entityData['isEquippable'] ?? false,
      enableUse: entityData['isUsable'] ?? false,
      onSelectedItem: (item) {
        switch (item) {
          case ItemPopUpMenuItems.use:
          case ItemPopUpMenuItems.equip:
            engine.hetu.invoke('equip', positionalArgs: [entityData]);
            setState(() {});
          case ItemPopUpMenuItems.unequip:
            engine.hetu.invoke('unequip', positionalArgs: [entityData]);
            setState(() {});
          case ItemPopUpMenuItems.destroy:
            engine.hetu.invoke('destroy', positionalArgs: [entityData]);
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

  void onInfoHeightCalculated(Size infoSize, Size screenSize) {
    setState(() {
      if (infoSize.height < screenSize.height) {
        _infoPosY =
            math.min(screenSize.height - infoSize.height, _hoverGridRect!.top);
      }

      double preferredX = _hoverGridRect!.right + kEntityInfoIndent;
      if (preferredX > (screenSize.width - infoSize.width)) {
        _infoPosX = _hoverGridRect!.left - kEntityInfoIndent - infoSize.width;
      } else {
        _infoPosX = preferredX;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final windowPositions =
        context.watch<WindowPositionState>().windowPositions;
    final position = windowPositions['details'] ?? GameUI.detailsWindowPosition;

    final equipmentsData = [];
    for (var i = 1; i < kEquipmentMax; ++i) {
      final equipmentId = _characterData['equipments'][i];
      final equipment = _characterData['inventory'][equipmentId];
      equipmentsData.add(equipment);
    }

    return DraggablePanel(
      title: engine.locale('build'),
      position: position,
      width: GameUI.profileWindowWidth,
      height: 400.0,
      onTapDown: widget.onTapDown,
      onDragUpdate: widget.onDragUpdate,
      onClose: widget.onClose,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatsView(
                  characterData: _characterData,
                  useColumn: true,
                ),
                SizedBox(
                  width: 360,
                  height: 380,
                  child: Column(
                    children: [
                      EquipmentsView(
                        equipmentsData: equipmentsData,
                        onMouseEnterItemGrid: onMouseEnterItemGrid,
                        onMouseExitItemGrid: onMouseExitItemGrid,
                        onItemSecondaryTapped: onItemSecondaryTapped,
                      ),
                      InventoryView(
                        height: 280,
                        inventoryData: _characterData['inventory'],
                        type: widget.type,
                        minSlotCount: 36,
                        onMouseEnterItemGrid: onMouseEnterItemGrid,
                        onMouseExitItemGrid: onMouseExitItemGrid,
                        onItemSecondaryTapped: onItemSecondaryTapped,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_hoverEntityData != null)
            EntityInfo(
              entityData: _hoverEntityData,
              width: kEntityInfoWidth,
              onHeightCalculated: onInfoHeightCalculated,
              left: _infoPosX,
              top: _infoPosY,
            ),
        ],
      ),
    );
  }
}
