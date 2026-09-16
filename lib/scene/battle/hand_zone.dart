import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/hovertip.dart';

import '../../ui.dart';
import '../../data/game.dart';

class HandZone extends PiledZone with HandlesGesture {
  void Function(CustomGameCard card)? onCardSelected;

  /// 悬浮描述自定义回调：接收默认描述，返回最终展示的悬浮文本
  ///（如 battle.dart 为置灰卡牌附加缺少资源提示）
  String Function(CustomGameCard card, String description)? onHoverDescription;

  bool enableInteraction;

  int energy = 0;

  HandZone({
    required super.position,
    super.reverseX,
    super.cardBasePriority = 500,
    super.isVisible,
    super.pileStartPosition,
    required this.enableInteraction,
  }) : super(
          size: GameUI.handZoneSize,
          piledCardSize: GameUI.battleCardSize,
          pileOffset: Vector2(GameUI.handCardSpacing, 0),
          focusedSize: GameUI.battleCardFocusedSize,
          focusedOffset: Vector2(
              -(GameUI.battleCardFocusedSize.x - GameUI.battleCardSize.x) / 2,
              -(GameUI.battleCardFocusedSize.y - GameUI.battleCardSize.y)),
          pileStyle: PileStyle.queue,
          spreadMargin: GameUI.battleCardSize.x / 4,
        );

  @override
  void tryAddCard(
    GameCard c, {
    bool clone = false,
    int? index,
    bool animated = true,
    bool sort = true,
  }) {
    assert(c is CustomGameCard);
    CustomGameCard card = c as CustomGameCard;

    super.tryAddCard(card, clone: clone);

    if (!enableInteraction) return;

    enableCardInteraction(card);
  }

  void enableCardInteraction(CustomGameCard card) {
    if (!cards.contains(card)) return;

    card.enableGesture = true;

    // 恢复交互回调（参考 tryAddCard 中的逻辑）
    card.onTapUp = (button, position) {
      Hovertip.hide(card);
      card.setFocused(false);
      setSpreadCenter(card, false);
      onCardSelected?.call(card);
    };

    card.onMouseEnter = () {
      card.setFocused(true);
      card.showGlow = true;
      final (_, description) = GameData.getBattleCardDescription(
        card.data,
        isDetailed: true,
        showAffixes: false,
        withPrediction: true,
      );
      Hovertip.show(
        scene: game,
        target: card,
        direction: HovertipDirection.topCenter,
        content: onHoverDescription?.call(card, description) ?? description,
        config: ScreenTextConfig(
          anchor: Anchor.topCenter,
          textAlign: TextAlign.center,
        ),
      );
      setSpreadCenter(card, true);
    };

    card.onMouseExit = () {
      card.setFocused(false);
      if (!card.isSelected) {
        card.showGlow = false;
      }
      card.resetPriority();
      Hovertip.hide(card);
      setSpreadCenter(card, false);
    };
  }
}
