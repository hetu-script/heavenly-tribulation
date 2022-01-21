import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path/path.dart' as path;

import '../engine/engine.dart';
import '../shared/localization.dart';
import '../engine/scene/maze.dart';
import 'shared/loading_screen.dart';
import '../engine/scene/worldmap.dart';
import '../event/event.dart';
import '../event/events.dart';
import '../shared/constants.dart';
import '../../shared/datetime.dart';
import 'load_game_dialog.dart';

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

    engine.registerSceneConstructor('WorldMap', ([String? arg]) {
      return WorldMapScene(arg);
    });

    engine.registerSceneConstructor('Maze', ([String? arg]) {
      return MazeScene(arg);
    });

    engine.registerListener(
        GameEvents.onBack2Menu,
        EventHandler(widget.key!, (GameEvent event) {
          refreshSaves();
        }));

    engine.registerListener(
      SceneEvents.started,
      EventHandler(widget.key!, (event) {
        setState(() {
          _isLoading = false;
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
      LocationEvents.left,
      EventHandler(widget.key!, (event) {
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
      return LoadingScreen(text: engine.locale['loading']);
    }
    // else if (currentLocationId != null) {
    //   return LocationView(locationId: currentLocationId!);
    // }
    else if (engine.currentScene != null) {
      return engine.currentScene!.widget;
    } else {
      final menuButtons = <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                engine.createScene('WorldMap');
              });
            },
            child: Text(locale['sandBoxMode']),
          ),
        ),
      ];

      if (savedFiles.isNotEmpty) {
        menuButtons.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ElevatedButton(
              onPressed: () {
                LoadGameDialog.show(context, list: savedFiles)
                    .then((SaveInfo? info) {
                  if (info != null) {
                    _isLoading = true;
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

      menuButtons.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('editor');
          },
          child: Text(locale['gameEditor']),
        ),
      ));

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: menuButtons,
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
