import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';
// import 'package:samsara/paint.dart';

import '../../../ui.dart';
// import '../../../global.dart';
// import 'character.dart';

class BattleDeck extends PiledZone {
  int? previouslyFocusedCardIndex;
  int currentFocusedCardIndex = -1;

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
          pileOffset: Vector2(GameUI.battleCardSize.x / 2, 0),
          focusedSize: GameUI.battleCardFocusedBSize,
        );

  @override
  void onLoad() {
    for (final card in cards) {
      gameRef.world.add(card);
    }
  }

  Future<PlayingCard> nextCard() async {
    ++currentFocusedCardIndex;
    if (currentFocusedCardIndex >= cards.length) {
      currentFocusedCardIndex = 0;
    }
    final card = cards[currentFocusedCardIndex];
    await card.setFocused(true);

    return card;
  }

  // @override
  // void render(Canvas canvas) {
  //   canvas.drawRRect(rborder, DefaultBorderPaint.light);
  // }
}
