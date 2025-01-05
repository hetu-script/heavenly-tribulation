import 'dart:async';
import 'dart:math' as math;

// import 'package:flutter/material.dart';
// import 'package:flame/rendering.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
// import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/components/hovertip.dart';

import '../../../data.dart';
import '../../../ui.dart';
import 'deckbuilding_zone.dart';
import 'common.dart';
import '../../../engine.dart';
import 'cardcrafting_area.dart';

// 可以无限制使用的卡牌
// const Set<String> unlimitedCardIds = {
//   'attack_normal',
// };

/// 卡牌收藏界面，和普通的 PiledZone 不同，
/// 这里的卡牌是多行显示，并且带有翻页功能。
class CardLibraryZone extends BorderComponent with HandlesGesture {
  static const _indent = 20.0;
  // static final _firstCardPos = Vector2(_indent, kDeckZoneHeight + _indent);

  // late final SpriteComponent background;

  double _leftIndent = 0.0;

  DeckBuildingZone? _buildingZone;
  set buildingZone(DeckBuildingZone? zone) {
    _buildingZone = zone;

    if (zone != null) {
      for (final card in zone.cards) {
        setCardEnabledById(card.deckId, false);
      }
    }
  }

  CardCraftingArea? craftingArea;

  DeckBuildingZone? get buildingZone => _buildingZone;

  Sprite? stackSprite;

  CustomGameCard? draggingCard;

  // 卡库，key是 id（不是deckID），value是component
  final Map<String, CustomGameCard> library = {};

  final List<Vector2> _cardPositions = [];
  late int _cardsLimitInRow;
  int _curCardPosX = 0, _curCardPosY = 0, _curRows = 1;
  double _virtualHeight = 0;

  double _curYOffset = 0;

  List<DeckBuildingZone> preloadBuildingZones = [];

  @override
  void onMount() {
    super.onMount();

    for (final zone in preloadBuildingZones) {
      for (final cardId in zone.preloadCardIds) {
        final card = library[cardId];
        assert(card != null, 'Card $cardId not found in library');
        final clone = card!.clone();
        game.world.add(clone);
        zone.addCard(clone, animated: false);
      }
      zone.collapse(animated: false);
    }
  }

