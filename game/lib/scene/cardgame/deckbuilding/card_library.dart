import 'dart:async';
import 'dart:math' as math;

// import 'package:flutter/material.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:flame/flame.dart';
// import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/gestures/gesture_mixin.dart';

import '../../../global.dart';
import '../common.dart';
import 'deckbuilding_zone.dart';

/// 卡牌收藏界面，和普通的 PiledZone 不同，
/// 这里的卡牌是多行显示，并且带有翻页功能。
class CardLibrary extends GameComponent with HandlesGesture {
  static const _indent = 20.0;
  // static final _firstCardPos = Vector2(_indent, kDeckZoneHeight + _indent);

  DeckBuildingZone? buildingZone;

  Sprite? stackSprite;

  PlayingCard? draggingCard;

  final Map<String, PlayingCard> _library = {};

  void setCardDarkened(String deckId, [bool isDarkened = true]) {
    assert(_library.containsKey(deckId));
    final card = _library[deckId]!;
    card.isDarkened = isDarkened;
  }

  final List<Vector2> _cardPositions = [];
  late int _cardsLimitInRow;
  int _curCardPosX = 0, _curCardPosY = 0, _curRows = 1;
  double _curVirtualHeight = 0;

  void _calculateVirtualHeight() {
    _curVirtualHeight = math.max(
        _curRows * (kCardIndent + kLibraryCardHeight) + kCardIndent,
        kLibraryHeight);
  }

  int _curYOffset = 0;

  CardLibrary({
    Sprite? stackSprite,
  }) : super(
          position: kLibraryPosition,
          size: kLibrarySize,
          // piledCardSize: kLibraryCardSize,
          // pileOffset: kDeckZonePileOffset,
          // pileMargin: Vector2(_indent, _indent),
        ) {
    if (stackSprite != null) this.stackSprite = stackSprite;

    _cardsLimitInRow = (width / (kLibraryCardWidth + _indent)).floor();
    _calculateVirtualHeight();
    _generateNextCardPosition();
    assert(_cardsLimitInRow > 0);

    onDragIn = (int buttons, Vector2 position, GameComponent c) {
      if (c is PlayingCard) {
        if (buildingZone != null && buildingZone!.containsCard(c.deckId)) {
          setCardDarkened(c.deckId, false);
          c.removeFromPile();
          c.removeFromParent();
        }
      }
    };

    onMouseScrollUp = () {
      _curYOffset += 100;
      if (_curYOffset >= 0) _curYOffset = 0;
      _repositionCards();
    };
    onMouseScrollDown = () {
      _curYOffset -= 100;
      if ((_curVirtualHeight + _curYOffset) < kLibraryHeight) _curYOffset = 0;
      _repositionCards();
    };
  }

  @override
  FutureOr<void> onLoad() async {
    stackSprite ??= Sprite(await Flame.images.load('cardstack_back.png'));
  }

  bool containsCard(String cardId) => _library.containsKey(cardId);

  void _generateNextCardPosition() {
    final posX =
        _indent + (_curCardPosX * kLibraryCardWidth) + (_curCardPosX * _indent);
    final posY = kDeckZoneHeight +
        _indent +
        (_curCardPosY * kLibraryCardHeight) +
        (_curCardPosY * _indent) +
        _curYOffset;

    _cardPositions.add(Vector2(posX, posY));

    ++_curCardPosX;
    if (_curCardPosX >= _cardsLimitInRow) {
      _curCardPosX = 0;
      ++_curCardPosY;
      ++_curRows;
      _calculateVirtualHeight();
    }
  }

  void _repositionCards() {
    _curCardPosX = 0;
    _curCardPosY = 0;
    _curRows = 1;
    _cardPositions.clear();
    for (final card in _library.values) {
      _generateNextCardPosition();
      card.position = _cardPositions.last.clone();
    }
  }

  /// 向牌库中添加卡牌，如果已存在，就返回false
  PlayingCard? addCardById(String cardId) {
    PlayingCard? card = _library[cardId];
    if (card == null) {
      final cardData = cardsData[cardId];
      assert(cardData != null);
      final String id = cardData['id'];

      card = PlayingCard(
        id: id,
        deckId: id,
        // title: cardData['title'][engine.locale.languageId],
        // description: cardData['rules'][engine.locale.languageId],
        size: kLibraryCardSize,
        frameSpriteId: 'card/library/$id.png',
        // illustrationSpriteId: 'cards/illustration/$id.png',
        // illustrationHeightRatio: kCardIllustrationHeightRatio,
        // showTitle: true,
        // titleStyle: const ScreenTextStyle(
        //   colorTheme: ScreenTextColorTheme.light,
        //   anchor: Anchor.topCenter,
        //   padding: EdgeInsets.only(
        //       top: kLibraryCardHeight * kCardIllustrationHeightRatio),
        //   textStyle: TextStyle(fontSize: 16),
        // ),
        // showDescription: true,
        // descriptionStyle: const ScreenTextStyle(
        //   colorTheme: ScreenTextColorTheme.dark,
        // ),
      );

      assert(_cardPositions.isNotEmpty &&
          _cardPositions.length == _library.length + 1);
      card.position = _cardPositions.last.clone();
      _generateNextCardPosition();

      card.onTapDown = (int buttons, Vector2 position) {
        if (card!.isDarkened) return;
        final PlayingCard clone = card.clone();
        clone.enableGesture = false;
        clone.priority = kDraggingCardPriority;
        gameRef.world.add(clone);
        draggingCard = clone;
      };
      // 覆盖这个scene上的dragging component
      card.onDragStart = (buttons, dragPosition) => draggingCard;
      card.onDragUpdate = (buttons, dragPosition, dragOffset) {
        if (card!.isDarkened) return;
        draggingCard!.position += dragOffset;
      };

      void release() {
        draggingCard?.removeFromParent();
        draggingCard = null;
      }

      card.onTapUp = (_, __) {
        release();
        if (buildingZone != null) {
          buildingZone!.addCard(card!);
        }
      };
      card.onDragEnd = (_, __, ___) {
        release();
      };

      _library[cardId] = card;
      return card;
    } else {
      ++card.stack;
      return null;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
