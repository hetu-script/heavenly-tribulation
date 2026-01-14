import 'dart:async';

import 'package:display_metrics/display_metrics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';
import 'package:hetu_script/value/function/function.dart';
import 'package:samsara/hover_info.dart';

import 'scene/mainmenu/mainmenu_scene.dart';
import 'global.dart';
import 'scene/world/world.dart';
import 'scene/battle/battle.dart';
import 'scene/card_library/card_library.dart';
import 'scene/battle/character_binding.dart';
import 'ui.dart';
import 'scene/location/location.dart';
import 'state/states.dart';
import 'scene/cultivation/cultivation.dart';
import 'logic/logic.dart';
import 'scene/common.dart';
import 'widgets/timeflow.dart';
import 'data/constants.dart';
import 'scene/loading_screen.dart';
import 'scene/mini_game/matching/matching.dart';
import 'data/common.dart';
import 'data/game.dart';
import 'extensions.dart';

class GameApp extends StatefulWidget {
  const GameApp({super.key});

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp> {
  bool _isInitializingDisplayMetricsData = true;

  final _focusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // call DisplayMetrics.ensureInitialized(context) to ensure
    // DisplayMetricsData has been loaded
    DisplayMetrics.ensureInitialized(context)?.then((data) {
      if (_isInitializingDisplayMetricsData) {
        setState(() {
          _isInitializingDisplayMetricsData = false;
        });
      }
    });
  }

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

