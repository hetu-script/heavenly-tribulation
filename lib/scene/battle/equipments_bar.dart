import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/components.dart';
import 'package:provider/provider.dart';

import '../../ui.dart';
import '../../data/game.dart';
import '../../engine.dart';
import '../../data/common.dart';
import '../../widgets/character/stats.dart';
import '../../state/hover_content.dart';

const kItemGridSize = 30.0;

class EquipmentsBar extends GameComponent {
  final dynamic character;

  late final String cultivationDescription;

  EquipmentsBar({
    super.position,
    required this.character,
    super.paint,
  }) : super(size: GameUI.equipmentsBarSize);

  void _addItemGrid(int index, dynamic itemData) {
    final spriteButton = SpriteButton(
      position: Vector2(index * (kItemGridSize + 2.0), 0),
      size: Vector2(kItemGridSize, kItemGridSize),
      spriteId: itemData?['icon'],
      borderSpriteId: 'item/grid_rank${itemData?['rank'] ?? 0}.png',
      paint: paint,
    );
    spriteButton.onMouseEnter = () {
      if (itemData == null) return;
      engine.context.read<HoverContentState>().show(
            itemData,
            spriteButton.toAbsoluteRect(),
          );
    };
    spriteButton.onMouseExit = () {
      engine.context.read<HoverContentState>().hide();
    };
    add(spriteButton);
  }

  @override
  FutureOr<void> onLoad() {
    super.onLoad();

    cultivationDescription = GameData.getPassivesDescription(character);

    final equipments = character['equipments'];

    for (var i = 0; i < kEquipmentMax; ++i) {
      final itemId = equipments[i.toString()];
      final itemData = character['inventory'][itemId];
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
        character: character,
        showNonBattleStats: false,
      );
      engine.context.read<HoverContentState>().show(
            statsView,
            statsButton.toAbsoluteRect(),
            direction: HoverContentDirection.rightTop,
          );
    };
    statsButton.onMouseExit = () {
      engine.context.read<HoverContentState>().hide();
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
      engine.context.read<HoverContentState>().show(
            cultivationDescription,
            cultivationButton.toAbsoluteRect(),
            direction: HoverContentDirection.rightTop,
            textAlign: TextAlign.left,
          );
    };
    cultivationButton.onMouseExit = () {
      engine.context.read<HoverContentState>().hide();
    };
    add(cultivationButton);
  }
}
