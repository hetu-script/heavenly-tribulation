import 'package:flame/components.dart';
import 'package:heavenly_tribulation/scene/common.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view/dialog/confirm_dialog.dart';
import 'library_zone.dart';
import 'deckbuilding_zone.dart';
import '../../ui.dart';
import '../../engine.dart';
import 'common.dart';
import '../game_dialog/game_dialog.dart';
import 'cardcrafting_area.dart';
import '../../state/states.dart';
import '../../data.dart';
import '../../view/ui_overlay.dart';
import 'menus.dart';

class CardLibraryScene extends Scene {
  late final SpriteComponent background;
  late final SpriteComponent2 topBar, bottomBar, deckPilesZone;

  late final CardLibraryZone libraryZone;

  late final SpriteButton closeButton, setBattleDeckButton;
  late final RichTextComponent deckCount, cardCount;
  late final CustomGameCard exit;

  late final SpriteButton orderBy;

  late final SpriteButton skillBook;

  final List<DeckBuildingZone> deckPiles = [];
  DeckBuildingZone? _currentBuildingZone;

  late final PositionComponent deckPilesContainer;

  late final CardCraftingArea cardCraftingArea;

  late final dynamic _heroData;

  late final List<dynamic> _heroDecks;

  CardLibraryScene({required super.context}) : super(id: Scenes.library);

  void calculateVirtualHeight() {
    deckPilesContainer.height =
        deckPiles.length * (GameUI.deckbuildingCardSize.y + GameUI.indent);
  }

  void _setBattleDeck(DeckBuildingZone zone) {
    if (!zone.isCardsEnough) {
      GameDialog.show(
        context: context,
        dialogData: {
          'lines': [engine.locale('deckbuilding_cards_not_enough')],
        },
      );
      return;
    }

    if (!zone.isRequirementMet) {
      GameDialog.show(
        context: context,
        dialogData: {
          'lines': [engine.locale('deckbuilding_card_invalid')],
        },
      );
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
    cardCraftingArea.craftButton.isVisible = false;

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
    cardCraftingArea.craftButton.isVisible = true;

    assert(_currentBuildingZone != null);
    await _currentBuildingZone!.collapse();

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

  void onStartCraft() {
    exit.isVisible = false;
    closeButton.isVisible = true;
    libraryZone.craftingArea = cardCraftingArea;

    for (final zone in deckPiles) {
      zone.isVisible = false;
    }
  }

  void onEndCraft() async {
    exit.isVisible = true;
    closeButton.isVisible = false;
    if (cardCraftingArea.isFull) {
      final card = cardCraftingArea.cards.first as CustomGameCard;
      updateCardData(card);
    }

    libraryZone.craftingArea = null;

    await cardCraftingArea.endCraft();

    for (final zone in deckPiles) {
      zone.isVisible = true;
    }
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

  @override
  void onStart(arguments) {
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
      size: Vector2(size.x,
          size.y - GameUI.libraryZonePosition.y - GameUI.libraryZoneSize.y),
      position:
          Vector2(0, GameUI.libraryZonePosition.y + GameUI.libraryZoneSize.y),
      priority: kBottomBarPriority,
      enableGesture: true,
    );
    world.add(bottomBar);

    deckPilesZone = SpriteComponent2(
      spriteId: 'cultivation/cardlibrary_background_deck_piles_zone.png',
      position: GameUI.decksZoneBackgroundPosition,
      size: GameUI.decksZoneBackgroundSize,
      enableGesture: true,
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
      if (_currentBuildingZone != null) {
        onCloseDeck();
      } else if (cardCraftingArea.isCrafting) {
        onEndCraft();
      } else {
        _heroData['cardLibrary'] = libraryZone.library.map((key, value) {
          return MapEntry(key, value.data);
        });

        final enemyData = context.read<EnemyState>().enemyData;
        if (enemyData != null) {
          context.read<EnemyState>().setPrebattleVisible(true);
        }
        context.read<ViewPanelState>().clearAll();
        context.read<SceneControllerState>().pop();
      }
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

    libraryZone = CardLibraryZone();
    world.add(libraryZone);

    for (final deckData in _heroDecks) {
      final zone = createNewDeckBuildingZone(deckData: deckData);
      libraryZone.preloadBuildingZones.add(zone);
    }
    createNewDeckBuildingZone();
    _updateDeckCount();

    cardCraftingArea = CardCraftingArea(
      // priority: kBarPriority,
      onStartCraft: onStartCraft,
      onRemoveCard: (card) {
        libraryZone.setCardEnabledById(card.deckId);
        updateCardData(card as CustomGameCard);
      },
    );

    camera.viewport.add(cardCraftingArea);

    exit = GameData.getExitSiteCard(spriteId: 'exit_card');
    exit.onTap = (_, __) {
      context.read<SceneControllerState>().pop();
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
      priority: kBottomBarPriority + 5,
    );
    skillBook.onTapUp = (buttons, position) {
      context.read<ViewPanelState>().toogle(ViewPanels.itemSelect, {
        'inventoryData': _heroData['inventory'],
        'title': engine.locale('selectCardpack'),
        'type': 'select',
        'filter': 'cardpack',
      });
    };
    skillBook.onMouseEnter = () {
      final cardpackCount = engine.hetu.invoke('countItem', positionalArgs: [
        _heroData,
        'cardpack',
      ]);

      final cardpackHint =
          '${engine.locale('cardpack')}: <bold ${cardpackCount > 0 ? 'yellow' : ''}>${cardpackCount.toString().padLeft(10)}</>\n'
          '<grey>${engine.locale('deckbuilding_cardpack_hint')}</>';
      Hovertip.show(
        scene: this,
        target: skillBook,
        direction: HovertipDirection.topRight,
        content: cardpackHint,
        config: ScreenTextConfig(anchor: Anchor.topLeft),
        width: 160,
      );
    };
    skillBook.onMouseExit = () {
      Hovertip.hide(skillBook);
    };
    camera.viewport.add(skillBook);
  }

  @override
  void onEnd() {
    super.onEnd();

    engine.removeEventListener(Scenes.library);
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
