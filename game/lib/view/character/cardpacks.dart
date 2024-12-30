import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/common.dart';
import 'package:samsara/ui/close_button.dart';

import '../../engine.dart';
import '../../ui.dart';
// import 'status_effects.dart';
import 'equipments/inventory.dart';
import 'equipments/item_info.dart';
import '../common.dart';

class CardpacksView extends StatefulWidget {
  const CardpacksView({
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
  State<CardpacksView> createState() => _CardpacksViewState();
}

class _CardpacksViewState extends State<CardpacksView> {
  late final dynamic _characterData;

  double? _infoPosX, _infoPosY;

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

  @override
  void dispose() {
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
              width: 400.0,
              height: 400.0,
              decoration: BoxDecoration(
                color: kBackgroundColor,
                borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                border:
                    Border.all(color: Theme.of(context).colorScheme.onSurface),
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
                      SizedBox(
                        width: 360,
                        height: 320,
                        child: Column(
                          children: [
                            InventoryView(
                              height: 260,
                              inventoryData: _characterData['inventory'],
                              type: widget.type,
                              minSlotCount: 36,
                              onMouseEnterItemGrid: onMouseEnterItemGrid,
                              onMouseExitItemGrid: onMouseExitItemGrid,
                            ),
                          ],
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
