import 'package:flutter/gestures.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
// import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';
// import 'package:flame/flame.dart';
// import 'package:samsara/paint/paint.dart';
import 'package:samsara/samsara.dart';

import '../../../ui.dart';
import '../../../engine.dart';
import 'library_zone.dart';
import 'common.dart';

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

  /// 返回是否设置为true
  void setBattleDeck([bool? value]) {
    _isBattleDeck = value ?? !_isBattleDeck;
    setTitle();
  }

  late final SpriteButton placeholder;
  late final RichTextComponent deckInfo;

  CardLibraryZone? library;

  void Function(DeckBuildingZone zone) onEditDeck;

  void Function(DeckBuildingZone zone) onOpenDeckMenu;

  bool get isFull => cards.length >= limit;

  PlaceHolderState placeholderState = PlaceHolderState.newDeck;

  // bool isNewDeck;

  @override
  set isVisible(bool value) {
    super.isVisible = value;
    placeholder.isVisible = value;
    for (final card in cards) {
      card.isVisible = value;
    }
  }

  void Function(DeckBuildingZone zone)? onDeckEdited;

  DeckBuildingZone({
    super.title,
    bool? isBattleDeck,
    super.position,
    required super.limit,
    required this.onEditDeck,
    required this.onOpenDeckMenu,
    // this.isNewDeck = true,
    super.priority,
    this.onDeckEdited,
  })  : _isBattleDeck = isBattleDeck ?? false,
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

      final index =
          ((position.x - _indent) / (GameUI.deckbuildingCardSize.y + _indent))
              .truncate();

      // gameRef.world.add(component);
      if (addCard(component, index: index)) {
        // if (!unlimitedCardIds.contains(component.deckId)) {
        library!.setCardEnabledById(component.id, false);
        // }
      }
    };

    onPileChanged = () {
      placeholder.isVisible = cards.isEmpty;
      onDeckEdited?.call(this);
    };

    position.addListener(() {
      placeholder.position = position;
      sortCards(animated: false);
    });
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
    position = GameUI.decksZoneBackgroundPosition;
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
        '${engine.locale('deckbuilding.cardCount')}: ${cards.length}/$limit';
  }

  Future<void> collapse() async {
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
      await sortCards();
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

    placeholder = SpriteButton(
      spriteId: 'cultivation/deck_placeholder.png',
      hoverSpriteId: 'cultivation/deck_placeholder_hover.png',
      size: piledCardSize,
      position: position,
      // priority: kDeckCoverPriority,
    );
    placeholder.onMouseEnter = () {
      switch (placeholderState) {
        case PlaceHolderState.newDeck:
          Hovertip.show(
            scene: game,
            target: placeholder,
            direction: HovertipDirection.topCenter,
            content: engine.locale('deckbuilding.newDeck'),
            config: ScreenTextConfig(anchor: Anchor.center),
          );
        case PlaceHolderState.editDeck:
          Hovertip.show(
            scene: game,
            target: placeholder,
            direction: HovertipDirection.topCenter,
            content: engine.locale('deckbuilding.addCard'),
            config: ScreenTextConfig(anchor: Anchor.center),
          );
        case PlaceHolderState.deckCover:
        // Hovertip.show(
        //   scene: game,
        //   target: placeholder,
        //   direction: HovertipDirection.topCenter,
        //   content: engine.locale('deckbuilding.editDeck'),
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
              content: engine.locale('deckbuilding.addCard'),
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
    game.world.add(placeholder);

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
  }

  bool addCard(CustomGameCard card, {int? index}) {
    // if (!unlimitedCardIds.contains(card.deckId) && containsCard(card.deckId)) {
    if (containsCard(card.deckId)) return false;
    if (cards.length >= limit) return false;

    // final card = c.clone();
    // gameRef.world.add(card);
    card.size = GameUI.deckbuildingCardSize;

    card.enableGesture = true;
    card.onTapDown = (buttons, position) {
      Hovertip.hide(card);
      card.priority = kDraggingCardPriority;
    };
    card.onTapUp = (buttons, position) {
      if (buttons == kSecondaryButton) {
        library?.setCardEnabledById(card.deckId, true);
        card.removeFromPile();
      }
    };
    card.onDragStart = (buttons, dragPosition) => card;
    card.onDragUpdate = (buttons, offset) {
      card.position += offset;
    };
    card.onDragEnd = (buttons, position) {
      int dragToIndex = ((position.y - GameUI.decksZoneBackgroundPosition.y) /
              GameUI.pileZoneIndent)
          .truncate();

      reorderCard(card.index, dragToIndex);
    };

    // card.previewPriority = 100;

    card.onPreviewed = () {
      Hovertip.show(
        scene: game,
        target: card,
        direction: HovertipDirection.leftCenter,
        content: card.extraDescription,
        config: ScreenTextConfig(anchor: Anchor.topCenter),
      );
    };

    card.onUnpreviewed = () {
      Hovertip.hide(card);
    };

    placeCard(card, index: index);

    return true;
  }

  // @override
  // void render(Canvas canvas) {
  //   canvas.drawRect(border, PresetPaints.light);
  // }
}
