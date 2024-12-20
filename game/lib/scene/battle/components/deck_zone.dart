import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';
// import 'package:samsara/paint.dart';
import 'package:samsara/components/tooltip.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/paint/paint.dart';

import '../../../ui.dart';
// import '../../../global.dart';
// import 'character.dart';

class BattleDeckZone extends PiledZone with HandlesGesture {
  int _currentFocusedCardIndex = -1;

  BattleDeckZone({
    required super.position,
    super.cards,
    super.focusedPosition,
    super.pileStructure,
    required super.reverseX,
  }) : super(
          size: GameUI.battleDeckZoneSize,
          piledCardSize: GameUI.battleCardSize,
          pileMargin: Vector2(10, 10),
          pileOffset: Vector2(GameUI.battleCardSize.x / 3 * 2, 0),
          focusedSize: GameUI.battleCardFocusedSize,
        );

  @override
  void onLoad() {
    for (final card in cards) {
      if (!card.isMounted) {
        gameRef.world.add(card);
      }

      card.onPreviewed = () {
        Tooltip.show(
          scene: game,
          target: card,
          direction: TooltipDirection.topLeft,
          content: (card as CustomGameCard).extraDescription,
          config: ScreenTextConfig(anchor: Anchor.topCenter),
        );
      };

      card.onUnpreviewed = () {
        if (!card.isFocused) {
          Tooltip.hide();
        }
      };
    }
  }

  Future<GameCard> nextCard() async {
    ++_currentFocusedCardIndex;
    if (_currentFocusedCardIndex >= cards.length) {
      _currentFocusedCardIndex = 0;
      for (final card in cards) {
        card.isEnabled = true;
      }
    }

    return cards[_currentFocusedCardIndex];
  }

  void reset() {
    _currentFocusedCardIndex = -1;

    for (final card in cards) {
      if (card.isFocused) {
        card.setFocused(false);
      }
    }
  }

  // @override
  // void render(Canvas canvas) {
  //   canvas.drawRRect(rrect, PredefinedPaints.light);
  // }
}
