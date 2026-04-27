import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/hovertip.dart';

import '../../ui.dart';
import '../../global.dart';
import '../../data/game.dart';

class HandZone extends PiledZone with HandlesGesture {
  void Function(CustomGameCard card)? onCardSelected;

  HandZone({
    required super.position,
    super.reverseX,
    super.cardBasePriority = 500,
    super.isVisible,
    super.pileStartPosition,
    super.focusedPosition,
  }) : super(
          size: GameUI.handZoneSize,
          piledCardSize: GameUI.battleCardSize,
          pileOffset: Vector2(GameUI.handCardSpacing, 0),
          focusedSize: GameUI.battleCardFocusedSize,
          pileStyle: PileStyle.queue,
        );

  void setupCardInteraction(CustomGameCard card) {
    card.enablePreview = true;
    card.onTapUp = (button, position) {
      onCardSelected?.call(card);
    };

    card.onPreviewed = () {
      card.priority = 1000; // 提高优先级以覆盖其他元素
      final isDetailed = engine.config.developMode;
      final (_, description) = GameData.getBattleCardDescription(
        card.data,
        isDetailed: isDetailed,
        showDetailedHint: false,
      );
      Hovertip.show(
        scene: game,
        target: card,
        direction: HovertipDirection.topCenter,
        content: description,
        config: ScreenTextConfig(
          anchor: Anchor.topCenter,
          textAlign: TextAlign.center,
        ),
      );
    };

    card.onUnpreviewed = () {
      card.resetPriority();
      Hovertip.hide(card);
    };
  }

  void clearCardInteraction(CustomGameCard card) {
    card.onTapUp = null;
    card.enablePreview = false;
  }

  Future<void> clearHand() async {
    for (final card in cards) {
      clearCardInteraction(card as CustomGameCard);
    }
    cards.clear();
  }
}
