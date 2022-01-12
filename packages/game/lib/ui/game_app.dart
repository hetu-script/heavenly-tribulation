import 'package:flutter/material.dart';

import '../shared/localization.dart';

import '../engine/scene/scene.dart';
import '../engine/scene/maze.dart';
import 'loading_screen.dart';
import '../engine/game.dart';
import 'editor/editor.dart';
import '../engine/scene/worldmap.dart';

enum MenuMode {
  menu,
  editor,
}

class GameApp extends StatefulWidget {
  final SamsaraGame game;

  const GameApp({Key? key, required this.game}) : super(key: key);

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  SamsaraGame get game => widget.game;

  GameLocalization get locale => widget.game.locale;

  MenuMode _menuMode = MenuMode.menu;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isLoading = true;

    game.registerSceneConstructor('WorldMap', () {
      return WorldMapScene(
        game: game,
      );
    });
    game.registerSceneConstructor('Maze', () {
      return MazeScene(
        game: game,
      );
    });
    game.registerListener(SceneEvents.started, (event) {
      setState(() {});
    });
    game.registerListener(SceneEvents.ended, (event) {
      setState(() {});
    });

    () async {
      await game.init();
      game.hetu.evalFile('core/main.ht', invokeFunc: 'init');
      game.hetu.switchModule('game:main');

      // pass the build context to script
      game.hetu.invoke('build', positionalArgs: [context]);

      setState(() {
        isLoading = false;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (isLoading) {
      return const LoadingScreen(text: 'Loading...');
    } else if (game.currentScene == null) {
      switch (_menuMode) {
        case MenuMode.menu:
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // if this is a new game
                          game.hetu.invoke('onGameEvent',
                              positionalArgs: ['onNewGameStarted']);
                        });
                      },
                      child: Text(locale['newGame']),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _menuMode = MenuMode.editor;
                        });
                      },
                      child: Text(locale['gameEditor']),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          game.enterScene('WorldMap');
                        });
                      },
                      child: const Text('世界测试'),
                    ),
                  ),
                ],
              ),
            ),
          );
        case MenuMode.editor:
          return GameEditor(
              onQuit: () {
                setState(() {
                  _menuMode = MenuMode.menu;
                });
              },
              game: game);
      }
    } else {
      return game.currentScene!.widget;
    }
  }
}
