import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';

import '../common.dart';

class DeckZone extends PiledZone {
  int currentFocusedCardIndex = -1;

  DeckZone({
    super.id,
    required super.x,
    required super.y,
    super.cards,
    // super.focusOffset,
    super.titleAnchor = Anchor.topRight,
  }) : super(
          width: kDeckZoneWidth,
          height: kDeckZoneHeight,
          piledCardSize: kCardSize,
        );

  void setNextCardFocused() {
    ++currentFocusedCardIndex;
    if (currentFocusedCardIndex >= cards.length) {
      currentFocusedCardIndex = 0;
    }
    final card = cards[currentFocusedCardIndex];
    card.setFocused(true);

    int previousIndex = currentFocusedCardIndex - 1;
    if (previousIndex < 0) {
      previousIndex = cards.length - 1;
    }
    final previousCard = cards[previousIndex];
    previousCard.setFocused(false);
  }
}
