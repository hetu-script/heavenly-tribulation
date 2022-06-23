import 'package:samsara/samsara.dart';

import '../global.dart';

class MazeScene extends Scene {
  late final TileMap map;

  MazeScene({required super.controller}) : super(key: 'Maze');

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await engine.invoke('createMaze');
    add(map);
  }
}
