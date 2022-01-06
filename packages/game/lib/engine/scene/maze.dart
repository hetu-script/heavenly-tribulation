import 'package:flutter/material.dart';

import 'scene.dart';
import 'component/map.dart';
import '../game.dart';

class MazeScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  late final MapComponent map;

  MazeScene({
    required SamsaraGame game,
  })  : overlayBuilderMap = {
          'overlayUI': (BuildContext context, Scene scene) {
            return Material(
              child: Stack(
                children: <Widget>[
                  Positioned(
                    child: IconButton(
                      onPressed: () {
                        game.leaveScene('Maze');
                      },
                      icon: const Icon(Icons.menu_open),
                    ),
                  ),
                ],
              ),
            );
          },
        },
        super(key: 'Maze', game: game);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await game.hetu.invoke('createMaze');
    add(map);
    _loaded = true;
  }

  @override
  late final Map<String, Widget Function(BuildContext, Scene)>
      overlayBuilderMap;
}
