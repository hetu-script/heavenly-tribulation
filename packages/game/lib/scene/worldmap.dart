import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:hetu_script/values.dart';

import '../global.dart';

class WorldMapScene extends Scene {
  late final TileMap map;

  HTStruct worldData;

  WorldMapScene({required this.worldData, required super.controller})
      : super(key: 'worldmap');

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    map = await TileMap.fromData(mapData: worldData, engine: engine);
    add(map);
    isMapReady = true;
    engine
        .broadcast(MapLoadedEvent(isNewGame: worldData['isNewGame'] ?? false));
  }
}
