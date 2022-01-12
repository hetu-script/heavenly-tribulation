import 'package:flutter/material.dart';

import 'scene.dart';
import '../tilemap/map.dart';
import '../game.dart';
import '../../ui/game/overlay/worldmap.dart';

class WorldMapScene extends Scene {
  var _loaded = false;
  bool get loaded => _loaded;

  MapComponent? map;

  WorldMapScene({
    required SamsaraGame game,
  }) : super(key: 'WorldMap', game: game);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await game.hetu.invoke('createWorld', namedArgs: {
      'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
    });
    add(map!);
    _loaded = true;
  }

  @override
  Widget get widget {
    return WorldMapOverlay(game: game, scene: this);
  }
}
