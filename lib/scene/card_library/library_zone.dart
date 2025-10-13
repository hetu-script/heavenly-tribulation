import 'dart:async';
import 'dart:math' as math;

import 'package:samsara/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:samsara/gestures.dart';
// import 'package:samsara/components/hovertip.dart';

import '../../game/game.dart';
import '../../game/ui.dart';
import '../../game/logic/logic.dart';
import 'deckbuilding_zone.dart';
import '../common.dart';
import '../../engine.dart';
import '../game_dialog/game_dialog_content.dart';
import 'card_library.dart';

/// 卡牌收藏界面，和普通的 PiledZone 不同，
/// 这里的卡牌是多行显示，并且带有翻页功能。
class CardLibraryZone extends GameComponent with HandlesGesture {
  // static final _firstCardPos = Vector2(_indent, kDeckZoneHeight + _indent);

  // late final SpriteComponent background;

  // double _leftIndent = 0.0;

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

  FilterByOptions _filterByOptions = FilterByOptions.all;
  FilterByOptions get filterByOptions => _filterByOptions;

  void Function(CustomGameCard card)? onCardPreviewed;
  void Function()? onCardUnpreviewed;

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
        (GameUI.libraryZoneSize.x / (GameUI.libraryCardSize.x + GameUI.indent))
            .ceil();
    // _leftIndent = (GameUI.libraryZoneSize.x -
    //         (GameUI.libraryCardSize.x * _cardsLimitInRow +
    //             GameUI.indent * (_cardsLimitInRow - 1))) /
    //     2;

    assert(_cardsLimitInRow > 0);

    // onDragIn = (int button, Vector2 position, GameComponent? component) {
    //   if (component is CustomGameCard) {
    //     if (buildingZone != null && buildingZone!.cards.contains(component)) {
    //       setCardEnabledById(component.deckId, true);
    //       component.removeFromPile();
    //     }
    //   }
    // };

    onMouseScrollUp = () {
      if ((game as CardLibraryScene).craftingCard != null) return;
      _reposition(100);
    };
    onMouseScrollDown = () {
      if ((game as CardLibraryScene).craftingCard != null) return;
      _reposition(-100);
    };

    onDragUpdate = (int button, Vector2 position, Vector2 delta) {
      if ((game as CardLibraryScene).craftingCard != null) return;
      _reposition(delta.y);
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

  void filterCards({FilterByOptions? options}) {
    if (options != null) _filterByOptions = options;

    for (final card in library.values) {
      switch (_filterByOptions) {
        case FilterByOptions.all:
          card.isFiltered = false;
        case FilterByOptions.requirementsMet:
          final requirementsMet = GameLogic.checkRequirements(card.data);
          card.isFiltered = (requirementsMet != null);
        case FilterByOptions.categoryAttack:
          card.isFiltered = (card.data['category'] != 'attack');
        case FilterByOptions.categoryBuff:
          card.isFiltered = (card.data['category'] != 'buff');
        case FilterByOptions.spellcraft:
        case FilterByOptions.swordcraft:
        case FilterByOptions.bodyforge:
        case FilterByOptions.avatar:
        case FilterByOptions.vitality:
          card.isFiltered = (card.data['genre'] != _filterByOptions.name);
        case FilterByOptions.kind_punch:
        case FilterByOptions.kind_kick:
        case FilterByOptions.kind_qinna:
        case FilterByOptions.kind_dianxue:
        case FilterByOptions.kind_sword:
        case FilterByOptions.kind_sabre:
        case FilterByOptions.kind_staff:
        case FilterByOptions.kind_spear:
        case FilterByOptions.kind_bow:
        case FilterByOptions.kind_dart:
        case FilterByOptions.kind_flying_sword:
        case FilterByOptions.kind_shenfa:
        case FilterByOptions.kind_qinggong:
        case FilterByOptions.kind_xinfa:
        case FilterByOptions.kind_airbend:
        case FilterByOptions.kind_firebend:
        case FilterByOptions.kind_waterbend:
        case FilterByOptions.kind_lightning_control:
        case FilterByOptions.kind_earthbend:
        case FilterByOptions.kind_plant_control:
        case FilterByOptions.kind_sigil:
        case FilterByOptions.kind_power_word:
        case FilterByOptions.kind_scripture:
        case FilterByOptions.kind_music:
        case FilterByOptions.kind_array:
        case FilterByOptions.kind_potion:
        case FilterByOptions.kind_scroll:
          card.isFiltered =
              (card.data['kind'] != _filterByOptions.name.substring(5));
      }

      card.isVisible = !card.isFiltered;
    }

    sortCards();
  }

  void sortCards({OrderByOptions? options}) {
    _curCardPosX = 0;
    _curCardPosY = 0;
    _curRows = 1;
    _cardPositions.clear();

    if (options != null) _orderByOptions = options;
    List<CustomGameCard> orderedList;
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
      if (card.isFiltered) {
        continue;
      }
      card.position = _generateNextCardPosition();
    }
  }

