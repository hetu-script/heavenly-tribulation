import 'dart:async';
import 'dart:math' as math;

import 'package:samsara/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:samsara/gestures.dart';
// import 'package:samsara/components/hovertip.dart';

import '../../game/data.dart';
import '../../game/ui.dart';
import 'deckbuilding_zone.dart';
import '../common.dart';
import '../../engine.dart';
// import 'cardcrafting_area.dart';
import '../game_dialog/game_dialog_content.dart';
import 'menus.dart';
import 'card_library.dart';

/// 卡牌收藏界面，和普通的 PiledZone 不同，
/// 这里的卡牌是多行显示，并且带有翻页功能。
class CardLibraryZone extends GameComponent with HandlesGesture {
  static const _indent = 20.0;
  // static final _firstCardPos = Vector2(_indent, kDeckZoneHeight + _indent);

  // late final SpriteComponent background;

  double _leftIndent = 0.0;

  late final PositionComponent container;

  DeckBuildingZone? _buildingZone;
  set buildingZone(DeckBuildingZone? zone) {
    _buildingZone = zone;

    if (zone != null) {
      for (final card in zone.cards) {
        setCardEnabledById(card.deckId, false);
      }
    }
  }

  // CardCraftingArea? craftingArea;

  DeckBuildingZone? get buildingZone => _buildingZone;

  Sprite? stackSprite;

  // 卡库，key是 id（不是deckID），value是component
  final Map<String, CustomGameCard> library = {};

  final List<Vector2> _cardPositions = [];
  late int _cardsLimitInRow;
  int _curCardPosX = 0, _curCardPosY = 0, _curRows = 1;

  OrderByOptions _orderByOptions = OrderByOptions.byAcquiredTimeDescending;
  OrderByOptions get orderByOption => _orderByOptions;

  List<DeckBuildingZone> preloadBuildingZones = [];

  void Function(CustomGameCard card)? onCardPreviewed;
  void Function()? onCardUnpreviewed;

  @override
  void onMount() {
    super.onMount();

    for (final zone in preloadBuildingZones) {
      for (final cardId in zone.preloadCardIds) {
        final card = library[cardId];
        assert(card != null, 'Card $cardId not found in library');
        zone.tryAddCard(card!, animated: false, clone: true);
      }
      zone.collapse(animated: false);
    }
  }

