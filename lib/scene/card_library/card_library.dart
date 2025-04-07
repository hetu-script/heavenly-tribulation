import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/gestures.dart';
import 'package:hetu_script/utils/uid.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/utils/math.dart' as math;

import '../../widgets/dialog/confirm.dart';
import 'library_zone.dart';
import 'deckbuilding_zone.dart';
import '../../game/ui.dart';
import '../../game/logic.dart';
import '../../engine.dart';
import 'common.dart';
// import 'cardcrafting_area.dart';
import '../../state/states.dart';
import '../../game/data.dart';
import '../../widgets/ui_overlay.dart';
import 'menus.dart';
import '../game_dialog/game_dialog_content.dart';
import '../common.dart';
import '../../common.dart';
import '../particles/light_point.dart';

const kBasicCardKinds = {
  'punch',
  'kick',
  // 'xinfa',
};

const kMaxLightPointCount = 20;

enum CraftType {
  exp,
  money,
  shard,
}

class CardLibraryScene extends Scene {
  static final random = math.Random();

  CardLibraryScene({required super.context}) : super(id: Scenes.cardlibrary);

  late final SpriteComponent background;
  late final SpriteComponent2 topBar, bottomBar, deckPilesZone;
  late final SpriteComponent cardCraftingArea;

  late final CardLibraryZone libraryZone;

  late final SpriteButton closeButton, setBattleDeckButton;
  late final RichTextComponent deckCount, cardCount;
  late final CustomGameCard exit;

  late final SpriteButton orderBy;
  late final SpriteButton filterBy;

  final List<DeckBuildingZone> deckPiles = [];
  DeckBuildingZone? _currentBuildingZone;

  late final PositionComponent deckPilesContainer;

  late final List<dynamic> _heroDecks;

  final List<CustomGameCard> _cardpackCards = [];

  late final RichTextComponent expLabel;
  late final SpriteButton skillBook, expBottle;

  late final SpriteComponent2 barrier;

  late final SpriteButton collectButton;

  late final SpriteButton craftScrollButton;

  late final SpriteButton closeCraftButton;

  CustomGameCard? draggingCard;

  CustomGameCard? _craftingCard;
  CustomGameCard? get craftingCard => _craftingCard;

  final List<SpriteButton> _craftOptionButtons = [];

  final List<LightPoint> _lightPoints = [];

  final List<math.PointOnCircle> _lightPointsPositions = [];

  bool enableCardCraft = false, enableScrollCraft = false;

  CraftType craftType = CraftType.exp;

  /// 最多只显示 4 个光点
  void addExpLightPoints() {
    final int exp = GameData.heroData['unconvertedExp'];
    int lightCount = 0;
    if (exp > 0) {
      lightCount = exp ~/ 1000 + 1;
    }
    if (lightCount > kMaxLightPointCount) {
      lightCount = kMaxLightPointCount;
    }
    while (_lightPoints.length < lightCount) {
      final lightPoint = LightPoint(
        position: _lightPointsPositions.random.position,
        priority: kExpLightPriority,
        preferredSize: Vector2(20, 20),
        flickerRate: 8,
      );
      _lightPoints.add(lightPoint);
      camera.viewport.add(lightPoint);
    }

    while (_lightPoints.length > lightCount) {
      final point = _lightPoints.last;
      point.removeFromParent();
      _lightPoints.removeLast();
    }
  }

  void updateExp() {
    final int exp = GameData.heroData['unconvertedExp'];
    expLabel.text = '${engine.locale('unconvertedExp')}: $exp';

    if (exp > 10000) {
      if (expBottle.spriteId != 'cultivation/bottle3.png') {
        expBottle.tryLoadSprite(
          spriteId: 'cultivation/bottle3.png',
          hoverSpriteId: 'cultivation/bottle3_hover.png',
        );
      }
    } else if (exp > 1000) {
      if (expBottle.spriteId != 'cultivation/bottle2.png') {
        expBottle.tryLoadSprite(
          spriteId: 'cultivation/bottle2.png',
          hoverSpriteId: 'cultivation/bottle2_hover.png',
        );
      }
    } else {
      if (expBottle.spriteId != 'cultivation/bottle1.png') {
        expBottle.tryLoadSprite(
          spriteId: 'cultivation/bottle1.png',
          hoverSpriteId: 'cultivation/bottle1_hover.png',
        );
      }
    }
  }

