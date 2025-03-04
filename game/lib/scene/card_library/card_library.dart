import 'package:flame/components.dart';
import 'package:flutter/gestures.dart';
import 'package:heavenly_tribulation/scene/common.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/dialog/confirm_dialog.dart';
import 'library_zone.dart';
import 'deckbuilding_zone.dart';
import '../../ui.dart';
import '../../engine.dart';
import 'common.dart';
import '../game_dialog/game_dialog.dart';
// import 'cardcrafting_area.dart';
import '../../state/states.dart';
import '../../data.dart';
import '../../widgets/ui_overlay.dart';
import 'menus.dart';

const kAffixOperations = [
  'addAffix',
  'rerollAffix',
  'replaceAffix',
  'upgradeCard',
  'upgradeRank',
];

class CardLibraryScene extends Scene {
  late final SpriteComponent background;
  late final SpriteComponent2 topBar, bottomBar, deckPilesZone;
  late final SpriteComponent cardCraftingArea;

  late final CardLibraryZone libraryZone;

  late final SpriteButton closeButton, setBattleDeckButton;
  late final RichTextComponent deckCount, cardCount;
  late final CustomGameCard exit;

  late final SpriteButton orderBy;

  final List<DeckBuildingZone> deckPiles = [];
  DeckBuildingZone? _currentBuildingZone;

  late final PositionComponent deckPilesContainer;

  // late final CardCraftingArea cardCraftingArea;

  late final dynamic _heroData;

  late final List<dynamic> _heroDecks;

  final List<CustomGameCard> _cardpackCards = [];

  late final SpriteButton skillBook;

  late final SpriteComponent2 barrier;

  late final SpriteButton collectButton;

  late final SpriteButton closeCraftButton;

  CustomGameCard? draggingCard;

  CustomGameCard? _craftingCard;

  final List<SpriteButton> _craftOptionButtons = [];

  void cardDragStart(CustomGameCard card) {
    final CustomGameCard clone = card.clone();
    clone.enableGesture = false;
    clone.position = card.absolutePosition.clone();
    clone.priority = kDraggingCardPriority;
    camera.viewport.add(clone);
    draggingCard = clone;
  }

  void cardDragRelease() {
    draggingCard?.removeFromParent();
    draggingCard = null;
  }

  CardLibraryScene({required super.context}) : super(id: Scenes.library);

  void calculateVirtualHeight() {
    deckPilesContainer.height =
        deckPiles.length * (GameUI.deckbuildingCardSize.y + GameUI.indent);
  }

  void _setBattleDeck(DeckBuildingZone zone) {
    if (!zone.isCardsEnough) {
      GameDialog.show(context, engine.locale('deckbuilding_cards_not_enough'));
      return;
    }

    if (!zone.isRequirementMet) {
      GameDialog.show(context, engine.locale('deckbuilding_card_invalid'));
      return;
    }

    if (!zone.isBattleDeck) {
      zone.setBattleDeck();
      for (final otherZone in deckPiles) {
        if (otherZone != zone && otherZone.isBattleDeck) {
          otherZone.setBattleDeck(false);
        }
      }
      _heroData['battleDeckIndex'] = zone.index;
    } else {
      _heroData['battleDeckIndex'] = -1;
    }
    for (var i = 0; i < deckPiles.length - 1; ++i) {
      _heroDecks[i]['isBattleDeck'] = deckPiles[i].isBattleDeck;
    }
  }

  void onOpenDeckMenu(DeckBuildingZone zone) {
    final menuPosition = RelativeRect.fromLTRB(
        zone.position.x, zone.position.y, zone.position.x, 0.0);
    final menu = buildDeckPopUpMenuItems(onSelectedItem: (item) {
      switch (item) {
        case DeckMenuItems.setAsBattleDeck:
          _setBattleDeck(zone);
        case DeckMenuItems.editDeck:
          onEditDeck(zone);
        case DeckMenuItems.deleteDeck:
          _deleteDeck(zone);
      }
    });
    showMenu(
      context: context,
      items: menu,
      position: menuPosition,
    );
  }

