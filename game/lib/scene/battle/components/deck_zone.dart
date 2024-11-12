import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';
// import 'package:samsara/paint.dart';

import '../../../ui.dart';
// import '../../../global.dart';
// import 'character.dart';

class BattleDeck extends PiledZone {
  int _currentFocusedCardIndex = -1;

  BattleDeck({
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
      card.enablePreview = true;
      if (!card.isMounted) {
        gameRef.world.add(card);
      }
    }
  }

  Future<GameCard> nextCard() async {
    ++_currentFocusedCardIndex;
    if (_currentFocusedCardIndex >= cards.length) {
      _currentFocusedCardIndex = 0;
    }
    final card = cards[_currentFocusedCardIndex];
    await card.setFocused(true);

    return card;
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
