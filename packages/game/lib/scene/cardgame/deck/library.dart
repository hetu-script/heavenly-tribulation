import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:samsara/paint/paint.dart';

import '../../../global.dart';
import '../common.dart';

class Library extends GameComponent with HandlesGesture {
  Sprite? cardStackBackSprite;

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
  /// 调用此方法前，必须先赋值 [cardStackBackSprite]
  PlayingCard? addCard(String cardId) {
    assert(cardStackBackSprite != null);

    PlayingCard? card = _library[cardId];
    if (card != null) {
      ++card.stack;
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
        title: cardData['title'][engine.locale.languageId],
        description: cardData['rules'][engine.locale.languageId],
        width: kLibraryCardWidth,
        height: kLibraryCardHeight,
        frontSpriteId: spriteId,
        showTitle: true,
        titleStyle: const ScreenTextStyle(
          colorTheme: ScreenTextColorTheme.dark,
          anchor: Anchor.topLeft,
          padding: EdgeInsets.only(left: 12, top: 8),
        ),
        showStack: true,
        stackStyle: ScreenTextStyle(
          backgroundSprite: cardStackBackSprite,
        ),
        showDescription: true,
      );

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

      _library[cardId] = card;
      return card;
    }
  }

  void removeCard(String cardId) {
    PlayingCard? card = _library[cardId];

    if (card != null && card.stack > 1) {
      --card.stack;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