  void _updateDeckCount() {
    deckCount.text =
        '${engine.locale('deckbuilding_deck_count')}: ${deckPiles.length - 1}';
  }

  void _updateCardCount(DeckBuildingZone zone) {
    StringBuffer detailedCount = StringBuffer();
    detailedCount.writeln(
        '${engine.locale('deckbuilding_card_count')}: ${zone.cards.length}');
    detailedCount.writeln(
        '${engine.locale('deckbuilding_limit_min')}: ${_currentBuildingZone!.limitMin}');
    detailedCount.writeln(
        '${engine.locale('deckbuilding_limit')}: ${_currentBuildingZone!.limit}');
    detailedCount.writeln(
        '${engine.locale('deckbuilding_limit_ephemeral')}: ${_currentBuildingZone!.ephemeralCount}/${_currentBuildingZone!.limitEphemeralMax}');
    detailedCount.writeln(
        '${engine.locale('deckbuilding_limit_ongoing')}: ${_currentBuildingZone!.ongoingCount}/${_currentBuildingZone!.limitOngoingMax}');
    cardCount.text = detailedCount.toString();
  }

  void onEditDeck(DeckBuildingZone zone) {
    exit.isVisible = false;
    deckPilesZone.enableGesture = false;
    deckCount.isVisible = false;
    cardCount.isVisible = true;
    setBattleDeckButton.isVisible = true;
    closeButton.isVisible = true;
    // cardCraftingArea.craftButton.isVisible = false;

    for (final existedZone in deckPiles) {
      if (existedZone != zone) {
        existedZone.isVisible = false;
      }
    }

    _currentBuildingZone = libraryZone.buildingZone = zone;

    deckPilesContainer.position.y = GameUI.decksZoneBackgroundPosition.y -
        zone.index * (GameUI.deckbuildingCardSize.y + GameUI.indent);

    _updateCardCount(zone);

    zone.expand();
  }

  void _deleteDeckBuildingZone(DeckBuildingZone zone) {
    deckPiles.remove(zone);
    zone.dispose();
    _resizeDeckPilesContainer();
    for (var i = 0; i < deckPiles.length; ++i) {
      final zone = deckPiles[i];
      zone.index = i;
      zone.position =
          Vector2(0, i * (GameUI.deckbuildingCardSize.y + GameUI.indent));
    }

    _checkDeckPilesContainerPosition();
  }

  void _deleteDeck(DeckBuildingZone zone, {bool warning = true}) async {
    if (warning) {
      final value = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (context) =>
            ConfirmDialog(description: engine.locale('dangerOperationPrompt')),
      );

      if (value == false) return;
    }

    if (_heroData['battleDeckIndex'] == zone.index) {
      _heroData['battleDeckIndex'] = -1;
    }
    _heroDecks.removeAt(zone.index);

    _deleteDeckBuildingZone(zone);

    if (deckPiles.isEmpty) {
      createNewDeckBuildingZone();
    }

