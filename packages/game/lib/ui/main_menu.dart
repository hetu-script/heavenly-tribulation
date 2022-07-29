import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
// import 'package:samsara/event.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hetu_script/values.dart';

import 'overlay/maze/maze.dart';
import 'view/console.dart';
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
import 'shared/label.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  GameLocalization get locale => engine.locale;

  // 模组信息，key是模组名字，value代表是否启用
  final _modsInfo = <String, bool>{
    'story': true,
  };

  final _savedFiles = <SaveInfo>[];

  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('worldmap', ([dynamic args]) async {
      // 因为生成世界时会触发一些mod的回调函数，因此需要先载入 mod 数据
      for (final key in _modsInfo.keys) {
        if (_modsInfo[key] == true) {
          engine.invoke('load', moduleName: key);
        }
      }

      HTStruct worldData;
      final path = args!['path'];
      if (path != null) {
        final gameSavePath = File(path);
        final gameDataString = gameSavePath.readAsStringSync();
        final gameData = jsonDecode(gameDataString);
        final historySavePath = File('${path}2');
        final historyDataString = historySavePath.readAsStringSync();
        final historyData = jsonDecode(historyDataString);
        engine.info('从 [$path] 载入游戏存档。');
        worldData = engine.invoke('loadGameFromJsonData',
            positionalArgs: [gameData, historyData]);
      } else {
        worldData = engine.invoke('createWorldMap', namedArgs: args);
      }

      return WorldMapScene(worldData: worldData, controller: engine);
    });

    engine.registerSceneConstructor('maze', ([dynamic data]) async {
      return MazeScene(mapData: data!, controller: engine);
    });
  }

  Future<void> refreshSaves() async {
    _savedFiles.clear();
    _savedFiles.addAll(await _getSavedFiles());
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
      for (final key in _modsInfo.keys) {
        if (_modsInfo[key] == true) {
          engine.loadModFromAssets(
            '$key/main.ht',
            moduleName: key,
          );
        }
      }
    } else {
      final game = await rootBundle.load('assets/mods/game.mod');
      final gameBytes = game.buffer.asUint8List();
      engine.loadModFromBytes(
        gameBytes,
        moduleName: 'game',
        namedArgs: {'lang': 'zh', 'gameEngine': engine},
        isMainMod: true,
      );
      for (final key in _modsInfo.keys) {
        if (_modsInfo[key] == true) {
          final mod = await rootBundle.load('assets/mods/$key.mod');
          final modBytes = mod.buffer.asUint8List();
          engine.loadModFromBytes(
            modBytes,
            moduleName: key,
          );
        }
      }
    }

    engine.invoke('build', positionalArgs: [context]);
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
                        engine.invoke('build', positionalArgs: [context]);
                        setState(() {});
                      });
                    }
                  });
                },
                child: Label(
                  locale['sandboxMode'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  LoadGameDialog.show(context, list: _savedFiles)
                      .then((SaveInfo? info) {
                    if (info != null) {
                      showDialog(
                        context: context,
                        builder: (context) => MainGameOverlay(
                          key: UniqueKey(),
                          args: {
                            "id": info.worldId,
                            "path": info.path,
                          },
                        ),
                      ).then((value) {
                        engine.invoke('build', positionalArgs: [context]);
                        setState(() {});
                      });
                    } else {
                      if (_savedFiles.isEmpty) {
                        setState(() {});
                      }
                    }
                  });
                },
                child: Label(
                  locale['loadGame'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.of(context).pushNamed('editor');
                },
                child: Label(
                  locale['gameEditor'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (Global.isOnDesktop) ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    windowManager.close();
                  },
                  child: Label(
                    locale['exit'],
                    width: 100.0,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ];

          return Scaffold(
            body: Global.orientationMode == OrientationMode.landscape
                ? Stack(
                    children: [
                      Positioned(
                        left: 20.0,
                        bottom: 20.0,
                        height: 300.0,
                        width: 120.0,
                        child: Column(children: menus),
                      ),
                      if (engine.debugMode)
                        Positioned(
                          right: 20.0,
                          bottom: 20.0,
                          width: 120.0,
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    final mazeData = engine.invoke('testMaze');
                                    showDialog(
                                      context: context,
                                      builder: (context) => MazeOverlay(
                                        key: UniqueKey(),
                                        mazeData: mazeData,
                                      ),
                                    ).then((value) {
                                      engine.invoke('build',
                                          positionalArgs: [context]);
                                      setState(() {});
                                    });
                                  },
                                  child: const Label(
                                    'Test Maze',
                                    width: 100.0,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          const Console(),
                                    ).then((value) => setState(() {
                                          engine.invoke('build',
                                              positionalArgs: [context]);
                                        }));
                                  },
                                  child: const Label(
                                    'Console',
                                    width: 100.0,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                : Container(
                    color: Global.appTheme.backgroundColor,
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
          final worldId = path.basenameWithoutExtension(entity.path);
          final d = entity.lastModifiedSync().toLocal();
          final saveInfo = SaveInfo(
            worldId: worldId,
            timestamp: d.toMeaningfulString(),
            path: entity.path,
          );
          list.add(saveInfo);
        }
      }
    }
    return list;
  }
}