    _initEngine();
  }

  Future<void> _initEngine() async {
    engine.setLoading(true);
    // 初始化引擎
    final sw = Stopwatch()..start();

    GameUI.init();

    engine.config = EngineConfig(
      name: 'Heavenly Tribulation',
      desktop: true,
      debugMode: true,
      musicVolume: 0.5,
      soundEffectVolume: 0.5,
      mods: {
        'story': {
          'enabled': false,
        },
      },
      showFps: false,
    );

    await engine.init(context);

    engine.hetu.invoke('build', positionalArgs: [context]);

    engine.bgm.initialize();

    // TODO: 读取游戏配置

    // 读取存档列表
    context.read<GameSavesState>().loadList();

    engine.registerSceneConstructor(Scenes.mainmenu, (arguments) async {
      return MainMenuScene(context: context);
    });

    engine.registerSceneConstructor(Scenes.cultivation, (arguments) async {
      return CultivationScene(
        context: context,
        isEditorMode: arguments['isEditorMode'] ?? false,
      );
    });

    engine.registerSceneConstructor(Scenes.library, (arguments) async {
      return CardLibraryScene(
        context: context,
        isEditorMode: arguments['isEditorMode'] ?? false,
      );
    });

    engine.registerSceneConstructor(Scenes.battle, (arguments) async {
      return BattleScene(
        heroData: arguments['hero'] ?? GameData.hero,
        enemyData: arguments['enemy'],
        isSneakAttack: arguments['isSneakAttack'] ?? false,
        onBattleStart: arguments['onBattleStart'],
        onBattleEnd: arguments['onBattleEnd'],
        endBattleAfterRounds: arguments['endBattleAfterTurns'] ?? 0,
        backgroundImageId:
            arguments['background'] ?? 'battle/scene/plain_day.png',
      );
    });

    engine.registerSceneConstructor(Scenes.location, (arguments) async {
      final locationId = arguments['locationId'];
      assert(locationId != null, 'LocationScene 需要传入 locationId 参数');
      final location = GameData.getLocation(locationId);
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
            .invoke('setCurrentWorld', positionalArgs: [arguments['id']]);
        final worldInfo = GameData.getLlmChatSystemPrompt1();
        engine.prepareLlamaBaseState(worldInfo);
      } else if (method == 'generate') {
        engine.info('创建程序生成的随机世界。');
        worldData =
            engine.hetu.invoke('createSandboxWorld', namedArgs: arguments);
      } else if (method == 'blank') {
        engine.info('创建空白世界。');
        worldData =
            engine.hetu.invoke('createBlankWorld', namedArgs: arguments);
      }

      final scene = WorldMapScene(
        context: context,
        worldData: worldData,
        backgroundSpriteId: arguments['background'],
        // bgm: isEditorMode ? null : 'ghuzheng-fantasie-23506.mp3',
        isEditorMode: isEditorMode,
      );
      GameData.worldScenes[worldData['id']] = scene;
      return scene;
    });

    engine.registerSceneConstructor(Scenes.matchingGame, (arguments) async {
      final String kind = arguments['kind'];
      bool isProduction = arguments['isProduction'] ?? false;
      // int salary = 0;
      int staminaCost = 0;
      final resources = {};

      dynamic locationId = arguments['locationId'];
      dynamic location = arguments['location'];
      location ??= GameData.game['locations'][locationId];
      if (location != null) {
        staminaCost = kSiteWorkableStaminaCost[kind]!;
        final double workStaminaCostFactor =
            GameData.hero['stats']['staminaCostWork'];
        staminaCost = (staminaCost * workStaminaCostFactor).round();

        // 该地块所拥有的资源类型及其丰富度
        final terrain = GameData.getTerrainById(location['terrainIndex']);
        final res = terrain['resources'];
        final double workEfficiency = GameData.hero['stats']['workEfficiency'];
        for (final materialId in res.keys) {
          resources[materialId] = (res[materialId]! * workEfficiency).round();
        }
        // else {
        // salary = kSiteWorkableBaseSalaries[kind]!;
        // }
      }

      return MatchingGame(
        id: Scenes.matchingGame,
        context: context,
        kind: kind,
        development: arguments['development'] ?? 0,
        isProduction: isProduction,
        staminaCost: staminaCost,
        resources: resources,
      );
    });

    engine.hetu.interpreter.bindExternalFunctionType(
      'onBattleEnd',
      (HTFunction function) {
        return (bool arg1, int arg2) {
          return function.call(positionalArgs: [arg1, arg2]);
        };
      },
    );

    engine.hetu.interpreter.bindExternalClass(BattleCharacterClassBinding());
    engine.hetu.interpreter.bindExternalClass(Constants());

    engine.hetu.interpreter.bindExternalFunction(
        'getLifeSpanForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.getLifeSpanForRank(positionalArgs.first),
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
        'fameForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.fameForRank(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'expForLevel',
        ({positionalArgs, namedArgs}) =>
            GameLogic.expForLevel(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'contributionForJobRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.contributionForJobRank(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'calculateMaxSiteCountForCity',
        ({positionalArgs, namedArgs}) =>
            GameLogic.calculateMaxSiteCountForCity(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'maxCityCountForSectDevelopment',
        ({positionalArgs, namedArgs}) =>
            GameLogic.maxCityCountForSectDevelopment(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'getMinMaxExtraAffixCount',
        ({positionalArgs, namedArgs}) =>
            GameLogic.getMinMaxExtraAffixCount(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'getTribulationCountForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.getTribulationCountForRank(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'getCardCraftMaterial',
        ({positionalArgs, namedArgs}) => GameLogic.getCardCraftMaterial(
            positionalArgs[0], positionalArgs[1]),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'getDeckLimitForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.getDeckLimitForRank(positionalArgs.first),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('estimateItemPrice', (
        {positionalArgs, namedArgs}) {
      return GameLogic.estimateItemPrice(positionalArgs[0], positionalArgs[1],
          range: namedArgs['range']);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('generateCityTerritory', (
        {positionalArgs, namedArgs}) {
      return GameLogic.generateCityTerritory(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('generateZone', (
        {positionalArgs, namedArgs}) {
      return GameLogic.generateZone(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::execute', (
        {positionalArgs, namedArgs}) {
      return dialog.execute();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::pushImage', (
        {positionalArgs, namedArgs}) {
      dialog.pushImage(
        positionalArgs[0],
        offsetX: namedArgs['offsetX'],
        offsetY: namedArgs['offsetY'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::popImage', (
        {positionalArgs, namedArgs}) {
      dialog.popImage(
        imageId: namedArgs['image'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::popAllImages', (
        {positionalArgs, namedArgs}) {
      dialog.popAllImages();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::pushBackground', (
        {positionalArgs, namedArgs}) {
      dialog.pushBackground(positionalArgs.first,
          isFadeIn: namedArgs['isFadeIn'] ?? false);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::popBackground', (
        {positionalArgs, namedArgs}) {
      dialog.popBackground(
          imageId: namedArgs['image'],
          isFadeOut: namedArgs['isFadeOut'] ?? false);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::popAllBackgrounds', (
        {positionalArgs, namedArgs}) {
      dialog.popAllBackgrounds();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::pushTask', (
        {positionalArgs, namedArgs}) {
      final func = positionalArgs[0] as HTFunction;
      dialog.pushTask(
        () async => await func.call(),
        flagId: namedArgs['flagId'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::pushDialogRaw', (
        {positionalArgs, namedArgs}) {
      dialog.pushDialogRaw(
        positionalArgs.first,
        imageId: namedArgs['imageId'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::pushDialog', (
        {positionalArgs, namedArgs}) {
      dialog.pushDialog(
        positionalArgs.first,
        character: namedArgs['character'],
        characterId: namedArgs['characterId'],
        npc: namedArgs['npc'],
        npcId: namedArgs['npcId'],
        isHero: namedArgs['isHero'] ?? false,
        nameId: namedArgs['nameId'],
        name: namedArgs['name'],
        hideName: namedArgs['hideName'] ?? false,
        icon: namedArgs['icon'],
        hideIcon: namedArgs['hideIcon'] ?? false,
        image: namedArgs['illustration'],
        hideImage: namedArgs['hideIllustration'] ?? false,
        interpolations: namedArgs['interpolations'],
      );
    });

    engine.hetu.interpreter.bindExternalFunction('dialog::pushSelectionRaw', (
        {positionalArgs, namedArgs}) {
      dialog.pushSelectionRaw(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('dialog::pushSelection', (
        {positionalArgs, namedArgs}) {
      dialog.pushSelection(positionalArgs[0], positionalArgs[1]);
    });

    engine.hetu.interpreter.bindExternalFunction('dialog::checkSelected', (
        {positionalArgs, namedArgs}) {
      return dialog.checkSelected(positionalArgs[0]);
    });

    engine.hetu.interpreter.bindExternalFunction('debug::reloadGameData', (
        {positionalArgs, namedArgs}) {
      GameData.initGameData();
      dialog.pushDialog(engine.locale('reloadGameDataPrompt'));
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::datetime', (
        {positionalArgs, namedArgs}) {
      GameLogic.calculateTimestamp();
      return {
        'timestamp': GameData.game['timestamp'],
        'tickOfYear': GameLogic.ticksOfYear,
        'tickOfMonth': GameLogic.ticksOfMonth,
        'tickOfDay': GameLogic.ticksOfDay,
        'year': GameLogic.year,
        'month': GameLogic.month,
        'day': GameLogic.day,
        'timeOfDay': GameLogic.timeString,
      };
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateUI', (
        {positionalArgs, namedArgs}) {
      gameState.updateUI();
      gameState.updateDatetime();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateHeroAtLocation', (
        {positionalArgs, namedArgs}) {
      gameState.updateLocation(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateActiveJournals', (
        {positionalArgs, namedArgs}) {
      gameState.updateActiveJournals();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'Game::switchWorld',
        ({positionalArgs, namedArgs}) => GameData.switchWorld(
            positionalArgs.first,
            clearCache: namedArgs['clearCache'] ?? false),
        override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'Game::popScene',
        ({positionalArgs, namedArgs}) =>
            engine.popScene(clearCache: namedArgs['clearCache'] ?? false),
        override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateGame', (
        {positionalArgs, namedArgs}) {
      GameLogic.updateGame(
        ticks: namedArgs['tick'] ?? kTicksPerTime,
        force: namedArgs['force'] ?? false,
        updateUI: namedArgs['updateUI'] ?? true,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateHistory', (
        {positionalArgs, namedArgs}) {
      gameState.updateHistory();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateDungeon', (
        {positionalArgs, namedArgs}) {
      gameState.updateDungeon(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::tryEnterDungeon', (
        {positionalArgs, namedArgs}) {
      GameLogic.tryEnterDungeon(
        rank: namedArgs['rank'],
        isBasic: namedArgs['isCommon'] ?? true,
        dungeonId: namedArgs['dungeonId'] ?? 'dungeon_1',
        pushScene: namedArgs['pushScene'] ?? true,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::onDying', (
        {positionalArgs, namedArgs}) {
      return GameLogic.onDying();
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction(
        'Game::characterAllocateSkills', ({positionalArgs, namedArgs}) {
      GameLogic.characterAllocateSkills(
        positionalArgs.first,
        rejuvenate: namedArgs['rejuvenate'] ?? false,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::updateNpcsAtLocation', (
        {positionalArgs, namedArgs}) {
      final npcs = GameData.getNpcsAtLocation(positionalArgs.first);
      gameState.updateNpcs(npcs);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::hideNpc', (
        {positionalArgs, namedArgs}) {
      gameState.hideNpc(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::promptItems', (
        {positionalArgs, namedArgs}) {
      return GameLogic.promptItems(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::promptJournal', (
        {positionalArgs, namedArgs}) {
      return GameLogic.promptJournal(
        positionalArgs[0],
        selectionsRaw: namedArgs['selectionsRaw'],
        selections: namedArgs['selections'],
        interpolations: namedArgs['interpolations'],
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::promptNewRank', (
        {positionalArgs, namedArgs}) {
      return GameLogic.promptNewRank(positionalArgs.first);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::selectCharacter', (
        {positionalArgs, namedArgs}) {
      return GameLogic.selectCharacter(
          ids: namedArgs['ids'], datas: namedArgs['datas']);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::selectLocation', (
        {positionalArgs, namedArgs}) {
      return GameLogic.selectLocation(
          ids: namedArgs['ids'], datas: namedArgs['datas']);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::selectSite', (
        {positionalArgs, namedArgs}) {
      return GameLogic.selectSite(
          ids: namedArgs['ids'], datas: namedArgs['datas']);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::selectSect', (
        {positionalArgs, namedArgs}) {
      return GameLogic.selectSect(
          ids: namedArgs['ids'], datas: namedArgs['datas']);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::setUIVisible', (
        {positionalArgs, namedArgs}) {
      gameState.setUIVisible(positionalArgs.first ?? true);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::setInteractable', (
        {positionalArgs, namedArgs}) {
      gameState.isInteractable = positionalArgs.first ?? true;
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showTimeflow', (
        {positionalArgs, namedArgs}) {
      TimeflowDialog.show(context: context, ticks: positionalArgs[0]);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::selectItem', (
        {positionalArgs, namedArgs}) {
      return GameLogic.selectItem(
        character: namedArgs['character'],
        title: namedArgs['title'],
        filter: namedArgs['filter'],
        multiSelect: namedArgs['multiSelect'] ?? false,
      );
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showLibrary', (
        {positionalArgs, namedArgs}) {
      engine.context.read<ViewPanelState>().clearAll();
      engine.pushScene(Scenes.library, arguments: {
        'enableCardCraft': namedArgs['enableCardCraft'] ?? false,
        'enableScrollCraft': namedArgs['enableScrollCraft'] ?? false,
      });
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showCultivation', (
        {positionalArgs, namedArgs}) {
      engine.context.read<ViewPanelState>().clearAll();
      engine.pushScene(Scenes.cultivation, arguments: {
        'location': namedArgs['location'],
        'enableCultivate': namedArgs['enableCultivate'] ?? false,
      });
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showPrebattle', (
        {positionalArgs, namedArgs}) {
      engine.context.read<HoverContentState>().hide();
      engine.context.read<ViewPanelState>().clearAll();
      context.read<EnemyState>().show(
            positionalArgs.first,
            onBattleStart: namedArgs['onBattleStart'],
            onBattleEnd: namedArgs['onBattleEnd'],
            background: namedArgs['background'],
            loseOnEscape: namedArgs['loseOnEscape'] ?? false,
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
        'background': namedArgs['background'],
      };
      engine.pushScene(Scenes.battle, arguments: arg);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showMerchant', (
        {positionalArgs, namedArgs}) {
      if (namedArgs['depositMode'] == true) {
        context.read<MerchantState>().show(
              positionalArgs.first,
              materialMode: namedArgs['materialMode'] ?? false,
              merchantType: MerchantType.depositBox,
            );
      } else {
        context.read<MerchantState>().show(
              positionalArgs.first,
              materialMode: namedArgs['materialMode'] ?? false,
              useShard: namedArgs['useShard'] ?? false,
              priceFactor: namedArgs['priceFactor'] ?? {},
              filter: namedArgs['filter'],
            );
      }
    }, override: true);
    engine.hetu.interpreter.bindExternalFunction('Game::showWorkbench', (
        {positionalArgs, namedArgs}) {
      engine.context.read<ViewPanelState>().toogle(ViewPanels.workbench);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showAlchemy', (
        {positionalArgs, namedArgs}) {
      engine.context.read<ViewPanelState>().toogle(ViewPanels.alchemy);
    }, override: true);

    engine.hetu.interpreter.bindExternalFunction('Game::showMeeting', (
        {positionalArgs, namedArgs}) {
      GameLogic.showMeeting(
          positionalArgs[0], positionalArgs[1], positionalArgs[2]);
    }, override: true);

    engine.info('游戏引擎初始化耗时：${sw.elapsedMilliseconds}ms');

    sw.reset();
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
          await engine.loadModFromAssetsString(
            '$key/main.ht',
            module: key,
          );
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
          final mod = await rootBundle.load('assets/mods/$key.mod');
          final modBytes = mod.buffer.asUint8List();
          await engine.loadModFromBytes(
            modBytes,
            module: key,
          );
        }
      }
    }
    engine.info('模组数据初始化耗时：${sw.elapsedMilliseconds}ms');

    // 载入动画，卡牌等纯JSON格式的游戏数据
    sw.reset();

    await GameData.init();

    engine.info('游戏数据初始化耗时：${sw.elapsedMilliseconds}ms');

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

    engine.pushScene(
      Scenes.mainmenu,
      arguments: {'reset': true},
      onAfterLoaded: () {
        engine.setLoading(false);
      },
    );

    sw.stop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializingDisplayMetricsData) {
      return const LoadingScreen();
    }

    final screenSize = MediaQuery.sizeOf(context);
    GameUI.setSize(screenSize.toVector2());

    final scene = context.watch<SamsaraEngine>().scene;
    final isLoading = context.watch<SamsaraEngine>().isLoading;
    return Scaffold(
      body: Stack(
        children: [
          scene?.build(
                context,
                loadingBuilder: (context) => const LoadingScreen(),
              ) ??
              const LoadingScreen(),
          if (isLoading) const LoadingScreen(),
        ],
      ),
    );
  }
}
