import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/sprite_button.dart';

import '../../ui.dart';

class EnergyDisplay extends GameComponent {
  late final SpriteButton _filledButton;
  late final SpriteButton _emptyButton;

  EnergyDisplay({
    required super.position,
  }) : super(
          size: GameUI.battleEnergyBottleSize,
          anchor: Anchor.center,
        ) {
    _filledButton = SpriteButton(
      spriteId: 'battle/bottle.png',
      hoverSpriteId: 'battle/bottle_hover.png',
      size: GameUI.battleEnergyBottleSize,
      isVisible: false,
    );
    _emptyButton = SpriteButton(
      spriteId: 'battle/bottle_empty.png',
      hoverSpriteId: 'battle/bottle_empty_hover.png',
      size: GameUI.battleEnergyBottleSize,
      isVisible: true,
    );
    add(_filledButton);
    add(_emptyButton);
  }

  void setEnergy(int current) {
    if (current > 0) {
      _filledButton.text = '$current';
      _filledButton.isVisible = true;
      _emptyButton.isVisible = false;
    } else {
      _filledButton.isVisible = false;
      _emptyButton.isVisible = true;
    }
  }
}
