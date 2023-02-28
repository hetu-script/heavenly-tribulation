import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/cardgame/playing_card.dart';

import '../../../global.dart';
import '../common.dart';

class Library extends GameComponent with HandlesGesture {
  final Map<String, PlayingCard> _library = {};

  late int cardsLimitInRow;
  late Vector2 currentCardPosition;
  int currentCardPosInRow = 0, currentCardPosInColumn = 0;

  Library({
    super.position,
    super.size,
  }) {
    currentCardPosition = Vector2(10, y + 10);
    calculateArray();
  }

  void calculateArray() {
    cardsLimitInRow = (width / kCardWidth).floor();
    assert(cardsLimitInRow > 0);
  }

  bool containsCard(String cardId) => _library.containsKey(cardId);

  /// 向牌库中添加卡牌，如果已存在，就返回false
  PlayingCard? addCard(String cardId) {
    PlayingCard? card = _library[cardId];
    if (card != null) {
      ++card.count;
      return null;
    } else {
      final cardData = cardsData[cardId];

      final expansion = cardData['expansion'];
      String? spriteId = cardData['spriteId'];
      if (spriteId != null) {
        spriteId = expansion != null ? '$expansion/$spriteId' : spriteId;
      }

      card = PlayingCard(
        id: cardData['id'],
        width: kLibraryCardWidth,
        height: kLibraryCardHeight,
        frontSpriteId: spriteId,
        countDecorSpriteId: 'cardcount',
        showCount: true,
      );
      _library[cardId] = card;

      void generateNextPosition() {
        ++currentCardPosInRow;
        if (currentCardPosInRow > cardsLimitInRow) {
          currentCardPosInRow = 0;
          ++currentCardPosInColumn;
        }

        currentCardPosition.x = 10 +
            (currentCardPosInRow * kLibraryCardWidth) +
            (currentCardPosInRow * 10);
        currentCardPosition.y = y +
            10 +
            (currentCardPosInColumn * kLibraryCardHeight) +
            (currentCardPosInColumn * 10);
      }

      card.position = currentCardPosition.clone();
      generateNextPosition();

      return card;
    }
  }

  void removeCard(String cardId) {
    PlayingCard? card = _library[cardId];

    if (card != null && card.count > 1) {
      --card.count;
    }
  }
}
