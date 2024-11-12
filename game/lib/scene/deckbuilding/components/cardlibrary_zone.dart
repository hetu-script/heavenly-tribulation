import 'dart:async';
import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:flame/rendering.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/card.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
// import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/gestures/gesture_mixin.dart';

import '../../../data.dart';
import '../../../ui.dart';
import 'deckbuilding_zone.dart';

const kDraggingCardPriority = 2000;
// 可以无限制使用的卡牌
const Set<String> unlimitedCardIds = {
  'attack_normal',
};

/// 卡牌收藏界面，和普通的 PiledZone 不同，
/// 这里的卡牌是多行显示，并且带有翻页功能。
class CardLibraryZone extends GameComponent with HandlesGesture {
  static const _indent = 20.0;
  // static final _firstCardPos = Vector2(_indent, kDeckZoneHeight + _indent);

  late final SpriteComponent background;

  double _leftIndent = 0.0;

  DeckBuildingZone? buildingZone;

  Sprite? stackSprite;

  GameCard? draggingCard;

  final Map<String, GameCard> _library = {};

  void setCardEnabledById(String deckId, [bool isEnabled = true]) {
    assert(_library.containsKey(deckId));
    final card = _library[deckId]!;
    card.isEnabled = isEnabled;
  }

  final List<Vector2> _cardPositions = [];
  late int _cardsLimitInRow;
  int _curCardPosX = 0, _curCardPosY = 0, _curRows = 1;
  double _virtualHeight = 0;

  void _calculateVirtualHeight() {
    _virtualHeight = math.max(
        _curRows * (GameUI.libraryCardSize.y + GameUI.indent) + GameUI.indent,
        GameUI.librarySize.y);
  }

  double _curYOffset = 0;

  CardLibraryZone({
    Sprite? stackSprite,
  }) : super(
          position: GameUI.libraryPosition,
          size: GameUI.librarySize,
          // piledCardSize: kLibraryCardSize,
          // pileOffset: kDeckZonePileOffset,
          // pileMargin: Vector2(_indent, _indent),
        ) {
    if (stackSprite != null) this.stackSprite = stackSprite;

    _cardsLimitInRow = (width / (GameUI.libraryCardSize.x + _indent)).floor();
    _calculateVirtualHeight();
    _leftIndent = (size.x -
            (GameUI.libraryCardSize.x * _cardsLimitInRow +
                GameUI.indent * (_cardsLimitInRow - 1))) /
        2;
    _generateNextCardPosition();
    assert(_cardsLimitInRow > 0);

    onDragIn = (int buttons, Vector2 position, GameComponent? component) {
      if (component is GameCard) {
        if (buildingZone != null &&
            buildingZone!.containsCard(component.deckId)) {
          setCardEnabledById(component.deckId, false);
          component.removeFromPile();
        }
      }
    };

    onMouseScrollUp = () => _reposition(100);
    onMouseScrollDown = () => _reposition(-100);

    onDragUpdate = (int buttons, Vector2 offset) {
      _reposition(offset.y);
    };
  }

  void _reposition(double offsetY) {
    if (_virtualHeight <= GameUI.librarySize.y) return;
    if (offsetY == 0) return;

    _curYOffset += offsetY;
    final maxValue = _virtualHeight - GameUI.librarySize.y;
    if (_curYOffset < -maxValue) {
      _curYOffset = -maxValue;
    }
    if (_curYOffset >= 0) {
      _curYOffset = 0;
    }
    _repositionCards();
  }

  @override
  Future<void> onLoad() async {
    stackSprite ??= Sprite(await Flame.images.load('cardstack_back.png'));

    background = SpriteComponent(
      sprite: Sprite(
          await Flame.images.load('cultivation/deckbuilding/library.png')),
      size: size,
    );
    add(background);
  }

  bool containsCard(String cardId) => _library.containsKey(cardId);

  void _generateNextCardPosition() {
    final posX = _leftIndent +
        (_curCardPosX * GameUI.libraryCardSize.x) +
        (_curCardPosX * _indent);
    final posY = GameUI.deckbuildingZoneSize.y +
        _indent +
        (_curCardPosY * GameUI.libraryCardSize.y) +
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
  GameCard? addCardById(String cardId) {
    GameCard? card = _library[cardId];
    if (card == null) {
      card = GameData.getBattleCard(cardId);

      assert(_cardPositions.isNotEmpty &&
          _cardPositions.length == _library.length + 1);
      card.position = _cardPositions.last.clone();
      _generateNextCardPosition();

      void release() {
        draggingCard?.removeFromParent();
        draggingCard = null;
      }

      card.onTapDown = (int buttons, Vector2 position) {
        final GameCard clone = card!.clone();
        clone.enableGesture = false;
        clone.priority = kDraggingCardPriority;
        gameRef.world.add(clone);
        draggingCard = clone;
      };
      card.onTapUp = (_, __) {
        release();
        assert(buildingZone != null);
        final c = card!.clone();
        gameRef.world.add(c);
        buildingZone!.addCard(c);
        if (!unlimitedCardIds.contains(card.deckId)) {
          card.isEnabled = false;
        }
      };

      // 覆盖这个scene上的dragging component
      card.onDragStart = (buttons, dragPosition) => draggingCard;
      card.onDragUpdate = (int buttons, Vector2 offset) {
        draggingCard!.position += offset;
      };

      card.onDragEnd = (_, __) {
        release();
      };

      _library[cardId] = card;
      return card;
    } else {
      ++card.stack;
      return null;
    }
  }

  // @override
  // void render(Canvas canvas) {
  //   canvas.drawRect(border, PredefinedPaints.light);
  // }
}
