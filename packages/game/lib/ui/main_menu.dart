import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:heavenly_tribulation/ui/overlay/maze/maze.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
// import 'package:samsara/event.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hetu_script/values.dart';

import '../global.dart';
import 'shared/loading_screen.dart';
import '../shared/constants.dart';
import '../../shared/datetime.dart';
import 'load_game_dialog.dart';
import '../binding/external_game_functions.dart';
import '../scene/worldmap.dart';
import '../scene/maze.dart';
import 'create_game_dialog.dart';
// import '../event/events.dart';
import 'overlay/main_game.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({required super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  GameLocalization get locale => engine.locale;

  final savedFiles = <SaveInfo>[];

  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('worldmap', ([dynamic args]) async {
      HTStruct world;
      final path = args!['path'];
      if (path != null) {
        final gameSavePath = File(path);
        final gameDataString = gameSavePath.readAsStringSync();
        final gameData = jsonDecode(gameDataString);
        final historySavePath = File('${path}2');
        final historyDataString = historySavePath.readAsStringSync();
        final historyData = jsonDecode(historyDataString);
        engine.info('从 [$path] 载入游戏存档。');
        world = engine.invoke('loadGameFromJsonData',
            positionalArgs: [gameData, historyData]);
      } else {
        world = engine.invoke('createWorldMap', namedArgs: args);
      }
      engine.invoke('loadModsToGame');
      return WorldMapScene(data: world, controller: engine);
    });

    engine.registerSceneConstructor('maze', ([dynamic data]) async {
      return MazeScene(data: data!, controller: engine);
    });
  }

  Future<void> refreshSaves() async {
    savedFiles.clear();
    savedFiles.addAll(await _getSavedFiles());
  }

  Future<bool> _prepareData() async {
    await refreshSaves();
    if (engine.isLoaded) return false;
    await engine.init(externalFunctions: externalGameFunctions);
    if (kDebugMode) {
      engine.loadModFromAssets(
        'game/main.ht',
        moduleName: 'game',
        namedArgs: {'lang': 'zh', 'gameEngine': engine},
        isMainMod: true,
      );
      engine.loadModFromAssets(
        'story/main.ht',
        moduleName: 'story',
      );
    } else {
      final game = await rootBundle.load('assets/game.mod');
      final gameBytes = game.buffer.asUint8List();
      engine.loadModFromBytes(
        gameBytes,
        moduleName: 'game',
        namedArgs: {'lang': 'zh', 'gameEngine': engine},
        isMainMod: true,
      );
      final mod = await rootBundle.load('assets/story.mod');
      final modBytes = mod.buffer.asUint8List();
      engine.loadModFromBytes(
        modBytes,
        moduleName: 'story',
      );
    }
    engine.isLoaded = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prepareData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingScreen(
              text: engine.isLoaded ? engine.locale['loading'] : 'Loading...');
        } else {
          final menus = <Widget>[
            // const Padding(
            //   padding: EdgeInsets.only(top: 150),
            //   child: Image(
            //     image: AssetImage('assets/images/title.png'),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateGameDialog(),
                  ).then((value) {
                    if (value != null) {
                      showDialog(
                        context: context,
                        builder: (context) => MainGameOverlay(
                          key: UniqueKey(),
                          args: value,
                        ),
                      ).then((value) {
                        setState(() {});
                      });
                    }
                  });
                },
                child: Text(locale['newGame']),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: ElevatedButton(
                onPressed: () {
                  final mazeData = engine.invoke('createMaze', namedArgs: {});
                  showDialog(
                    context: context,
                    builder: (context) => MazeOverlay(
                      key: UniqueKey(),
                      data: mazeData,
                    ),
                  ).then((value) {
                    setState(() {});
                  });
                },
                child: const Text('Test Maze'),
              ),
            ),
            if (savedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    LoadGameDialog.show(context, list: savedFiles)
                        .then((SaveInfo? info) {
                      if (info != null) {
                        Navigator.of(context).pushNamed('worldmap',
                            arguments: {"path": info.path});
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
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('editor');
                },
                child: Text(locale['gameEditor']),
              ),
            ),
            if (GlobalConfig.isOnDesktop) ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    windowManager.close();
                  },
                  child: Text(locale['exit']),
                ),
              ),
            ],
          ];

          return Scaffold(
            body: GlobalConfig.orientationMode == OrientationMode.landscape
                ? Stack(
                    children: [
                      Positioned(
                        left: 20.0,
                        bottom: 20.0,
                        height: 300.0,
                        width: 120.0,
                        child: Column(children: menus),
                      ),
                    ],
                  )
                : Container(
                    color: GlobalConfig.theme.backgroundColor,
                    // decoration: const BoxDecoration(
                    //   image: DecorationImage(
                    //     fit: BoxFit.fill,
                    //     image: AssetImage('assets/images/bg/background_01.jpg'),
                    //   ),
                    // ),
                    alignment: Alignment.center,
                    child: Column(children: menus),
                  ),
          );
        }
      },
    );
  }

  Future<List<SaveInfo>> _getSavedFiles() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final saveFolder =
        path.join(appDirectory.path, 'Heavenly Tribulation', 'save');

    final list = <SaveInfo>[];
    final saveDirectory = Directory(saveFolder);
    if (saveDirectory.existsSync()) {
      for (final entity in saveDirectory.listSync()) {
        if (entity is File &&
            path.extension(entity.path) == kWorldSaveFileExtension) {
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
