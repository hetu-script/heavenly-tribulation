import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/common.dart';
import 'package:samsara/ui/close_button.dart';

import '../../config.dart';
import 'equipments/stats.dart';
import 'equipments/equipments.dart';
// import 'status_effects.dart';
import 'equipments/inventory.dart';
import 'equipments/entity_info.dart';
import '../../view/menu_item_builder.dart';

const kEntityInfoIndent = 10.0;
const kEntityInfoWidth = 300.0;

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
  void Function(ItemPopUpMenuItems item)? onItemPressed,
}) {
  return <PopupMenuEntry<ItemPopUpMenuItems>>[
    if (showUnequip)
      buildMenuItem(
        item: ItemPopUpMenuItems.unequip,
        name: engine.locale('unequip'),
        onItemPressed: onItemPressed,
        width: 80.0,
      ),
    if (!showUnequip) ...[
      buildMenuItem(
        item: ItemPopUpMenuItems.use,
        name: engine.locale('use'),
        onItemPressed: onItemPressed,
        width: 80.0,
        enabled: enableUse,
      ),
      if (showEquip)
        buildMenuItem(
          item: ItemPopUpMenuItems.equip,
          name: engine.locale('equip'),
          onItemPressed: onItemPressed,
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
        onItemPressed: onItemPressed,
        width: 80.0,
        enabled: enableDiscard,
      ),
    ],
  ];
}

class EquipmentsAndStatsView extends StatefulWidget {
  const EquipmentsAndStatsView({
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
  State<EquipmentsAndStatsView> createState() => _EquipmentsAndStatsViewState();
}

class _EquipmentsAndStatsViewState extends State<EquipmentsAndStatsView>
    with SingleTickerProviderStateMixin {
  static final List<Tab> _tabs = <Tab>[
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.inventory),
          ),
          Text(engine.locale('build')),
        ],
      ),
    ),
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.summarize),
          ),
          Text(engine.locale('stats')),
        ],
      ),
    ),
  ];

  late TabController _tabController;

  late final dynamic _characterData;

  double? _infoPosX, _infoPosY;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: _tabs.length);
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
    _tabController.index = widget.tabIndex;

    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      _characterData = engine.hetu
          .invoke('getCharacterById', positionalArgs: [widget.characterId]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void onMouseExitItemGrid(dynamic entityData, Rect gridRenderBox) {
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
      onItemPressed: (item) {
        switch (item) {
          case ItemPopUpMenuItems.use:
          case ItemPopUpMenuItems.equip:
            engine.hetu
                .invoke('equip', positionalArgs: [_characterData, entityData]);
            setState(() {});
          case ItemPopUpMenuItems.unequip:
            engine.hetu.invoke('unequip',
                positionalArgs: [_characterData, entityData]);
            setState(() {});
          case ItemPopUpMenuItems.destroy:
            engine.hetu.invoke('destroy',
                positionalArgs: [_characterData, entityData]);
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

  Widget? _buildMaterial(String name, dynamic data, {bool ignoreZero = false}) {
    final value = data[name];
    if (value > 0 || ignoreZero) {
      return Tooltip(
        message: engine.locale('$name.description'),
        child: Container(
          width: 100.0,
          padding: const EdgeInsets.only(right: 5.0),
          child: Row(
            children: [
              Text('${engine.locale(name)}:'),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return null;
  }

  List<Widget> _buildMaterials() {
    final data = _characterData['materials'];
    final List<Widget> materials = [];
    materials.add(_buildMaterial('money', data, ignoreZero: true)!);
    materials.add(_buildMaterial('jade', data, ignoreZero: true)!);
    for (final name in kMaterials) {
      final widget = _buildMaterial(name, data);
      if (widget != null) {
        materials.add(widget);
      }
    }
    return materials;
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
    final equipmentsData = [];
    for (var i = 1; i < kEquipmentMax; ++i) {
      final equipmentId = _characterData['equipments'][i];
      final equipment = _characterData['inventory'][equipmentId];
      equipmentsData.add(equipment);
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(5.0)),
            child: Container(
              width: 640.0,
              height: 400.0,
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                border: Border.all(
                    color: Theme.of(context).colorScheme.onBackground),
              ),
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(
                    engine.locale('build'),
                  ),
                  actions: const [CloseButton2()],
                ),
                body: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 360,
                            height: 320,
                            child: Column(
                              children: [
                                EquipmentsView(
                                  equipmentsData: equipmentsData,
                                  onMouseEnterItemGrid: onMouseEnterItemGrid,
                                  onMouseExitItemGrid: onMouseExitItemGrid,
                                  onItemSecondaryTapped: onItemSecondaryTapped,
                                ),
                                InventoryView(
                                  height: 260,
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
                          StatsView(
                            characterData: _characterData,
                            useColumn: true,
                          ),
                        ],
                      ),
                      Container(
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.only(
                            top: 5.0, left: 10.0, right: 10.0),
                        child: Wrap(
                          children: _buildMaterials(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
