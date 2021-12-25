import 'scene.dart';
import 'component/map.dart';
import '../game.dart';

class MazeScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  MazeScene({required SamsaraGame game}) : super(key: 'Maze', game: game);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final MapComponent map = await game.hetu.invoke('createMaze');
    add(map);
    _loaded = true;
  }
}