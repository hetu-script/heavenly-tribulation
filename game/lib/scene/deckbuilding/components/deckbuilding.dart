import 'package:samsara/samsara.dart';
// import 'package:samsara/components.dart';
// import 'package:flame/flame.dart';
// import 'package:samsara/gestures.dart';

// import '../../../global.dart';
import 'cardlibrary_zone.dart';
import 'deckbuilding_zone.dart';
// import '../../../ui.dart';

class DeckBuildingScene extends Scene {
  late final CardLibraryZone libraryZone;
  late final DeckBuildingZone buildingZone;

  final List<String> library;

  DeckBuildingScene({
    required super.controller,
    required this.library,
    required super.context,
  }) : super(id: 'deckBuilding');

  @override
  Future<void> onLoad() async {
    super.onLoad();

    libraryZone = CardLibraryZone();
    world.add(libraryZone);

    buildingZone = DeckBuildingZone(limit: 4);
    world.add(buildingZone);

    libraryZone.buildingZone = buildingZone;
    buildingZone.library = libraryZone;

    for (final cardId in library) {
      final card = libraryZone.addCardById(cardId);
      // 如果卡牌已经存在，则library.addCard会返回null，下面就不用处理。
      if (card == null) continue;
      // 这里要直接加到世界上而非library管理，因为卡牌会被拖动
      world.add(card);
    }
  }

  // @override
  // void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
  //   camera.moveBy(-details.delta.toVector2() / camera.viewfinder.zoom);

  //   super.onDragUpdate(pointer, buttons, details);
  // }
}
