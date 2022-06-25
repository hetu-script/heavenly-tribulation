import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';
import 'package:hetu_script/values.dart';

import '../global.dart';

class MazeScene extends Scene {
  late final TileMap map;

  HTStruct data;

  MazeScene({required this.data, required super.controller})
      : super(key: 'maze');

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    map = await TileMap.fromData(data: data, engine: engine);
    map.showClouds = false;
    map.showSelected = false;
    map.showFogOfWar = true;
    add(map);
    isMapReady = true;
    engine.broadcast(const MapLoadedEvent());
  }
}
