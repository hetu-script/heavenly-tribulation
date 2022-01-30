import 'dart:io';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'scene.dart';
import '../tilemap/map.dart';
import '../../ui/overlay/worldmap/worldmap.dart';
import '../engine.dart';
import '../../event/events.dart';

class WorldMapScene extends Scene {
  TileMap? map;

  String? arg;

  WorldMapScene(this.arg) : super(key: 'WorldMap');

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

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

    add(map!);
    isMapReady = true;
    engine.broadcast(const MapEvent.mapLoaded());
  }

  @override
  Widget get widget {
    // 如果不加下面这一行，component 会丢失 Scene, 原因不明
    if (map != null && map!.parent == null) {
      add(map!);
    }
    return WorldMapOverlay(key: UniqueKey(), scene: this);
  }
}
