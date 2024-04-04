import 'package:flutter/gestures.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/cardgame/card.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
// import 'package:samsara/samsara.dart';
import 'package:samsara/components.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../../../ui.dart';
// import '../../../global.dart';
import 'cardlibrary_zone.dart';

class DeckBuildingZone extends PiledZone with HandlesGesture {
  static const _indent = 20.0;

  late final SpriteComponent background;

  CardLibraryZone? library;

  DeckBuildingZone({
    super.limit = 8,
  }) : super(
          size: GameUI.deckbuildingZoneSize,
          piledCardSize: GameUI.deckbuildingCardSize,
          pileOffset: GameUI.deckbuildingZonePileOffset,
          pileMargin: Vector2(_indent, _indent),
          priority: 1000,
          borderRadius: 20.0,
        ) {
    onDragIn = (int buttons, Vector2 position, GameComponent? component) {
      if (component is! Card) return;
      if (cards.contains(component)) return;

      final index =
          ((position.x - _indent) / (GameUI.deckbuildingCardSize.y + _indent))
              .truncate();

      gameRef.world.add(component);
      if (addCard(component, index: index)) {
        if (!unlimitedCardIds.contains(component.deckId)) {
          library!.setCardEnabledById(component.id);
        }
      }
    };
  }

  @override
  void onLoad() async {
    background = SpriteComponent(
      sprite: Sprite(
          await Flame.images.load('cultivation/deckbuilding/deckbuilding.png')),
      size: size,
    );
    add(background);
  }

  bool addCard(Card card, {int? index}) {
    if (!unlimitedCardIds.contains(card.deckId) && containsCard(card.deckId)) {
      return false;
    }
    if (cards.length >= limit) return false;

    // final card = c.clone();
    // gameRef.world.add(card);
    card.size = GameUI.deckbuildingCardSize;

    card.enableGesture = true;
    card.onTapDown = (buttons, position) {
      card.priority = kDraggingCardPriority;
    };
    card.onTapUp = (buttons, position) {
      if (buttons == kSecondaryButton) {
        library?.setCardEnabledById(card.deckId, true);
        card.removeFromPile();
      }
    };
    card.onDragUpdate = (buttons, offset) {
      card.position += offset;
    };
    card.onDragEnd = (buttons, position) {
      int dragToIndex =
          ((position.x - _indent) / (GameUI.deckbuildingCardSize.x + _indent))
              .truncate();

      reorderCard(card.index, dragToIndex);
    };

    placeCard(card, index: index);

    return true;
  }

  // @override
  // void render(Canvas canvas) {
  //   // canvas.drawRect(border, DefaultBorderPaint.light);
  // }
}