  CardLibraryZone({
    Sprite? stackSprite,
    super.priority,
  }) : super(
          position: GameUI.libraryZonePosition,
          size: GameUI.libraryZoneSize,
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
      if (component is CustomGameCard) {
        if (buildingZone != null && buildingZone!.cards.contains(component)) {
          setCardEnabledById(component.deckId, true);
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

  void setCardEnabledById(String deckId, [bool isEnabled = true]) {
    assert(library.containsKey(deckId));
    final card = library[deckId]!;
    card.isEnabled = isEnabled;
    // card.enableGesture = isEnabled;
  }

  void _calculateVirtualHeight() {
    _virtualHeight = math.max(
        _curRows * (GameUI.libraryCardSize.y + GameUI.indent) + GameUI.indent,
        GameUI.libraryZoneSize.y);
  }

  void _reposition(double offsetY) {
    if (_virtualHeight <= GameUI.libraryZoneSize.y) return;
    if (offsetY == 0) return;

    _curYOffset += offsetY;
    final maxValue = _virtualHeight - GameUI.libraryZoneSize.y;
    if (_curYOffset < -maxValue) {
      _curYOffset = -maxValue;
    }
    if (_curYOffset >= 0) {
      _curYOffset = 0;
    }

    _curCardPosX = 0;
    _curCardPosY = 0;
    _curRows = 1;
    _cardPositions.clear();
    for (final card in library.values) {
      _generateNextCardPosition();
      card.position = _cardPositions.last.clone();
    }
  }

  @override
  Future<void> onLoad() async {
    stackSprite ??= Sprite(await Flame.images.load('cardstack_back.png'));

    // background = SpriteComponent(
    //   sprite: Sprite(await Flame.images.load('cultivation/bg_library.png')),
    //   size: size,
    // );
    // add(background);
    final hero = engine.hetu.fetch('hero');
    final libraryData = hero['cardLibrary'];

    for (final cardData in libraryData.values) {
      final card = addCardByData(cardData);
      // 这里要直接加到世界上而非library管理，因为卡牌可能会在不同的区域之间拖动
      // 这样的话如果卡牌改变了区域，不用考虑修改其相对位置和父组件的问题
      game.world.add(card);
    }
  }

  bool containsCard(String cardId) => library.containsKey(cardId);

  void _generateNextCardPosition() {
    final posX = GameUI.libraryZonePosition.x +
        _leftIndent +
        (_curCardPosX * GameUI.libraryCardSize.x) +
        (_curCardPosX * _indent);
    final posY = GameUI.libraryZonePosition.y +
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

  CustomGameCard addCardByData(dynamic data) {
    final card = GameData.createBattleCardFromData(data);
    // add(card);
    card.size = GameUI.libraryCardSize;

    assert(_cardPositions.isNotEmpty &&
        _cardPositions.length == library.length + 1);
    card.position = _cardPositions.last.clone();
    _generateNextCardPosition();

    void release() {
      draggingCard?.removeFromParent();
      draggingCard = null;
    }

    card.onTapDown = (int buttons, Vector2 position) {
      void cloneCard() {
        final CustomGameCard clone = card.clone();
        clone.enableGesture = false;
        clone.priority = kDraggingCardPriority;
        game.world.add(clone);
        draggingCard = clone;
      }

      Hovertip.hide(card);
      if (buttons == kPrimaryButton) {
        if (!card.isEnabled) return;
        if (buildingZone != null) {
          if (buildingZone!.isFull) return;
          cloneCard();
        } else if (craftingArea != null) {
          if (craftingArea!.isFull) return;
          cloneCard();
        }
      }
    };
    card.onTapUp = (int buttons, __) async {
      if (!card.isEnabled) return;
      if (buttons == kPrimaryButton) {
        if (buildingZone != null) {
          release();
          if (buildingZone!.isFull) return;
          final c = card.clone();
          game.world.add(c);
          buildingZone!.addCard(c);
          card.isEnabled = false;
        } else if (craftingArea != null) {
          release();
          final c = card.clone();
          game.world.add(c);
          craftingArea!.addCard(c);
          card.isEnabled = false;
        }
      }
    };

    // 返回实际被拖动的卡牌，以覆盖这个scene上的dragging component
    card.onDragStart = (buttons, dragPosition) => draggingCard;
    card.onDragUpdate =
        (int buttons, Vector2 offset) => draggingCard?.position += offset;

    card.onDragEnd = (_, __) {
      release();
    };

    card.onPreviewed = (component) {
      Hovertip.show(
        scene: game,
        target: component,
        direction: HovertipDirection.rightTop,
        content: card.extraDescription,
        config: ScreenTextConfig(anchor: Anchor.topCenter),
      );
    };

    card.onUnpreviewed = (component) {
      Hovertip.hide(component);
    };

    library[card.id] = card;

    return card;
  }

  /// 向牌库中添加卡牌，如果已存在，就返回false
  // GameCard? addCardById(String cardId) {
  //   GameCard? card = _library[cardId];
  //   if (card == null) {
  //     card = GameData.getBattleCard(cardId);

  //     assert(_cardPositions.isNotEmpty &&
  //         _cardPositions.length == _library.length + 1);
  //     card.position = _cardPositions.last.clone();
  //     _generateNextCardPosition();

  //     void release() {
  //       draggingCard?.removeFromParent();
  //       draggingCard = null;
  //     }

  //     card.onTapDown = (int buttons, Vector2 position) {
  //       final GameCard clone = card!.clone();
  //       clone.enableGesture = false;
  //       clone.priority = kDraggingCardPriority;
  //       gameRef.world.add(clone);
  //       draggingCard = clone;
  //     };
  //     card.onTapUp = (_, __) {
  //       release();
  //       assert(buildingZone != null);
  //       final c = card!.clone();
  //       gameRef.world.add(c);
  //       buildingZone!.addCard(c);
  //       if (!unlimitedCardIds.contains(card.deckId)) {
  //         card.isEnabled = false;
  //       }
  //     };

  //     // 覆盖这个scene上的dragging component
  //     card.onDragStart = (buttons, dragPosition) => draggingCard;
  //     card.onDragUpdate = (int buttons, Vector2 offset) {
  //       draggingCard!.position += offset;
  //     };

  //     card.onDragEnd = (_, __) {
  //       release();
  //     };

  //     _library[cardId] = card;
  //     return card;
  //   } else {
  //     ++card.stack;
  //     return null;
  //   }
  // }
}
