import 'dart:io';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:heavenly_tribulation/ui/overlay/worldmap/worldmap.dart';

import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';

import '../global.dart';

class WorldMapScene extends Scene {
  TileMap? map;

  String? arg;

  WorldMapScene({this.arg, required SceneController controller})
      : super(key: 'WorldMap', controller: controller);

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    if (arg != null) {
      final worldSavePath = File(arg!);
      final worldDataString = worldSavePath.readAsStringSync();
      final worldData = jsonDecode(worldDataString);
      final historySavePath = File(arg! + '2');
      final historyDataString = historySavePath.readAsStringSync();
      final historyData = jsonDecode(historyDataString);
      engine.hetu.interpreter.invoke('loadGameFromJsonData',
          positionalArgs: [worldData, historyData]);
      map = await TileMap.fromJson(data: worldData['world'], engine: engine);
    } else {
      map = await engine.invoke('createWorldMap', namedArgs: {
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
