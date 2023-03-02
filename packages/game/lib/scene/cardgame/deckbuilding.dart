import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/playing_card.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/gestures.dart';

import 'common.dart';
import 'deck/library.dart';

class DeckBuildingScene extends Scene {
  Map<String, int> deckData;

  late final Library library;

  PlayingCard? draggingCard;

  DeckBuildingScene({
    required super.controller,
    required this.deckData,
  }) : super(name: 'deckBuilding', key: 'deckBuilding');
  @override
  Future<void> onLoad() async {
    library = Library(
        position: Vector2(0, kLibraryCardHeight * 1.2), size: kGamepadSize);
    add(library);

    library.cardStackBackSprite =
        Sprite(await Flame.images.load('cardstack_back.png'));

    for (final cardId in deckData.keys) {
      for (var i = 0; i < deckData[cardId]!; ++i) {
        // 牌库中每种牌其实只有一个 component
        final card = library.addCard(cardId);
        if (card != null) {
          card.onPointerDown = () {
            draggingCard = card;
          };

          add(card);
        }
      }
    }
  }

  @override
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    super.onTapUp(pointer, buttons, details);

    draggingCard = null;
  }
}
