import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heavenly_tribulation/scene/mainmenu/mainmenu.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/samsara.dart';

import 'engine.dart';
import 'binding/dialog_bindings.dart';
import 'scene/world/world.dart';
import 'scene/battle/battle.dart';
import 'scene/card_library/card_library.dart';
import 'binding/character_binding.dart';
import 'data.dart';
import 'ui.dart';
import 'scene/world/location/location.dart';
import 'scene/game_dialog/game_dialog_controller.dart';
import 'state/states.dart';
import 'scene/cultivation/cultivation.dart';
import 'logic/algorithm.dart';
import 'scene/common.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  bool _isLoading = false, _isInitted = false;

  final _focusNode = FocusNode();

  @override
  void dispose() {
    super.dispose();
    _focusNode.dispose();
    // engine.removeEventListener(id);
    engine.bgm.dispose();
  }

  @override
  void initState() {
    super.initState();
    engine.bgm.initialize();
    // TODO: 读取游戏配置

    // 读取存档列表
    context.read<GameSavesState>().loadList();

    engine.registerSceneConstructor(Scenes.mainmenu, ([dynamic args]) async {
      return MainMenuScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.cultivation, ([dynamic data]) async {
      return CultivationScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.library, ([dynamic data]) async {
      return CardLibraryScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.battle, ([dynamic data]) async {
      return BattleScene(
        heroData: data['heroData'],
        enemyData: data['enemyData'],
        heroDeck: data['heroDeck'],
        enemyDeck: data['enemyDeck'],
        isSneakAttack: data['isSneakAttack'],
      );
    });

    engine.registerSceneConstructor(Scenes.location, (
        [dynamic locationData]) async {
      assert(locationData != null);
      return LocationScene(
        context: context,
        locationData: locationData,
      );
    });

    engine.registerSceneConstructor(Scenes.worldmap, ([dynamic args]) async {
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
        context: context,
        worldData: worldData,
        backgroundSpriteId: args['background'],
        // bgm: isEditorMode ? null : 'ghuzheng-fantasie-23506.mp3',
        isEditorMode: isEditorMode,
      );

      final colors = engine.hetu.invoke('getCurrentWorldZoneColors');
      engine.addTileMapZoneColors(scene.map, worldId!, colors);

      return scene;
    });
  }

  Future<void> _initGame() async {
    await engine.init(externalFunctions: dialogFunctions);

    engine.hetu.interpreter.bindExternalFunction('_start', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().start();
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

    engine.hetu.interpreter.bindExternalFunction('showGameOverlay', (
        {positionalArgs, namedArgs}) {
      context
          .read<GameUIOverlayVisibilityState>()
          .setVisible(positionalArgs.first ?? true);
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
      GameData.initGameData();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('showCultivation', (
        {positionalArgs, namedArgs}) {
      context.read<SceneControllerState>().push(Scenes.cultivation);
    }, override: true);

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
    await GameData.init(flutterContext: context);

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
  }

  // FutureBuilder 根据返回值是否为null来判断是否成功，因此这里无论如何需要返回一个值
  Future<bool> _loadScene() async {
    if (_isLoading) return false;
    _isLoading = true;

    if (!_isInitted) {
      // 刚打开游戏，需要初始化引擎，载入数据，debug模式下还要初始化一个游戏存档用于测试
      await _initGame();
      _isInitted = true;

      if (mounted) {
        context
            .read<SceneControllerState>()
            .push(Scenes.mainmenu, arguments: {'reset': true});
      }
    } else {
      // 游戏已经初始化完毕，此时根据当前状态读取或切换场景
      assert(engine.isInitted);
      assert(GameData.isInitted);
      assert(GameUI.isInitted);
    }

    _isLoading = false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    GameConfig.screenSize = MediaQuery.sizeOf(context);
    if (GameUI.size != GameConfig.screenSize.toVector2()) {
      engine.info(
          '画面尺寸修改为：${GameConfig.screenSize.width}x${GameConfig.screenSize.height}');
      GameUI.resizeTo(GameConfig.screenSize.toVector2());
    }

    return FutureBuilder(
      future: _loadScene(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
        }
        if (!snapshot.hasData) {
          return LoadingScreen(
            text: engine.isInitted ? engine.locale('loading') : 'Loading...',
          );
        } else {
          final scene = context.watch<SceneControllerState>().scene;
          return Scaffold(body: scene?.build(context));
        }
      },
    );
  }
}
