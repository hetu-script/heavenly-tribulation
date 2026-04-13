import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/gestures.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/utils/math.dart' as math;
import 'package:samsara/widgets/ui/menu_builder.dart';
import 'package:samsara/hover_info.dart';

import '../../extensions.dart';
import '../../widgets/dialog/confirm.dart';
import 'library_zone.dart';
import 'deckbuilding_zone.dart';
import '../../ui.dart';
import '../../global.dart';
import 'common.dart';
import '../../state/states.dart';
import '../../data/game.dart';
import '../common.dart';
import '../../data/common.dart';
import '../particles/light_point.dart';
import '../../widgets/dialog/input_string.dart';
import '../../widgets/common.dart';
import '../../game_events.dart';

const kMaxLightPointCount = 20;

const _kBattleCardBasicBuffs = [
  'punch',
  'kick',
  'xinfa',
  'shenfa',
  'qinggong',
];

enum CraftType {
  exp,
  money,
  shard,
}

enum DeckMenuItems {
  setTitle,
  setAsBattleDeck,
  editDeck,
  deleteDeck,
}

enum OrderByOptions {
  byAcquiredTimeDescending,
  byAcquiredTimeAscending,
  byLevelDescending,
  byLevelAscending,
  byRankDescending,
  byRankAscending,
}

enum FilterByOptions {
  all,
  requirementsMet,
  categoryAttack,
  categoryBuff,
  spellcraft,
  swordcraft,
  avatar,
  bodyforge,
  vitality,
  kind_punch,
  kind_kick,
  kind_qinna,
  kind_dianxue,
  kind_sword,
  kind_sabre,
  kind_staff,
  kind_spear,
  kind_bow,
  kind_dart,
  kind_flying_sword,
  kind_shenfa,
  kind_qinggong,
  kind_xinfa,
  kind_airbend,
  kind_firebend,
  kind_waterbend,
  kind_lightning_control,
  kind_earthbend,
  kind_plant_control,
  kind_sigil,
  kind_power_word,
  kind_scripture,
  kind_music,
  kind_array,
  kind_potion,
  kind_scroll,
}

class CardLibraryScene extends Scene {
  CardLibraryScene({
    this.isEditorMode = false,
  }) : super(id: Scenes.library);

  bool _isInitializing = true;
  final bool isEditorMode;

  late final SpriteComponent background;
  late final SpriteComponent2 topBar, bottomBar, deckPilesZone;
  late final SpriteComponent cardCraftZoneDecoration;

  late final CardLibraryZone libraryZone;
  final List<DeckBuildingZone> heroDeckZones = [];

  late final SpriteButton closeButton, setBattleDeckButton;
  late final RichTextComponent deckCount, cardCount;
  late final CustomGameCard exit;

  late final SpriteButton orderBy;
  late final SpriteButton filterBy;

  final List<DeckBuildingZone> deckPiles = [];
  DeckBuildingZone? currentBuildingZone;

  late final PositionComponent deckPilesContainer;

  late final List<dynamic> heroDecks;

  final List<CustomGameCard> cardpackCards = [];

  late final SpriteButton skillBook; // , expBottle;
  // late final RichTextComponent expLabel;

  late final SpriteComponent2 barrier;

  late final SpriteButton collectButton;

  late final SpriteButton dismantleButton;

  late final SpriteButton closeCraftButton;

  CustomGameCard? draggingCard;

  CustomGameCard? craftingCard;

  final List<SpriteButton> craftOptionButtons = [];

  final List<LightPoint> lightPoints = [];

  final List<math.PointOnCircle> _lightPointsPositions = [];

  FutureOr<void> Function()? onEnterScene;

  bool enableCardCraft = false, enableScrollCraft = false;

  CraftType craftType = CraftType.exp;

  /// 最多只显示 4 个光点
  // void updateExpLightPoints() {
  //   final int exp = GameData.hero['exp'];
  //   int lightCount = 0;
  //   if (exp > 0) {
  //     lightCount = exp ~/ 1000 + 1;
  //   }
  //   if (lightCount > kMaxLightPointCount) {
  //     lightCount = kMaxLightPointCount;
  //   }
  //   while (lightPoints.length < lightCount) {
  //     final lightPoint = LightPoint(
  //       assetId: 'light_point.png',
  //       position: _lightPointsPositions.random.position,
  //       priority: kExpLightPriority,
  //       preferredSize: Vector2(20, 20),
  //       flickerRate: 8,
  //     );
  //     lightPoints.add(lightPoint);
  //     camera.viewport.add(lightPoint);
  //   }

