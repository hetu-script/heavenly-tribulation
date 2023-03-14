import 'package:samsara/cardgame/cardgame.dart';
import 'package:flame/components.dart';

import '../common.dart';
import '../../../global.dart';
import 'character.dart';

class DeckZone extends PiledZone {
  int currentFocusedCardIndex = -1;

  DeckZone({
    super.id,
    required super.position,
    super.cards,
    // super.focusOffset,
    super.titleAnchor = Anchor.topRight,
    super.pileMargin,
    super.pileOffset,
  }) : super(
          size: kBattleDeckZoneSize,
          piledCardSize: kBattleCardSize,
        );

  void nextCard(BattleCharacter hero, BattleCharacter opponent) {
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
    if (previousIndex != currentFocusedCardIndex) {
      final previousCard = cards[previousIndex];
      previousCard.setFocused(false);
    }

    engine.invoke(card.data['script'],
        namespace: 'Card', positionalArgs: [hero, opponent]);
  }
}
