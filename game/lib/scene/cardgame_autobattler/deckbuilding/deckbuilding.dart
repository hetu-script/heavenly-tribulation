import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';

import '../common.dart';
import 'library.dart';
import 'deckbuilding_zone.dart';

class DeckBuildingScene extends Scene {
  Map<String, int> deckData;

  late final Library library;
  late final DeckBuildingZone deck;

  PlayingCard? draggingCard;

  DeckBuildingScene({
    required super.controller,
    required this.deckData,
  }) : super(id: 'deckBuilding');
  @override
  Future<void> onLoad() async {
    fitScreen();

    deck = DeckBuildingZone();
    world.add(deck);

    library = Library(size: kGamepadSize);
    world.add(library);

    Sprite cardStackBackSprite =
        Sprite(await Flame.images.load('cardstack_back.png'));

    for (final cardId in deckData.keys) {
      for (var i = 0; i < deckData[cardId]!; ++i) {
        // 牌库中每种牌其实只有一个 component
        final card = library.addCard(cardId, cardStackBackSprite);
        if (card == null) continue;

        card.onTapDown = (int buttons, Vector2 position) {
          final PlayingCard clone = card.clone();
          clone.showStack = false;
          clone.enableGesture = false;
          clone.priority = kDraggingCardPriority;
          world.add(clone);
          draggingCard = clone;
          card.stack -= 1;
        };
        // 覆盖这个scene上的dragging component
        card.onDragStart = (buttons, dragPosition) => draggingCard;
        card.onDragUpdate = (buttons, dragPosition, worldPosition) {
          draggingCard!.position = worldPosition - dragPosition;
        };
        void release() {
          draggingCard?.removeFromParent();
          draggingCard = null;
          card.stack += 1;
        }

        card.onTapUp = (_, __) => release();
        card.onDragEnd = (_, __, worldPosition) {
          if (!deck.containsPoint(worldPosition)) {
            release();
          }
        };
        world.add(card);
      }
    }
  }
}
