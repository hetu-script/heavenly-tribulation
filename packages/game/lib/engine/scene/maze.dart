import 'scene.dart';
import '../tilemap/map.dart';
import '../engine.dart';

class MazeScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  late final TileMap map;

  MazeScene() : super(key: 'Maze');

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await engine.hetu.invoke('createMaze');
    add(map);
    _loaded = true;
  }
}
