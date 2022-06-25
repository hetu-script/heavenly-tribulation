import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:hetu_script/values.dart';

import '../global.dart';

class WorldMapScene extends Scene {
  late final TileMap map;

  HTStruct data;

  WorldMapScene({required this.data, required super.controller})
      : super(key: 'worldmap');

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    map = await TileMap.fromData(data: data, engine: engine);
    add(map);
    isMapReady = true;
    engine.broadcast(MapLoadedEvent(isNewGame: data['isNewGame'] ?? false));
  }
}
