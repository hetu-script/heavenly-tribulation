import 'package:flame/components.dart';
import 'package:heavenly_tribulation/common.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/sprite_component2.dart';
// import 'package:samsara/cardgame/cardgame.dart';
// import 'package:flame/flame.dart';
// import 'package:samsara/gestures.dart';
import 'package:samsara/components.dart';
import 'package:flutter/material.dart';

import '../../../dialog/confirm_dialog.dart';
import '../../../view/menu_item_builder.dart';
// import '../../../global.dart';
import 'library_zone.dart';
import 'deckbuilding_zone.dart';
import '../../../ui.dart';
import '../../../engine.dart';
import 'common.dart';
import '../../../dialog/game_dialog/game_dialog.dart';
// import '../../../data.dart';
import '../../events.dart';
import 'cardcrafting_area.dart';

enum DeckMenuItems {
  setAsBattleDeck,
  editDeck,
  deleteDeck,
}

List<PopupMenuEntry<DeckMenuItems>> buildDeckPopUpMenuItems(
    {void Function(DeckMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<DeckMenuItems>>[
    buildMenuItem(
      item: DeckMenuItems.setAsBattleDeck,
      name: engine.locale('deckbuilding.setAsBattleDeck'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DeckMenuItems.editDeck,
      name: engine.locale('edit'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(height: 12.0),
    buildMenuItem(
      item: DeckMenuItems.deleteDeck,
      name: engine.locale('delete'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

enum DeckBuildingSceneState {
  expCollection, // 收集经验球提升等级和境界
  // introspection,
  skillTree, // 显示和分配天赋树技能
}

class CardLibraryScene extends Scene {
  late final SpriteComponent background;
  late final SpriteComponent2 topBar, bottomBar, deckPilesZone;

  late final CardLibraryZone libraryZone;

  late final SpriteButton closeButton, setAsBattleDeckButton;
  late final RichTextComponent cardCount;

  final List<DeckBuildingZone> deckPiles = [];
  DeckBuildingZone? _currentBuildingZone;

  late final CardCraftingArea cardCraftingArea;

  double _deckPilesZoneVirtualHeight = 0, _curYOffset = 0;

  late final dynamic _heroData;
  late final int _cardLimit;

  int _currentDeckIndex = -1;

  late final List<dynamic> _heroDecks;

  CardLibraryScene({
    required super.controller,
    required super.context,
  }) : super(id: 'deckBuilding');

  void calculateVirtualHeight() {
    _deckPilesZoneVirtualHeight =
        deckPiles.length * (GameUI.deckbuildingCardSize.y + GameUI.indent);
  }

  void _setAsBattleDeck(DeckBuildingZone zone) {
    if (!zone.isFull) {
      GameDialog.show(
        context: context,
        dialogData: {
          'lines': [engine.locale('deckbuilding.deckIsNotFull')],
        },
      );
    } else {
      if (!zone.isBattleDeck) {
        zone.setBattleDeck();
        for (final otherZone in deckPiles) {
          if (otherZone != zone && otherZone.isBattleDeck) {
            otherZone.setBattleDeck(false);
          }
        }
        _heroData['battleDeckIndex'] = deckPiles.indexOf(zone);
      } else {
        _heroData['battleDeckIndex'] = -1;
      }
      for (var i = 0; i < deckPiles.length - 1; ++i) {
        _heroDecks[i]['isBattleDeck'] = deckPiles[i].isBattleDeck;
      }
    }
  }

  void onOpenDeckMenu(DeckBuildingZone zone) {
    final menuPosition = RelativeRect.fromLTRB(
        zone.position.x, zone.position.y, zone.position.x, 0.0);
    final menu = buildDeckPopUpMenuItems(onSelectedItem: (item) {
      switch (item) {
        case DeckMenuItems.setAsBattleDeck:
          _setAsBattleDeck(zone);
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

  void _refreshCardCount(DeckBuildingZone zone) {
    cardCount.text =
        '${engine.locale('deckbuilding.cardCount')}: ${zone.cards.length}/${zone.limit}';
  }

  void onEditDeck(DeckBuildingZone zone) {
    cardCount.isVisible = true;
    setAsBattleDeckButton.isVisible = true;

    for (final existedZone in deckPiles) {
      if (existedZone != zone) {
        existedZone.isVisible = false;
      }
    }

    _currentDeckIndex = deckPiles.indexOf(zone);
    _currentBuildingZone = libraryZone.buildingZone = zone;

    _refreshCardCount(zone);

    zone.expand();
  }

  void _deleteDeck(DeckBuildingZone zone) async {
    final value = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          ConfirmDialog(description: engine.locale('dangerOperationPrompt')),
    );

    if (value == false) return;

    final index = deckPiles.indexOf(zone);
    if (_heroData['battleDeckIndex'] == index) {
      _heroData['battleDeckIndex'] = -1;
    }
    _heroDecks.removeAt(index);
    deckPiles.remove(zone);
    zone.dispose();
    if (deckPiles.isEmpty) {
      createNewDeckBuildingZone();
    }

    _deckPilesZoneVirtualHeight +=
        GameUI.deckbuildingCardSize.y + GameUI.indent;

    _repositionDeckPiles();
  }

  void onCloseDeck() async {
    setAsBattleDeckButton.isVisible = false;
    cardCount.isVisible = false;

    assert(_currentBuildingZone != null);
    await _currentBuildingZone!.collapse();

    if (_currentBuildingZone!.cards.isEmpty) {
      if (_currentBuildingZone != deckPiles.last && deckPiles.length > 1) {
        deckPiles.remove(_currentBuildingZone);
        _currentBuildingZone!.dispose();
      }
    } else {
      for (final card in _currentBuildingZone!.cards) {
        libraryZone.setCardEnabledById(card.deckId, true);
      }
      if (deckPiles.last == _currentBuildingZone) {
        createNewDeckBuildingZone();
      }

      final List decks = _heroData['battleDecks'];

      final deckInfo = {
        'title': _currentBuildingZone!.title,
        'isBattleDeck': _currentBuildingZone!.isBattleDeck,
        'cards':
            _currentBuildingZone!.cards.map((card) => card.deckId).toList(),
      };

      if (_currentDeckIndex >= decks.length) {
        decks.add(deckInfo);
      } else {
        decks[_currentDeckIndex] = deckInfo;
      }
    }

    for (final zone in deckPiles) {
      zone.isVisible = true;
    }

    _repositionDeckPiles();

    _currentDeckIndex = -1;
    libraryZone.buildingZone = _currentBuildingZone = null;
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
      limit: _cardLimit,
      position: Vector2(
          GameUI.decksZoneBackgroundPosition.x,
          GameUI.decksZoneBackgroundPosition.y +
              _deckPilesZoneVirtualHeight +
              _curYOffset),
      // priority: kDeckPilesZonePriority,
      onEditDeck: (buildingZone) => onEditDeck(buildingZone),
      onOpenDeckMenu: (buildingZone) => onOpenDeckMenu(buildingZone),
      onDeckEdited: (buildingZone) => _refreshCardCount(buildingZone),
    );
    world.add(zone);
    deckPiles.add(zone);

    _deckPilesZoneVirtualHeight +=
        GameUI.deckbuildingCardSize.y + GameUI.indent;

    return zone;
  }

  void _repositionDeckPiles([double? offsetY]) {
    if (offsetY != null) {
      _curYOffset += offsetY;
    }

    if (_deckPilesZoneVirtualHeight > GameUI.libraryZoneSize.y) {
      final maxValue = _deckPilesZoneVirtualHeight - GameUI.libraryZoneSize.y;
      if (_curYOffset < -maxValue) {
        _curYOffset = -maxValue;
      }
      if (_curYOffset >= 0) {
        _curYOffset = 0;
      }
    } else {
      _curYOffset = 0;
    }

    for (var i = 0; i < deckPiles.length; ++i) {
      final zone = deckPiles[i];
      zone.position = Vector2(
          GameUI.decksZoneBackgroundPosition.x,
          GameUI.decksZoneBackgroundPosition.y +
              i * (GameUI.deckbuildingCardSize.y + GameUI.indent) +
              _curYOffset);
    }
  }

  void onStartCraft() {
    libraryZone.craftingArea = cardCraftingArea;

    for (final zone in deckPiles) {
      zone.isVisible = false;
    }
  }

  void onEndCraft() async {
    if (cardCraftingArea.isFull) {
      final card = cardCraftingArea.craftingZone.cards.first as CustomGameCard;
      refreshCardData(card);
    }

    libraryZone.craftingArea = null;

    await cardCraftingArea.endCraft();

    for (final zone in deckPiles) {
      zone.isVisible = true;
    }
  }

  void refreshCardData(CustomGameCard card) {
    final libraryCard = libraryZone.library[card.id];
    assert(libraryCard != null);

    // libraryCard!.data = card.data;
    libraryCard!.description = card.description;
    libraryCard.extraDescription = card.extraDescription;

    for (final zone in deckPiles) {
      if (zone.cards.isNotEmpty) {
        final Iterable<GameCard> cards = zone.cards.where((card) {
          return card.deckId == libraryCard.id;
        });
        if (cards.isNotEmpty) {
          final deckCard = cards.first as CustomGameCard;
          deckCard.description = libraryCard.description;
          deckCard.extraDescription = libraryCard.extraDescription;
        }
      }
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _heroData = engine.hetu.fetch('hero');
    final int rank = _heroData['cultivationRank'];
    _cardLimit = getDeckCardLimitFromRank(rank);
    _heroDecks = _heroData['battleDecks'];

    cardCount = RichTextComponent(
      position: Vector2(GameUI.decksZoneBackgroundPosition.x,
          GameUI.decksZoneBackgroundPosition.y - GameUI.largeIndent),
      size: GameUI.buttonSizeMedium,
      config: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
        anchor: Anchor.center,
      ),
      priority: kDeckPilesZonePriority,
      isVisible: false,
    );
    camera.viewport.add(cardCount);

    closeButton = SpriteButton(
      text: engine.locale('close'),
      anchor: Anchor.topLeft,
      position: GameUI.decksZoneCloseButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      textConfig: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
      ),
      priority: kDeckPilesZonePriority,
      // isVisible: false,
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
        engine.emit(GameEvents.leaveScene);
      }
    };
    camera.viewport.add(closeButton);

    setAsBattleDeckButton = SpriteButton(
      text: engine.locale('deckbuilding.setAsBattleDeck'),
      anchor: Anchor.topLeft,
      position: GameUI.setAsBattleDeckButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button.png',
      textConfig: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
      ),
      priority: kDeckPilesZonePriority,
      isVisible: false,
    );
    setAsBattleDeckButton.onTapUp = (buttons, position) {
      _setAsBattleDeck(_currentBuildingZone!);
    };
    camera.viewport.add(setAsBattleDeckButton);

    background = SpriteComponent(
      sprite: await Sprite.load('cultivation/cardlibrary_background.png'),
      size: size,
    );
    world.add(background);

    topBar = SpriteComponent2(
      spriteId: 'cultivation/cardlibrary_background_top.png',
      size: Vector2(size.x, GameUI.libraryZonePosition.y),
      priority: kBarPriority,
    );
    world.add(topBar);

    bottomBar = SpriteComponent2(
      spriteId: 'cultivation/cardlibrary_background_bottom.png',
      size: Vector2(size.x,
          size.y - GameUI.libraryZonePosition.y - GameUI.libraryZoneSize.y),
      position:
          Vector2(0, GameUI.libraryZonePosition.y + GameUI.libraryZoneSize.y),
      priority: kBarPriority,
    );
    world.add(bottomBar);

    deckPilesZone = SpriteComponent2(
      spriteId: 'cultivation/cardlibrary_background_deck_piles_zone.png',
      size: Vector2(size.x - GameUI.libraryZoneBackgroundSize.x,
          GameUI.libraryZoneBackgroundSize.y),
      position: Vector2(GameUI.libraryZoneBackgroundSize.x,
          GameUI.libraryZoneBackgroundPosition.y),
    );
    deckPilesZone.onMouseScrollUp = () => _repositionDeckPiles(100);
    deckPilesZone.onMouseScrollDown = () => _repositionDeckPiles(-100);
    world.add(deckPilesZone);

    libraryZone = CardLibraryZone();
    world.add(libraryZone);

    // buildingZone = DeckBuildingZone(limit: 4);
    // world.add(buildingZone);

    // libraryZone.buildingZone = buildingZone;
    // buildingZone.library = libraryZone;

    for (final deckData in _heroDecks) {
      final zone = createNewDeckBuildingZone(deckData: deckData);
      libraryZone.preloadBuildingZones.add(zone);
    }
    createNewDeckBuildingZone();

    cardCraftingArea = CardCraftingArea(
      priority: kBarPriority,
      onStartCraft: onStartCraft,
      onRemoveCard: (card) {
        libraryZone.setCardEnabledById(card.deckId);
        refreshCardData(card as CustomGameCard);
      },
    );

    camera.viewport.add(cardCraftingArea);
  }

  // @override
  // void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
  //   camera.moveBy(-details.delta.toVector2() / camera.viewfinder.zoom);

  //   super.onDragUpdate(pointer, buttons, details);
  // }
}
