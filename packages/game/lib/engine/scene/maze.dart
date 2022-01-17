import 'package:flutter/widgets.dart';

import 'scene.dart';
import '../tilemap/map.dart';
import '../engine.dart';
import '../../ui/overlay/maze.dart';

class MazeScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  late final MapComponent map;

  MazeScene() : super(key: 'Maze');

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await engine.hetu.invoke('createMaze');
    add(map);
    _loaded = true;
  }

  @override
  Widget widgetBuilder(BuildContext context) {
    return MazeOverlay(key: UniqueKey(), scene: this);
  }
}
