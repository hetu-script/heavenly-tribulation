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
  /// 能量瓶显示元气（energy_positive_life 状态层数）。
  /// 图标暂用元气费用图标（原瓶子图标已弃用，见计划 §6.2；图标美术后续人工处理）
  void setEnergy(int current) {
    text = '$current';
    tryLoadSprite(
      spriteId: 'icon/cost/qi_basic.png',
      hoverSpriteId: 'icon/cost/qi_basic.png',
    );
  }
}
