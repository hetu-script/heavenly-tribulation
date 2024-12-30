import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/sprite_component2.dart';
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

enum DeckMenuItems {
  setAsBattleDeck,
  editDeck,
  deleteDeck,
}

List<PopupMenuEntry<DeckMenuItems>> buildDeckPopUpMenuItems(
    {void Function(DeckMenuItems item)? onItemPressed}) {
  return <PopupMenuEntry<DeckMenuItems>>[
    buildMenuItem(
      item: DeckMenuItems.setAsBattleDeck,
      name: engine.locale('deckbuilding.setAsBattleDeck'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: DeckMenuItems.editDeck,
      name: engine.locale('edit'),
      onItemPressed: onItemPressed,
    ),
    const PopupMenuDivider(height: 12.0),
    buildMenuItem(
      item: DeckMenuItems.deleteDeck,
      name: engine.locale('delete'),
      onItemPressed: onItemPressed,
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

  late final SpriteButton closeDeck;
  late final RichTextComponent cardCount;

  final List<DeckBuildingZone> deckPiles = [];
  DeckBuildingZone? currentBuildingZone;

  double _deckPilesZoneVirtualHeight = 0, _curYOffset = 0;

  late final dynamic _heroData;
  late final int _cardLimit;

  int _currentDeckIndex = -1;

  late final List<dynamic> _heroDecks;

  CardLibraryScene({
    required super.controller,
    required super.context,
  }) : super(id: 'deckBuilding');

  void _loadHeroBattleDecks() {
    if (_heroDecks.isEmpty) {
      createNewDeckBuildingZone();
    } else {
      for (final deckData in _heroDecks) {
        final title = deckData['title'];
        final isBattleDeck = deckData['isBattleDeck'];
        final zone = createNewDeckBuildingZone(
          title: title,
          isBattleDeck: isBattleDeck,
        );
        final List<dynamic>? cardIds = deckData['cards'];
        if (cardIds != null) {
          for (final cardId in cardIds) {
            assert(libraryZone.library.containsKey(cardId));
            final card = libraryZone.library[cardId];
            final clone = card!.clone();
            zone.addCard(clone);
          }
        }
      }
    }
  }

  void calculateVirtualHeight() {
    _deckPilesZoneVirtualHeight =
        deckPiles.length * (GameUI.deckbuildingCardSize.y + GameUI.indent);
  }

  void onOpenDeckMenu(DeckBuildingZone zone) {
    final menuPosition = RelativeRect.fromLTRB(
        zone.position.x, zone.position.y, zone.position.x, 0.0);
    final menu = buildDeckPopUpMenuItems(onItemPressed: (item) {
      switch (item) {
        case DeckMenuItems.setAsBattleDeck:
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
              _heroData['battleDeckIndex'] = null;
            }
          }
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

  void _refreshCardCount() {
    cardCount.text =
        '${engine.locale('deckbuilding.cardCount')}: ${currentBuildingZone!.cards.length}/${currentBuildingZone!.limit}';
  }

  void onEditDeck(DeckBuildingZone zone) {
    for (final existedZone in deckPiles) {
      if (existedZone != zone) {
        existedZone.isVisible = false;
      }
    }

    currentBuildingZone = libraryZone.buildingZone = zone;

    _refreshCardCount();
    cardCount.isVisible = true;
    closeDeck.isVisible = true;

    zone.expand();
  }

  void _deleteDeck(DeckBuildingZone zone) async {
    final value = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) =>
          ConfirmDialog(description: engine.locale('dangerOperationPrompt')),
    );

    if (value == true) {
      deckPiles.remove(zone);
      zone.dispose();
    }

    if (deckPiles.isEmpty) {
      createNewDeckBuildingZone();
    }

    _deckPilesZoneVirtualHeight +=
        GameUI.deckbuildingCardSize.y + GameUI.indent;

    _repositionDeckPiles();
  }

  void onCloseDeck() async {
    closeDeck.isVisible = false;
    cardCount.isVisible = false;

    assert(currentBuildingZone != null);
    await currentBuildingZone!.collapse();

    if (currentBuildingZone!.cards.isEmpty) {
      if (currentBuildingZone != deckPiles.last && deckPiles.length > 1) {
        deckPiles.remove(currentBuildingZone);
        currentBuildingZone!.removeFromParent();
      }
    } else {
      for (final card in currentBuildingZone!.cards) {
        libraryZone.setCardEnabledById(card.deckId, true);
      }
      if (deckPiles.last == currentBuildingZone) {
        createNewDeckBuildingZone();
      }
    }

    for (final zone in deckPiles) {
      zone.isVisible = true;
    }

    libraryZone.buildingZone = currentBuildingZone = null;

    _repositionDeckPiles();
  }

  DeckBuildingZone createNewDeckBuildingZone({
    String? title,
    bool? isBattleDeck,
  }) {
    final zone = DeckBuildingZone(
      title: title,
      isBattleDeck: isBattleDeck,
      limit: _cardLimit,
      position: Vector2(
          GameUI.decksZoneBackgroundPosition.x,
          GameUI.decksZoneBackgroundPosition.y +
              _deckPilesZoneVirtualHeight +
              _curYOffset),
      // priority: kDeckPilesZonePriority,
      onEditDeck: (zone) => onEditDeck(zone),
      onOpenDeckMenu: (zone) => onOpenDeckMenu(zone),
      onDeckEdited: (zone) => _refreshCardCount(),
    );
    currentBuildingZone = zone;
    currentBuildingZone!.library = libraryZone;
    world.add(currentBuildingZone!);
    deckPiles.add(currentBuildingZone!);

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

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _heroData = engine.hetu.fetch('hero');
    final int rank = _heroData['cultivationRank'];
    assert(rank >= 0);
    if (rank == 0) {
      _cardLimit = 3;
    } else {
      _cardLimit = rank + 2;
    }
    _heroDecks = _heroData['battleDecks'];

    closeDeck = SpriteButton(
      text: engine.locale('close'),
      anchor: Anchor.topLeft,
      position: GameUI.decksZoneCloseButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      textConfig: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
      ),
      priority: kDeckPilesZonePriority,
      isVisible: false,
    );
    closeDeck.onTapUp = (buttons, position) {
      onCloseDeck();
    };
    camera.viewport.add(closeDeck);

    cardCount = RichTextComponent(
      anchor: Anchor.center,
      position: Vector2(closeDeck.center.x,
          closeDeck.center.y - closeDeck.size.y - GameUI.smallIndent),
      size: GameUI.buttonSizeMedium,
      config: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
        anchor: Anchor.center,
      ),
      priority: kDeckPilesZonePriority,
      isVisible: false,
    );
    camera.viewport.add(cardCount);

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

    _loadHeroBattleDecks();
  }

  // @override
  // void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
  //   camera.moveBy(-details.delta.toVector2() / camera.viewfinder.zoom);

  //   super.onDragUpdate(pointer, buttons, details);
  // }
}
