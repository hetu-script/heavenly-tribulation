import 'package:flutter/material.dart';

import '../shared/localization.dart';

import '../engine/scene/scene.dart';
import '../engine/scene/maze.dart';
import 'shared/loading_screen.dart';
import '../engine/game.dart';
import '../engine/scene/worldmap.dart';
import '../event/event.dart';

class GameApp extends StatefulWidget {
  final SamsaraGame game;

  const GameApp({required Key key, required this.game}) : super(key: key);

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  SamsaraGame get game => widget.game;

  GameLocalization get locale => widget.game.locale;

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
    game.registerListener(
      SceneEvents.started,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    game.registerListener(
      SceneEvents.ended,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

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
                      game.enterScene('WorldMap');
                    });
                  },
                  child: Text(locale['sandBoxMode']),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('editor');
                  },
                  child: Text(locale['gameEditor']),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return game.currentScene!.widget;
    }
  }
}
