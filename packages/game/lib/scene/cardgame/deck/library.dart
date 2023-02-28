import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/cardgame/playing_card.dart';

import '../../../global.dart';
import '../common.dart';

class Library extends GameComponent with HandlesGesture {
  final Map<String, PlayingCard> _library = {};

  late int cardsLimitInRow;
  Vector2 currentPosition = Vector2(10, 10);
  int currentPosInRow = 0, currentPosInColumn = 0;

  Library({
    super.position,
    super.size,
  }) {
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
      );
      _library[cardId] = card;

      void generateNextPosition() {
        ++currentPosInRow;
        if (currentPosInRow > cardsLimitInRow) {
          currentPosInRow = 0;
          ++currentPosInColumn;
        }

        currentPosition.x =
            10 + (currentPosInRow * kLibraryCardWidth) + (currentPosInRow * 10);
        currentPosition.y = 10 +
            (currentPosInColumn * kLibraryCardHeight) +
            (currentPosInColumn * 10);
      }

      card.position = currentPosition.clone();
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
