import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/samsara.dart';
import 'package:hetu_script/value/function/function.dart';

import 'scene/mainmenu/mainmenu.dart';
import 'engine.dart';
import 'scene/world/world.dart';
import 'scene/battle/battle.dart';
import 'scene/card_library/card_library.dart';
import 'binding/character_binding.dart';
import 'data.dart';
import 'ui.dart';
import 'scene/world/location/location.dart';
import 'state/states.dart';
import 'scene/cultivation/cultivation.dart';
import 'logic/algorithm.dart';
import 'scene/common.dart';

import 'scene/game_dialog/game_dialog_content.dart';
import 'widgets/dialog/character_visit_dialog.dart';
import 'widgets/dialog/character_select_dialog.dart';
import 'widgets/merchant/merchant.dart';
import 'widgets/quest/quests.dart';
import 'widgets/dialog/progress_indicator_dialog.dart';
import 'widgets/dialog/input_integer.dart';

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

    engine.registerSceneConstructor(Scenes.mainmenu, (
        [Map<String, dynamic> arguments = const {}]) async {
      return MainMenuScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.cultivation, (
        [Map<String, dynamic> arguments = const {}]) async {
      return CultivationScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.library, (
        [Map<String, dynamic> arguments = const {}]) async {
      return CardLibraryScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.battle, (
        [Map<String, dynamic> arguments = const {}]) async {
      return BattleScene(
        heroData: arguments['hero'],
        enemyData: arguments['enemy'],
        // heroDeck: arguments['heroDeck'],
        // enemyDeck: arguments['enemyDeck'],
        isSneakAttack: arguments['isSneakAttack'] ?? false,
        isAutoBattle: arguments['isAutoBattle'] ?? false,
        onBattleStart: arguments['onBattleStart'],
        onBattleEnd: arguments['onBattleEnd'],
      );
    });

    engine.registerSceneConstructor(Scenes.location, (
        [Map<String, dynamic> arguments = const {}]) async {
      final locationData = arguments['location'];
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
        engine.debug('创建程序生成的随机世界。');
        worldData = engine.hetu.invoke('createSandboxWorld', namedArgs: args);
      } else if (method == 'blank') {
        engine.debug('创建空白世界。');
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
    await engine.init();

    engine.hetu.interpreter.bindExternalClass(BattleCharacterClassBinding());

    engine.hetu.interpreter.bindExternalFunction('expForLevel',
        ({positionalArgs, namedArgs}) => expForLevel(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::_pushDialog', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().pushDialog(positionalArgs[0]);
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::execute', (
        {positionalArgs, namedArgs}) {
      return context.read<GameDialogState>().execute();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushImage', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().pushImage(
            positionalArgs[0],
            offsetX: namedArgs['offsetX'],
            offsetY: namedArgs['offsetY'],
          );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::popImage', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popImage(
            imageId: namedArgs['image'],
          );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushBackground', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().pushBackground(positionalArgs.first,
          isFadeIn: namedArgs['isFadeIn'] ?? false);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::popBackground', (
        {positionalArgs, namedArgs}) {
      context
          .read<GameDialogState>()
          .popBackground(isFadeOut: namedArgs['isFadeOut'] ?? false);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushTask', (
        {positionalArgs, namedArgs}) {
      final func = positionalArgs[0] as HTFunction;
      context.read<GameDialogState>().pushTask(
            () => func.call(),
            flagId: namedArgs['flagId'],
          );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushSelection', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().pushSelection(positionalArgs[0]);
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::checkSelected', (
        {positionalArgs, namedArgs}) {
      return context.read<GameDialogState>().checkSelected(positionalArgs[0]);
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::_selectCharacter', (
        {positionalArgs, namedArgs}) {
      return CharacterSelectDialog.show(
        context: positionalArgs[0],
        title: positionalArgs[1],
        characterIds: positionalArgs[2],
        showCloseButton: positionalArgs[3],
      );
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::_selectResidence', (
        {positionalArgs, namedArgs}) {
      return CharacterVisitDialog.show(
        context: positionalArgs[0],
        characterIds: positionalArgs[1],
        hideHero: namedArgs['hideHero'],
      );
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::_merchant', (
        {positionalArgs, namedArgs}) {
      return MerchantView.show(
        context: positionalArgs[0],
        merchantData: positionalArgs[1],
        priceFactor: positionalArgs[2],
        allowSell: positionalArgs[3],
        sellableCategory: positionalArgs[4],
        sellableKind: positionalArgs[5],
      );
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::_quests', (
        {positionalArgs, namedArgs}) {
      return QuestsView.show(
        context: positionalArgs[0],
        siteData: positionalArgs[1],
      );
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::_progress', (
        {positionalArgs, namedArgs}) {
      bool? Function()? func;
      if (positionalArgs[2] is HTFunction) {
        func = () => (positionalArgs[2] as HTFunction).call();
      }
      return ProgressIndicatorDialog.show(
        context: positionalArgs[0],
        title: positionalArgs[1],
        checkProgress: func,
      );
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::_inputInteger', (
        {positionalArgs, namedArgs}) {
      return InputIntegerDialog.show(
        context: positionalArgs[0],
        title: positionalArgs[1],
        min: positionalArgs[2],
        max: positionalArgs[3],
      );
    });

    engine.hetu.interpreter.bindExternalFunction('Player::updateHero', (
        {positionalArgs, namedArgs}) {
      context.read<HeroState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Player::updateHistory', (
        {positionalArgs, namedArgs}) {
      context.read<HistoryState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Player::updateQuest', (
        {positionalArgs, namedArgs}) {
      context.read<QuestState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Debug::reloadGameData', (
        {positionalArgs, namedArgs}) {
      GameData.initGameData();
      GameDialogContent.show(context, engine.locale('reloadGameDataPrompt'));
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Debug::reloadModules', (
        {positionalArgs, namedArgs}) {
      GameData.initModules();
      GameDialogContent.show(context, engine.locale('reloadModulesPrompt'));
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('System::showHeroInfo', (
        {positionalArgs, namedArgs}) {
      context
          .read<HeroInfoVisibilityState>()
          .setVisible(positionalArgs.first ?? true);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('System::showLibrary', (
        {positionalArgs, namedArgs}) {
      engine.pushScene(Scenes.library);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('System::showCultivation', (
        {positionalArgs, namedArgs}) {
      engine.pushScene(Scenes.cultivation);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('System::showPrebattle', (
        {positionalArgs, namedArgs}) {
      context.read<EnemyState>().update(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('System::showBattle', (
        {positionalArgs, namedArgs}) {
      final heroData = engine.hetu.fetch('hero');
      final arg = {
        'id': Scenes.battle,
        'hero': namedArgs['hero'] ?? heroData,
        'enemy': namedArgs['enemy'],
        'isSneakAttack': namedArgs['isSneakAttack'] ?? false,
        'isAutoBattle': namedArgs['isAutoBattle'] ?? false,
        'onBattleStart': namedArgs['onBattleStart'],
        'onBattleEnd': namedArgs['onBattleEnd'],
      };
      engine.pushScene(Scenes.battle, arguments: arg);
    }, override: true);

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

      engine.pushScene(Scenes.mainmenu, arguments: {'reset': true});
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
      engine.debug(
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
          final scene = context.watch<SamsaraEngine>().scene;
          return Scaffold(body: scene?.build(context));
        }
      },
    );
  }
}
