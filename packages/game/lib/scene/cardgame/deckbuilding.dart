import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/playing_card.dart';

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
    library = Library(size: kGamepadSize);
    add(library);

    for (final cardId in deckData.keys) {
      // 牌库中每种牌其实只有一个 component
      final card = library.addCard(cardId);
      if (card != null) {
        add(card);
      }
    }
  }
}
