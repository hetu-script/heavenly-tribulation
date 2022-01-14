import 'package:flutter/widgets.dart';

import 'scene.dart';
import '../tilemap/map.dart';
import '../game.dart';
import '../../ui/game/overlay/maze.dart';

class MazeScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  late final MapComponent map;

  MazeScene({
    required SamsaraGame game,
  }) : super(key: 'Maze', game: game);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await game.hetu.invoke('createMaze');
    add(map);
    _loaded = true;
  }

  @override
  Widget get widget {
    return MazeOverlay(key: UniqueKey(), game: game, scene: this);
  }
}
