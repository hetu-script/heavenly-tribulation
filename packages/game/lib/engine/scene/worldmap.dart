import '../../event/map_event.dart';
import 'scene.dart';
import '../tilemap/map.dart';
import '../engine.dart';

class WorldMapScene extends Scene {
  MapComponent? map;

  WorldMapScene() : super(key: 'WorldMap') {}

  @override
  Future<void> onLoad() async {
    super.onLoad();
    map = await engine.hetu.invoke('createWorldMap', namedArgs: {
      'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
    });
    add(map!);
    engine.broadcast(const MapEvent.mapLoaded());
  }

  void reload() {
    if (map != null) {
      add(map!);
    }
  }
}
