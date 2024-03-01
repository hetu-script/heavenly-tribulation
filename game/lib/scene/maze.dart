import 'package:samsara/samsara.dart';
import 'package:samsara/event/tilemap.dart';
import 'package:samsara/tilemap.dart';
import 'package:hetu_script/values.dart';

import '../config.dart';

class MazeScene extends Scene {
  late final TileMap map;

  HTStruct mapData;

  TextStyle captionStyle;

  MazeScene({
    required this.mapData,
    required super.controller,
    required this.captionStyle,
  })  : map = TileMap(
          engine: engine,
          captionStyle: captionStyle,
          tileShape: TileShape.hexagonalVertical,
          gridWidth: 32.0,
          gridHeight: 28.0,
          tileSpriteSrcWidth: 32.0,
          tileSpriteSrcHeight: 64.0,
          tileOffsetX: 0.0,
          tileOffsetY: 16.0,
          scaleFactor: 2.0,
          showClouds: false,
          showSelected: false,
          showFogOfWar: true,
        ),
        super(id: mapData['id']);

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await map.updateData(mapData);
    world.add(map);
    isMapReady = true;
    engine.emit(const MapLoadedEvent());
  }
}
