import 'package:flutter/gestures.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
import 'package:samsara/components.dart';
import 'package:samsara/samsara.dart';
import 'package:provider/provider.dart';

import '../../ui.dart';
import '../../engine.dart';
import 'library_zone.dart';
import 'common.dart';
import '../game_dialog/game_dialog.dart';
import '../../logic/battlecard.dart';
import 'card_library.dart';
import '../../state/hoverinfo.dart';
import '../common.dart';

enum PlaceHolderState {
  newDeck,
  editDeck,
  deckCover,
}

class DeckBuildingZone extends PiledZone with HandlesGesture {
  static const _indent = 20.0;

  final dynamic heroData;

  // late final SpriteComponent background;

  bool _isBattleDeck;
  bool get isBattleDeck => _isBattleDeck;

  int index;

  bool _saved = false;
  bool get saved => _saved;
  void save() {
    _saved = true;

    final List decks = heroData['battleDecks'];
    final deckInfo = createDeckInfo();

    if (index >= decks.length) {
      decks.add(deckInfo);
    } else {
      decks[index] = deckInfo;
    }
  }

  /// 返回是否设置为true
  void setBattleDeck([bool? value]) {
    _isBattleDeck = value ?? !_isBattleDeck;
    setTitle();
  }

  late final SpriteButton placeholder;
  late final RichTextComponent deckInfo;

  late final CardLibraryZone library;

  void Function(DeckBuildingZone zone) onEditDeck;

  void Function(DeckBuildingZone zone) onOpenDeckMenu;

  PlaceHolderState placeholderState = PlaceHolderState.newDeck;

  @override
  set isVisible(bool value) {
    super.isVisible = value;
    placeholder.isVisible = value;
    deckInfo.isVisible = value;
    for (final card in cards) {
      card.isVisible = value;
    }
  }

  void Function(DeckBuildingZone zone)? onDeckEdited;

  final List<dynamic> preloadCardIds;

  late final int limitMin, limitEphemeralMax, limitOngoingMax;

  bool get isCardsEnough {
    if (cards.length < limitMin) return false;
    return true;
  }

  int get ongoingCount {
    return cards.where((card) {
      final cardData = (card as CustomGameCard).data;
      return cardData['category'] == 'ongoing';
    }).length;
  }

  int get ephemeralCount {
    return cards.where((card) {
      final cardData = (card as CustomGameCard).data;
      return cardData['category'] == 'ephemeral';
    }).length;
  }

  bool get isRequirementMet {
    bool valid = true;

    if (cards.length < limitMin) valid = false;

    for (final card in cards) {
      valid = checkCardRequirement(heroData, (card as CustomGameCard).data);
    }

    return valid;
  }

  void Function(CustomGameCard card)? onCardPreviewed;
  void Function()? onCardUnpreviewed;

  DeckBuildingZone({
    this.heroData,
    super.title,
    bool? isBattleDeck,
    List<dynamic>? preloadCardIds,
    super.position,
    required this.onEditDeck,
    required this.onOpenDeckMenu,
    required this.library,
    // this.isNewDeck = true,
    super.priority,
    required this.index,
    this.onDeckEdited,
    this.onCardPreviewed,
    this.onCardUnpreviewed,
  })  : _isBattleDeck = isBattleDeck ?? false,
        preloadCardIds = preloadCardIds ?? [],
        super(
          size: GameUI.deckbuildingCardSize,
          piledCardSize: GameUI.deckbuildingCardSize,
          pileMargin: Vector2(0, 0),
          pileOffset: GameUI.deckbuildingZonePileOffset,
          borderRadius: 20.0,
        ) {
    title ??= engine.locale('untitled');

    onDragIn = (int buttons, Vector2 position, GameComponent? component) {
      if (component is! CustomGameCard) return;
      if (cards.contains(component)) return;
      if (containsCard(component.deckId)) return;

      final index =
          ((position.x - _indent) / (GameUI.deckbuildingCardSize.y + _indent))
              .truncate();

      final result = tryAddCard(component, index: index, clone: false);
      if (result == null) {
        library.setCardEnabledById(component.id, false);
      } else {
        GameDialog.show(
          context: game.context,
          dialogData: {
            'lines': [engine.locale(result)],
          },
        );
      }
    };

    onPileChanged = () {
      placeholder.isVisible = cards.isEmpty;
      onDeckEdited?.call(this);
    };

    // position.addListener(() {
    //   placeholder.position = position;
    //   sortCards(animated: false);
    // });
  }

