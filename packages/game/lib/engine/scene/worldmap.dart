import 'package:flutter/material.dart';

import 'scene.dart';
import '../tilemap/map.dart';
import '../game.dart';
import '../../ui/game/overlay/worldmap.dart';

class WorldMapScene extends Scene {
  var _loaded = false;
  bool get loaded => _loaded;

  MapComponent? map;
  Map<String, dynamic>? mapData;

  WorldMapScene({
    required SamsaraGame game,
    this.mapData,
  }) : super(key: 'WorldMap', game: game);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (mapData == null) {
      map = await game.hetu.invoke('createWorldMap', namedArgs: {
        'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
      });
    } else {
      map = await game.hetu.invoke('loadWorldMap', positionalArgs: [mapData]);
    }

    add(map!);
    _loaded = true;
  }

  @override
  Widget get widget {
    return WorldMapOverlay(key: UniqueKey(), game: game, scene: this);
  }
}
