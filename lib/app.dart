import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:hetu_script/utils/json.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/samsara.dart';
import 'package:hetu_script/value/function/function.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import 'scene/mainmenu/mainmenu.dart';
import 'engine.dart';
import 'scene/world/world.dart';
import 'scene/battle/battle.dart';
import 'scene/card_library/card_library.dart';
import 'scene/battle/character_binding.dart';
import 'game/data.dart';
import 'game/ui.dart';
import 'scene/world/location.dart';
import 'state/states.dart';
import 'scene/cultivation/cultivation.dart';
import 'game/logic.dart';
import 'scene/common.dart';
import 'widgets/dialog/timeflow.dart';
import 'widgets/ui/menu_builder.dart';
import 'common.dart';
import 'game/constants.dart';

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

    engine.registerSceneConstructor(Scenes.mainmenu, (arguments) async {
      return MainMenuScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.cultivation, (arguments) async {
      return CultivationScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.library, (arguments) async {
      return CardLibraryScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.battle, (arguments) async {
      return BattleScene(
        heroData: arguments['hero'] ?? GameData.hero,
        enemyData: arguments['enemy'],
        isSneakAttack: arguments['isSneakAttack'] ?? false,
        onBattleStart: arguments['onBattleStart'],
        onBattleEnd: arguments['onBattleEnd'],
      );
    });

    engine.registerSceneConstructor(Scenes.location, (arguments) async {
      final location = arguments['location'];
      assert(location != null);
      return LocationScene(
        context: context,
        location: location,
      );
    });

    engine.registerSceneConstructor(Scenes.worldmap, (arguments) async {
      dynamic worldData;
      final method = arguments['method'];
      final isEditorMode = arguments['isEditorMode'] ?? false;
      if (method == 'load' || method == 'preset') {
        worldData = engine.hetu
            .invoke('switchWorld', positionalArgs: [arguments['id']]);
      } else if (method == 'generate') {
        engine.debug('创建程序生成的随机世界。');
        worldData =
            engine.hetu.invoke('createSandboxWorld', namedArgs: arguments);
        GameData.worldIds.add(worldData['id']);
      } else if (method == 'blank') {
        engine.debug('创建空白世界。');
        worldData =
            engine.hetu.invoke('createBlankWorld', namedArgs: arguments);
        GameData.worldIds.add(worldData['id']);
      }

      final scene = WorldMapScene(
        context: context,
        worldData: worldData,
        backgroundSpriteId: arguments['background'],
        // bgm: isEditorMode ? null : 'ghuzheng-fantasie-23506.mp3',
        isEditorMode: isEditorMode,
      );

      scene.loadZoneColors();
      return scene;
    });
  }

  Future<void> _initGame() async {
    int tik = DateTime.now().millisecondsSinceEpoch;
    await engine.init(context);

    engine.hetu.interpreter.bindExternalClass(BattleCharacterClassBinding());
    engine.hetu.interpreter.bindExternalClass(ConstantsBinding());

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
        'getCardCraftOperationCost',
        ({positionalArgs, namedArgs}) => GameLogic.getCardCraftOperationCost(
            positionalArgs[0], positionalArgs[1]),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'getDeckLimitForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.getDeckLimitForRank(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('calculateItemPrice', (
        {positionalArgs, namedArgs}) {
      return GameLogic.calculateItemPrice(positionalArgs.first,
          priceFactor: namedArgs['priceFactor'],
          isSell: namedArgs['isSell'] ?? true);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('generateZone', (
        {positionalArgs, namedArgs}) {
      return GameLogic.generateZone(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::execute', (
        {positionalArgs, namedArgs}) {
      engine.setCursor(Cursors.normal);
      // context.read<CursorState>().set('normal');
      return dialog.execute();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushImage', (
        {positionalArgs, namedArgs}) {
      dialog.pushImage(
        positionalArgs[0],
        offsetX: namedArgs['offsetX'],
        offsetY: namedArgs['offsetY'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::popImage', (
        {positionalArgs, namedArgs}) {
      dialog.popImage(
        imageId: namedArgs['image'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::popAllImages', (
        {positionalArgs, namedArgs}) {
      dialog.popAllImages();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushBackground', (
        {positionalArgs, namedArgs}) {
      dialog.pushBackground(positionalArgs.first,
          isFadeIn: namedArgs['isFadeIn'] ?? false);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::popBackground', (
        {positionalArgs, namedArgs}) {
      dialog.popBackground(
          imageId: namedArgs['image'],
          isFadeOut: namedArgs['isFadeOut'] ?? false);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::popAllBackgrounds', (
        {positionalArgs, namedArgs}) {
      dialog.popAllBackgrounds();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushTask', (
        {positionalArgs, namedArgs}) {
      final func = positionalArgs[0] as HTFunction;
      dialog.pushTask(
        () => func.call(),
        flagId: namedArgs['flagId'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushDialogRaw', (
        {positionalArgs, namedArgs}) {
      dialog.pushDialogRaw(
        positionalArgs.first,
        imageId: namedArgs['imageId'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushDialog', (
        {positionalArgs, namedArgs}) {
      dialog.pushDialog(
        positionalArgs.first,
        character: namedArgs['character'],
        characterId: namedArgs['characterId'],
        isHero: namedArgs['isHero'] ?? false,
        nameId: namedArgs['nameId'],
        name: namedArgs['name'],
        hideName: namedArgs['hideName'] ?? false,
        icon: namedArgs['icon'],
        hideIcon: namedArgs['hideIcon'] ?? false,
        illustration: namedArgs['illustration'],
        hideIllustration: namedArgs['hideIllustration'] ?? false,
        interpolations: namedArgs['interpolations'],
      );
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushSelectionRaw', (
        {positionalArgs, namedArgs}) {
      dialog.pushSelectionRaw(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Dialog::pushSelection', (
        {positionalArgs, namedArgs}) {
      dialog.pushSelection(positionalArgs[0], positionalArgs[1]);
    });

    engine.hetu.interpreter.bindExternalFunction('Dialog::checkSelected', (
        {positionalArgs, namedArgs}) {
      return dialog.checkSelected(positionalArgs[0]);
    });

    engine.hetu.interpreter.bindExternalFunction('Debug::reloadGameData', (
        {positionalArgs, namedArgs}) {
      GameData.initGameData();
      dialog.pushDialog(engine.locale('reloadGameDataPrompt'));
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::datetime', (
        {positionalArgs, namedArgs}) {
      return {
        'timestamp': GameData.game['timestamp'],
        'tickOfYear': GameLogic.ticksOfYear,
        'tickOfMonth': GameLogic.ticksOfMonth,
        'tickOfDay': GameLogic.ticksOfDay,
        'year': GameLogic.year,
        'month': GameLogic.month,
        'day': GameLogic.day,
        'timeOfDay': GameLogic.timeOfDay,
      };
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateHero', (
        {positionalArgs, namedArgs}) {
      context.read<HeroState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateLocation', (
        {positionalArgs, namedArgs}) {
      context.read<HeroPositionState>().updateLocation(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'Game::pushScene',
        ({positionalArgs, namedArgs}) =>
            context.read<SamsaraEngine>().pushScene(
                  positionalArgs.first,
                  constructorId: namedArgs['category'],
                  arguments: namedArgs['arguments'] ?? const {},
                ),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'Game::switchScene',
        ({positionalArgs, namedArgs}) =>
            context.read<SamsaraEngine>().switchScene(
                  positionalArgs.first,
                  arguments: namedArgs['arguments'] ?? const {},
                  restart: namedArgs['restart'] ?? false,
                ),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'Game::pushWorld',
        ({positionalArgs, namedArgs}) =>
            context.read<SamsaraEngine>().pushScene(
                  positionalArgs.first,
                  constructorId: Scenes.worldmap,
                  arguments: {'id': positionalArgs.first, 'method': 'load'},
                  clearCache: namedArgs['clearCache'] ?? false,
                ),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::popScene', (
        {positionalArgs, namedArgs}) {
      context.read<SamsaraEngine>().popScene(
            clearCache: namedArgs['clearCache'] ?? false,
          );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateGame', (
        {positionalArgs, namedArgs}) {
      GameLogic.updateGame(
        tick: namedArgs['tick'] ?? 1,
        timeflow: namedArgs['timeflow'] ?? true,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateHistory', (
        {positionalArgs, namedArgs}) {
      context.read<HeroAndGlobalHistoryState>().update();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::hideNpc', (
        {positionalArgs, namedArgs}) {
      context.read<NpcListState>().hide(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::promptNewQuest', (
        {positionalArgs, namedArgs}) {
      engine.setCursor(Cursors.normal);
      // context.read<CursorState>().set('normal');
      context.read<NewQuestState>().update(quest: positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::promptNewItems', (
        {positionalArgs, namedArgs}) {
      final items = positionalArgs.first is List
          ? positionalArgs.first
          : [positionalArgs.first];
      engine.setCursor(Cursors.normal);
      // context.read<CursorState>().set('normal');
      final completer = Completer();
      context.read<NewItemsState>().update(items: items, completer: completer);
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
      GameLogic.showItemSelect(
        character: namedArgs['character'],
        title: namedArgs['title'],
        filter: namedArgs['filter'],
        multiSelect: namedArgs['multiSelect'] ?? false,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showLibrary', (
        {positionalArgs, namedArgs}) {
      engine.pushScene(Scenes.library, arguments: {
        'enableCardCraft': namedArgs['enableCardCraft'] ?? false,
        'enableScrollCraft': namedArgs['enableScrollCraft'] ?? false,
      });
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showCultivation', (
        {positionalArgs, namedArgs}) {
      engine.pushScene(Scenes.cultivation, arguments: {
        'location': namedArgs['location'],
        'enableCultivate': namedArgs['enableCultivate'] ?? false,
      });
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showPrebattle', (
        {positionalArgs, namedArgs}) {
      context.read<EnemyState>().show(
            positionalArgs.first,
            onBattleStart: namedArgs['onBattleStart'],
            onBattleEnd: namedArgs['onBattleEnd'],
          );
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
      context.read<MerchantState>().show(
            positionalArgs.first,
            materialMode: namedArgs['materialMode'] ?? false,
            useShard: namedArgs['useShard'] ?? false,
            priceFactor: namedArgs['priceFactor'] ?? {},
            filter: namedArgs['filter'],
          );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'Game::characterAllocateSkills', ({positionalArgs, namedArgs}) {
      GameLogic.characterAllocateSkills(positionalArgs.first);
    }, override: true);

    engine.info('游戏引擎初始化耗时：${DateTime.now().millisecondsSinceEpoch - tik}ms');

    tik = DateTime.now().millisecondsSinceEpoch;
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
            await engine.loadModFromAssetsString(
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
        module: 'main',
        namedArgs: mainConfig,
        isMainMod: true,
      );

      for (final key in engine.mods.keys) {
        if (engine.mods[key]?['enabled'] == true) {
          if (engine.mods[key]?['preinclude'] == true) {
            final mod = await rootBundle.load('assets/mods/$key.mod');
            final modBytes = mod.buffer.asUint8List();
            await engine.loadModFromBytes(
              modBytes,
              module: key,
            );
          }
        }
      }
    }
    engine.info('脚本引擎初始化耗时：${DateTime.now().millisecondsSinceEpoch - tik}ms');

    // 载入动画，卡牌等纯JSON格式的游戏数据
    tik = DateTime.now().millisecondsSinceEpoch;
    await GameData.init();
    engine.info('游戏数据初始化耗时：${DateTime.now().millisecondsSinceEpoch - tik}ms');

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

      // engine.setCursor(Cursors.normal);
      // context.read<CursorState>().set('normal');

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
          return fluent.FlyoutTarget(
            controller: globalFlyoutController,
            child: scene?.build(context) ?? const SizedBox.shrink(),
          );
        }
      },
    );
  }
}
