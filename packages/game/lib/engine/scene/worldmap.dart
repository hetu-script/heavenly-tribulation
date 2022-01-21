import 'dart:io';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../../event/events.dart';
import 'scene.dart';
import '../tilemap/map.dart';
import '../engine.dart';
import '../../ui/overlay/worldmap/worldmap.dart';

class WorldMapScene extends Scene {
  TileMap? map;

  String? arg;

  WorldMapScene([this.arg]) : super(key: 'WorldMap');

  @override
  Future<void> onLoad() async {
    super.onLoad();

    if (map == null) {
      if (arg != null) {
        final data = File(arg!);
        final dataString = data.readAsStringSync();
        final jsonData = jsonDecode(dataString);
        engine.hetu.invoke('loadGameFromJsonData', positionalArgs: [jsonData]);
        map = await TileMap.fromJson(jsonData['world']);
      } else {
        map = await engine.hetu.invoke('createWorldMap', namedArgs: {
          'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
        });
      }
    }

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
