import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';

import '../engine.dart';
import 'shared/loading_screen.dart';
import '../shared/constants.dart';
import '../../shared/datetime.dart';
import 'load_game_dialog.dart';
import '../binding/external_game_functions.dart';
import '../scene/worldmap.dart';
import '../scene/maze.dart';

class GameApp extends StatefulWidget {
  const GameApp({required Key key}) : super(key: key);

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  GameLocalization get locale => engine.locale;

  bool _isLoading = true;

  String? currentLocationId;

  final savedFiles = <SaveInfo>[];

  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('WorldMap', ([String? arg]) async {
      return WorldMapScene(arg: arg, controller: engine);
    });

    engine.registerSceneConstructor('Maze', ([String? arg]) async {
      return MazeScene(controller: engine);
    });

    engine.registerListener(
        GameEvents.onBack2Menu,
        EventHandler(widget.key!, (GameEvent event) {
          refreshSaves();
        }));

    // engine.registerListener(
    //   Events.loadingScene,
    //   EventHandler(widget.key!, (event) {
    //     setState(() {
    //       _isLoading = true;
    //     });
    //   }),
    // );

    engine.registerListener(
      Events.createdScene,
      EventHandler(widget.key!, (event) {
        setState(() {
          _isLoading = false;
        });
      }),
    );

    engine.registerListener(
      Events.endedScene,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    engine.registerListener(
      Events.enteredLocation,
      EventHandler(widget.key!, (event) {
        Navigator.of(context).pushNamed(
          'location',
          arguments: (event as LocationEvent).locationId,
        );
        // setState(() {
        //   // currentLocationId = (event as LocationEvent).locationId;
        // });
      }),
    );

    engine.registerListener(
      Events.leftLocation,
      EventHandler(widget.key!, (event) {
        // setState(() {
        //   // currentLocationId = null;
        // });
      }),
    );

    () async {
      await engine.init(externalFunctions: externalGameFunctions);
      // engine.hetu.evalFile('core/main.ht', invokeFunc: 'init');
      // engine.hetu.switchModule('game:main');

      await refreshSaves();

      setState(() {
        _isLoading = false;
      });
    }();
  }

  Future<void> refreshSaves() async {
    savedFiles.clear();
    savedFiles.addAll(await _getSavedFiles());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(
          text: engine.isLoaded ? engine.locale['loading'] : 'Loading...');
    }
    // else if (currentLocationId != null) {
    //   return LocationView(locationId: currentLocationId!);
    // }
    else if (engine.currentScene != null) {
      return engine.currentScene!.widget;
    } else {
      final menuWidgets = <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 150),
          child: Image(
            image: AssetImage('assets/images/title.png'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              engine.createScene('WorldMap');
            },
            child: Text(locale['sandBoxMode']),
          ),
        ),
      ];

      if (savedFiles.isNotEmpty) {
        menuWidgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: ElevatedButton(
              onPressed: () {
                LoadGameDialog.show(context, list: savedFiles)
                    .then((SaveInfo? info) {
                  if (info != null) {
                    setState(() {
                      _isLoading = true;
                    });
                    engine.createScene('WorldMap', info.path);
                  } else {
                    if (savedFiles.isEmpty) {
                      setState(() {});
                    }
                  }
                });
              },
              child: Text(locale['loadGame']),
            ),
          ),
        );
      }

      menuWidgets.add(Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('editor');
          },
          child: Text(locale['gameEditor']),
        ),
      ));

      return Scaffold(
        body: Container(
          color: Colors.black,
          // decoration: const BoxDecoration(
          //   image: DecorationImage(
          //     fit: BoxFit.fill,
          //     image: AssetImage('assets/images/bg/background_01.jpg'),
          //   ),
          // ),
          alignment: Alignment.center,
          child: Column(
            children: menuWidgets,
          ),
        ),
      );
    }
  }

  Future<List<SaveInfo>> _getSavedFiles() async {
    final appDirectory = await path.getApplicationDocumentsDirectory();
    final saveFolder =
        path.join(appDirectory.path, 'Heavenly Tribulation', 'save');

    final list = <SaveInfo>[];
    final saveDirectory = Directory(saveFolder);
    if (saveDirectory.existsSync()) {
      for (final entity in saveDirectory.listSync()) {
        if (entity is File &&
            path.extension(entity.path) == kSaveFileExtension) {
          final d = entity.lastModifiedSync().toLocal();
          final saveInfo =
              SaveInfo(timestamp: d.toMeaningfulString(), path: entity.path);
          list.add(saveInfo);
        }
      }
    }
    return list;
  }
}
