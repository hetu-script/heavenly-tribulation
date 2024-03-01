import 'package:samsara/samsara.dart';
import 'package:samsara/event/tilemap.dart';
import 'package:samsara/tilemap.dart';
import 'package:hetu_script/values.dart';

import '../config.dart';

class WorldMapScene extends Scene {
  final TileMap map;

  HTStruct worldData;

  TextStyle captionStyle;

  final bool isFirstLoad;

  WorldMapScene({
    required this.worldData,
    required super.controller,
    required this.captionStyle,
    this.isFirstLoad = false,
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
          showClouds: true,
          showSelected: true,
          showFogOfWar: false,
        ),
        super(id: worldData['id']);

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await map.updateData(worldData);
    world.add(map);
    isMapReady = true;
    engine.emit(MapLoadedEvent(isFirstLoad: isFirstLoad));
    fitScreen();
  }
}
