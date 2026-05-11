import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/hovertip.dart';

import '../../ui.dart';
import '../../data/game.dart';

class HandZone extends PiledZone with HandlesGesture {
  void Function(CustomGameCard card)? onCardSelected;

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

    card.enableGesture = true;

    card.onTapUp = (button, position) {
      Hovertip.hide(card);
      onCardSelected?.call(card);

      card.removeFromPile();
      setSpreadCenter(card, false);
    };

    card.onMouseEnter = () {
      card.setFocused(true);
      card.showGlow = true;
      final (_, description) = GameData.getBattleCardDescription(
        card.data,
        isDetailed: true,
        showAffixes: false,
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
      setSpreadCenter(card, true);
    };

    card.onMouseExit = () {
      card.setFocused(false);
      card.showGlow = false;
      Hovertip.hide(card);
      setSpreadCenter(card, false);
    };
  }

  void clearCardInteraction(CustomGameCard card) {
    card.enableGesture = false;
    card.onTapUp = null;
    card.onMouseEnter = null;
    card.onMouseExit = null;
  }
}
