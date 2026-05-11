import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/sprite_button.dart';

import '../../ui.dart';

class EnergyDisplay extends SpriteButton {
  EnergyDisplay({
    required super.position,
  }) : super(
          size: GameUI.battleEnergyBottleSize,
          anchor: Anchor.center,
          textConfig: ScreenTextConfig(
            textStyle: TextStyle(
              fontFamily: GameUI.fontFamilyKaiti,
              fontWeight: FontWeight.bold,
              fontSize: 24.0,
            ),
          ),
        );
  void setEnergy(int current) {
    text = '$current';
    if (current > 0) {
      tryLoadSprite(
          spriteId: 'battle/bottle.png',
          hoverSpriteId: 'battle/bottle_hover.png');
    } else {
      tryLoadSprite(
          spriteId: 'battle/bottle_empty.png',
          hoverSpriteId: 'battle/bottle_empty_hover.png');
    }
  }
}
