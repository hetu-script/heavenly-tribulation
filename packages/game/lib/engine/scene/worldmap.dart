import 'package:flutter/widgets.dart';

import '../../event/map_event.dart';
import 'scene.dart';
import '../tilemap/map.dart';
import '../engine.dart';
import '../../ui/overlay/worldmap/worldmap.dart';

class WorldMapScene extends Scene {
  TileMap? map;

  WorldMapScene() : super(key: 'WorldMap');

  @override
  Future<void> onLoad() async {
    super.onLoad();
    map = await engine.hetu.invoke('createWorldMap', namedArgs: {
      'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
    });
    add(map!);
    engine.broadcast(const MapEvent.mapLoaded());
  }

  void reload() {}

  @override
  Widget get widget {
    // 如果不加下面这一行，component 会丢失 Scene, 原因不明
    if (map != null && map!.parent == null) {
      add(map!);
    }
    return WorldMapOverlay(key: UniqueKey(), scene: this);
  }
}