    _updateDeckCount();
  }

  void onCloseDeck() async {
    exit.isVisible = true;
    deckPilesZone.enableGesture = true;
    deckCount.isVisible = true;
    cardCount.isVisible = false;
    setBattleDeckButton.isVisible = false;
    closeButton.isVisible = false;
    // cardCraftingArea.craftButton.isVisible = true;

    assert(_currentBuildingZone != null);
    await _currentBuildingZone!.collapse(animated: false);

    if (_currentBuildingZone!.cards.isEmpty) {
      if (_currentBuildingZone != deckPiles.last && deckPiles.length > 1) {
        _deleteDeck(_currentBuildingZone!, warning: false);
      }
    } else {
      for (final card in _currentBuildingZone!.cards) {
        libraryZone.setCardEnabledById(card.deckId, true);
      }
      if (deckPiles.last == _currentBuildingZone) {
        createNewDeckBuildingZone();
      }

      _currentBuildingZone!.save();
    }

    for (final zone in deckPiles) {
      zone.isVisible = true;
    }

    libraryZone.buildingZone = _currentBuildingZone = null;

    // deckPilesContainer.position.y =
    //     getDeckPilesContainerMinOffsetY(ignoreEmptyDeck: true);

    _updateDeckCount();
  }

  void _resizeDeckPilesContainer() {
    deckPilesContainer.height =
        deckPiles.length * (GameUI.deckbuildingCardSize.y + GameUI.indent);
  }

  DeckBuildingZone createNewDeckBuildingZone({dynamic deckData}) {
    String? title = deckData?['title'];
    bool? isBattleDeck = deckData?['isBattleDeck'];
    List? cardIds = deckData?['cards'];
    final zone = DeckBuildingZone(
      heroData: _heroData,
      title: title,
      isBattleDeck: isBattleDeck,
      preloadCardIds: cardIds,
      library: libraryZone,
      index: deckPiles.length,
      position: Vector2(0,
          deckPiles.length * (GameUI.deckbuildingCardSize.y + GameUI.indent)),
      // priority: kDeckPilesZonePriority,
      onEditDeck: (buildingZone) => onEditDeck(buildingZone),
      onOpenDeckMenu: (buildingZone) => onOpenDeckMenu(buildingZone),
      onDeckEdited: (buildingZone) => _updateCardCount(buildingZone),
    );
    deckPilesContainer.add(zone);
    deckPiles.add(zone);
    _resizeDeckPilesContainer();

    return zone;
  }

  double getDeckPilesContainerMinOffsetY({bool ignoreEmptyDeck = false}) {
    int offset = (deckPiles.length > 1 && ignoreEmptyDeck) ? 2 : 1;

    return deckPiles.isNotEmpty
        ? GameUI.decksZoneBackgroundPosition.y -
            (deckPiles.length - offset) *
                (GameUI.deckbuildingCardSize.y + GameUI.indent)
        : 0.0;
  }

  void _checkDeckPilesContainerPosition() {
    double curOffsetY = deckPilesContainer.position.y;
    if (deckPilesContainer.height <= GameUI.decksZoneBackgroundSize.y) {
      curOffsetY = GameUI.decksZoneBackgroundPosition.y;
    } else {
      if (curOffsetY > GameUI.decksZoneBackgroundPosition.y) {
        curOffsetY = GameUI.decksZoneBackgroundPosition.y;
      } else {
        final minValue = getDeckPilesContainerMinOffsetY();
        if (curOffsetY < minValue) {
          curOffsetY = minValue;
        }
      }
    }
    deckPilesContainer.position.y = curOffsetY;
  }

  void _repositionDeckPiles(double offsetY) {
    deckPilesContainer.position.y += offsetY;

    _checkDeckPilesContainerPosition();
  }

  void _showCraftingCardInfo() {
    assert(_craftingCard != null);
    final (_, description) = GameData.getDescriptionFromCardData(
        _craftingCard!.data,
        isDetailed: true);
    Hovertip.show(
      scene: this,
      target: _craftingCard!,
      direction: HovertipDirection.rightTop,
      content: description,
      config: ScreenTextConfig(anchor: Anchor.topCenter),
      width: kCraftingCardInfoWidth,
    );
  }

  void _affixOperation(CustomGameCard? card, String id) {
    if (card == null) {
      GameDialog.show(context, engine.locale('deckbuilding_no_card_hint'));
      return;
    }

    final result = engine.hetu.invoke(id, positionalArgs: [card.data]);

    if (result != null) {
      // 如果不能进行精炼，返回的是错误信息的本地化字符串key
      GameDialog.show(context, engine.locale(result));
    } else {
      engine.play('hammer-hitting-an-anvil-25390.mp3');

      addHintText(
        engine.locale('deckbuilding_${id}_hint'),
        position: card.center,
        offsetY: 30.0,
        textStyle: TextStyle(
          fontFamily: GameUI.fontFamily,
        ),
        horizontalVariation: 0.0,
        verticalVariation: 0.0,
      );

      final (description, _) = GameData.getDescriptionFromCardData(card.data);
      card.description = description;
      _showCraftingCardInfo();
    }
  }

  void _addAffixOperationButton(String id, Vector2 position) {
    final SpriteButton button = SpriteButton(
      position: position,
      spriteId: 'ui/button10.png',
      size: Vector2(140, 30),
      text: engine.locale('deckbuilding_$id'),
      priority: kBarrierPriority + 100,
      isVisible: false,
    );
    button.onTapUp = (buttons, position) {
      assert(_craftingCard != null);
      Hovertip.hide(button);
      _affixOperation(_craftingCard, id);
    };
    button.onMouseEnter = () {
      Hovertip.show(
        scene: this,
        target: button,
        direction: HovertipDirection.rightCenter,
        content: engine.locale('deckbuilding_${id}_description'),
        config: ScreenTextConfig(anchor: Anchor.topCenter),
      );
    };
    button.onMouseExit = () {
      Hovertip.hide(button);
    };
    camera.viewport.add(button);
    _craftOptionButtons.add(button);
  }

  void onStartCraft(CustomGameCard card) {
    // exit.isVisible = false;
    // closeButton.isVisible = true;
    // libraryZone.craftingArea = cardCraftingArea;

    // for (final zone in deckPiles) {
    //   zone.isVisible = false;
    // }

    skillBook.enableGesture = false;
    barrier.isVisible = true;
    closeCraftButton.isVisible = true;
    for (final button in _craftOptionButtons) {
      button.isVisible = true;
    }

    final clone = card.clone();
    _craftingCard = clone;
    clone.enableGesture = false;
    clone.size = GameUI.cardpackCardSize;
    clone.position = GameUI.cardpackCardPositions[0];
    clone.priority = kBarrierPriority;
    camera.viewport.add(clone);

    _showCraftingCardInfo();
  }

  void onEndCraft() async {
    // exit.isVisible = true;
    // closeButton.isVisible = false;
    // if (cardCraftingArea.isFull) {
    //   final card = cardCraftingArea.cards.first as CustomGameCard;
    //   updateCardData(card);
    // }

    // libraryZone.craftingArea = null;

    // await cardCraftingArea.endCraft();

    // for (final zone in deckPiles) {
    //   zone.isVisible = true;
    // }

    skillBook.enableGesture = true;
    barrier.isVisible = false;
    closeCraftButton.isVisible = false;
    for (final button in _craftOptionButtons) {
      button.isVisible = false;
    }

    assert(_craftingCard != null);
    updateCardData(_craftingCard!);

    Hovertip.hide(_craftingCard!);
    _craftingCard!.removeFromParent();
    _craftingCard = null;
  }

  void updateCardData(CustomGameCard card) {
    final libraryCard = libraryZone.library[card.id];
    assert(libraryCard != null);

    libraryCard!.description = card.description;

    for (final zone in deckPiles) {
      if (zone.cards.isNotEmpty) {
        final Iterable<GameCard> cards = zone.cards.where((card) {
          return card.deckId == libraryCard.id;
        });
        if (cards.isNotEmpty) {
          final deckCard = cards.first as CustomGameCard;
          deckCard.description = libraryCard.description;
        }
      }
    }
  }

  void updateOrderByButtonText() {
    orderBy.text = engine.locale(libraryZone.orderByOption.name);
  }

  void onOpenAllCardpack() {
    final cardpacks = _heroData['inventory'].values.where((itemData) {
      return itemData['category'] == 'cardpack';
    }).toList();

    engine.play(GameSound.cardDealt2);
    for (final cardpackData in cardpacks) {
      engine.hetu.invoke('lose', namespace: 'Player', positionalArgs: [
        cardpackData,
      ]);
      for (var i = 0; i < 3; ++i) {
        final cardData = engine.hetu.invoke(
          'BattleCard',
          namedArgs: {
            'maxRank': _heroData['cultivationRank'],
            'rank': i == 0 ? cardpackData['rank'] : null,
            'genre': i == 0 ? cardpackData['genre'] : null,
            'kind': i == 0 ? cardpackData['kind'] : null,
            'isIdentified': true,
          },
        );

        engine.hetu.invoke('acquire', namespace: 'Player', positionalArgs: [
          cardData,
        ]);
      }
    }

    libraryZone.updateHeroLibrary();
  }

  void onOpenCardpack(dynamic cardpackData) {
    if (cardpackData == null) return;

    skillBook.enableGesture = false;
    barrier.isVisible = true;

    collectButton.text = engine.locale('deckbuilding_identify_all');

    engine.play(GameSound.cardDealt2);
    for (var i = 0; i < 3; ++i) {
      final cardData = engine.hetu.invoke(
        'BattleCard',
        namedArgs: {
          'maxRank': i == 0 ? null : cardpackData['rank'],
          'rank': i == 0 ? cardpackData['rank'] : null,
          'genre': i == 0 ? cardpackData['genre'] : null,
          'kind': i == 0 ? cardpackData['kind'] : null,
        },
      );
      final card = GameData.createBattleCardFromData(cardData);
      _cardpackCards.add(card);

      card.showGlow = true;
      card.preferredPriority = kBarrierPriority;
      card.resetPriority();
      card.size = Vector2.zero();
      card.position = skillBook.center;

      card.onTapUp = (int buttons, Vector2 position) {
        if (card.data['isIdentified'] != true) {
          engine.play(GameSound.craft);
          card.data['isIdentified'] = true;
          final (description, _) =
              GameData.getDescriptionFromCardData(card.data);
          card.description = description;
          previewCard(
            context,
            'cardpack_card_${card.id}',
            card.data,
            card.toAbsoluteRect(),
            characterData: _heroData,
          );
        }
        final unidentifiedCards = _cardpackCards.where((card) {
          return card.data['isIdentified'] != true;
        });
        if (unidentifiedCards.isEmpty) {
          collectButton.text = engine.locale('deckbuilding_collect_all');
        }
      };

      card.onPreviewed = () => previewCard(
            context,
            'cardpack_card_${card.id}',
            card.data,
            card.toAbsoluteRect(),
            characterData: _heroData,
          );
      card.onUnpreviewed = () => unpreviewCard(context);

      camera.viewport.add(card);

      final index = i;
      card
          .moveTo(
        duration: 0.35,
        toPosition: GameUI.cardpackCardPositions[0],
        toSize: GameUI.cardpackCardSize,
      )
          .then((_) {
        if (index == 0) {
          engine.play(GameSound.cardFlipping);
          collectButton.isVisible = true;
        } else {
          card.moveTo(
            duration: 0.55,
            toPosition: GameUI.cardpackCardPositions[index],
            toSize: GameUI.cardpackCardSize,
          );
        }
      });
    }

    engine.hetu.invoke(
      'lose',
      namespace: 'Player',
      positionalArgs: [cardpackData],
    );
  }

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) {
    super.onStart(arguments);

    if (isLoaded) {
      libraryZone.repositionToTop();
      deckPilesContainer.position.y = GameUI.decksZoneBackgroundPosition.y;
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _heroData = engine.hetu.fetch('hero');
    _heroDecks = _heroData['battleDecks'];

    barrier = SpriteComponent2(
      size: size,
      color: GameUI.barrierColor,
      priority: kBarrierPriority,
      isVisible: false,
      enableGesture: true,
    );
    barrier.onTapUp = (buttons, position) {
      if (buttons == kSecondaryButton) {
        if (_craftingCard != null) {
          onEndCraft();
        }
      }
    };
    camera.viewport.add(barrier);

    background = SpriteComponent(
      sprite: await Sprite.load('cultivation/cardlibrary_background.png'),
      size: size,
    );
    world.add(background);

    topBar = SpriteComponent2(
      spriteId: 'cultivation/cardlibrary_background_top.png',
      size: Vector2(size.x, GameUI.libraryZonePosition.y),
      priority: kTopBarPriority,
      enableGesture: true,
    );
    world.add(topBar);

    bottomBar = SpriteComponent2(
      spriteId: 'cultivation/cardlibrary_background_bottom.png',
      size: Vector2(
          size.x,
          size.y -
              GameUI.libraryZoneBackgroundPosition.y -
              GameUI.libraryZoneBackgroundSize.y),
      position: Vector2(
          0,
          GameUI.libraryZoneBackgroundPosition.y +
              GameUI.libraryZoneBackgroundSize.y),
      priority: kBottomBarPriority,
      enableGesture: true,
    );
    world.add(bottomBar);

    deckPilesZone = SpriteComponent2(
      spriteId: 'cultivation/cardlibrary_background_deck_piles_zone.png',
      position: GameUI.decksZoneBackgroundPosition,
      size: GameUI.decksZoneBackgroundSize,
      enableGesture: true,
      priority: kDeckPilesZonePriority,
    );
    deckPilesZone.onMouseScrollUp = () => _repositionDeckPiles(100);
    deckPilesZone.onMouseScrollDown = () => _repositionDeckPiles(-100);
    world.add(deckPilesZone);

    deckPilesContainer = PositionComponent(
      position: GameUI.decksZoneBackgroundPosition,
      size: Vector2(GameUI.decksZoneBackgroundSize.x, 0),
      priority: kDeckPilesZonePriority,
    );
    world.add(deckPilesContainer);

    deckCount = RichTextComponent(
      position: Vector2(
          GameUI.decksZoneBackgroundPosition.x + GameUI.smallIndent,
          GameUI.decksZoneBackgroundPosition.y - GameUI.buttonSizeMedium.y),
      size: GameUI.buttonSizeMedium,
      config: ScreenTextConfig(
        outlined: true,
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
        anchor: Anchor.bottomCenter,
      ),
      priority: kDeckPilesZonePriority,
    );
    camera.viewport.add(deckCount);

    cardCount = RichTextComponent(
      position: Vector2(
          GameUI.decksZoneBackgroundPosition.x + GameUI.smallIndent,
          GameUI.decksZoneBackgroundPosition.y - 240),
      size: Vector2(140, 240),
      config: ScreenTextConfig(
        outlined: true,
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
        anchor: Anchor.bottomCenter,
      ),
      priority: kDeckPilesZonePriority,
      isVisible: false,
      enableGesture: true,
    );
    cardCount.onMouseEnter = () {
      assert(_currentBuildingZone != null);
      StringBuffer cardCountHint = StringBuffer();
      final rank = _heroData['cultivationRank'];
      final rankString = engine.locale('cultivationRank_$rank');
      cardCountHint.writeln(
          '${engine.locale('cultivationRank')}: <rank$rank>$rankString</>');
      cardCountHint
          .write('<grey>${engine.locale('deckbuilding_limit_hint')}</>');
      Hovertip.show(
        scene: this,
        target: cardCount,
        direction: HovertipDirection.bottomCenter,
        content: cardCountHint.toString(),
        config: ScreenTextConfig(anchor: Anchor.topCenter),
        width: 200,
      );
    };
    cardCount.onMouseExit = () {
      Hovertip.hide(cardCount);
    };
    camera.viewport.add(cardCount);

    closeButton = SpriteButton(
      text: engine.locale('close'),
      anchor: Anchor.topLeft,
      position: GameUI.decksZoneCloseButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      priority: kDeckPilesZonePriority,
      isVisible: false,
    );
    closeButton.onTapUp = (buttons, position) {
      assert(_currentBuildingZone != null);
      onCloseDeck();
      // else if (cardCraftingArea.isCrafting) {
      //   onEndCraft();
      // }
    };
    camera.viewport.add(closeButton);

    setBattleDeckButton = SpriteButton(
      text: engine.locale('deckbuilding_set_battle_deck'),
      anchor: Anchor.topLeft,
      position: GameUI.setBattleDeckButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button.png',
      priority: kDeckPilesZonePriority,
      isVisible: false,
    );
    setBattleDeckButton.onTapUp = (buttons, position) {
      _setBattleDeck(_currentBuildingZone!);
    };
    camera.viewport.add(setBattleDeckButton);

    libraryZone = CardLibraryZone(heroData: _heroData);
    world.add(libraryZone);

    for (final deckData in _heroDecks) {
      final zone = createNewDeckBuildingZone(deckData: deckData);
      libraryZone.preloadBuildingZones.add(zone);
    }
    createNewDeckBuildingZone();
    _updateDeckCount();

    cardCraftingArea = SpriteComponent(
      sprite: await Sprite.load('cultivation/cardlibrary_cardcraft.png'),
      size: GameUI.cardCraftingZoneSize,
      position: GameUI.cardCraftingZoneInitialPosition,
      priority: kTopBarPriority + 10,
    );
    world.add(cardCraftingArea);

    // cardCraftingArea = CardCraftingArea(
    //   // priority: kBarPriority,
    //   onStartCraft: onStartCraft,
    //   onRemoveCard: (card) {
    //     libraryZone.setCardEnabledById(card.deckId);
    //     updateCardData(card);
    //   },
    // );
    // camera.viewport.add(cardCraftingArea);

    exit = GameData.getExitSiteCard(spriteId: 'exit_card');
    exit.onTap = (_, __) {
      // _heroData['cardLibrary'] = libraryZone.library.map((key, value) {
      //   return MapEntry(key, value.data);
      // });

      engine.popScene();
      context.read<EnemyState>().setPrebattleVisible();
    };
    camera.viewport.add(exit);

    orderBy = SpriteButton(
      position: GameUI.libraryZonePosition + Vector2(50, -50),
      size: GameUI.buttonSizeLong,
      spriteId: 'ui/button20.png',
      priority: kBottomBarPriority,
      text: engine.locale('sort'),
    );
    orderBy.onTapUp = (buttons, position) {
      final menuPosition = RelativeRect.fromLTRB(orderBy.position.x,
          orderBy.position.y + orderBy.size.y, orderBy.position.x, 0.0);
      final menu = buildOrderByMenuItems(onSelectedItem: (option) {
        libraryZone.repositionToTop();
        libraryZone.sortCards(orderBy: option);
        updateOrderByButtonText();
      });
      showMenu(
        context: context,
        items: menu,
        position: menuPosition,
      );
    };
    orderBy.onMouseEnter = () {};
    orderBy.onMouseExit = () {};
    camera.viewport.add(orderBy);
    updateOrderByButtonText();

    skillBook = SpriteButton(
      position: Vector2(-60, GameUI.size.y - 160),
      size: Vector2(360, 360),
      spriteId: 'cultivation/battlebook.png',
      hoverSpriteId: 'cultivation/battlebook_hover.png',
      priority: kBarrierPriority,
    );
    skillBook.onTapUp = (buttons, position) {
      context.read<ViewPanelState>().toogle(
        ViewPanels.itemSelect,
        arguments: {
          'characterData': _heroData,
          'title': engine.locale('selectCardpack'),
          'filter': 'cardpack',
          'onSelect': onOpenCardpack,
          'onSelectAll': onOpenAllCardpack,
        },
      );
    };
    skillBook.onMouseEnter = () {
      final cardpackCount = engine.hetu.invoke('countItem', positionalArgs: [
        _heroData,
        'cardpack',
      ]);

      final cardpackHint =
          '${engine.locale('ownedCardpack')}: <bold ${cardpackCount > 0 ? 'yellow' : 'grey'}>${cardpackCount.toString().padLeft(10)}</>\n'
          '<grey>${engine.locale('deckbuilding_cardpack_hint')}</>';
      Hovertip.show(
        scene: this,
        target: skillBook,
        direction: HovertipDirection.topRight,
        content: cardpackHint,
        config: ScreenTextConfig(anchor: Anchor.topLeft),
        width: 200,
      );
    };
    skillBook.onMouseExit = () {
      Hovertip.hide(skillBook);
    };
    camera.viewport.add(skillBook);

    collectButton = SpriteButton(
      text: engine.locale('deckbuilding_identify_all'),
      anchor: Anchor.center,
      position: GameUI.cardpackCardPositions[1] +
          Vector2(GameUI.cardpackCardSize.x / 2,
              GameUI.cardpackCardSize.y + GameUI.hugeIndent),
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      priority: kBarrierPriority,
      isVisible: false,
    );
    collectButton.onTapUp = (buttons, position) {
      final unidentifiedCards = _cardpackCards.where((card) {
        return card.data['isIdentified'] != true;
      });

      if (unidentifiedCards.isNotEmpty) {
        engine.play(GameSound.craft);
        for (final card in unidentifiedCards) {
          card.data['isIdentified'] = true;
          final (description, _) =
              GameData.getDescriptionFromCardData(card.data);
          card.description = description;
        }
        collectButton.text = engine.locale('deckbuilding_collect_all');
      } else {
        engine.play(GameSound.cardDealt2);

        barrier.isVisible = false;
        collectButton.isVisible = false;

        for (final card in _cardpackCards) {
          engine.hetu.invoke(
            'acquire',
            namespace: 'Player',
            positionalArgs: [card.data],
          );
          card
              .moveTo(
            duration: 0.35,
            toPosition: skillBook.center,
            toSize: Vector2.zero(),
          )
              .then((_) {
            card.removeFromParent();
          });
        }
        _cardpackCards.clear();
        libraryZone.updateHeroLibrary();
        skillBook.enableGesture = true;
      }
    };
    camera.viewport.add(collectButton);

    // craftOptionButtonsContainer = BorderComponent(
    //   position: displayCardSize +
    //       Vector2(displayCardSize.x + 300 + GameUI.hugeIndent, 0),
    //   isVisible: false,
    // );
    // camera.viewport.add(craftOptionButtonsContainer);

    for (var i = 0; i < kAffixOperations.length; i++) {
      final operation = kAffixOperations[i];
      _addAffixOperationButton(
          operation,
          GameUI.cardpackCardPositions[0] +
              Vector2(
                  GameUI.cardpackCardSize.x +
                      GameUI.indent * 2 +
                      kCraftingCardInfoWidth,
                  (GameUI.buttonSizeSmall.y + 10) * i));
    }

    closeCraftButton = SpriteButton(
      text: engine.locale('close'),
      anchor: Anchor.center,
      position: GameUI.cardpackCardPositions[0] +
          Vector2(GameUI.cardpackCardSize.x / 2,
              GameUI.cardpackCardSize.y + GameUI.hugeIndent),
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      priority: kBarrierPriority,
      isVisible: false,
    );
    closeCraftButton.onTapUp = (buttons, position) {
      onEndCraft();
    };
    camera.viewport.add(closeCraftButton);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneWidget(scene: this),
        const Positioned(
          left: 0,
          top: 0,
          child: GameUIOverlay(showLibrary: false),
        ),
      ],
    );
  }
}
