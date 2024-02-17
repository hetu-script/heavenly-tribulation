import 'package:samsara/samsara.dart';

// import '../common.dart';
import 'card_library.dart';
import 'deckbuilding_zone.dart';

class DeckBuildingScene extends Scene {
  late final CardLibrary library;
  late final DeckBuildingZone buildingZone;

  final Set<String> librayData;

  DeckBuildingScene({
    required super.controller,
    required this.librayData,
  }) : super(id: 'deckBuilding');

  @override
  Future<void> onLoad() async {
    fitScreen();

    library = CardLibrary();
    world.add(library);

    buildingZone = DeckBuildingZone(cardSize: 4);
    world.add(buildingZone);

    library.buildingZone = buildingZone;
    buildingZone.library = library;

    for (final cardId in librayData) {
      final card = library.addCardById(cardId);
      // 如果卡牌已经存在，则library.addCard会返回null，下面就不用处理。
      if (card == null) continue;
      // 这里要直接加到世界上而非library管理，因为卡牌会被拖动
      world.add(card);
    }
  }
}
