import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';

import '../global.dart';

class MazeScene extends Scene {
  late final TileMap map;

  Map<String, dynamic> jsonData;

  MazeScene({required this.jsonData, required super.controller})
      : super(key: 'maze');

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    map = await TileMap.fromJson(data: jsonData, engine: engine);

    add(map);
    isMapReady = true;
    engine.broadcast(const MapLoadedEvent());
  }
}
