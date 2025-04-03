import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/components.dart';
import 'package:provider/provider.dart';

import '../../game/ui.dart';
import '../../game/data.dart';
import '../../common.dart';
import '../../widgets/character/stats.dart';
import '../../state/hoverinfo.dart';

const kItemGridSize = 30.0;

class EquipmentsBar extends GameComponent {
  final dynamic characterData;

  late final String cultivationDescription;

  EquipmentsBar({
    super.position,
    required this.characterData,
    super.paint,
  }) : super(size: GameUI.equipmentsBarSize);

  void _addItemGrid(int index, dynamic itemData) {
    final spriteButton = SpriteButton(
      position: Vector2(index * (kItemGridSize + 2.0), 0),
      size: Vector2(kItemGridSize, kItemGridSize),
      spriteId: itemData?['icon'],
      borderSpriteId: 'item/grid.png',
      paint: paint,
    );
    spriteButton.onMouseEnter = () {
      if (itemData == null) return;
      game.context.read<HoverInfoContentState>().show(
            itemData,
            spriteButton.toAbsoluteRect(),
          );
    };
    spriteButton.onMouseExit = () {
      game.context.read<HoverInfoContentState>().hide();
    };
    add(spriteButton);
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();

    cultivationDescription = GameData.getPassivesDescription(characterData);

    final equipments = characterData['equipments'];

    for (var i = 0; i < kEquipmentMax; ++i) {
      final itemId = equipments[i.toString()];
      final itemData = characterData['inventory'][itemId];
      _addItemGrid(i, itemData);
    }

    final statsButton = SpriteButton(
      position: Vector2(kEquipmentMax * (kItemGridSize + 2.0), 0),
      size: Vector2(kItemGridSize, kItemGridSize),
      spriteId: 'icon/cultivate.png',
      borderSpriteId: 'item/grid.png',
      paint: paint,
    );
    statsButton.onMouseEnter = () {
      final Widget statsView = CharacterStats(
        characterData: characterData,
        isHero: false,
        showNonBattleStats: false,
      );
      game.context.read<HoverInfoContentState>().show(
            statsView,
            statsButton.toAbsoluteRect(),
            direction: HoverInfoDirection.rightTop,
          );
    };
    statsButton.onMouseExit = () {
      game.context.read<HoverInfoContentState>().hide();
    };
    add(statsButton);

    final cultivationButton = SpriteButton(
      position: Vector2((kEquipmentMax + 1) * (kItemGridSize + 2.0), 0),
      size: Vector2(kItemGridSize, kItemGridSize),
      spriteId: 'icon/stats.png',
      borderSpriteId: 'item/grid.png',
      paint: paint,
    );
    cultivationButton.onMouseEnter = () {
      game.context.read<HoverInfoContentState>().show(
            cultivationDescription,
            cultivationButton.toAbsoluteRect(),
            direction: HoverInfoDirection.rightTop,
            textAlign: TextAlign.left,
          );
    };
    cultivationButton.onMouseExit = () {
      game.context.read<HoverInfoContentState>().hide();
    };
    add(cultivationButton);
  }
}
