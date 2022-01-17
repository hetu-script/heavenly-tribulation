import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../shared/localization.dart';
import '../engine/scene/scene.dart';
import '../engine/scene/maze.dart';
import 'shared/loading_screen.dart';
import '../engine/scene/worldmap.dart';
import '../event/event.dart';

class GameApp extends StatefulWidget {
  const GameApp({required Key key}) : super(key: key);

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GameLocalization get locale => engine.locale;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    isLoading = true;

    engine.registerSceneConstructor('WorldMap', () {
      return WorldMapScene();
    });
    engine.registerSceneConstructor('Maze', () {
      return MazeScene();
    });
    engine.registerListener(
      SceneEvents.started,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    engine.registerListener(
      SceneEvents.ended,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    () async {
      await engine.init();
      engine.hetu.evalFile('core/main.ht', invokeFunc: 'init');
      engine.hetu.switchModule('game:main');

      // pass the build context to script
      engine.hetu.invoke('build', positionalArgs: [context]);

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
    } else if (engine.currentScene == null) {
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
                      engine.enterScene('WorldMap');
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
      return engine.currentScene!.widgetBuilder(context);
    }
  }
}
