import 'package:flutter/material.dart';
// import '../ui/view/location.dart';

import '../engine/engine.dart';
import '../shared/localization.dart';
import '../event/scene_event.dart';
import '../engine/scene/maze.dart';
import 'shared/loading_screen.dart';
import '../engine/scene/worldmap.dart';
import '../event/event.dart';
import '../event/location_event.dart';
import 'overlay/worldmap/worldmap.dart';

class GameApp extends StatefulWidget {
  const GameApp({required Key key}) : super(key: key);

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  GameLocalization get locale => engine.locale;

  bool isLoading = true;

  String? currentLocationId;

  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('WorldMap', () {
      return WorldMapScene();
    });

    engine.registerSceneConstructor('Maze', () {
      return MazeScene();
    });

    engine.registerListener(
      SceneEvents.loading,
      EventHandler(widget.key!, (event) {
        setState(() {
          isLoading = true;
        });
      }),
    );

    engine.registerListener(
      SceneEvents.started,
      EventHandler(widget.key!, (event) {
        setState(() {
          isLoading = false;
        });
      }),
    );

    engine.registerListener(
      SceneEvents.ended,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    engine.registerListener(
      LocationEvents.entered,
      EventHandler(widget.key!, (event) {
        Navigator.pushNamed(
          context,
          'location',
          arguments: (event as LocationEvent).locationId,
        );
        // setState(() {
        //   // currentLocationId = (event as LocationEvent).locationId;
        // });
      }),
    );

    engine.registerListener(
      LocationEvents.left,
      EventHandler(widget.key!, (event) {
        Navigator.pop(context);
        // setState(() {
        //   // currentLocationId = null;
        // });
      }),
    );

    () async {
      await engine.init();
      // engine.hetu.evalFile('core/main.ht', invokeFunc: 'init');
      // engine.hetu.switchModule('game:main');

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
    }
    // else if (currentLocationId != null) {
    //   return LocationView(locationId: currentLocationId!);
    // }
    else if (engine.currentScene is WorldMapScene) {
      final worldMap = engine.currentScene as WorldMapScene;
      worldMap.reload();
      return WorldMapOverlay(key: UniqueKey(), scene: worldMap);
    } else {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    engine.enterScene('WorldMap');
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
    }
  }
}