  @override
  set priority(int value) {
    super.priority = value;

    sortCards(animated: false);
  }

  void dispose() {
    for (final card in cards) {
      card.removeFromParent();
    }
    placeholder.removeFromParent();
    removeFromParent();
  }

  Future<void> expand() async {
    // position = GameUI.decksZoneBackgroundPosition;
    priority = kDeckPilesZonePriority;
    pileOffset = GameUI.deckbuildingZonePileOffset;
    placeholder.text = null;
    deckInfo.isVisible = false;
    for (final card in cards) {
      card.enableGesture = true;
    }
    setState(PlaceHolderState.editDeck);

    if (cards.isNotEmpty) {
      placeholder.isVisible = false;
      await sortCards();
    }
  }

  void setTitle() {
    deckInfo.text =
        '${_isBattleDeck ? '<yellow bold>${engine.locale('deckbuilding.battleDeck')}</>' : ''}\n'
        '$title\n'
        '${engine.locale('deckbuilding_card_count')}: ${cards.length}';
  }

  Future<void> collapse({bool animated = true}) async {
    priority = 0;
    pileOffset = Vector2(0, 0);
    if (cards.isNotEmpty) {
      setTitle();
    }
    for (final card in cards) {
      card.enableGesture = false;
    }

    if (cards.isEmpty) {
      setState(PlaceHolderState.newDeck);
    } else {
      await sortCards(animated: animated);
      setState(PlaceHolderState.deckCover);
      placeholder.isVisible = true;
      deckInfo.isVisible = true;
    }
  }

  void setState(PlaceHolderState state) {
    placeholderState = state;
    switch (state) {
      case PlaceHolderState.newDeck:
        placeholder.priority = priority;
        placeholder.spriteId = 'cultivation/deck_placeholder.png';
        placeholder.hoverSpriteId = 'cultivation/deck_placeholder_hover.png';
        placeholder.tryLoadSprite();
      case PlaceHolderState.editDeck:
        placeholder.priority = priority;
        placeholder.spriteId = 'cultivation/card_placeholder.png';
        placeholder.hoverSpriteId = 'cultivation/card_placeholder_hover.png';
        placeholder.tryLoadSprite();
      case PlaceHolderState.deckCover:
        placeholder.priority = kDeckCoverPriority;
        placeholder.spriteId = 'cultivation/deck_cover.png';
        placeholder.hoverSpriteId = 'cultivation/deck_cover_hover.png';
        placeholder.tryLoadSprite();
    }
  }

  @override
  void onLoad() async {
    // background = SpriteComponent(
    //   sprite:
    //       Sprite(await Flame.images.load('cultivation/bg_deckbuilding.png')),
    //   size: size,
    // );
    // add(background);

    assert(heroData != null);
    final deckLimit = getDeckLimitFromRank(heroData['cultivationRank']);
    limitMin = deckLimit.$1;
    limit = deckLimit.$2;
    limitEphemeralMax = deckLimit.$3;
    limitOngoingMax = deckLimit.$4;
    assert(limitMin > 0);
    assert(limit >= limitMin);
    assert(limitEphemeralMax >= 0);
    assert(limitOngoingMax >= 0);

    placeholder = SpriteButton(
      spriteId: 'cultivation/deck_placeholder.png',
      hoverSpriteId: 'cultivation/deck_placeholder_hover.png',
      size: piledCardSize,
      priority: kTopBarPriority,
    );
    placeholder.onMouseEnter = () {
      switch (placeholderState) {
        case PlaceHolderState.newDeck:
          Hovertip.show(
            scene: game,
            target: placeholder,
            direction: HovertipDirection.bottomCenter,
            content: engine.locale('deckbuilding_new_deck_hint'),
            config: ScreenTextConfig(anchor: Anchor.topCenter),
            width: 200,
          );
        case PlaceHolderState.editDeck:
          Hovertip.show(
            scene: game,
            target: placeholder,
            direction: HovertipDirection.bottomCenter,
            content: engine.locale('deckbuilding_add_card_hint'),
            config: ScreenTextConfig(anchor: Anchor.topCenter),
          );
        case PlaceHolderState.deckCover:
        // Hovertip.show(
        //   scene: game,
        //   target: placeholder,
        //   direction: HovertipDirection.topCenter,
        //   content: engine.locale('deckbuilding_edit_deck_hint'),
        //   config: ScreenTextConfig(anchor: Anchor.center),
        // );
      }
    };
    placeholder.onMouseExit = () {
      Hovertip.hide(placeholder);
    };
    placeholder.onTapUp = (buttons, position) {
      if (buttons == kPrimaryButton) {
        switch (placeholderState) {
          case PlaceHolderState.newDeck:
            setState(PlaceHolderState.editDeck);
            onEditDeck(this);
            Hovertip.hide(placeholder);
            Hovertip.show(
              scene: game,
              target: placeholder,
              direction: HovertipDirection.topCenter,
              content: engine.locale('deckbuilding_add_card_hint'),
              config: ScreenTextConfig(anchor: Anchor.center),
            );
          case PlaceHolderState.deckCover:
            placeholder.isVisible = false;
            onEditDeck(this);
          case PlaceHolderState.editDeck:
        }
      } else if (buttons == kSecondaryButton &&
          placeholderState == PlaceHolderState.deckCover) {
        onOpenDeckMenu(this);
      }
    };

    deckInfo = RichTextComponent(
      size: placeholder.size,
      config: ScreenTextConfig(
        outlined: true,
        textStyle: TextStyle(
          fontFamily: GameUI.fontFamily,
        ),
        anchor: Anchor.bottomCenter,
        padding: EdgeInsets.only(bottom: 120),
      ),
    );
    placeholder.add(deckInfo);

    add(placeholder);
  }

