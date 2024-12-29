import 'package:flutter/gestures.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
// import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';
// import 'package:flame/flame.dart';
import 'package:samsara/paint/paint.dart';

import '../../../ui.dart';
import '../../../config.dart';
import 'library_zone.dart';

const kDeckCoverPriority = 10000;

class DeckBuildingZone extends PiledZone with HandlesGesture {
  static const _indent = 20.0;

  // late final SpriteComponent background;

  late final SpriteButton placeHolder, deckCover;

  CardLibraryZone? library;

  void Function(DeckBuildingZone zone) onEditDeck;

  bool get isFull => cards.length >= limit;

  // bool isNewDeck;

  DeckBuildingZone({
    super.position,
    super.limit = 8,
    required this.onEditDeck,
    // this.isNewDeck = true,
    super.priority,
  }) : super(
          size: GameUI.deckbuildingCardSize,
          piledCardSize: GameUI.deckbuildingCardSize,
          pileMargin: Vector2(GameUI.indent, 0),
          pileOffset: GameUI.deckbuildingZonePileOffset,
          borderRadius: 20.0,
        ) {
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
      placeHolder.isVisible = cards.isEmpty;
    };
  }

  void collapse() async {
    pileOffset = Vector2(0, 0);
    for (final card in cards) {
      card.enableGesture = false;
    }

    if (cards.isNotEmpty) {
      await sortCards();
      deckCover.isVisible = true;
    }
  }

  void setCardPlaceholder() {
    placeHolder.spriteId = 'cultivation/card_placeholder.png';
    placeHolder.hoverSpriteId = 'cultivation/card_placeholder_hover.png';
    placeHolder.tryLoadSprite();
    placeHolder.enableGesture = false;
  }

  @override
  void onLoad() async {
    // background = SpriteComponent(
    //   sprite:
    //       Sprite(await Flame.images.load('cultivation/bg_deckbuilding.png')),
    //   size: size,
    // );
    // add(background);

    placeHolder = SpriteButton(
      spriteId: 'cultivation/deck_placeholder.png',
      hoverSpriteId: 'cultivation/deck_placeholder_hover.png',
      size: piledCardSize,
      position: Vector2(GameUI.indent, 0),
      onTap: (buttons, position) {},
    );
    placeHolder.onMouseEnter = () {
      Tooltip.show(
        scene: game,
        target: placeHolder,
        direction: TooltipDirection.topCenter,
        content: engine.locale('deckbuilding.createNewDeck'),
        width: 90,
      );
    };
    placeHolder.onMouseExit = () {
      Tooltip.hide(placeHolder);
    };
    placeHolder.onTapUp = (buttons, position) {
      if (cards.isEmpty) {
        setCardPlaceholder();
      }
      onEditDeck(this);
      // onCreateDeck(this);
      // isNewDeck = false;
      if (cards.isNotEmpty) {
        placeHolder.isVisible = false;
      }
    };
    add(placeHolder);

    deckCover = SpriteButton(
      spriteId: 'cultivation/battlecard/card_sleeve.png',
      hoverSpriteId: 'cultivation/battlecard/card_sleeve_hover.png',
      size: GameUI.deckCoverSize,
      onTap: (buttons, position) {},
      priority: kDeckCoverPriority,
      isVisible: false,
      position: GameUI.deckCoverPosition,
    );

    game.camera.viewport.add(deckCover);
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
      Tooltip.hide(card);
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
      Tooltip.show(
        scene: game,
        target: card,
        direction: TooltipDirection.leftCenter,
        content: card.extraDescription,
        config: ScreenTextConfig(anchor: Anchor.topCenter),
      );
    };

    card.onUnpreviewed = () {
      Tooltip.hide(card);
    };

    placeCard(card, index: index);

    return true;
  }

  // @override
  // void render(Canvas canvas) {
  //   // canvas.drawRect(border, DefaultBorderPaint.light);
  // }
}