  //   while (lightPoints.length > lightCount) {
  //     final point = lightPoints.last;
  //     point.removeFromParent();
  //     lightPoints.removeLast();
  //   }
  // }

  // void updateExp() {
  //   final int exp = GameData.hero['exp'];
  //   expLabel.text = '${engine.locale('exp')}: $exp';

  //   if (exp > 10000) {
  //     if (expBottle.spriteId != 'cultivation/bottle3.png') {
  //       expBottle.tryLoadSprite(
  //         spriteId: 'cultivation/bottle3.png',
  //         hoverSpriteId: 'cultivation/bottle3_hover.png',
  //       );
  //     }
  //   } else if (exp > 1000) {
  //     if (expBottle.spriteId != 'cultivation/bottle2.png') {
  //       expBottle.tryLoadSprite(
  //         spriteId: 'cultivation/bottle2.png',
  //         hoverSpriteId: 'cultivation/bottle2_hover.png',
  //       );
  //     }
  //   } else {
  //     if (expBottle.spriteId != 'cultivation/bottle1.png') {
  //       expBottle.tryLoadSprite(
  //         spriteId: 'cultivation/bottle1.png',
  //         hoverSpriteId: 'cultivation/bottle1_hover.png',
  //       );
  //     }
  //   }
  // }

