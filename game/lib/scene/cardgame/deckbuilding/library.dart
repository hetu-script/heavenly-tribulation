import 'dart:async';

import 'package:flame/sprite.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/playing_card.dart';

import '../../../global.dart';
import '../common.dart';

/// 卡牌收藏界面，和普通的 PiledZone 不同，
/// 这里的卡牌是多行显示，并且带有翻页功能。
class Library extends GameComponent {
  static const _indent = 10.0;
  // static final _firstCardPos = Vector2(_indent, kDeckZoneHeight + _indent);

  late int _cardsLimitInRow;
  late Vector2 _curCardPos;
  int _curCardPosX = 0, _curCardPosY = 0;

  final Map<String, PlayingCard> _library = {};
  Library({
    super.position,
    super.size,
  });

  @override
  FutureOr<void> onLoad() {
    calculateArray();
  }

  void calculateArray() {
    _curCardPos = Vector2(_indent, kDeckZoneHeight + _indent);
    _cardsLimitInRow = (width / kBattleCardWidth).floor();
    assert(_cardsLimitInRow > 0);
  }

  bool containsCard(String cardId) => _library.containsKey(cardId);

  void _generateNextPosition() {
    ++_curCardPosX;
    if (_curCardPosX > _cardsLimitInRow) {
      _curCardPosX = 0;
      ++_curCardPosY;
    }

    _curCardPos.x =
        _indent + (_curCardPosX * kLibraryCardWidth) + (_curCardPosX * 10);
    _curCardPos.y = kDeckZoneHeight +
        _indent +
        (_curCardPosY * kLibraryCardHeight) +
        (_curCardPosY * 10);
  }

  /// 向牌库中添加卡牌，如果已存在，就返回false
  PlayingCard? addCard(String cardId, Sprite cardStackBackSprite) {
    PlayingCard? card = _library[cardId];
    if (card != null) {
      ++card.stack;
      return null;
    } else {
      final cardData = cardsData[cardId];
      assert(cardData != null);

      final expansion = cardData['expansion'];
      String? spriteId = cardData['spriteId'];
      if (spriteId != null) {
        spriteId = expansion != null ? '$expansion/$spriteId' : spriteId;
      }

      card = PlayingCard(
        id: cardData['id'],
        title: cardData['title'][engine.locale.languageId],
        description: cardData['rules'][engine.locale.languageId],
        size: kLibraryCardSize,
        frontSpriteId: spriteId,
        showTitle: true,
        titleStyle: const ScreenTextStyle(
          colorTheme: ScreenTextColorTheme.dark,
          anchor: Anchor.topLeft,
          padding: EdgeInsets.only(left: 12, top: 8),
        ),
        showDescription: true,
        showStack: true,
        stackStyle: ScreenTextStyle(
          backgroundSprite: cardStackBackSprite,
        ),
      );

      card.position = _curCardPos.clone();
      _generateNextPosition();

      _library[cardId] = card;
      return card;
    }
  }

  void removeCard(String cardId) {
    PlayingCard? card = _library[cardId];

    if (card != null) {
      if (card.stack > 1) {
        --card.stack;
      } else {
        _library.remove(cardId);
      }
    }
  }

  void sortCards() {}

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
