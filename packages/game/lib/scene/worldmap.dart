import 'dart:io';
import 'dart:convert';

import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';

import '../global.dart';

class WorldMapScene extends Scene {
  late final TileMap map;

  Map<String, dynamic> arg;

  WorldMapScene({required this.arg, required SceneController controller})
      : super(key: 'WorldMap', controller: controller);

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final path = arg['path'];
    if (path != null) {
      final worldSavePath = File(path);
      final worldDataString = worldSavePath.readAsStringSync();
      final worldData = jsonDecode(worldDataString);
      final historySavePath = File('${path}2');
      final historyDataString = historySavePath.readAsStringSync();
      final historyData = jsonDecode(historyDataString);
      engine.hetu.interpreter.invoke('loadGameFromJsonData',
          positionalArgs: [worldData, historyData]);
      map = await TileMap.fromJson(data: worldData['world'], engine: engine);
    } else {
      map = await engine.invoke('createWorldMap', namedArgs: {
        'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
        ...arg,
      });
    }

    add(map);
    isMapReady = true;
    engine.broadcast(const MapEvent.mapLoaded());
  }
}