  @override
  void onStart([dynamic arguments]) {
    super.onStart(arguments);

    engine.context.read<EnemyState>().setPrebattleVisible(false);
    engine.context.read<HoverContentState>().hide();
    engine.context.read<ViewPanelState>().clearAll();

    enableCardCraft = arguments?['enableCardCraft'] ??
        (GameData.hero['passives']['enable_cardcraft'] ?? false);
    enableScrollCraft = arguments?['enableScrollCraft'] ??
        (GameData.hero['passives']['enable_scrollcraft'] ?? false);

    onEnterScene = arguments?['onEnterScene'];

    craftType = switch (arguments?['craftType']) {
      'exp' => CraftType.exp,
      'money' => CraftType.money,
      'shard' => CraftType.shard,
      _ => CraftType.exp,
    };

    Iterable? cardpacksToOpen = arguments?['cardpacks'];
    if (cardpacksToOpen != null) {
      arguments.remove('cardpacks');
      engine.setSceneArguments(id, arguments);
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

  void setBattleDeck(DeckBuildingZone zone) async {
    if (!zone.isCardsEnough) {
      dialog.pushDialog('deckbuilding_cards_not_enough');
      await dialog.execute();
      return;
    }

    if (!zone.isRequirementMet) {
      dialog.pushDialog('deckbuilding_card_invalid');
      await dialog.execute();
      return;
    }

    if (!zone.isBattleDeck) {
      zone.setBattleDeck();
      for (final otherZone in deckPiles) {
        if (otherZone != zone && otherZone.isBattleDeck) {
          otherZone.setBattleDeck(false);
        }
      }
      GameData.hero['battleDeckIndex'] = zone.index;
    } else {
      GameData.hero['battleDeckIndex'] = -1;
    }
    for (var i = 0; i < deckPiles.length - 1; ++i) {
      heroDecks[i]['isBattleDeck'] = deckPiles[i].isBattleDeck;
    }
  }

  void onOpenDeckMenu(DeckBuildingZone zone) {
    showFluentMenu(
      cursor: GameUI.cursor,
      position: zone.absolutePosition.toOffset(),
      items: {
        engine.locale('deckbuilding_set_title'): DeckMenuItems.setTitle,
        engine.locale('deckbuilding_set_battle_deck'):
            DeckMenuItems.setAsBattleDeck,
        engine.locale('edit'): DeckMenuItems.editDeck,
        engine.locale('delete'): DeckMenuItems.deleteDeck,
      },
      onSelectedItem: (item) async {
        switch (item) {
          case DeckMenuItems.setTitle:
            final String? title = await showDialog(
              context: engine.context,
              builder: (context) {
                return InputStringDialog(
                  title: engine.locale('inputName'),
                );
              },
            );
            if (title?.isBlank ?? true) return;
            zone.title = title;
            zone.updateTitle();
            final deck = GameData.hero['battleDecks'][zone.index];
            assert(deck != null);
            deck['title'] = title;
          case DeckMenuItems.setAsBattleDeck:
            setBattleDeck(zone);
          case DeckMenuItems.editDeck:
            onEditDeck(zone);
          case DeckMenuItems.deleteDeck:
            deleteDeck(zone);
        }
      },
    );
  }

  void updateDeckCount() {
    deckCount.text =
        '${engine.locale('deckbuilding_deck_count')}: ${deckPiles.length - 1}';
  }

  void updateCardCount(DeckBuildingZone zone) {
    final detailedCount = StringBuffer();
    detailedCount.writeln(
        '${engine.locale('deckbuilding_card_count')}: ${zone.cards.length}');
    // detailedCount.writeln(
    //     '${engine.locale('deckbuilding_limit_min')}: ${_currentBuildingZone!.limitMin}');
    if (currentBuildingZone != null) {
      detailedCount.writeln(
          '${engine.locale('deckbuilding_limit')}: ${currentBuildingZone!.limit}');
      detailedCount.writeln(
          '${engine.locale('deckbuilding_limit_ongoing')}: ${currentBuildingZone!.ongoingCount}/${currentBuildingZone!.limitOngoingMax}');
    } // detailedCount.writeln(
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

    currentBuildingZone = libraryZone.buildingZone = zone;

    deckPilesContainer.position.y = GameUI.decksZoneBackgroundPosition.y -
        zone.index * (GameUI.deckbuildingCardSize.y + GameUI.indent);

    updateCardCount(zone);

    zone.expand();
  }

  void deleteDeckBuildingZone(DeckBuildingZone zone) {
    deckPiles.remove(zone);
    zone.dispose();
    _resizeDeckPilesContainer();
    for (var i = 0; i < deckPiles.length; ++i) {
      final zone = deckPiles[i];
      zone.index = i;
      zone.position =
          Vector2(0, i * (GameUI.deckbuildingCardSize.y + GameUI.indent));
    }

    checkDeckPilesContainerPosition();
  }

  void deleteDeck(DeckBuildingZone zone, {bool warning = true}) async {
    if (warning) {
      final value = await showDialog<bool>(
        context: engine.context,
        builder: (context) =>
            ConfirmDialog(description: engine.locale('dangerOperationPrompt')),
      );

      if (value == false) return;
    }

    if (GameData.hero['battleDeckIndex'] == zone.index) {
      GameData.hero['battleDeckIndex'] = -1;
    }
    heroDecks.removeAt(zone.index);

    deleteDeckBuildingZone(zone);
    if (deckPiles.isEmpty) {
      createNewDeckBuildingZone();
    }
    updateDeckCount();
  }

  void onCloseDeck() async {
    exit.isVisible = true;
    deckPilesZone.enableGesture = true;
    deckCount.isVisible = true;
    cardCount.isVisible = false;
    setBattleDeckButton.isVisible = false;
    closeButton.isVisible = false;

    assert(currentBuildingZone != null);
    await currentBuildingZone!.collapse(animated: false);

    if (currentBuildingZone!.cards.isEmpty) {
      if (currentBuildingZone != deckPiles.last && deckPiles.length > 1) {
        deleteDeck(currentBuildingZone!, warning: false);
      }
    } else {
      for (final card in currentBuildingZone!.cards) {
        libraryZone.setCardEnabledById(card.uniqueId, true);
      }
      if (deckPiles.last == currentBuildingZone) {
        createNewDeckBuildingZone();
      }

      currentBuildingZone!.save();
    }

    for (final zone in deckPiles) {
      zone.isVisible = true;
    }

    libraryZone.buildingZone = currentBuildingZone = null;

    updateDeckCount();
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
      onDeckEdited: (buildingZone) => updateCardCount(buildingZone),
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

  void checkDeckPilesContainerPosition() {
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

  void repositionDeckPiles(double offsetY) {
    deckPilesContainer.position.y += offsetY;

    checkDeckPilesContainerPosition();
  }

  void showCraftingCardInfo() {
    assert(craftingCard != null);
    Hovertip.hide(craftingCard!);
    final (_, description) = GameData.getBattleCardDescription(
        craftingCard!.data,
        showRequirement: false,
        showDetailedHint: false,
        isDetailed: true);
    Hovertip.show(
      scene: this,
      target: craftingCard!,
      direction: HovertipDirection.leftTop,
      content: description,
      config: ScreenTextConfig(
        anchor: Anchor.topCenter,
        textAlign: TextAlign.center,
      ),
      width: kCraftingCardInfoWidth,
    );
  }

  void onUseCraftMaterial(dynamic craftmeterialData) {
    assert(craftingCard != null);

    final category = craftmeterialData['category'] as String;

    if (category == 'scroll_paper') {
      craftScroll(craftmeterialData);
      return;
    }

    final operationId = category.replaceAll('craftmaterial_', '');

    assert(kCardCraftOperations.contains(operationId),
        'Unknown card crafting operation: $operationId');

    final result = engine.hetu.invoke(operationId,
        positionalArgs: [craftingCard!.data, craftmeterialData['rank']]);

    if (result != null) {
      // 返回的是提示的文本信息
      dialog.pushDialog(result);
      dialog.execute();
    } else {
      engine.hetu.invoke(
        'lose',
        namespace: 'Player',
        positionalArgs: [craftmeterialData],
      );

      engine.play(GameSound.anvil);

      addHintText(
        engine.locale('craft_${operationId}_hint'),
        position: craftingCard!.center,
        offsetY: 30.0,
        textStyle: TextStyle(
          fontFamily: GameUI.fontFamilyKaiti,
        ),
        horizontalVariation: 0.0,
        verticalVariation: 0.0,
      );

      final (description, _) =
          GameData.getBattleCardDescription(craftingCard!.data);
      craftingCard!.description = description;
      showCraftingCardInfo();
    }
  }

  void dismantleCard(String cardId) {
    assert(craftingCard != null);

    engine.hetu.invoke(
      'dismantleCard',
      namespace: 'Player',
      positionalArgs: [craftingCard!.data],
      namedArgs: {'gainFragments': true},
    );

    libraryZone.removeCardById(cardId);
    for (final pile in deckPiles) {
      pile.removeCardById(cardId);
    }

    engine.play(GameSound.paperrip);

    endCraft();
  }

  void startCraft(CustomGameCard card) {
    engine.context.read<HoverContentState>().hide();

    skillBook.enableGesture = false;
    // expBottle.enableGesture = false;
    // expLabel.isVisible = true;
    barrier.isVisible = true;
    closeCraftButton.isVisible = true;

    bool isScroll = card.data['genre'] == 'scroll';

    dismantleButton.isVisible = true;
    dismantleButton.isEnabled = !isScroll;

    if (!isScroll) {
      if (enableCardCraft && enableScrollCraft) {
        engine.context.read<CraftState>().setCrafting(true,
            rank: card.data['rank'], craftMode: CraftMode.all);
      } else if (enableCardCraft) {
        engine.context.read<CraftState>().setCrafting(true,
            rank: card.data['rank'], craftMode: CraftMode.affix);
      } else if (enableScrollCraft) {
        engine.context.read<CraftState>().setCrafting(true,
            rank: card.data['rank'], craftMode: CraftMode.scroll);
      }
    }

    final clone = card.clone();
    craftingCard = clone;
    clone.size = GameUI.cardpackCardSize;
    clone.position = GameUI.cardpackCardPositions[1];
    clone.priority = kBarrierUIPriority;
    clone.enableGesture = false;
    camera.viewport.add(clone);
    showCraftingCardInfo();

    engine.addEventListener(
        Scenes.library, GameEvents.craftMaterialSelected, onUseCraftMaterial);
  }

  void endCraft() async {
    Hovertip.hideAll();
    engine.context.read<CraftState>().setCrafting(false);

    skillBook.enableGesture = true;
    // expBottle.enableGesture = true;
    // expLabel.isVisible = false;
    barrier.isVisible = false;
    closeCraftButton.isVisible = false;
    dismantleButton.isVisible = false;

    assert(craftingCard != null);
    updateCardData(craftingCard!);

    Hovertip.hide(craftingCard!);
    craftingCard!.removeFromParent();
    craftingCard = null;

    engine.removeEventListeners(Scenes.library);
  }

  void craftScroll(dynamic paper) {
    assert(craftingCard != null);
    final scrollCard = craftingCard!;

    engine.hetu.invoke('craftScroll',
        namespace: 'Player', positionalArgs: [scrollCard.data]);

    libraryZone.removeCardById(scrollCard.id);
    for (final pile in deckPiles) {
      pile.removeCardById(scrollCard.id);
    }

    scrollCard.id = scrollCard.data['id'];
    scrollCard.title = scrollCard.data['name'];
    final (description, _) = GameData.getBattleCardDescription(scrollCard.data);
    scrollCard.description = description;
    scrollCard.tryLoadSprite(
        illustrationSpriteId: 'battlecard/illustration/scroll.png');

    showCraftingCardInfo();

    engine.context.read<CraftState>().setCrafting(false);
    engine.context.read<HoverContentState>().hide();

    libraryZone.addCardByData(craftingCard!.data);
    libraryZone.sortCards();

    addHintText(
      engine.locale('craft_scroll_hint'),
      position: craftingCard!.center,
      offsetY: 30.0,
      textStyle: TextStyle(
        fontFamily: GameUI.fontFamilyKaiti,
      ),
      horizontalVariation: 0.0,
      verticalVariation: 0.0,
    );

    engine.play(GameSound.writing);
  }

  void updateCardData(CustomGameCard card) {
    final libraryCard = libraryZone.library[card.id];
    if (libraryCard == null) return;

    libraryCard.description = card.description;

    for (final zone in deckPiles) {
      if (zone.cards.isNotEmpty) {
        final Iterable<GameCard> cards = zone.cards.where((card) {
          return card.uniqueId == libraryCard.id;
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
    }) {
      final bool basic = filter['isBasic'] ?? false;
      final category = isMainCard ? filter['category'] : null;
      final genre = isMainCard ? filter['genre'] : (basic ? 'none' : null);
      final rank = isMainCard ? filter['rank'] : (basic ? 0 : null);
      final kind = isMainCard
          ? filter['kind']
          : (basic
              ? GameData.random.nextIterable(_kBattleCardBasicBuffs)
              : null);
      final maxRank = filter['rank'];
      final cardData = engine.hetu.invoke(
        'BattleCard',
        namedArgs: {
          'kind': kind,
          'genre': genre,
          'category': category,
          'rank': rank,
          'maxRank': maxRank,
        },
      );
      return cardData;
    }

    if (cardpacksData.length == 1) {
      final cardpackData = cardpacksData.first;

      skillBook.enableGesture = false;
      barrier.isVisible = true;

      collectButton.text = engine.locale('deckbuilding_identify_all');

      engine.play(GameSound.dealCard);
      for (var i = 0; i < 3; ++i) {
        bool isMainCard = i == 1;
        final cardData = createCard(
          isMainCard: isMainCard,
          filter: cardpackData['filter'],
        );

        final card = GameData.createBattleCard(cardData);
        cardpackCards.add(card);

        card.preferredPriority = kBarrierUIPriority;
        card.resetPriority();
        card.size = Vector2.zero();
        card.position = skillBook.center;
        card.onTapUp = (int button, Vector2 position) {
          if (card.isFlipped) {
            unpreviewCard();
            engine.play(GameSound.craft);
            card.isFlipped = false;
            final (description, _) =
                GameData.getBattleCardDescription(card.data);
            card.description = description;
            previewCard(
              'cardpack_card_${card.id}',
              card.data,
              card.toAbsoluteRect(),
              character: GameData.hero,
            );
          }
          final unidentifiedCards =
              cardpackCards.where((card) => card.isFlipped == true);
          if (unidentifiedCards.isEmpty) {
            collectButton.text = engine.locale('deckbuilding_collect_all');
          }
        };

        card.onPreviewed = () {
          card.showGlow = true;
          if (card.isFlipped) return;
          previewCard(
            'cardpack_card_${card.id}',
            card.data,
            card.toAbsoluteRect(),
            character: GameData.hero,
          );
        };
        card.onUnpreviewed = () {
          card.showGlow = false;
          if (card.isFlipped) return;
          unpreviewCard();
        };

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
            engine.play(GameSound.dealDeck);
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
        namedArgs: {'incurIncident': false},
      );
    } else {
      // final Iterable cardpacks =
      //     GameData.heroData['inventory'].values.where((itemData) {
      //   return cardpacksData.containsKey(itemData['id']);
      // }).toList();

      engine.play(GameSound.dealCard);
      for (final cardpackData in cardpacksData) {
        engine.hetu.invoke(
          'lose',
          namespace: 'Player',
          positionalArgs: [cardpackData],
          namedArgs: {'incurIncident': false},
        );
        for (var i = 0; i < 3; ++i) {
          bool isMainCard = i == 1;
          final cardData = createCard(
            isMainCard: isMainCard,
            filter: cardpackData['filter'],
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

    for (final point in lightPoints) {
      if (!point.isMoving) {
        final targetPosition = _lightPointsPositions.random;
        point.moveTo(
          duration: LightPoint.random.nextDouble() * 2 + 2,
          delay: LightPoint.random.nextDouble() * 2 + 2,
          toPosition: targetPosition.position,
          curve: Curves.easeOut,
        );
      }
    }
  }

  void showCardpackSelect({Iterable? selectedItems}) {
    engine.context.read<ItemSelectState>().show(
          GameData.hero,
          title: engine.locale('selectCardpack'),
          filter: {'category': 'cardpack'},
          multiSelect: true,
          onSelect: onOpenCardpack,
          selectedItems: selectedItems,
        );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    heroDecks = GameData.hero['battleDecks'];

    // _lightPointsPositions.addAll(math.generateDividingPointsOnCircle(
    //   center: GameUI.expBottlePosition,
    //   radius: 40,
    //   number: 20,
    // ));

    barrier = SpriteComponent2(
      size: size,
      color: GameUI.barrierColor,
      priority: kBarrierPriority,
      isVisible: false,
      enableGesture: true,
    );
    barrier.onTapUp = (button, position) {
      if (button == kSecondaryButton) {
        if (craftingCard != null) {
          endCraft();
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
    deckPilesZone.onMouseScrollUp = (position) => repositionDeckPiles(100);
    deckPilesZone.onMouseScrollDown = (position) => repositionDeckPiles(-100);
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
        textStyle: TextStyle(fontFamily: GameUI.fontFamilyKaiti),
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
        textStyle: TextStyle(fontFamily: GameUI.fontFamilyKaiti),
        anchor: Anchor.bottomCenter,
      ),
      priority: kDeckPilesZonePriority,
      isVisible: false,
      enableGesture: true,
    );
    cardCount.onMouseEnter = () {
      assert(currentBuildingZone != null);
      final cardCountHint = StringBuffer();
      final rank = GameData.hero['rank'];
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
    closeButton.onTapUp = (button, position) {
      assert(currentBuildingZone != null);
      onCloseDeck();
      // else if (cardCraftingArea.isCrafting) {
      //   onEndCraft();
      // }
    };
    camera.viewport.add(closeButton);

    setBattleDeckButton = SpriteButton(
      text: engine.locale('deckbuilding_set_battle_deck'),
      anchor: Anchor.topLeft,
      position: GameUI.deckbuildingZoneButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button.png',
      priority: kDeckPilesZonePriority,
      isVisible: false,
    );
    setBattleDeckButton.onTapUp = (button, position) {
      setBattleDeck(currentBuildingZone!);
    };
    camera.viewport.add(setBattleDeckButton);

    libraryZone = CardLibraryZone();
    world.add(libraryZone);

    cardCraftZoneDecoration = SpriteComponent(
      sprite: await Sprite.load('cultivation/cardlibrary_cardcraft.png'),
      size: GameUI.cardCraftZoneSize,
      position: GameUI.cardCraftZonePosition,
      priority: kTopBarPriority + 10,
    );
    world.add(cardCraftZoneDecoration);

    exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'location/card/exit.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
    );
    exit.onTap = (_, __) {
      engine.popScene();
      engine.context.read<EnemyState>().setPrebattleVisible();
    };
    camera.viewport.add(exit);

    orderBy = SpriteButton(
      position: GameUI.orderByButtonPosition,
      size: GameUI.buttonSizeLong,
      spriteId: 'ui/button20.png',
      priority: kBottomBarPriority,
      text: engine.locale('sort'),
    );
    orderBy.onTapUp = (button, position) {
      showFluentMenu<OrderByOptions>(
        cursor: GameUI.cursor,
        position: orderBy.bottomLeft.toOffset(),
        items: {
          engine.locale('acquiredTime'): {
            engine.locale('descending'):
                OrderByOptions.byAcquiredTimeDescending,
            engine.locale('ascending'): OrderByOptions.byAcquiredTimeAscending,
          },
          engine.locale('level'): {
            engine.locale('descending'): OrderByOptions.byLevelDescending,
            engine.locale('ascending'): OrderByOptions.byLevelAscending,
          },
          engine.locale('cultivationRank'): {
            engine.locale('descending'): OrderByOptions.byRankDescending,
            engine.locale('ascending'): OrderByOptions.byRankAscending,
          },
        },
        onSelectedItem: (OrderByOptions option) {
          libraryZone.repositionToTop();
          libraryZone.sortCards(options: option);
          updateOrderByButtonText();
        },
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
    filterBy.onTapUp = (button, position) {
      showFluentMenu<FilterByOptions>(
        cursor: GameUI.cursor,
        position: filterBy.bottomLeft.toOffset(),
        items: {
          engine.locale('all'): FilterByOptions.all,
          engine.locale('requirementsMet'): FilterByOptions.requirementsMet,
          engine.locale('category'): {
            engine.locale('attack'): FilterByOptions.categoryAttack,
            engine.locale('buff'): FilterByOptions.categoryBuff,
          },
          engine.locale('genre'): {
            engine.locale('spellcraft'): FilterByOptions.spellcraft,
            engine.locale('swordcraft'): FilterByOptions.swordcraft,
            engine.locale('bodyforge'): FilterByOptions.bodyforge,
            engine.locale('avatar'): FilterByOptions.avatar,
            engine.locale('vitality'): FilterByOptions.vitality,
          },
          engine.locale('martialArts'): {
            engine.locale('kind_punch'): FilterByOptions.kind_punch,
            engine.locale('kind_kick'): FilterByOptions.kind_kick,
            engine.locale('kind_qinna'): FilterByOptions.kind_qinna,
            engine.locale('kind_dianxue'): FilterByOptions.kind_dianxue,
            engine.locale('kind_sword'): FilterByOptions.kind_sword,
            engine.locale('kind_sabre'): FilterByOptions.kind_sabre,
            engine.locale('kind_staff'): FilterByOptions.kind_staff,
            engine.locale('kind_spear'): FilterByOptions.kind_spear,
            engine.locale('kind_bow'): FilterByOptions.kind_bow,
            engine.locale('kind_dart'): FilterByOptions.kind_dart,
            engine.locale('kind_shenfa'): FilterByOptions.kind_shenfa,
            engine.locale('kind_qinggong'): FilterByOptions.kind_qinggong,
            engine.locale('kind_xinfa'): FilterByOptions.kind_xinfa,
          },
          engine.locale('sorcery'): {
            engine.locale('kind_flying_sword'):
                FilterByOptions.kind_flying_sword,
            engine.locale('kind_airbend'): FilterByOptions.kind_airbend,
            engine.locale('kind_firebend'): FilterByOptions.kind_firebend,
            engine.locale('kind_waterbend'): FilterByOptions.kind_waterbend,
            engine.locale('kind_lightning_control'):
                FilterByOptions.kind_lightning_control,
            engine.locale('kind_earthbend'): FilterByOptions.kind_earthbend,
            engine.locale('kind_plant_control'):
                FilterByOptions.kind_plant_control,
          },
          engine.locale('other'): {
            engine.locale('kind_sigil'): FilterByOptions.kind_sigil,
            engine.locale('kind_power_word'): FilterByOptions.kind_power_word,
            engine.locale('kind_scripture'): FilterByOptions.kind_scripture,
            engine.locale('kind_music'): FilterByOptions.kind_music,
            engine.locale('kind_array'): FilterByOptions.kind_array,
            engine.locale('kind_potion'): FilterByOptions.kind_potion,
            engine.locale('kind_scroll'): FilterByOptions.kind_scroll,
          },
        },
        onSelectedItem: (FilterByOptions option) {
          libraryZone.repositionToTop();
          libraryZone.filterCards(options: option);
          updateFilterByButtonText();
        },
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
    skillBook.onTapUp = (button, position) {
      if (button == kSecondaryButton) return;
      showCardpackSelect();
    };
    skillBook.onMouseEnter = () {
      final cardpackCount =
          engine.hetu.invoke('entityHasItemCategory', positionalArgs: [
        GameData.hero,
        'cardpack',
      ]);

      final battleCardCount = GameData.hero['cardLibrary'].length;

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

    // expBottle = SpriteButton(
    //   position: GameUI.expBottlePosition,
    //   anchor: Anchor.center,
    //   size: GameUI.expBottleSize,
    //   priority: kBarrierUIPriority,
    //   angle: math.radians(15),
    // );
    // expBottle.onMouseEnter = () {
    //   final int exp = GameData.hero['exp'];
    //   Hovertip.show(
    //     scene: this,
    //     target: expBottle,
    //     direction: HovertipDirection.topCenter,
    //     content:
    //         '${engine.locale('exp')}: <bold yellow ${exp > 0 ? 'yellow' : 'grey'}>$exp</>',
    //     width: 150,
    //     config: ScreenTextConfig(textAlign: TextAlign.center),
    //   );
    // };
    // expBottle.onMouseExit = () {
    //   Hovertip.hide(expBottle);
    // };
    // camera.viewport.add(expBottle);

    // expLabel = RichTextComponent(
    //   anchor: Anchor.center,
    //   position: expBottle.center,
    //   size: Vector2(200, 60),
    //   priority: kBarrierUIPriority,
    //   isVisible: false,
    //   config: ScreenTextConfig(
    //     outlined: true,
    //     textStyle: TextStyle(
    //       color: Colors.yellow,
    //       fontFamily: GameUI.fontFamilyKaiti,
    //       fontSize: 20,
    //     ),
    //     anchor: Anchor.bottomCenter,
    //   ),
    // );
    // camera.viewport.add(expLabel);

    collectButton = SpriteButton(
      text: engine.locale('deckbuilding_identify_all'),
      anchor: Anchor.center,
      position: GameUI.craftZoneCloseButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      priority: kBarrierUIPriority,
      isVisible: false,
    );
    collectButton.onTapUp = (button, position) {
      if (button == kSecondaryButton) return;
      final unidentifiedCards = cardpackCards.where((card) {
        return card.data['isIdentified'] != true;
      });

      if (unidentifiedCards.isNotEmpty) {
        engine.play(GameSound.craft);
        for (final card in unidentifiedCards) {
          card.data['isIdentified'] = true;
          final (description, _) = GameData.getBattleCardDescription(card.data);
          card.description = description;
        }
        collectButton.text = engine.locale('deckbuilding_collect_all');
      } else {
        engine.play(GameSound.dealCard);

        barrier.isVisible = false;
        collectButton.isVisible = false;

        for (final card in cardpackCards) {
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
        cardpackCards.clear();
        libraryZone.updateHeroLibrary();
        skillBook.enableGesture = true;
      }
    };
    camera.viewport.add(collectButton);

    dismantleButton = SpriteButton(
      anchor: Anchor.center,
      size: Vector2(180, 180),
      position: Vector2(
        GameUI.size.x / 2,
        GameUI.cardpackCardPositions[1].y +
            GameUI.cardpackCardSize.y +
            GameUI.hugeIndent +
            GameUI.indent,
      ),
      spriteId: 'cultivation/scroll.png',
      hoverSpriteId: 'cultivation/scroll_hover.png',
      priority: kBarrierUIPriority,
      isVisible: false,
    );
    dismantleButton.onTapUp = (button, position) {
      if (!dismantleButton.isEnabled) return;
      if (button == kSecondaryButton) return;
      assert(craftingCard != null);
      dismantleCard(craftingCard!.id);
    };
    dismantleButton.onMouseEnter = () {
      if (dismantleButton.isEnabled) {
        engine.context.read<HoverContentState>().show(
              rect: dismantleButton.toAbsoluteRect(),
              data: engine.locale('craft_dismantle_description'),
              direction: HoverContentDirection.topCenter,
            );
      } else {
        engine.context.read<HoverContentState>().show(
              rect: dismantleButton.toAbsoluteRect(),
              data: engine.locale('craft_dismantle_disabled'),
              direction: HoverContentDirection.topCenter,
            );
      }
    };
    dismantleButton.onMouseExit = () {
      engine.context.read<HoverContentState>().hide();
    };
    camera.viewport.add(dismantleButton);

    closeCraftButton = SpriteButton(
      text: engine.locale('close'),
      anchor: Anchor.center,
      position: GameUI.craftZoneCloseButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      priority: kBarrierUIPriority,
      isVisible: false,
    );
    closeCraftButton.onTapUp = (button, position) {
      endCraft();
    };
    camera.viewport.add(closeCraftButton);

    libraryZone.updateHeroLibrary();

    for (final deckData in heroDecks) {
      final zone = createNewDeckBuildingZone(deckData: deckData);
      heroDeckZones.add(zone);

      for (final cardId in zone.preloadCardIds) {
        final card = libraryZone.library[cardId];
        assert(card != null, 'Card $cardId not found in library');
        zone.tryAddCard(card!, animated: false, clone: true);
      }
      zone.collapse(animated: false);
      zone.updateDeckLimit();
    }
    createNewDeckBuildingZone();
    updateDeckCount();
  }

  @override
  void onMount() async {
    super.onMount();

    Hovertip.hideAll();
    updateOrderByButtonText();
    updateFilterByButtonText();
    // updateExp();
    // updateExpLightPoints();

    if (_isInitializing) {
      _isInitializing = false;
    } else {
      // 载入卡牌库中的卡牌
      libraryZone.updateHeroLibrary();

      for (final zone in deckPiles) {
        zone.updateDeckLimit();
      }
    }
    libraryZone.repositionToTop();
    deckPilesContainer.position.y = GameUI.decksZoneBackgroundPosition.y;

    if (GameData.game['enableTutorial'] == true) {
      if (GameData.flags['tutorial']['cardLibrary'] != true) {
        // 功法图录教程
        GameData.flags['tutorial']['cardLibrary'] = true;
        dialog.pushDialog('hint_cardLibrary',
            npc: GameData.game['npcs']['xitong']);
        await dialog.execute();
      }
    }

    await onEnterScene?.call();
    await engine.hetu
        .invoke('onGameEvent', positionalArgs: ['onEnterCardLibrary']);
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Stack(
      children: [
        SceneWidget(
          scene: this,
          loadingBuilder: loadingBuilder,
          overlayBuilderMap: overlayBuilderMap,
          initialActiveOverlays: initialActiveOverlays,
        ),
        GameUIOverlay(
          showNpcs: false,
          enableLibrary: false,
          actions: [
            Container(
              decoration: GameUI.boxDecoration,
              width: GameUI.infoButtonSize.width,
              height: GameUI.infoButtonSize.height,
              child: IconButton(
                icon: Icon(Icons.question_mark),
                padding: const EdgeInsets.all(0),
                mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
                onPressed: () {
                  dialog.pushDialog('hint_cardLibrary');
                  dialog.execute();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
