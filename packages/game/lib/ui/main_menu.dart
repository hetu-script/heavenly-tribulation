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
import 'overlay/worldmap/worldmap.dart';

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

    engine.registerSceneConstructor('worldmap', (
        [Map<String, dynamic>? args]) async {
      Map<String, dynamic> worldData;
      final path = args!['path'];
      if (path != null) {
        final gameSavePath = File(path);
        final gameDataString = gameSavePath.readAsStringSync();
        final gameData = jsonDecode(gameDataString);
        final historySavePath = File('${path}2');
        final historyDataString = historySavePath.readAsStringSync();
        final historyData = jsonDecode(historyDataString);
        engine.info('从 [$path] 载入游戏存档。');
        engine.invoke('loadGameFromJsonData',
            positionalArgs: [gameData, historyData]);
        engine.invoke('loadModsToGame');
        worldData = gameData['world'];
      } else {
        worldData = engine.invoke('createWorldMap', namedArgs: {
          'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
          ...args,
        });
      }
      return WorldMapScene(jsonData: worldData, controller: engine);
    });

    engine.registerSceneConstructor('Maze', (
        [Map<String, dynamic>? arg]) async {
      return MazeScene(controller: engine);
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
          if (engine.currentScene != null) {
            return engine.currentScene!.widget;
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
                    ).then(
                      (value) {
                        if (value != null) {
                          showDialog(
                            context: context,
                            builder: (context) => WorldMapOverlay(
                              key: UniqueKey(),
                              data: value,
                            ),
                          ).then((value) {
                            setState(() {});
                          });
                        }
                      },
                    );
                  },
                  child: Text(locale['sandBoxMode']),
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

            Widget layout;
            if (GlobalConfig.orientationMode == OrientationMode.landscape) {
              layout = Stack(
                children: [
                  Positioned(
                    left: 20.0,
                    bottom: 20.0,
                    height: 300.0,
                    width: 120.0,
                    child: Column(children: menus),
                  ),
                ],
              );
            } else {
              layout = Container(
                color: GlobalConfig.theme.backgroundColor,
                // decoration: const BoxDecoration(
                //   image: DecorationImage(
                //     fit: BoxFit.fill,
                //     image: AssetImage('assets/images/bg/background_01.jpg'),
                //   ),
                // ),
                alignment: Alignment.center,
                child: Column(children: menus),
              );
            }
            return Scaffold(body: layout);
          }
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
