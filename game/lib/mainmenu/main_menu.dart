import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:samsara/extensions.dart';
// import 'package:samsara/extensions.dart';
// import 'package:samsara/samsara.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:samsara/event.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:hetu_script/values.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/console.dart';
// import 'package:video_player_win/video_player_win.dart';

// import '../pages/map/maze/maze_overlay.dart';
import '../config.dart';
import 'load_game.dart';
import '../dialog/binding/dialog_bindings.dart';
import '../scene/world/world.dart';
// import '../map/maze/maze.dart';
import 'create_sandbox_game.dart';
// import '../event/events.dart';
import '../scene/world/world_overlay.dart';
import '../scene/battle/components/battle.dart';
import '../scene/deckbuilding/components/deckbuilding.dart';
import '../scene/battle/binding/character_binding.dart';
import '../data.dart';
import '../scene/deckbuilding/deckbuilding.dart';
import '../ui.dart';
import '../scene/world/location/components/location_site.dart';
import 'create_blank_map.dart';
import '../editor/world_editor.dart';
// import '../../dialog/game_dialog/game_dialog.dart';
import '../dialog/game_dialog/game_dialog_controller.dart';
import '../state/states.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  // late File _videoFile;
  // late WinVideoPlayerController _videoController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // TODO: 读取游戏配置

    // 读取存档列表
    context.read<GameSavesState>().loadList();

    engine.registerSceneConstructor('locationSite', ([dynamic args]) async {
      return LocationSiteScene(
        controller: engine,
        context: context,
        id: args['id'],
        background: args['background'],
        sitesIds: args['sitesIds'],
        sitesData: args['sitesData'],
      );
    });

    engine.registerSceneConstructor('tilemap', ([dynamic args]) async {
      dynamic worldData;
      final method = args['method'];
      final isEditorMode = args['isEditorMode'] ?? false;
      String? worldId;
      if (method == 'load' || method == 'preset') {
        worldData =
            engine.hetu.invoke('switchWorld', positionalArgs: [args['id']]);
      } else if (method == 'generate') {
        engine.info('创建程序生成的随机世界。');
        worldData = engine.hetu.invoke('createSandboxWorld', namedArgs: args);
      } else if (method == 'blank') {
        engine.info('创建空白世界。');
        worldData = engine.hetu.invoke('createBlankWorld', namedArgs: args);
      }
      worldId ??= engine.hetu.invoke('getCurrentWorldId');

      engine.hetu.invoke('calculateTimestamp');

      final scene = WorldMapScene(
        isMainWorld: worldData['isMainWorld'],
        worldData: worldData,
        controller: engine,
        backgroundSpriteId: args['background'],
        // ignore: use_build_context_synchronously
        context: context,
        captionStyle: captionStyle,
        bgm: isEditorMode ? null : 'ghuzheng-fantasie-23506.mp3',
        showFogOfWar: !isEditorMode,
        showNonInteractableHintColor: isEditorMode,
        showGrids: isEditorMode,
      );

      final colors = engine.hetu.invoke('getCurrentWorldZoneColors');
      engine.addTileMapZoneColors(scene.map, worldId!, colors);

      return scene;
    });

    engine.registerSceneConstructor('deckBuilding', ([dynamic data]) async {
      return DeckBuildingScene(
        controller: engine,
        libray: data,
        context: context,
      );
    });

    engine.registerSceneConstructor('cardGame', ([dynamic data]) async {
      return BattleScene(
        context: context,
        controller: engine,
        id: data['id'],
        heroData: data['heroData'],
        enemyData: data['enemyData'],
        heroCards: data['heroCards'],
        enemyCards: data['enemyCards'],
        isSneakAttack: data['isSneakAttack'],
      );
    });

    engine.bgm.initialize();
    engine.loop('chinese-oriental-tune-06-12062.mp3',
        volume: GameConfig.musicVolume);
  }

  @override
  void dispose() {
    super.dispose();
    engine.removeEventListener(widget.key!);

    // _videoController.dispose();

    // engine.bgm.stop();
    engine.bgm.dispose();
  }

  // 因为 FutureBuilder根据返回值是否为null来判断，因此这里无论如何要返回一个值
  Future<bool> _prepareData() async {
    if (engine.isInitted) {
      engine.hetu.invoke('build', positionalArgs: [context]);
      _isLoading = false;
      return true;
    }
    if (_isLoading) return false;
    _isLoading = true;

    await engine.init(externalFunctions: dialogFunctions);

    engine.hetu.interpreter.bindExternalFunction('_start', (
        {positionalArgs, namedArgs}) {
      if (mounted) {
        context.read<GameDialogState>().start();
      }
      GameDialogController.show(context: positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('pop', (
        {positionalArgs, namedArgs}) {
      Navigator.of(context).pop();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('end', (
        {positionalArgs, namedArgs}) {
      if (mounted) {
        context.read<GameDialogState>().end();
      }
      // 清理掉所有可能没有清理的残存数据
      context.read<GameDialogState>().popAllImage();
      context.read<GameDialogState>().popAllScene();
      Navigator.of(context).pop();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('pushImage', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().pushImage(
            positionalArgs[0],
            positionXOffset: positionalArgs[1],
          );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popImage', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popImage(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popAllImage', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popAllImage();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('pushScene', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().pushScene(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popScene', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popScene();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popAllScene', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popAllScene();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popAllScene', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popAllScene();
    }, override: true);

    engine.hetu.interpreter.bindExternalClass(BattleCharacterClassBinding());

    final mainConfig = {'locale': engine.languageId};
    if (kDebugMode) {
      engine.loadModFromAssetsString(
        'game/main.ht',
        module: 'game',
        namedArgs: mainConfig,
        isMainMod: true,
      );
    } else {
      final game = await rootBundle.load('assets/mods/game.mod');
      final gameBytes = game.buffer.asUint8List();
      engine.loadModFromBytes(
        gameBytes,
        moduleName: 'game',
        namedArgs: mainConfig,
        isMainMod: true,
      );
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
    _isLoading = false;
    setState(() {});
    return true;
  }

  @override
  Widget build(BuildContext context) {
    GameConfig.screenSize = MediaQuery.sizeOf(context);
    if (GameUI.size != GameConfig.screenSize.toVector2()) {
      engine.info(
          '画面尺寸修改为：${GameConfig.screenSize.width}x${GameConfig.screenSize.height}');
      GameUI.init(GameConfig.screenSize.toVector2());
    }

    return FutureBuilder(
      future: _prepareData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          if (snapshot.hasError) {
            throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
          }
          return LoadingScreen(
            text: engine.isInitted ? engine.locale('loading') : 'Loading...',
            showClose: snapshot.hasError,
          );
        } else {
          final menus = <Widget>[];
          switch (context.watch<MainMenuState>().state) {
            case MainMenuStates.main:
              menus.addAll([
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.game);
                    },
                    child: Label(
                      engine.locale('startGame'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.editor);
                    },
                    child: Label(
                      engine.locale('editors'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {},
                    child: Label(
                      engine.locale('settings'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.debug);
                    },
                    child: Label(
                      engine.locale('debugMod'),
                      width: 150.0,
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
                      engine.locale('exit'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              ]);
            case MainMenuStates.game:
              menus.addAll([
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.main);
                      engine.bgm.pause();
                      showDialog(
                        context: context,
                        builder: (context) => WorldOverlay(
                          args: const {
                            'id': 'cave',
                            'path': 'tutorial',
                            'method': 'preset',
                          },
                        ),
                      ).then((_) {
                        GameData.isGameCreated = false;
                        engine.bgm.resume();
                      });
                    },
                    child: Label(
                      engine.locale('tutorial'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Padding(
                //   padding: const EdgeInsets.only(top: 20.0),
                //   child: ElevatedButton(
                //     onPressed: () {},
                //     child: Label(
                //       engine.locale('storyMode'),
                //       width: 150.0,
                //       textAlign: TextAlign.center,
                //     ),
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CreateSandboxGameDialog(),
                      ).then((args) {
                        if (args == null) return;
                        context
                            .read<MainMenuState>()
                            .setState(MainMenuStates.main);
                        engine.bgm.pause();
                        showDialog(
                          context: context,
                          builder: (context) => WorldOverlay(args: args),
                        ).then((_) {
                          GameData.isGameCreated = false;
                          engine.bgm.resume();
                        });
                      });
                    },
                    child: Label(
                      engine.locale('sandboxMode'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog<SaveInfo?>(
                        context: context,
                        builder: (context) => const LoadGameDialog(),
                      ).then((SaveInfo? info) async {
                        if (info == null) return;
                        context
                            .read<MainMenuState>()
                            .setState(MainMenuStates.main);
                        engine.bgm.pause();
                        showDialog(
                          context: context,
                          builder: (context) => WorldOverlay(
                            args: {
                              'id': info.currentWorldId,
                              'path': info.savePath,
                              'method': 'load',
                            },
                          ),
                        ).then((_) {
                          GameData.isGameCreated = false;
                          engine.bgm.resume();
                        });
                      });
                    },
                    child: Label(
                      engine.locale('load'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.main);
                    },
                    child: Label(
                      engine.locale('goBack'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ]);
            case MainMenuStates.editor:
              menus.addAll([
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const CreateBlankMapDialog(),
                      ).then((value) {
                        if (value == null) return;
                        context
                            .read<MainMenuState>()
                            .setState(MainMenuStates.main);
                        engine.bgm.pause();
                        showDialog(
                          context: context,
                          builder: (context) => WorldEditorOverlay(args: value),
                        ).then((_) {
                          GameData.isGameCreated = false;
                          engine.bgm.resume();
                        });
                      });
                    },
                    child: Label(
                      engine.locale('createMap'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog<SaveInfo?>(
                        context: context,
                        builder: (context) => const LoadGameDialog(),
                      ).then((SaveInfo? info) {
                        if (info == null) return;
                        context
                            .read<MainMenuState>()
                            .setState(MainMenuStates.main);
                        engine.bgm.pause();
                        showDialog(
                          context: context,
                          builder: (context) => WorldEditorOverlay(
                            args: {
                              'id': info.currentWorldId,
                              'method': 'load',
                              'path': info.savePath,
                              'isEditorMode': true,
                            },
                          ),
                        ).then((_) {
                          GameData.isGameCreated = false;
                          engine.bgm.resume();
                        });
                      });
                    },
                    child: Label(
                      engine.locale('load'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.main);
                    },
                    child: Label(
                      engine.locale('goBack'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ]);
            case MainMenuStates.debug:
              menus.addAll([
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.main);
                      engine.bgm.pause();

                      final hero = engine.hetu.invoke('Character', namedArgs: {
                        'isMajorCharacter': false,
                        'baseStats': {
                          'life': 40,
                        }
                      });
                      final enemy = engine.hetu.invoke('Character', namedArgs: {
                        'isMajorCharacter': false,
                        'baseStats': {
                          'life': 80,
                          'physiqueAttack': 5,
                        },
                        'skin': 'boar',
                      });
                      const heroLibrary = [
                        'attack_normal',
                        'defend_normal',
                        'blade_1',
                        // 'blade_2',
                        'blade_3',
                        'blade_4',
                        // 'blade_5',
                        'blade_6',
                        'blade_7',
                        'blade_8',
                        'blade_9',
                        'blade_10',
                        'blade_11',
                        'blade_12',
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
                      // final enemyDeck = PresetDecks.random;
                      final enemyDeck = PresetDecks.basic;

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
                        engine.bgm.resume();
                      });
                    },
                    child: Label(engine.locale('debugBattle'),
                        width: 200.0, textAlign: TextAlign.center),
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
                    child: Label(engine.locale('console'),
                        width: 200.0, textAlign: TextAlign.center),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.main);
                    },
                    child: Label(engine.locale('goBack'),
                        width: 150.0, textAlign: TextAlign.center),
                  ),
                ),
              ]);
          }

          return Scaffold(
            body: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                SizedBox(
                  height: GameConfig.screenSize.height,
                  width: GameConfig.screenSize.width,
                  child: const Image(
                    image: AssetImage('assets/images/title2.gif'),
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned(
                  top: 200.0,
                  child: Image(
                    image: AssetImage('assets/images/title.png'),
                  ),
                ),
                Positioned(
                  bottom: 20.0,
                  height: 280.0,
                  width: 150.0,
                  child: Column(children: menus),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}