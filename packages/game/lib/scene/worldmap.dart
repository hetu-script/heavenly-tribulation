import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';

import '../global.dart';

class WorldMapScene extends Scene {
  late final TileMap map;

  Map<String, dynamic> jsonData;

  WorldMapScene({required this.jsonData, required SceneController controller})
      : super(key: 'worldmap', controller: controller);

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    map = await TileMap.fromJson(data: jsonData, engine: engine);
    add(map);
    isMapReady = true;
    engine.broadcast(const MapEvent.mapLoaded());
  }
}
