import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:samsara/extensions.dart';
// import 'package:samsara/extensions.dart';
// import 'package:samsara/samsara.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:samsara/event.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/ui/flutter/loading_screen.dart';
import 'package:samsara/ui/flutter/label.dart';
import 'package:samsara/console.dart';
// import 'package:video_player_win/video_player_win.dart';
import 'package:samsara/cardgame/playing_card.dart';

import '../pages/map/maze/maze.dart';
import '../config.dart';
import '../shared/constants.dart';
import '../../shared/datetime.dart';
import 'load_game_dialog.dart';
import 'dialog/binding/dialog_bindings.dart';
import '../scene/worldmap.dart';
import '../scene/maze.dart';
import 'create_game_dialog.dart';
// import '../event/events.dart';
import '../pages/map/world/world.dart';
import '../pages/battle/scene/battle.dart';
import '../pages/deckbuilding/scene/deckbuilding.dart';
import '../pages/battle/binding/character_binding.dart';
import '../data.dart';
import '../pages/deckbuilding/deckbuilding.dart';
import '../ui.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  // late File _videoFile;
  // late WinVideoPlayerController _videoController;

  bool _isLoading = false;

  // 模组信息，key是模组名字，value代表是否启用
  final _modsInfo = <String, bool>{
    'story': true,
  };

  final _savedFiles = <SaveInfo>[];

  @override
  void initState() {
    super.initState();

    // 读取游戏配置

    engine.registerSceneConstructor('worldmap', ([dynamic args]) async {
      engine.hetu.invoke('resetGame');

      var isFirstLoad = false;

      // 因为生成世界时会触发一些mod的回调函数，因此需要先载入 mod 数据
      for (final key in _modsInfo.keys) {
        if (_modsInfo[key] == true) {
          engine.hetu.invoke('load', module: key);
        }
      }

      HTStruct worldData;
      final path = args!['path1'];
      if (path != null) {
        final gameSavePath = File(path);
        final gameDataString = gameSavePath.readAsStringSync();
        final gameData = jsonDecode(gameDataString);
        final mapSavePath = File(args!['path2']);
        final mapDataString = mapSavePath.readAsStringSync();
        final mapData = jsonDecode(mapDataString);
        engine.info('从 [$path] 载入游戏存档。');
        worldData = engine.hetu.invoke('loadGameFromJsonData',
            positionalArgs: [gameData, mapData]);
      } else {
        worldData = engine.hetu.invoke('createWorldMap', namedArgs: args);
        engine.hetu.invoke('enterWorld', positionalArgs: [worldData]);
        isFirstLoad = true;
      }

      return WorldMapScene(
        worldData: worldData,
        controller: engine,
        captionStyle: captionStyle,
        isFirstLoad: isFirstLoad,
      );
    });

    engine.registerSceneConstructor('maze', ([dynamic data]) async {
      return MazeScene(
        mapData: data!,
        controller: engine,
        captionStyle: captionStyle,
      );
    });

    engine.registerSceneConstructor('deckBuilding', ([dynamic data]) async {
      return DeckBuildingScene(
        controller: engine,
        libray: data,
      );
    });

    engine.registerSceneConstructor('cardGame', ([dynamic data]) async {
      return BattleScene(
          controller: engine,
          id: data['id'],
          heroData: data['heroData'],
          enemyData: data['enemyData'],
          heroCards: data['heroCards'],
          enemyCards: data['enemyCards'],
          isSneakAttack: data['isSneakAttack']);
    });

    engine.bgm.initialize();
    // engine.playBGM('music/chinese-oriental-tune-06-12062.mp3',
    //     volume: GameConfig.musicVolume);
  }

  @override
  void dispose() {
    super.dispose();
    engine.removeEventListener(widget.key!);

    // _videoController.dispose();

    // engine.bgm.stop();
    // engine.bgm.dispose();
  }

  // 因为 FutureBuilder根据返回值是否为null来判断，因此这里无论如何要返回一个值
  Future<bool?> _prepareData() async {
    if (engine.isInitted) {
      engine.hetu.invoke('build', positionalArgs: [context]);
      return true;
    }
    if (_isLoading) return false;
    _isLoading = true;

    _savedFiles.clear();
    _savedFiles.addAll(await _getSavedFiles());

    await engine.init(
      externalFunctions: dialogFunctions,
      // modules: {'cardGame'},
    );

    engine.hetu.interpreter.bindExternalClass(BattleCharacterClassBinding());

    if (kDebugMode) {
      engine.loadModFromAssetsString(
        'game/main.ht',
        module: 'game',
        namedArgs: {'lang': 'zh', 'gameEngine': engine},
        isMainMod: true,
      );
      for (final key in _modsInfo.keys) {
        if (_modsInfo[key] == true) {
          engine.loadModFromAssetsString(
            '$key/main.ht',
            module: key,
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

    // 载入动画，卡牌等纯JSON格式的游戏数据
    await GameData.load();

    engine.hetu.invoke('build', positionalArgs: [context]);

    // const videoFilename = 'D:/_dev/heavenly-tribulation/media/video/title2.mp4';
    // _videoFile = File.fromUri(Uri.file(videoFilename));
    // _videoController = WinVideoPlayerController.file(_videoFile);
    // _videoController.initialize().then((_) {
    //   // Ensure the first frame is shown after the video is initialized.
    //   setState(() {
    //     if (_videoController.value.isInitialized) {
    //       _videoController.play();
    //     } else {
    //       engine.error("Failed to load [$videoFilename]!");
    //     }
    //   });
    // });
    // _videoController.setLooping(true);
    setState(() {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    GameConfig.screenSize = MediaQuery.sizeOf(context);
    engine.info(
        '游戏画面尺寸：${GameConfig.screenSize.width}x${GameConfig.screenSize.height}');
    GameUI.init(GameConfig.screenSize.toVector2());

    return FutureBuilder(
      future: _prepareData(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw (snapshot.error!);
        }

        if (!snapshot.hasData || snapshot.data == false) {
          return LoadingScreen(
              text: engine.isInitted ? engine.locale['loading'] : 'Loading...');
        } else {
          final menus = <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateGameDialog(),
                  ).then((value) {
                    if (value != null) {
                      // engine.stopBGM();
                      showDialog(
                        context: context,
                        builder: (context) => WorldOverlay(
                          key: UniqueKey(),
                          args: value,
                        ),
                      ).then((_) {
                        engine.hetu.invoke('build', positionalArgs: [context]);
                        setState(() {});
                      });
                    }
                  });
                },
                child: Label(
                  engine.locale['sandboxMode'],
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
                      // FlameAudio.bgm.pause();
                      showDialog(
                        context: context,
                        builder: (context) => WorldOverlay(
                          key: UniqueKey(),
                          args: {
                            "id": info.worldId,
                            "path1": info.savepath1,
                            "path2": info.savepath2,
                          },
                        ),
                      ).then((_) {
                        engine.hetu.invoke('build', positionalArgs: [context]);
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
                  engine.locale['loadGame'],
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
                  engine.locale['gameEditor'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  windowManager.close();
                },
                child: Label(
                  engine.locale['exit'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ];

          final debugMenus = <Widget>[
            Positioned(
              right: 20.0,
              bottom: 20.0,
              width: 200.0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // engine.bgm.stop();

                        final hero = engine.hetu.invoke('Character');
                        final enemy = engine.hetu.invoke('Character');
                        const heroLibrary = [
                          'attack_normal',
                          'defend_normal',
                          'sword_1',
                          'sword_2',
                          'sword_3',
                          'sword_4',
                          'sword_5',
                          'sword_6',
                          'sword_7',
                          'sword_8',
                          'sword_9',
                          'sword_10',
                          'sword_11',
                          'sword_12',
                          'array_1',
                          'array_2',
                          'array_3',
                          'array_4',
                          'array_5',
                          'rune_1',
                          'rune_2',
                          'rune_3',
                          'rune_4',
                          'alchemy_1',
                          'alchemy_2',
                          'craft_1',
                          'craft_2',
                        ];
                        final enemyDeck = <PlayingCard>[];
                        enemyDeck.add(GameData.getBattleCard('attack_normal'));
                        enemyDeck.add(GameData.getBattleCard('attack_normal'));
                        enemyDeck.add(GameData.getBattleCard('attack_normal'));
                        enemyDeck.add(GameData.getBattleCard('attack_normal'));

                        showDialog(
                          context: context,
                          builder: (context) => DeckBuildingOverlay(
                            deckSize: 4,
                            heroData: hero,
                            enemyData: enemy,
                            heroLibrary: heroLibrary,
                            enemyDeck: enemyDeck,
                          ),
                        ).then((value) {
                          // FlameAudio.bgm.resume();
                        });
                      },
                      child: const Label(
                        'Test Deckbuilding',
                        width: 200.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // FlameAudio.bgm.stop();
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Material(
                              type: MaterialType.transparency,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final mazeData = engine.hetu
                                            .invoke('testMazeMountain');
                                        showDialog(
                                          context: context,
                                          builder: (context) => MazeOverlay(
                                            key: UniqueKey(),
                                            mazeData: mazeData,
                                          ),
                                        );
                                      },
                                      child: const Text('mountain'),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final mazeData = engine.hetu.invoke(
                                            'testMazeCultivationRecruit');
                                        showDialog(
                                          context: context,
                                          builder: (context) => MazeOverlay(
                                            key: UniqueKey(),
                                            mazeData: mazeData,
                                          ),
                                        );
                                      },
                                      child: const Text('cultivation recruit'),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('close'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).then(
                          (_) {
                            engine.hetu
                                .invoke('build', positionalArgs: [context]);
                            setState(() {});
                          },
                        );
                      },
                      child: const Label(
                        'Test Maze',
                        width: 200.0,
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
                              Console(engine: engine),
                        ).then((_) => setState(() {
                              engine.hetu
                                  .invoke('build', positionalArgs: [context]);
                            }));
                      },
                      child: const Label(
                        'Console',
                        width: 200.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ];

          return Scaffold(
            body: Stack(
              children: [
                //   Positioned(
                //     width: GameConfig.screenSize.width,
                //     height: GameConfig.screenSize.height,
                //     child: AspectRatio(
                //       aspectRatio: GameConfig.screenSize.aspectRatio,
                //       child: WinVideoPlayer(_videoController),
                //     ),
                //   ),
                Positioned(
                  left: 0.0,
                  bottom: 0.0,
                  height: GameConfig.screenSize.height,
                  width: GameConfig.screenSize.width,
                  child: const Image(
                    image: AssetImage('assets/images/title2.gif'),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  left: 20.0,
                  bottom: 20.0,
                  height: 300.0,
                  width: 120.0,
                  child: Column(children: menus),
                ),
                if (engine.config.debugMode) ...debugMenus,
              ],
            ),
          );
        }
      },
    );
  }

  Future<List<SaveInfo>> _getSavedFiles() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final saveFolder =
        path.join(appDirectory.path, GameConfig.gameTitle, 'save');

    final list = <SaveInfo>[];
    final saveDirectory = Directory(saveFolder);
    if (saveDirectory.existsSync()) {
      for (final entity in saveDirectory.listSync()) {
        if (entity is File &&
            path.extension(entity.path) == kGameSaveFileExtension) {
          final worldId = path.basenameWithoutExtension(entity.path);
          final d = entity.lastModifiedSync().toLocal();
          final saveInfo = SaveInfo(
            worldId: worldId,
            timestamp: d.toMeaningfulString(),
            savepath1: entity.path,
            savepath2: '${entity.path}$kUniverseSaveFilePostfix',
          );
          list.add(saveInfo);
        }
      }
    }
    return list;
  }
}
