import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:samsara/extensions.dart';
// import 'package:samsara/samsara.dart';
// import 'package:flame_audio/flame_audio.dart';
// import 'package:samsara/event.dart';
import 'package:window_manager/window_manager.dart';
// import 'package:hetu_script/values.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/ui/label.dart';
import 'package:samsara/console.dart';
// import 'package:video_player_win/video_player_win.dart';
import 'package:samsara/cardgame/card.dart';

import '../dialog/game_dialog/game_dialog.dart';
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
import '../scene/card_library/components/library.dart';
import '../scene/battle/binding/character_binding.dart';
import '../data.dart';
import '../scene/card_library/card_library.dart';
import '../ui.dart';
import '../scene/world/location/components/location_site.dart';
import 'create_blank_map.dart';
import '../editor/world_editor.dart';
// import '../../dialog/game_dialog/game_dialog.dart';
import '../dialog/game_dialog/game_dialog_controller.dart';
import '../state/states.dart';
import '../scene/cultivation/cultivation.dart';
import '../scene/cultivation/components/cultivation.dart';
import '../scene/battle/battle.dart';
import '../logic/algorithm.dart';

const kMainMenuBGM = 'chinese-oriental-tune-06-12062.mp3';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }
  // late File _videoFile;
  // late WinVideoPlayerController _videoController;

  bool _isLoading = false;

  final _menuFocusNode = FocusNode();

  void showCultivation() {
    context.read<HeroState>().update();
    context.read<HistoryState>().update();
    // engine.hetu.invoke('acquireByIds');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CultivationOverlay()),
    );
  }

  void _playBGM() {
    engine.playBGM(kMainMenuBGM, volume: GameConfig.musicVolume);
  }

  // Route was pushed onto navigator and is now topmost route.
  @override
  void didPush() {
    _playBGM();
  }

  // Covering route was popped off the navigator.
  @override
  void didPopNext() {
    _playBGM();
  }

  /// Called when the current route has been popped off.
  @override
  void didPop() {
    engine.pauseBGM();
  }

  /// Called when a new route has been pushed, and the current route is no
  /// longer visible.
  @override
  void didPushNext() {
    engine.pauseBGM();
  }

  @override
  void dispose() {
    super.dispose();
    engine.removeEventListener(widget.key!);
    routeObserver.unsubscribe(this);
    // _videoController.dispose();
    engine.disposeBGM();
  }

  @override
  void initState() {
    super.initState();

    engine.initBGM();

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
        // bgm: isEditorMode ? null : 'ghuzheng-fantasie-23506.mp3',
        showFogOfWar: !isEditorMode,
        showNonInteractableHintColor: isEditorMode,
        showGrids: isEditorMode,
      );

      final colors = engine.hetu.invoke('getCurrentWorldZoneColors');
      engine.addTileMapZoneColors(scene.map, worldId!, colors);

      return scene;
    });

    engine.registerSceneConstructor('cultivation', ([dynamic data]) async {
      return CultivationScene(
        controller: engine,
        context: context,
      );
    });

    engine.registerSceneConstructor('deckBuilding', ([dynamic data]) async {
      return CardLibraryScene(
        controller: engine,
        library: data,
        context: context,
      );
    });

    engine.registerSceneConstructor('cardBattle', ([dynamic data]) async {
      return BattleScene(
        context: context,
        controller: engine,
        id: data['id'],
        heroData: data['heroData'],
        enemyData: data['enemyData'],
        heroDeck: data['heroDeck'],
        enemyDeck: data['enemyDeck'],
        isSneakAttack: data['isSneakAttack'],
      );
    });
  }

  // 因为 FutureBuilder 根据返回值是否为null来判断，因此这里无论如何要返回一个值
  Future<bool> _loadData() async {
    if (GameData.isInitted) {
      assert(engine.isInitted);
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
            positionXOffset: namedArgs['positionXOffset'],
            positionYOffset: namedArgs['positionYOffset'],
            fadeIn: namedArgs['fadeIn'],
          );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popImage', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popImage(
            imageId: namedArgs['image'],
            fadeOut: namedArgs['fadeOut'],
          );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popAllImage', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popAllImage();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('pushScene', (
        {positionalArgs, namedArgs}) {
      context
          .read<GameDialogState>()
          .pushScene(positionalArgs.first, fadeIn: namedArgs['fadeIn']);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popScene', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popScene(fadeOut: namedArgs['fadeOut']);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('popAllScene', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popAllScene();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('updateHero', (
        {positionalArgs, namedArgs}) {
      context.read<HeroState>().update(showHeroInfo: namedArgs['showHeroInfo']);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('updateHistory', (
        {positionalArgs, namedArgs}) {
      context.read<HistoryState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('updateQuest', (
        {positionalArgs, namedArgs}) {
      context.read<QuestState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('reloadGameData', (
        {positionalArgs, namedArgs}) {
      GameData.loadGameData();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'showCultivation', ({positionalArgs, namedArgs}) => showCultivation(),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('expForLevel',
        ({positionalArgs, namedArgs}) => expForLevel(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalClass(BattleCharacterClassBinding());

    final mainConfig = {'locale': engine.languageId};
    if (kDebugMode) {
      await engine.loadModFromAssetsString(
        'main/main.ht',
        module: 'main',
        namedArgs: mainConfig,
        isMainMod: true,
      );

      for (final key in GameConfig.modules.keys) {
        if (GameConfig.modules[key]?['enabled'] == true) {
          if (GameConfig.modules[key]?['preinclude'] == true) {
            engine.loadModFromAssetsString(
              '$key/main.ht',
              module: key,
            );
          }
        }
      }
    } else {
      final main = await rootBundle.load('assets/mods/main.mod');
      final gameBytes = main.buffer.asUint8List();
      await engine.loadModFromBytes(
        gameBytes,
        moduleName: 'main',
        namedArgs: mainConfig,
        isMainMod: true,
      );

      for (final key in GameConfig.modules.keys) {
        if (GameConfig.modules[key]?['enabled'] == true) {
          if (GameConfig.modules[key]?['preinclude'] == true) {
            final mod = await rootBundle.load('assets/mods/$key.mod');
            final modBytes = mod.buffer.asUint8List();
            engine.loadModFromBytes(
              modBytes,
              moduleName: key,
            );
          }
        }
      }
    }

    // 载入动画，卡牌等纯JSON格式的游戏数据
    // ignore: use_build_context_synchronously
    await GameData.init(context);

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

    // 创建一个空游戏存档并初始化一些数据，这主要是为了主菜单的测试游戏和debug相关功能，并不会保存
    // 真正开始游戏后还会在执行一遍，因为每次newGame都会清空Game上的数据
    await GameData.newGame('mainmenu_temp');
    GameData.isGameCreated = false;

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
      future: _loadData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          if (snapshot.hasError) {
            throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
          }
          return LoadingScreen(
            text: engine.isInitted ? engine.locale('loading') : 'Loading...',
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
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) => WorldOverlay(
                            args: const {
                              'id': 'cave',
                              'savePath': 'tutorial',
                              'method': 'preset',
                            },
                          ),
                        ),
                      )
                          .then((_) {
                        GameData.isGameCreated = false;
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
                        if (context.mounted) {
                          context
                              .read<MainMenuState>()
                              .setState(MainMenuStates.main);

                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) => WorldOverlay(args: args),
                            ),
                          )
                              .then((_) {
                            GameData.isGameCreated = false;
                          });
                        }
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
                        if (context.mounted) {
                          context
                              .read<MainMenuState>()
                              .setState(MainMenuStates.main);

                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) => WorldOverlay(
                                args: {
                                  'id': info.currentWorldId,
                                  'savePath': info.savePath,
                                  'method': 'load',
                                },
                              ),
                            ),
                          )
                              .then((_) {
                            GameData.isGameCreated = false;
                          });
                        }
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
                        if (context.mounted) {
                          context
                              .read<MainMenuState>()
                              .setState(MainMenuStates.main);

                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  WorldEditorOverlay(args: value),
                            ),
                          )
                              .then((_) {
                            GameData.isGameCreated = false;
                          });
                        }
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
                        if (context.mounted) {
                          context
                              .read<MainMenuState>()
                              .setState(MainMenuStates.main);

                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) => WorldEditorOverlay(
                                args: {
                                  'id': info.currentWorldId,
                                  'method': 'load',
                                  'savePath': info.savePath,
                                  'isEditorMode': true,
                                },
                              ),
                            ),
                          )
                              .then((_) {
                            GameData.isGameCreated = false;
                          });
                        }
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

                      final hero = engine.hetu.invoke('Character', namedArgs: {
                        'unconvertedExp': 1000000,
                        'majorAttributes': ['dexterity'],
                      });
                      engine.hetu
                          .invoke('setHeroId', positionalArgs: [hero['id']]);

                      showCultivation();
                    },
                    child: Label(
                      engine.locale('debugCultivation'),
                      width: 150.0,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      context
                          .read<MainMenuState>()
                          .setState(MainMenuStates.main);

                      final hero = engine.hetu.invoke('Character', namedArgs: {
                        'isMajorCharacter': false,
                        // 'baseStats': {
                        //   'life': 40,
                        // }
                      });
                      final enemy = engine.hetu.invoke('Character', namedArgs: {
                        'isMajorCharacter': false,
                        // 'baseStats': {
                        //   'life': 80,
                        //   'physiqueAttack': 5,
                        // },
                        // 'skin': 'boar',
                      });
                      final heroLibrary = [];
                      for (var i = 0; i < 16; ++i) {
                        final cardData = engine.hetu.invoke(
                          'BattleCard',
                          namedArgs: {
                            'maxRank': 1,
                          },
                        );
                        heroLibrary.add(cardData);
                      }
                      final enemyDeck = <GameCard>[];
                      for (var i = 0; i < 4; ++i) {
                        final cardData = engine.hetu.invoke('BattleCard');
                        final enemyBattleCard =
                            GameData.createBattleCardByData(cardData);
                        enemyDeck.add(enemyBattleCard);
                      }

                      // final enemyDeck = PresetDecks.random;
                      // final enemyDeck = PrebuildDecks.basic;

                      final List<GameCard>? heroDeck =
                          await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CardLibraryOverlay(
                            deckSize: 4,
                            heroData: hero,
                            heroLibrary: heroLibrary,
                          ),
                        ),
                      );

                      if (heroDeck != null) {
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => BattleSceneOverlay(
                                key: UniqueKey(),
                                heroData: hero,
                                enemyData: enemy,
                                heroDeck: heroDeck,
                                enemyDeck: enemyDeck,
                                isSneakAttack: false,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Label(engine.locale('debugBattle'),
                        width: 200.0, textAlign: TextAlign.center),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      GameDialog.show(
                        context: context,
                        dialogData: {
                          'lines': [
                            "你好！这是一个带有<bold blue>格式化</>文本的<color='#F28234' link='test'>测试</>对话！"
                          ],
                        },
                      );
                    },
                    child: Label(engine.locale('debugGameDialog'),
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
                      );
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

          return KeyboardListener(
            autofocus: true,
            focusNode: _menuFocusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent) {}
            },
            child: Scaffold(
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
            ),
          );
        }
      },
    );
  }
}
