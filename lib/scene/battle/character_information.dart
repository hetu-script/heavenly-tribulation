import 'package:flame/components.dart';
import 'package:samsara/components.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

import '../../ui.dart';
import '../../widgets/character/profile.dart';
import 'equipments_bar.dart';
import '../../global.dart';

class CharacterInformation extends GameComponent {
  final dynamic hero, enemy;

  late final SpriteComponent versusIcon;
  late final SpriteButton heroIcon, enemyIcon;
  late final EquipmentsBar heroEquipments, enemyEquipments;

  CharacterInformation({
    super.priority,
    super.position,
    required this.hero,
    required this.enemy,
  }) : super(
          anchor: Anchor.topLeft,
          size: Vector2(
            GameUI.size.x,
            GameUI.battleCharacterAvatarSize.y + GameUI.smallIndent * 2,
          ),
        );

  void showCharacterInfo(dynamic data) {
    showDialog(
      context: engine.context,
      builder: (context) {
        return CharacterProfileView(character: data);
      },
    );
  }

  @override
  void onLoad() async {
    // VS 图标放在中间
    versusIcon = SpriteComponent(
      position: Vector2(
          (size.x - GameUI.versusIconSize.x) / 2,
          (size.y - GameUI.versusIconSize.y) / 2),
      sprite: await Sprite.load('ui/versus.png'),
      size: GameUI.versusIconSize,
      paint: paint,
    );
    add(versusIcon);

    // 英雄头像：左上角
    heroIcon = SpriteButton(
      position: Vector2(GameUI.largeIndent, GameUI.smallIndent),
      spriteId: hero['icon'],
      size: GameUI.battleCharacterAvatarSize,
      borderRadius: 12.0,
      paint: paint,
    );
    heroIcon.onTap = (_, __) {
      // showCharacterInfo(heroData);
    };
    add(heroIcon);

    // 敌方头像：右上角
    enemyIcon = SpriteButton(
      position: Vector2(
          size.x -
              GameUI.battleCharacterAvatarSize.x -
              GameUI.largeIndent,
          GameUI.smallIndent),
      spriteId: enemy['icon'],
      size: GameUI.battleCharacterAvatarSize,
      borderRadius: 12.0,
      paint: paint,
    );
    enemyIcon.onTap = (_, __) {
      // showCharacterInfo(enemyData);
    };
    add(enemyIcon);

    // 英雄装备栏：头像右侧
    heroEquipments = EquipmentsBar(
      position: Vector2(
          GameUI.largeIndent +
              GameUI.battleCharacterAvatarSize.x +
              GameUI.smallIndent,
          GameUI.smallIndent +
              GameUI.battleCharacterAvatarSize.y / 2 -
              GameUI.equipmentsBarSize.y / 2),
      character: hero,
      paint: paint,
    );
    heroEquipments.isVisible = false;
    add(heroEquipments);

    // 敌方装备栏：头像左侧
    enemyEquipments = EquipmentsBar(
      position: Vector2(
          size.x -
              GameUI.battleCharacterAvatarSize.x -
              GameUI.largeIndent -
              GameUI.smallIndent -
              GameUI.equipmentsBarSize.x,
          GameUI.smallIndent +
              GameUI.battleCharacterAvatarSize.y / 2 -
              GameUI.equipmentsBarSize.y / 2),
      character: enemy,
      paint: paint,
    );
    enemyEquipments.isVisible = false;
    add(enemyEquipments);
  }

  /// fadeIn 之后调用，显示装备栏
  void showEquipments() {
    heroEquipments.isVisible = true;
    enemyEquipments.isVisible = true;
  }
}
