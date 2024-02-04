import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
import 'package:samsara/samsara.dart';

import '../common.dart';
import '../../../global.dart';

class DeckBuildingZone extends PiledZone with HandlesGesture {
  static const _indent = 10.0;

  DeckBuildingZone()
      : super(
          size: kDeckZoneSize,
          piledCardSize: kLibraryCardSize,
          pileOffset: kDeckZonePileOffset,
          pileMargin: Vector2(_indent, _indent),
        ) {
    onTap = (buttons, position) {
      engine.info(pile);
    };

    onDragIn = (int buttons, Vector2 position, GameComponent card) {
      if (card is! PlayingCard) return;

      final index =
          ((position.x - _indent) / (kLibraryCardWidth + _indent)).truncate();

      card.enableGesture = true;
      card.onTapDown = (buttons, position) {
        card.priority = kDraggingCardPriority;
      };
      card.onTapUp = (buttons, position) {
        sortCards();
      };
      card.onDragUpdate = (buttons, dragPosition, worldPosition) {
        card.position = worldPosition - dragPosition;
      };
      card.onDragEnd = (buttons, dragPosition, worldPosition) {
        int dragToIndex =
            ((worldPosition.x - _indent) / (kLibraryCardWidth + _indent))
                .truncate();
        if (dragToIndex < 0) dragToIndex = 0;
        if (dragToIndex >= cards.length) dragToIndex = cards.length - 1;
        if (card.index > dragToIndex) {
          for (var i = dragToIndex; i < card.index; ++i) {
            final c = cards[i];
            ++c.index;
          }
          card.index = dragToIndex;
        } else if (card.index < dragToIndex) {
          for (var i = card.index + 1; i <= dragToIndex; ++i) {
            final c = cards[i];
            --c.index;
          }
          card.index = dragToIndex;
        }
        sortCards();
      };

      addCard(card, index: index);
    };
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(border, DefaultBorderPaint.light);
  }
}
