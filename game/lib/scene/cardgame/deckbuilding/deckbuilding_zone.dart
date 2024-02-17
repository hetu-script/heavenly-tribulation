import 'package:flutter/gestures.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
import 'package:samsara/samsara.dart';

import '../common.dart';
// import '../../../global.dart';
import 'card_library.dart';

class DeckBuildingZone extends PiledZone with HandlesGesture {
  static const _indent = 20.0;

  CardLibrary? library;

  int cardSize;

  DeckBuildingZone({
    this.cardSize = 8,
  }) : super(
          size: kDeckZoneSize,
          piledCardSize: kDeckZoneCardSize,
          pileOffset: kDeckZonePileOffset,
          pileMargin: Vector2(_indent, _indent),
        ) {
    onDragIn = (int buttons, Vector2 position, GameComponent c) {
      if (c is! PlayingCard) return;
      if (cards.contains(c)) return;

      final index =
          ((position.x - _indent) / (kDeckZoneCardWidth + _indent)).truncate();

      addCard(c, index: index);
    };
  }

  void addCard(PlayingCard c, {int? index}) {
    if (containsCard(c.deckId)) return;
    if (cards.length >= cardSize) return;

    final card = c.clone();
    gameRef.world.add(card);
    card.size = kDeckZoneCardSize;

    card.enableGesture = true;
    card.onTapDown = (buttons, position) {
      if (buttons == kPrimaryButton) {
        card.priority = kDraggingCardPriority;
      }
    };
    card.onTapUp = (buttons, position) {
      if (buttons == kSecondaryButton) {
        library?.setCardDarkened(card.deckId, false);
        card.removeFromPile();
        card.removeFromParent();
      }
    };
    card.onDragUpdate = (buttons, dragPosition, dragOffset) {
      card.position += dragOffset;
    };
    card.onDragEnd = (buttons, dragPosition, worldPosition) {
      int dragToIndex =
          ((worldPosition.x - _indent) / (kDeckZoneCardWidth + _indent))
              .truncate();

      reorderCard(card.index, dragToIndex);
    };

    placeCard(card, index: index);

    library?.setCardDarkened(card.deckId);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