  CardLibraryZone({
    Sprite? stackSprite,
    super.priority,
    this.onCardPreviewed,
    this.onCardUnpreviewed,
  }) : super(
          position: GameUI.libraryZonePosition,
          size: GameUI.libraryZoneSize,
        ) {
    if (stackSprite != null) this.stackSprite = stackSprite;

    _cardsLimitInRow =
        (GameUI.libraryZoneSize.x / (GameUI.libraryCardSize.x + _indent))
            .floor();
    _leftIndent = (GameUI.libraryZoneSize.x -
            (GameUI.libraryCardSize.x * _cardsLimitInRow +
                GameUI.indent * (_cardsLimitInRow - 1))) /
        2;
    assert(_cardsLimitInRow > 0);

    onDragIn = (int buttons, Vector2 position, GameComponent? component) {
      if (component is CustomGameCard) {
        if (buildingZone != null && buildingZone!.cards.contains(component)) {
          setCardEnabledById(component.deckId, true);
          component.removeFromPile();
        }
      }
    };

    onMouseScrollUp = () {
      _reposition(100);
    };
    onMouseScrollDown = () {
      _reposition(-100);
    };

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

  void _calculateContainerHeight() {
    container.height = math.max(
        _curRows * (GameUI.libraryCardSize.y + GameUI.indent) + GameUI.indent,
        GameUI.libraryZoneSize.y);
  }

  void repositionToTop() {
    container.position.y = GameUI.libraryZonePosition.y;
  }

  void _reposition(double offsetY) {
    final originalPosition = container.position.y;

    if (container.height <= GameUI.libraryZoneSize.y) return;
    if (offsetY == 0) return;

    double curYOffset = container.position.y;
    curYOffset += offsetY;
    final maxValue = GameUI.libraryZonePosition.y +
        GameUI.libraryZoneSize.y -
        container.height;
    if (curYOffset < maxValue) {
      curYOffset = maxValue;
    }
    if (curYOffset >= GameUI.libraryZonePosition.y) {
      curYOffset = GameUI.libraryZonePosition.y;
    }
    container.position.y = curYOffset;

    if (container.position.y == originalPosition) return;

    // _sortCards(reset: true);
  }

  void sortCards({OrderByOptions? orderBy}) {
    _curCardPosX = 0;
    _curCardPosY = 0;
    _curRows = 1;
    _cardPositions.clear();

    if (orderBy != null) _orderByOptions = orderBy;
    List orderedList;
    switch (_orderByOptions) {
      case OrderByOptions.byAcquiredTimeDescending:
        orderedList = library.values.toList()
          ..sort((a, b) =>
              b.data['acquiredSequence'].compareTo(a.data['acquiredSequence']));
      case OrderByOptions.byAcquiredTimeAscending:
        orderedList = library.values.toList()
          ..sort((a, b) =>
              a.data['acquiredSequence'].compareTo(b.data['acquiredSequence']));
      case OrderByOptions.byLevelDescending:
        orderedList = library.values.toList()
          ..sort((a, b) {
            final aL = a.data['level'];
            final bL = b.data['level'];
            if (aL != bL) {
              return bL.compareTo(aL);
            } else {
              return b.data['rank'].compareTo(a.data['rank']);
            }
          });
      case OrderByOptions.byLevelAscending:
        orderedList = library.values.toList()
          ..sort((a, b) {
            final aL = a.data['level'];
            final bL = b.data['level'];
            if (aL != bL) {
              return aL.compareTo(bL);
            } else {
              return a.data['rank'].compareTo(b.data['rank']);
            }
          });
      case OrderByOptions.byRankDescending:
        orderedList = library.values.toList()
          ..sort((a, b) {
            final aR = a.data['rank'];
            final bR = b.data['rank'];
            if (aR != bR) {
              return bR.compareTo(aR);
            } else {
              return b.data['level'].compareTo(a.data['level']);
            }
          });
      case OrderByOptions.byRankAscending:
        orderedList = library.values.toList()
          ..sort((a, b) {
            final aR = a.data['rank'];
            final bR = b.data['rank'];
            if (aR != bR) {
              return aR.compareTo(bR);
            } else {
              return a.data['level'].compareTo(b.data['level']);
            }
          });
    }

    for (final card in orderedList) {
      card.position = _generateNextCardPosition();
    }
  }

  void updateHeroLibrary() {
    final libraryData = GameData.heroData['cardLibrary'];
    for (final cardData in libraryData.values) {
      if (library.containsKey(cardData['id'])) continue;
      addCardByData(cardData);
    }
    _calculateContainerHeight();
    sortCards();
  }

  @override
  Future<void> onLoad() async {
    stackSprite ??= Sprite(await Flame.images.load('cardstack_back.png'));

    container = PositionComponent(
      position: GameUI.libraryZonePosition,
      size: GameUI.libraryZoneSize,
    );
    game.world.add(container);

    updateHeroLibrary();
  }

  bool containsCard(String cardId) => library.containsKey(cardId);

  Vector2 _generateNextCardPosition() {
    final posX = _leftIndent +
        (_curCardPosX * GameUI.libraryCardSize.x) +
        (_curCardPosX * _indent);
    final posY = _indent +
        (_curCardPosY * GameUI.libraryCardSize.y) +
        (_curCardPosY * _indent);

    ++_curCardPosX;
    if (_curCardPosX >= _cardsLimitInRow) {
      _curCardPosX = 0;
      ++_curCardPosY;
      ++_curRows;
      _calculateContainerHeight();
    }

    final pos = Vector2(posX, posY);
    _cardPositions.add(pos);

    return pos.clone();
  }

  CustomGameCard addCardByData(dynamic data) {
    final card = GameData.createBattleCardFromData(data);
    container.add(card);
    // add(card);
    card.size = GameUI.libraryCardSize;

    // assert(_cardPositions.isNotEmpty &&
    //     _cardPositions.length == library.length + 1);
    card.position = _generateNextCardPosition();

    card.onTapDown = (int buttons, Vector2 position) {
      if (buttons == kPrimaryButton) {
        if (!card.isEnabled) return;
        if (buildingZone != null) {
          if (buildingZone!.isFull) return;
          (game as CardLibraryScene).cardDragStart(card);
        }
        // else if (craftingArea != null) {
        //   if (craftingArea!.isFull) return;
        //   (game as CardLibraryScene).cardDragStart(card);
        // }
      }
    };

    card.onTapUp = (int buttons, __) async {
      if (!card.isEnabled) return;
      if (buttons == kPrimaryButton) {
        if (buildingZone != null) {
          // || craftingArea != null) {
          String? result = buildingZone!.tryAddCard(card, clone: true);
          // else if (craftingArea != null) {
          //   result = craftingArea!.tryAddCard(card, clone: true);
          // }
          if (result != null) {
            GameDialogContent.show(game.context, engine.locale(result));
          } else {
            engine.play(GameSound.cardDealt);
            card.isEnabled = false;
          }
        }
        (game as CardLibraryScene).cardDragRelease();
      } else if (buttons == kSecondaryButton) {
        (game as CardLibraryScene).onStartCraft(card);
      }
    };

    // 返回实际被拖动的卡牌，以覆盖这个scene上的dragging component
    card.onDragStart =
        (buttons, dragPosition) => (game as CardLibraryScene).draggingCard;
    card.onDragUpdate = (int buttons, Vector2 offset) =>
        (game as CardLibraryScene).draggingCard?.position += offset;
    card.onDragEnd = (_, __) {
      (game as CardLibraryScene).cardDragRelease();
    };
    card.onPreviewed = () => previewCard(
          game.context,
          'library_card_${card.id}',
          card.data,
          card.toAbsoluteRect(),
          characterData: GameData.heroData,
        );
    card.onUnpreviewed = () => unpreviewCard(game.context);

    library[card.id] = card;

    return card;
  }
}
