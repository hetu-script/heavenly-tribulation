import 'package:flutter/gestures.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
import 'package:samsara/components.dart';
import 'package:samsara/samsara.dart';
import 'package:provider/provider.dart';

import '../../game/ui.dart';
import '../../engine.dart';
import 'library_zone.dart';
import 'common.dart';
import '../game_dialog/game_dialog_content.dart';
import '../../game/logic.dart';
import 'card_library.dart';
import '../../state/hover_content.dart';
import '../common.dart';
import '../../game/data.dart';

enum PlaceHolderState {
  newDeck,
  editDeck,
  deckCover,
}

class DeckBuildingZone extends PiledZone with HandlesGesture {
  static const _indent = 20.0;

  // late final SpriteComponent background;

  bool _isBattleDeck;
  bool get isBattleDeck => _isBattleDeck;

  int index;

  bool _saved = false;
  bool get saved => _saved;

  void save() {
    _saved = true;

    final List decks = GameData.hero['battleDecks'];
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

  int limitEphemeralMax = -1; // limitOngoingMax = -1;

  bool get isCardsEnough {
    if (cards.length < limit) return false;
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

    if (cards.length < limit) valid = false;

    for (final card in cards) {
      final warning = GameLogic.checkRequirements((card as CustomGameCard).data,
          checkIdentified: true);
      valid = warning == null;
    }

    return valid;
  }

  void Function(CustomGameCard card)? onCardPreviewed;
  void Function()? onCardUnpreviewed;

  DeckBuildingZone({
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

    onDragIn = (int button, Vector2 position, GameComponent? component) {
      if (component is! CustomGameCard) return;
      if (cards.contains(component)) return;
      if (containsCard(component.deckId)) return;

      final index =
          ((position.x - _indent) / (GameUI.deckbuildingCardSize.y + _indent))
              .truncate();

      final result = tryAddCard(component, index: index, clone: true);
      if (result == null) {
        library.setCardEnabledById(component.id, false);
      } else {
        GameDialogContent.show(game.context, engine.locale(result));
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
    }
  }

  void setState(PlaceHolderState state) {
    placeholderState = state;
    switch (state) {
      case PlaceHolderState.newDeck:
        placeholder.priority = priority;
        placeholder.tryLoadSprite(
          spriteId: 'cultivation/deck_placeholder.png',
          hoverSpriteId: 'cultivation/deck_placeholder_hover.png',
        );
      case PlaceHolderState.editDeck:
        placeholder.priority = priority;
        placeholder.tryLoadSprite(
            spriteId: 'cultivation/card_placeholder.png',
            hoverSpriteId: 'cultivation/card_placeholder_hover.png');
      case PlaceHolderState.deckCover:
        placeholder.priority = kDeckCoverPriority;
        placeholder.tryLoadSprite(
          spriteId: 'cultivation/deck_cover.png',
          hoverSpriteId: 'cultivation/deck_cover_hover.png',
        );
    }
  }

  void updateDeckLimit() {
    final deckLimit = GameLogic.getDeckLimitForRank(GameData.hero['rank']);
    limit = deckLimit['limit']!;
    limitEphemeralMax = deckLimit['ephemeralMax']!;
    // limitOngoingMax = deckLimit['ongoingMax']!;
    assert(limitEphemeralMax >= 0);
    // assert(limitOngoingMax >= 0);
  }

  @override
  void onLoad() async {
    updateDeckLimit();

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
            config: ScreenTextConfig(anchor: Anchor.bottomCenter),
            width: 200,
          );
        case PlaceHolderState.editDeck:
          Hovertip.show(
            scene: game,
            target: placeholder,
            direction: HovertipDirection.bottomCenter,
            content: engine.locale('deckbuilding_add_card_hint'),
            config: ScreenTextConfig(anchor: Anchor.bottomCenter),
            width: 200,
          );
        case PlaceHolderState.deckCover:
          Hovertip.show(
            scene: game,
            target: placeholder,
            direction: HovertipDirection.topCenter,
            content: engine.locale('deckbuilding_edit_deck_hint'),
            config: ScreenTextConfig(anchor: Anchor.bottomCenter),
            width: 200,
          );
      }
    };
    placeholder.onMouseExit = () {
      Hovertip.hide(placeholder);
    };
    placeholder.onTapUp = (button, position) {
      if (button == kPrimaryButton) {
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
            setState(PlaceHolderState.editDeck);
            onEditDeck(this);
          default:
            return;
        }
      } else if (button == kSecondaryButton &&
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
    // if (ongoingCount >= limitOngoingMax && cardData['category'] == 'ongoing') {
    //   return 'deckbuilding_ongoing_card_limit';
    // }
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

    card.onTapDown = (button, position) {
      if (button == kPrimaryButton) {
        game.context.read<HoverContentState>().hide();
        (game as CardLibraryScene).cardDragStart(card);
      }
    };
    card.onTapUp = (button, position) {
      if (button == kPrimaryButton) {
        (game as CardLibraryScene).cardDragRelease();
      } else if (button == kSecondaryButton) {
        library.setCardEnabledById(card.deckId, true);
        card.removeFromPile();
      }
    };

    // 返回实际被拖动的卡牌，以覆盖这个scene上的dragging component
    card.onDragStart =
        (button, dragPosition) => (game as CardLibraryScene).draggingCard;
    card.onDragUpdate = (int button, Vector2 postion, Vector2 delta) =>
        // TODO: 这里为什么要除以 2 才能正确的得到位置???
        (game as CardLibraryScene).draggingCard?.position += delta / 2;
    card.onDragEnd = (button, position) {
      final libraryScene = game as CardLibraryScene;
      final draggingCard = libraryScene.draggingCard;
      if (draggingCard == null) return;
      int dragToIndex =
          (draggingCard.position.y - GameUI.decksZoneBackgroundPosition.y) ~/
              GameUI.deckbuildingZonePileOffset.y;

      libraryScene.cardDragRelease();

      reorderCard(card.index, dragToIndex);
    };
    card.onPreviewed = () => previewCard(
          game.context,
          'deckbuilding_card_${card.id}',
          card.data,
          card.toAbsoluteRect(),
          direction: HoverContentDirection.leftTop,
          character: GameData.hero,
        );
    card.onUnpreviewed = () => unpreviewCard(game.context);

    placeCard(card, index: index, animated: animated);

    return null;
  }

  dynamic createDeckInfo() {
    final info = {
      'title': title,
      'isBattleDeck': isBattleDeck,
      // 'isValid': isCardsEnough && isRequirementMet,
      'cards': cards.map((card) => card.deckId).toList(),
    };

    return info;
  }

  // @override
  // void render(Canvas canvas) {
  //   canvas.drawRect(border, PresetPaints.light);
  // }
}