  /// 尝试加入卡牌，如果不能加入，返回的是表示原因的字符串
  @override
  String? tryAddCard(GameCard c,
      {int? index, bool animated = true, bool clone = false}) {
    if (containsCard(c.deckId)) {
      return 'deckbuilding_already_in_battle_deck';
    }
    if (isFull) {
      return 'deckbuilding_deck_is_full';
    }
    final cardData = (c as CustomGameCard).data;
    if (cardData['isIdentified'] != true) {
      return 'deckbuilding_card_unidentified';
    }
    if (ongoingCount >= limitOngoingMax && cardData['category'] == 'ongoing') {
      return 'deckbuilding_ongoing_card_limit';
    }
    if (ephemeralCount >= limitEphemeralMax &&
        cardData['category'] == 'ephemeral') {
      return 'deckbuilding_ephemeral_card_limit';
    }

    CustomGameCard card = c;

    if (clone) {
      card = c.clone();
      card.position = c.absolutePosition - absolutePosition;
      add(card);
    }

    card.onTapDown = (buttons, position) {
      if (buttons == kPrimaryButton) {
        game.context.read<HoverInfoContentState>().hide();
        (game as CardLibraryScene).cardDragStart(card);
      }
    };
    card.onTapUp = (buttons, position) {
      if (buttons == kPrimaryButton) {
        (game as CardLibraryScene).cardDragRelease();
      } else if (buttons == kSecondaryButton) {
        library.setCardEnabledById(card.deckId, true);
        card.removeFromPile();
      }
    };

    // 返回实际被拖动的卡牌，以覆盖这个scene上的dragging component
    card.onDragStart =
        (buttons, dragPosition) => (game as CardLibraryScene).draggingCard;
    card.onDragUpdate = (int buttons, Vector2 offset) =>
        // TODO: 这里为什么要除以 2 才能正确的得到位置???
        (game as CardLibraryScene).draggingCard?.position += offset / 2;
    card.onDragEnd = (buttons, position) {
      int dragToIndex = (((game as CardLibraryScene).draggingCard!.position.y -
              GameUI.decksZoneBackgroundPosition.y) ~/
          GameUI.deckbuildingZonePileOffset.y);

      (game as CardLibraryScene).cardDragRelease();

      reorderCard(card.index, dragToIndex);
    };
    card.onPreviewed = () => previewCard(
          game.context,
          'deckbuilding_card_${card.id}',
          card.data,
          card.toAbsoluteRect(),
          direction: HoverInfoDirection.leftTop,
          characterData: heroData,
        );
    card.onUnpreviewed = () => unpreviewCard(game.context);

    placeCard(card, index: index, animated: animated);

    return null;
  }

  dynamic createDeckInfo() {
    final info = {
      'title': title,
      'isBattleDeck': isBattleDeck,
      'isValid': isCardsEnough && isRequirementMet,
      'cards': cards.map((card) => card.deckId).toList(),
    };

    return info;
  }

  // @override
  // void render(Canvas canvas) {
  //   canvas.drawRect(border, PresetPaints.light);
  // }
}