  void removeCard(String cardId) {
    final card = library[cardId];
    if (card != null) {
      library.remove(cardId);
      card.removeFromParent();

      _calculateContainerHeight();
      sortCards();
    }
  }

  void updateHeroLibrary() {
    final libraryData = GameData.hero['cardLibrary'];
    for (final cardData in libraryData.values) {
      if (library.containsKey(cardData['id'])) continue;
      addCardByData(cardData);
    }
    final List<String> toBeRemoved = [];
    for (final cardComponent in library.values) {
      if (!libraryData.containsKey(cardComponent.id)) {
        toBeRemoved.add(cardComponent.id);
      }
    }
    for (final cardId in toBeRemoved) {
      final card = library[cardId]!;
      card.removeFromParent();
      library.remove(cardId);
    }

    filterCards();
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
    final posX = _curCardPosX * (GameUI.libraryCardSize.x + GameUI.indent);
    final posY = _curCardPosY * (GameUI.libraryCardSize.y + GameUI.indent);

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
    final card = GameData.createBattleCard(data);
    container.add(card);
    // add(card);
    card.size = GameUI.libraryCardSize;

    // assert(_cardPositions.isNotEmpty &&
    //     _cardPositions.length == library.length + 1);
    // card.position = _generateNextCardPosition();

    // card.onTapDown = (int button, Vector2 position) {
    //   if (button == kPrimaryButton) {
    //     engine.setCursor(Cursors.drag);
    //     if (!card.isEnabled) return;
    //     if (buildingZone != null) {
    //       if (buildingZone!.isFull) return;
    //       (game as CardLibraryScene).cardDragStart(card);
    //     }
    //   }
    // };

    card.onTapUp = (int button, __) async {
      if (button == kPrimaryButton) {
        if (!card.isEnabled) return;
        engine.setCursor(Cursors.normal);
        if (buildingZone != null) {
          String? result = buildingZone!.tryAddCard(card, clone: true);
          if (result != null) {
            GameDialogContent.show(game.context, engine.locale(result));
          } else {
            engine.play(GameSound.cardDealt);
            card.isEnabled = false;
          }
        }
        // (game as CardLibraryScene).cardDragRelease();
      } else if (button == kSecondaryButton) {
        (game as CardLibraryScene).onStartCraft(card);
      }
    };

    // 返回实际被拖动的卡牌，以覆盖这个scene上的dragging component
    // card.onDragStart =
    //     (button, dragPosition) => (game as CardLibraryScene).draggingCard;
    // card.onDragUpdate = (int button, Vector2 position, Vector2 delta) =>
    //     (game as CardLibraryScene).draggingCard?.position += delta;
    // card.onDragEnd = (_, __) {
    //   engine.setCursor(Cursors.normal);
    //   (game as CardLibraryScene).cardDragRelease();
    // };

    card.onPreviewed = () => previewCard(
          game.context,
          'library_card_${card.id}',
          card.data,
          card.toAbsoluteRect(),
          character: GameData.hero,
        );
    card.onUnpreviewed = () => unpreviewCard(game.context);

    library[card.id] = card;

    return card;
  }
}
