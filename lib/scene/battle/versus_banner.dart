import 'package:flame/components.dart';
import 'package:samsara/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';

import '../../game/ui.dart';
import '../../widgets/character/profile.dart';
// import '../../state/hoverinfo.dart';
import 'equipments_bar.dart';

class VersusBanner extends GameComponent {
  // late final SpriteComponent2 versus;
  // late final Rect versusBannerRect;

  final dynamic heroData, enemyData;
  // late final SpriteComponent2 heroIcon, enemyIcon;

  VersusBanner({
    super.priority,
    super.position,
    required this.heroData,
    required this.enemyData,
  }) : super(
          anchor: Anchor.center,
          size: GameUI.versusBannerSize,
        );

  void showCharacterInfo(dynamic data) {
    showDialog(
      context: gameRef.context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return CharacterProfileView(characterData: data);
      },
    );
  }

  @override
  void onLoad() async {
    final versusIcon = SpriteComponent(
      // position: Vector2(center.x - 80.0, center.y - 90.0),
      position:
          Vector2(GameUI.battleCharacterAvatarSize.x + GameUI.hugeIndent, 0),
      sprite: Sprite(await Flame.images.load('battle/versus.png')),
      size: GameUI.versusIconSize,
      paint: paint,
    );
    add(versusIcon);

    final heroIcon = SpriteButton(
      // position: Vector2(center.x - 80.0 - 10.0 - 100.0, center.y - 50.0),
      position: Vector2(0, 40.0),
      spriteId: heroData['icon'],
      // image2: await Flame.images.load('illustration/border.png'),
      size: GameUI.battleCharacterAvatarSize,
      borderRadius: 12.0,
      paint: paint,
    );
    heroIcon.onTap = (_, __) {
      showCharacterInfo(heroData);
    };
    add(heroIcon);

    final heroEquipments = EquipmentsBar(
      position: heroIcon.bottomLeft +
          Vector2((heroIcon.size.x - GameUI.equipmentsBarSize.x) / 2,
              GameUI.smallIndent),
      characterData: heroData,
      paint: paint,
    );
    add(heroEquipments);

    final enemyIcon = SpriteButton(
      // position: Vector2(center.x + 80.0 + 10.0, center.y - 50.0),
      position: Vector2(
          GameUI.battleCharacterAvatarSize.x +
              GameUI.hugeIndent * 2 +
              GameUI.versusIconSize.x,
          40.0),
      spriteId: enemyData['icon'],
      // image2: await Flame.images.load('illustration/border.png'),
      size: GameUI.battleCharacterAvatarSize,
      borderRadius: 12.0,
      paint: paint,
    );
    enemyIcon.onTap = (_, __) {
      showCharacterInfo(enemyData);
    };
    add(enemyIcon);

    final enemyEquipments = EquipmentsBar(
      position: enemyIcon.bottomLeft +
          Vector2((heroIcon.size.x - GameUI.equipmentsBarSize.x) / 2,
              GameUI.smallIndent),
      characterData: enemyData,
      paint: paint,
    );
    add(enemyEquipments);
  }

  // @override
  // void render(Canvas canvas) {
  // versus.renderRect(canvas, versusBannerRect, overridePaint: paint);

  // heroIcon.renderRect(canvas, heroIconRect, overridePaint: paint);
  // enemyIcon.renderRect(canvas, enemyIconRect, overridePaint: paint);
  // }
}
