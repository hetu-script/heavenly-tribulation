import 'dart:async';

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
import 'game/data.dart';
import 'game/ui.dart';
import 'scene/world/location.dart';
import 'state/states.dart';
import 'scene/cultivation/cultivation.dart';
import 'game/logic.dart';
import 'scene/common.dart';
import 'scene/game_dialog/game_dialog_content.dart';
import 'widgets/dialog/timeflow.dart';
// import 'widgets/dialog/new_quests.dart';

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

    engine.registerSceneConstructor(Scenes.cardlibrary, (
        [Map<String, dynamic> arguments = const {}]) async {
      return CardLibraryScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.battle, (
        [Map<String, dynamic> arguments = const {}]) async {
      return BattleScene(
        heroData: arguments['hero'] ?? GameData.heroData,
        enemyData: arguments['enemy'],
        isSneakAttack: arguments['isSneakAttack'] ?? false,
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
      worldId ??= engine.hetu.fetch('currentWorldId', namespace: 'game');

      engine.hetu.invoke('calculateTimestamp');

      final scene = WorldMapScene(
        context: context,
        worldData: worldData,
        backgroundSpriteId: args['background'],
        // bgm: isEditorMode ? null : 'ghuzheng-fantasie-23506.mp3',
        isEditorMode: isEditorMode,
      );

      final colors = engine.hetu.invoke('getCurrentWorldZoneColors');
      engine.debug('刷新地图 ${scene.map.id} 上色信息');
      engine.loadTileMapZoneColors(scene.map, colors);

      return scene;
    });
  }

  Future<void> _initGame() async {
    await engine.init(context);

    engine.hetu.interpreter.bindExternalClass(BattleCharacterClassBinding());

    engine.hetu.interpreter.bindExternalFunction(
        'expForLevel',
        ({positionalArgs, namedArgs}) =>
            GameLogic.expForLevel(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'minLevelForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.minLevelForRank(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'maxLevelForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.maxLevelForRank(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'getDeckLimitForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.getDeckLimitForRank(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::_pushDialog', (
        {positionalArgs, namedArgs}) {
      final content = positionalArgs[0];
      context
          .read<GameDialogState>()
          .pushDialog(content, imageId: content['image']);
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

    engine.hetu.interpreter.bindExternalFunction('Dialog::popAllBackgrounds', (
        {positionalArgs, namedArgs}) {
      context.read<GameDialogState>().popAllBackgrounds();
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

    engine.hetu.interpreter.bindExternalFunction('Debug::reloadGameData', (
        {positionalArgs, namedArgs}) {
      GameData.initGameData();
      GameDialogContent.show(context, engine.locale('reloadGameDataPrompt'));
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::_update', (
        {positionalArgs, namedArgs}) {
      context.read<HeroState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateGameTime', (
        {positionalArgs, namedArgs}) {
      context.read<GameTimestampState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateHistory', (
        {positionalArgs, namedArgs}) {
      context.read<HeroAndGlobalHistoryState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateNpcList', (
        {positionalArgs, namedArgs}) {
      context.read<NpcListState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::promptNewQuest', (
        {positionalArgs, namedArgs}) {
      context.read<NewQuestState>().update(quest: positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::promptNewItems', (
        {positionalArgs, namedArgs}) {
      final completer = Completer();
      context
          .read<NewItemsState>()
          .update(items: positionalArgs.first, completer: completer);
      return completer.future;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showHeroInfo', (
        {positionalArgs, namedArgs}) {
      context
          .read<HeroInfoVisibilityState>()
          .setVisible(positionalArgs.first ?? true);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showTimeflow', (
        {positionalArgs, namedArgs}) {
      TimeflowDialog.show(context: context, max: positionalArgs[0]);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showItemSelect', (
        {positionalArgs, namedArgs}) {
      final completer = Completer();
      context.read<ViewPanelState>().toogle(
        ViewPanels.itemSelect,
        arguments: {
          'characterData': namedArgs['character'],
          'title': namedArgs['title'],
          'filter': namedArgs['filter'],
          'multiSelect': namedArgs['multiSelect'] ?? false,
          'onSelect': (items) {
            completer.complete(items);
          },
        },
      );
      return completer.future;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showLibrary', (
        {positionalArgs, namedArgs}) {
      engine.pushScene(Scenes.cardlibrary);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showCultivation', (
        {positionalArgs, namedArgs}) {
      engine.pushScene(Scenes.cultivation);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showPrebattle', (
        {positionalArgs, namedArgs}) {
      context.read<EnemyState>().show(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showBattle', (
        {positionalArgs, namedArgs}) {
      final arg = {
        'id': Scenes.battle,
        'hero': namedArgs['hero'],
        'enemy': namedArgs['enemy'],
        'isSneakAttack': namedArgs['isSneakAttack'] ?? false,
        'isAutoBattle': namedArgs['isAutoBattle'] ?? false,
        'onBattleStart': namedArgs['onBattleStart'],
        'onBattleEnd': namedArgs['onBattleEnd'],
      };
      engine.pushScene(Scenes.battle, arguments: arg);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showMerchant', (
        {positionalArgs, namedArgs}) {
      context
          .read<MerchantState>()
          .show(positionalArgs.first, priceFactor: namedArgs['priceFactor']);
    }, override: true);

    final mainConfig = {'locale': engine.languageId};
    if (kDebugMode) {
      await engine.loadModFromAssetsString(
        'main/main.ht',
        module: 'main',
        namedArgs: mainConfig,
        isMainMod: true,
      );

      for (final key in engine.mods.keys) {
        if (engine.mods[key]?['enabled'] == true) {
          if (engine.mods[key]?['preinclude'] == true) {
            final byteMod = await engine.loadModFromAssetsString(
              '$key/main.ht',
              module: key,
            );
            engine.hetu.assign(key, byteMod.namespaces.values.last,
                namespace: 'mods', defineIfAbsent: true);
          }
        }
      }
    } else {
      final main = await rootBundle.load('assets/mods/main.mod');
      final gameBytes = main.buffer.asUint8List();
      await engine.loadModFromBytes(
        gameBytes,
        module: 'main',
        namedArgs: mainConfig,
        isMainMod: true,
      );

      for (final key in engine.mods.keys) {
        if (engine.mods[key]?['enabled'] == true) {
          if (engine.mods[key]?['preinclude'] == true) {
            final mod = await rootBundle.load('assets/mods/$key.mod');
            final modBytes = mod.buffer.asUint8List();
            final byteMod = await engine.loadModFromBytes(
              modBytes,
              module: key,
            );
            engine.hetu.assign(key, byteMod.namespaces.values.last,
                namespace: 'mods', defineIfAbsent: true);
          }
        }
      }
    }

    // 载入动画，卡牌等纯JSON格式的游戏数据
    // ignore: use_build_context_synchronously
    await GameData.init();

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
    final screenSize = MediaQuery.sizeOf(context);
    if (GameUI.size != screenSize.toVector2()) {
      engine.debug('画面尺寸修改为：${screenSize.width}x${screenSize.height}');
      GameUI.resizeTo(screenSize.toVector2());
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
