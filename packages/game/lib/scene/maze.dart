import 'package:samsara/samsara.dart';

import '../engine.dart';

class MazeScene extends Scene {
  late final TileMap map;

  MazeScene({required SceneController controller})
      : super(key: 'Maze', controller: controller);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await engine.invoke('createMaze');
    add(map);
  }
}