  Future<void> _enterScene() async {
    updateOrderByButtonText();
    updateFilterByButtonText();
    libraryZone.repositionToTop();
    libraryZone.updateHeroLibrary();
    deckPilesContainer.position.y = GameUI.decksZoneBackgroundPosition.y;

    updateExp();
    addExpLightPoints();

    for (final deckZone in deckPiles) {
      deckZone.updateDeckLimit();
    }

    engine.hetu.invoke('onGameEvent', positionalArgs: ['onEnterCardLibrary']);
  }

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) {
    super.onStart(arguments);

    context.read<EnemyState>().setPrebattleVisible(false);
    context.read<HoverContentState>().hide();
    context.read<ViewPanelState>().clearAll();

    enableCardCraft = arguments['enableCardCraft'] ??
        (GameData.heroData['passives']['enable_cardcraft'] ?? false);
    enableScrollCraft = arguments['enableScrollCraft'] ??
        (GameData.heroData['passives']['enable_scrollcraft'] ?? false);

    craftType = switch (arguments['craftType']) {
      'exp' => CraftType.exp,
      'money' => CraftType.money,
      'shard' => CraftType.shard,
      _ => CraftType.exp,
    };

    Iterable? cardpacksToOpen = arguments['cardpacks'];
    if (cardpacksToOpen != null) {
      showCardpackSelect(selectedItems: cardpacksToOpen);
    }
  }

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

  void calculateVirtualHeight() {
    deckPilesContainer.height =
        deckPiles.length * (GameUI.deckbuildingCardSize.y + GameUI.indent);
  }

  void _setBattleDeck(DeckBuildingZone zone) {
    if (!zone.isCardsEnough) {
      GameDialogContent.show(
          context, engine.locale('deckbuilding_cards_not_enough'));
      return;
    }

    if (!zone.isRequirementMet) {
      GameDialogContent.show(
          context, engine.locale('deckbuilding_card_invalid'));
      return;
    }

    if (!zone.isBattleDeck) {
      zone.setBattleDeck();
      for (final otherZone in deckPiles) {
        if (otherZone != zone && otherZone.isBattleDeck) {
          otherZone.setBattleDeck(false);
        }
      }
      GameData.heroData['battleDeckIndex'] = zone.index;
    } else {
      GameData.heroData['battleDeckIndex'] = -1;
    }
    for (var i = 0; i < deckPiles.length - 1; ++i) {
      _heroDecks[i]['isBattleDeck'] = deckPiles[i].isBattleDeck;
    }
  }

  void onOpenDeckMenu(DeckBuildingZone zone) {
    final menuPosition = RelativeRect.fromLTRB(zone.absolutePosition.x,
        zone.absolutePosition.y, zone.absolutePosition.x, 0.0);
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
    // detailedCount.writeln(
    //     '${engine.locale('deckbuilding_limit_min')}: ${_currentBuildingZone!.limitMin}');
    detailedCount.writeln(
        '${engine.locale('deckbuilding_limit')}: ${_currentBuildingZone!.limit}');
    detailedCount.writeln(
        '${engine.locale('deckbuilding_limit_ephemeral')}: ${_currentBuildingZone!.ephemeralCount}/${_currentBuildingZone!.limitEphemeralMax}');
    // detailedCount.writeln(
    //     '${engine.locale('deckbuilding_limit_ongoing')}: ${_currentBuildingZone!.ongoingCount}/${_currentBuildingZone!.limitOngoingMax}');
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

    if (GameData.heroData['battleDeckIndex'] == zone.index) {
      GameData.heroData['battleDeckIndex'] = -1;
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
      priority: kDeckPilesZonePriority,
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
    Hovertip.hide(_craftingCard!);
    final (_, description) = GameData.getDescriptionFromCardData(
        _craftingCard!.data,
        isDetailed: true);
    Hovertip.show(
      scene: this,
      target: _craftingCard!,
      direction: HovertipDirection.rightTop,
      content: description,
      config: ScreenTextConfig(
        anchor: Anchor.topCenter,
        textAlign: TextAlign.center,
      ),
      width: kCraftingCardInfoWidth,
    );
  }

  void _affixOperation(CustomGameCard card, String id) {
    assert(kCardCraftOperations.contains(id));

    final result = engine.hetu.invoke(id, positionalArgs: [card.data]);

    if (result != null) {
      // 返回的是提示的文本信息
      GameDialogContent.show(context, result);
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
      updateExp();
    }

    if (id == 'dismantle') {
      libraryZone.removeCard(card.id);
      for (final pile in deckPiles) {
        pile.removeCardById(card.id);
      }

      onEndCraft();
      updateExp();
    }
  }

  void _addAffixOperationButton(String id, Vector2 position) {
    final SpriteButton button = SpriteButton(
      position: position,
      spriteId: 'ui/button10.png',
      size: GameUI.buttonSizeMedium,
      text: engine.locale('deckbuilding_$id'),
      priority: kBarrierUIPriority + 100,
      isVisible: false,
    );
    button.onTapUp = (buttons, position) {
      if (!button.isEnabled) return;
      if (buttons == kSecondaryButton) return;
      assert(_craftingCard != null);
      Hovertip.hide(button);
      _affixOperation(_craftingCard!, id);
    };
    button.onMouseEnter = () {
      assert(_craftingCard != null);

      final buffer = StringBuffer();

      if (button.isEnabled) {
        final expCost =
            GameLogic.getCardCraftOperationCost(id, _craftingCard!.data);

        buffer.writeln(engine.locale('deckbuilding_${id}_description'));
        if (expCost > 0) {
          if (id == 'dismantle') {
            buffer.writeln(
                '\n ${engine.locale('deckbuilding_exp_gain')}: <yellow>${expCost.toString()}</>');
          } else {
            buffer.writeln(
                '\n ${engine.locale('deckbuilding_exp_cost')}: <yellow>${expCost.toString()}</>');
          }
        }
      } else {
        buffer.writeln(engine.locale('functionDisabled'));
      }

      Hovertip.show(
        scene: this,
        target: button,
        direction: HovertipDirection.leftTop,
        content: buffer.toString(),
        width: 300,
      );
    };
    button.onMouseExit = () {
      Hovertip.hide(button);
    };
    camera.viewport.add(button);
    _craftOptionButtons.add(button);
  }

  void onStartCraft(CustomGameCard card) {
    skillBook.enableGesture = false;
    expBottle.enableGesture = false;
    expLabel.isVisible = true;
    barrier.isVisible = true;
    closeCraftButton.isVisible = true;

    bool isScroll = card.data['isScroll'] == true;

    for (final button in _craftOptionButtons) {
      button.isVisible = true;
      button.isEnabled = enableCardCraft && !isScroll;
    }

    craftScrollButton.isVisible = true;
    craftScrollButton.isEnabled = enableScrollCraft;

    final clone = card.clone();
    _craftingCard = clone;
    clone.size = GameUI.cardpackCardSize;
    clone.position = GameUI.cardpackCardPositions[1];
    clone.priority = kBarrierUIPriority;
    clone.enableGesture = false;
    camera.viewport.add(clone);
    _showCraftingCardInfo();
  }

  void onEndCraft() async {
    skillBook.enableGesture = true;
    expBottle.enableGesture = true;
    expLabel.isVisible = false;
    barrier.isVisible = false;
    closeCraftButton.isVisible = false;
    for (final button in _craftOptionButtons) {
      button.isVisible = false;
    }
    craftScrollButton.isVisible = false;

    assert(_craftingCard != null);
    updateCardData(_craftingCard!);

    Hovertip.hide(_craftingCard!);
    _craftingCard!.removeFromParent();
    _craftingCard = null;
  }

  void craftScroll() {
    assert(_craftingCard != null);
    if (_craftingCard == null) return;

    final scrollCard = _craftingCard!.clone(deepCopyData: true);
    final oldTitle = scrollCard.data['name'];

    scrollCard.data['id'] = randomUID(withTime: true);
    scrollCard.data['image'] = 'battlecard/illustration/scroll.png';
    scrollCard.title =
        scrollCard.data['name'] = '$oldTitle(${engine.locale('scroll2')})';
    scrollCard.data['isScroll'] = true;

    // scrollCard.data['category'] = 'scroll';
    scrollCard.data['rank'] = 0;
    scrollCard.data['genre'] = 'scroll';
    scrollCard.data['equipment'] = null;
    scrollCard.data['isEphemeral'] = true;

    final (description, _) =
        GameData.getDescriptionFromCardData(scrollCard.data);
    scrollCard.description = description;

    scrollCard.tryLoadSprite(
        illustrationSpriteId: 'battlecard/illustration/scroll.png');

    Hovertip.hide(_craftingCard!);
    _craftingCard!.removeFromParent();
    _craftingCard = scrollCard;
    scrollCard.enableGesture = false;
    camera.viewport.add(scrollCard);
    _showCraftingCardInfo();

    engine.hetu.invoke('acquireCard',
        namespace: 'Player', positionalArgs: [scrollCard.data]);

    libraryZone.updateHeroLibrary();

    craftScrollButton.isEnabled = false;

    for (final button in _craftOptionButtons) {
      button.isEnabled = false;
    }

    engine.play('writing-263642.mp3');
  }

  void updateCardData(CustomGameCard card) {
    final libraryCard = libraryZone.library[card.id];
    if (libraryCard == null) return;

    libraryCard.description = card.description;

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

  void updateFilterByButtonText() {
    filterBy.text =
        '${engine.locale('filter')} - ${engine.locale(libraryZone.filterByOptions.name)}';
  }

  void onOpenCardpack(Iterable cardpacksData) async {
    if (cardpacksData.isEmpty) return;

    dynamic createCard({
      required bool isMainCard,
      required filter,
      bool isIdentified = false,
      int packRank = 0,
    }) {
      final genre = isMainCard
          ? filter['genre']
          : (filter['isBasic'] == true ? 'none' : null);
      final kind = isMainCard
          ? filter['kind']
          : (filter['isBasic'] == true ? kBasicCardKinds.random : null);
      final category = isMainCard
          ? filter['category']
          : (filter['isBasic'] == true ? 'attack' : null);
      final rank = isMainCard ? packRank : null;
      final maxRank = isMainCard ? null : packRank;
      final cardData = engine.hetu.invoke(
        'BattleCard',
        namedArgs: {
          'kind': kind,
          'genre': genre,
          'maxRank': maxRank,
          'category': category,
          'rank': rank,
          'isIdentified': isIdentified,
        },
      );
      return cardData;
    }

    if (cardpacksData.length == 1) {
      final cardpackData = cardpacksData.first;
      final filter = cardpackData['filter'];
      int packRank = filter['rank'] ?? 0;

      skillBook.enableGesture = false;
      barrier.isVisible = true;

      collectButton.text = engine.locale('deckbuilding_identify_all');

      engine.play(GameSound.cardDealt2);
      for (var i = 0; i < 3; ++i) {
        bool isMainCard = i == 1;
        final cardData = createCard(
          isMainCard: isMainCard,
          filter: filter,
          packRank: packRank,
          isIdentified: false,
        );

        final card = GameData.createBattleCardFromData(cardData);
        _cardpackCards.add(card);

        card.showGlow = true;
        card.preferredPriority = kBarrierUIPriority;
        card.resetPriority();
        card.size = Vector2.zero();
        card.position = skillBook.center;

        card.onTapUp = (int buttons, Vector2 position) {
          if (card.data['isIdentified'] != true) {
            unpreviewCard(context);
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
              characterData: GameData.heroData,
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
              characterData: GameData.heroData,
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
    } else {
      // final Iterable cardpacks =
      //     GameData.heroData['inventory'].values.where((itemData) {
      //   return cardpacksData.containsKey(itemData['id']);
      // }).toList();

      engine.play(GameSound.cardDealt2);
      for (final cardpackData in cardpacksData) {
        final filter = cardpackData['filter'];
        int packRank = filter['rank'] ?? 0;
        engine.hetu.invoke('lose',
            namespace: 'Player', positionalArgs: [cardpackData]);
        for (var i = 0; i < 3; ++i) {
          bool isMainCard = i == 1;
          final cardData = createCard(
            isMainCard: isMainCard,
            filter: filter,
            packRank: packRank,
            isIdentified: true,
          );

          engine.hetu.invoke('acquireCard',
              namespace: 'Player', positionalArgs: [cardData]);
        }
      }

      libraryZone.updateHeroLibrary();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final point in _lightPoints) {
      if (!point.isMoving) {
        final targetPosition = _lightPointsPositions.random;
        point.moveTo(
          duration: random.nextDouble() * 2 + 2,
          delay: random.nextDouble() * 2 + 2,
          toPosition: targetPosition.position,
          curve: Curves.easeOut,
        );
      }
    }
  }

  void showCardpackSelect({Iterable? selectedItems}) {
    context.read<ViewPanelState>().toogle(
      ViewPanels.itemSelect,
      arguments: {
        'characterData': GameData.heroData,
        'title': engine.locale('selectCardpack'),
        'filter': {'category': 'cardpack'},
        'multiSelect': true,
        'onSelect': onOpenCardpack,
        'selectedItems': selectedItems,
      },
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _heroDecks = GameData.heroData['battleDecks'];

    _lightPointsPositions.addAll(math.generateDividingPointsFromCircle(
      center: GameUI.expBottlePosition,
      radius: 40,
      number: 20,
    ));

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
      final rank = GameData.heroData['rank'];
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

    libraryZone = CardLibraryZone();
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

    exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'location/card/exit.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
    );
    exit.onTap = (_, __) {
      engine.popScene();
      context.read<EnemyState>().setPrebattleVisible();
    };
    camera.viewport.add(exit);

    orderBy = SpriteButton(
      position: GameUI.orderByButtonPosition,
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
        libraryZone.sortCards(options: option);
        updateOrderByButtonText();
      });
      showMenu(
        context: context,
        items: menu,
        position: menuPosition,
      );
    };
    camera.viewport.add(orderBy);

    filterBy = SpriteButton(
      position: GameUI.filterByButtonPosition,
      size: GameUI.buttonSizeLong,
      spriteId: 'ui/button20.png',
      priority: kBottomBarPriority,
      text: engine.locale('filter'),
    );
    filterBy.onTapUp = (buttons, position) {
      final menuPosition = RelativeRect.fromLTRB(filterBy.position.x,
          filterBy.position.y + filterBy.size.y, filterBy.position.x, 0.0);
      final menu = buildFilterByMenuItems(onSelectedItem: (option) {
        libraryZone.repositionToTop();
        libraryZone.filterCards(options: option);
        updateFilterByButtonText();
      });
      showMenu(
        context: context,
        items: menu,
        position: menuPosition,
      );
    };
    camera.viewport.add(filterBy);

    skillBook = SpriteButton(
      position: GameUI.skillBookPosition,
      size: GameUI.skillBookSize,
      spriteId: 'cultivation/battlebook.png',
      hoverSpriteId: 'cultivation/battlebook_hover.png',
      priority: kBarrierUIPriority,
    );
    skillBook.onTapUp = (buttons, position) {
      if (buttons == kSecondaryButton) return;
      showCardpackSelect();
    };
    skillBook.onMouseEnter = () {
      final cardpackCount =
          engine.hetu.invoke('entityHasItemCategory', positionalArgs: [
        GameData.heroData,
        'cardpack',
      ]);

      final battleCardCount = GameData.heroData['cardLibrary'].length;

      final cardpackHint =
          '${engine.locale('ownedBattleCard')}: <bold ${battleCardCount > 0 ? 'yellow' : 'grey'}>$battleCardCount</>\n'
          '${engine.locale('ownedCardpack')}: <bold ${cardpackCount > 0 ? 'yellow' : 'grey'}>$cardpackCount</>\n'
          '<grey>${engine.locale('deckbuilding_cardpack_hint')}</>';
      Hovertip.show(
        scene: this,
        target: skillBook,
        direction: HovertipDirection.topRight,
        content: cardpackHint,
        config: ScreenTextConfig(textAlign: TextAlign.center),
        width: 240,
      );
    };
    skillBook.onMouseExit = () {
      Hovertip.hide(skillBook);
    };
    camera.viewport.add(skillBook);

    expBottle = SpriteButton(
      position: GameUI.expBottlePosition,
      anchor: Anchor.center,
      size: GameUI.expBottleSize,
      priority: kBarrierUIPriority,
      angle: math.radians(15),
    );
    expBottle.onMouseEnter = () {
      final int exp = GameData.heroData['unconvertedExp'];
      Hovertip.show(
        scene: this,
        target: expBottle,
        direction: HovertipDirection.topCenter,
        content:
            '${engine.locale('unconvertedExp')}: <bold ${exp > 0 ? 'yellow' : 'grey'}>$exp</>',
        width: 150,
        config: ScreenTextConfig(textAlign: TextAlign.center),
      );
    };
    expBottle.onMouseExit = () {
      Hovertip.hide(expBottle);
    };
    camera.viewport.add(expBottle);

    expLabel = RichTextComponent(
      anchor: Anchor.center,
      position: expBottle.center,
      size: Vector2(200, 60),
      priority: kBarrierUIPriority,
      isVisible: false,
      config: ScreenTextConfig(
        outlined: true,
        textStyle: TextStyle(
          color: Colors.yellow,
          fontFamily: GameUI.fontFamily,
          fontSize: 20,
        ),
        anchor: Anchor.bottomCenter,
      ),
    );
    camera.viewport.add(expLabel);

    collectButton = SpriteButton(
      text: engine.locale('deckbuilding_identify_all'),
      anchor: Anchor.center,
      position: GameUI.closeCraftButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      priority: kBarrierUIPriority,
      isVisible: false,
    );
    collectButton.onTapUp = (buttons, position) {
      if (buttons == kSecondaryButton) return;
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
            'acquireCard',
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

    for (var i = 0; i < kCardCraftOperations.length; i++) {
      final operation = kCardCraftOperations[i];
      _addAffixOperationButton(
        operation,
        Vector2(
          GameUI.cardpackCardPositions[1].x -
              (GameUI.buttonSizeMedium.x + GameUI.hugeIndent),
          GameUI.cardpackCardPositions[1].y +
              GameUI.indent +
              (GameUI.buttonSizeMedium.y + GameUI.smallIndent) * i,
        ),
      );
    }

    craftScrollButton = SpriteButton(
      anchor: Anchor.center,
      size: Vector2(180, 180),
      position: Vector2(
        GameUI.size.x / 2,
        GameUI.cardpackCardPositions[1].y +
            GameUI.cardpackCardSize.y +
            GameUI.hugeIndent * 2,
      ),
      spriteId: 'cultivation/scroll.png',
      hoverSpriteId: 'cultivation/scroll_hover.png',
      priority: kBarrierUIPriority,
      isVisible: false,
    );
    craftScrollButton.onTapUp = (buttons, position) {
      if (!craftScrollButton.isEnabled) return;
      if (buttons == kSecondaryButton) return;
      assert(_craftingCard != null);
      craftScroll();
    };
    craftScrollButton.onMouseEnter = () {
      assert(_craftingCard != null);

      final rank = _craftingCard!.data['rank'];

      final bool enabled = craftScrollButton.isEnabled || rank > 0;

      StringBuffer buffer = StringBuffer();
      if (enabled) {
        final expCost = GameLogic.getCardCraftOperationCost(
            'craftScroll', _craftingCard!.data);

        final paperCount =
            engine.hetu.invoke('entityHasItemKind', positionalArgs: [
          GameData.heroData,
          'scroll_paper_rank_$rank',
        ]);

        buffer.writeln(engine.locale('deckbuilding_craft_scroll'));
        buffer.writeln(' ');
        buffer.writeln(
            '${engine.locale('deckbuilding_exp_cost')}: <bold ${expCost > 0 ? 'yellow' : 'grey'}>$expCost</>');
        buffer.writeln(
            '${engine.locale('cultivationRank_$rank')}${engine.locale('rank2')}'
            '${engine.locale('deckbuilding_scroll_paper_count')}: <bold ${paperCount > 0 ? 'yellow' : 'grey'}>$paperCount</>');
      } else {
        buffer.writeln(engine.locale('functionDisabled'));
      }

      Hovertip.show(
        scene: this,
        target: craftScrollButton,
        direction: HovertipDirection.topCenter,
        content: buffer.toString(),
      );
    };
    craftScrollButton.onMouseExit = () {
      Hovertip.hide(craftScrollButton);
    };
    camera.viewport.add(craftScrollButton);

    closeCraftButton = SpriteButton(
      text: engine.locale('close'),
      anchor: Anchor.center,
      position: GameUI.closeCraftButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      priority: kBarrierUIPriority,
      isVisible: false,
    );
    closeCraftButton.onTapUp = (buttons, position) {
      onEndCraft();
    };
    camera.viewport.add(closeCraftButton);
  }

  @override
  void onMount() {
    super.onMount();

    _enterScene();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneWidget(scene: this),
        GameUIOverlay(
          enableNpcs: false,
          enableLibrary: false,
          enableAutoExhaust: false,
          action: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: GameUI.foregroundColor),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                GameDialogContent.show(
                  context,
                  engine.locale('help_cardlibrary'),
                  style: TextStyle(color: Colors.yellow),
                );
              },
              icon: Icon(
                Icons.question_mark,
                size: 20.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
