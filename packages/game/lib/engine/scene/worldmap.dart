import 'package:flutter/material.dart';

import 'scene.dart';
import '../tilemap/map.dart';
import '../engine.dart';
import '../../ui/overlay/worldmap/worldmap.dart';

class WorldMapScene extends Scene {
  var _loaded = false;
  bool get loaded => _loaded;

  MapComponent? map;
  Map<String, dynamic>? mapData;

  WorldMapScene({this.mapData}) : super(key: 'WorldMap');

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (mapData == null) {
      map = await engine.hetu.invoke('createWorldMap', namedArgs: {
        'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
      });
    } else {
      map = await engine.hetu.invoke('loadWorldMap', positionalArgs: [mapData]);
    }

    add(map!);
    _loaded = true;
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return WorldMapOverlay(key: UniqueKey(), scene: this);
  }
}
