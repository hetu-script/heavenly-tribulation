import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hetu_script/utils/collection.dart' as utils;
import 'package:samsara/cardgame/cardgame.dart';
import 'package:json5/json5.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/markdown_wiki.dart';
import 'package:samsara/tilemap/tilemap.dart';
import 'package:provider/provider.dart';

import '../ui.dart';
import 'common.dart';
import '../global.dart';
import '../scene/common.dart';
import '../logic/logic.dart';
import '../state/game_save.dart';
import '../scene/world/world.dart';
import 'prompt.dart';
import '../state/game_state.dart';

const _kSkinAnimationWidth = 288.0;
const _kSkinAnimationHeight = 112.0;
const _kSkinAnimationStepTime1 = 0.1;
const _kSkinAnimationStepTime2 = 0.7;

const _kActionIds = {
  'defeat',
  'dodge',
  'hit',
  'melee_startup',
  'melee_recovery',
  'bow_attack',
  'kick_attack',
  'punch_attack',
  'sabre_attack',
  'spear_attack',
  'sword_attack',
  'staff_attack',
  'spell_attack',
  'spell_attack_recovery',
  'kick_buff',
  'punch_buff',
  'sabre_buff',
  'spear_buff',
  'sword_buff',
  'staff_buff',
  'spell_buff',
};

final class MonthlyActivityIds {
  static const gifted = 'gifted';
  static const attacked = 'attacked';
  static const stolen = 'stolen';
  static const proposed = 'proposed';
  static const baishi = 'baishi';
  static const shoutu = 'shoutu';
  static const consulted = 'consulted';
  static const tutored = 'tutored';
  static const enrolled = 'enrolled';
  static const recruited = 'recruited';
  static const rented = 'rented';
}

final class GameMusic {
  static const menu = 'chinese-oriental-tune-06-12062.mp3';
  static const worldmap = 'ghuzheng-fantasie-23506.mp3';
  static const location = 'vietnam-bamboo-flute-143601.mp3';
  static const battle = 'war-drums-173853.mp3';
}

final class GameSound {
  static const victory = 'transition/chinese-ident-transition-1-283708.mp3';
  static const gameOver = 'transition/chinese-ident-transition-2-283707.mp3';

  static const click = 'click-21156.mp3';
  static const success = 'new-notification-026-380249.mp3';
  static const error = 'notification-error-427345.mp3';

  static const buff = 'buffer-spell-88994.mp3';
  static const debuff = 'bone-break-8-218516.mp3';
  static const block = 'shield-block-shortsword-143940.mp3';
  static const slash = 'hit-flesh-02-266309.mp3';
  static const enhance = 'dagger_drawn2-89025.mp3';
  static const fire = 'lighting-a-fire-14421.mp3';

  static const craft = 'hammer-hitting-an-anvil-25390.mp3';
  static const dealCard = 'playing-cards-being-delt-29099.mp3';
  static const dealDeck = 'card-flipping-75622.mp3';

  static const coins = 'coins-31879.mp3';
  static const anvil = 'hammer-hitting-an-anvil-25390.mp3';
  static const pickup = 'pickup_item-64282.mp3';
  static const drink = 'drink-sip-and-swallow-6974.mp3';
  static const charge = 'electric-sparks-68814.mp3';
  static const paperrip = 'paper-rip-twice-252619.mp3';
  static const writing = 'writing-263642.mp3';
  static const put = 'put_item-83043.mp3';
  static const broken = 'break06-36414.mp3';
  static const flip = 'flipcard-91468.mp3';
}

/// 游戏数据，大部分以JSON或者Hetu Struct形式保存
/// 这个类是纯静态类，方法都是有关读取和保存的
/// 游戏逻辑等操作这些数据的代码另外写在logic目录下的文件中
final class GameData with ChangeNotifier {
  static final Map<String, dynamic> animations = {};
  static final Map<String, SpriteSheet> spriteSheets = {};
  static final Map<String, SpriteAnimationWithTicker> _cachedAnimations = {};

  static final List<dynamic> wikiData = [];
  static late final WikiTreeNode wikiTreeNodes;

  static final Map<String, dynamic> tiles = {};
  static final Map<String, dynamic> mapComponents = {};
  static final Map<String, dynamic> battleCards = {};
  static final Map<String, dynamic> battleCardAffixes = {};
  static final Map<String, dynamic> statusEffects = {};
  static final Map<String, dynamic> items = {};
  static final Map<String, dynamic> passives = {};
  static final Map<String, dynamic> passiveTree = {};
  static final Map<String, dynamic> craftables = {};
  static final Map<String, dynamic> journals = {};
  static final Map<String, dynamic> quests = {};
  static final Map<String, dynamic> maps = {};

  static final Map<String, (String, String)> attributeNames = {};
  static final Map<String, String> sectCategoryNames = {};
  static final Map<String, String> cultivationGenreNames = {};
  static final Map<String, String> cityKindNames = {};
  static final Map<String, String> siteKindNames = {};

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  /// 游戏本身的数据，包含角色，对象，以及地图和时间线。
  static dynamic game, flags, universe, world, history, hero;

  static WorldMapScene? mainWorld, currentWorld;
  static Map<String, WorldMapScene> worldScenes = {};

  static Iterable<String> get worldIds => universe?.keys ?? const [];

  static math.Random random = math.Random();

  static dynamic getTerrainById(int index, {String? worldId}) {
    worldId ??= world['id'];
    final atWorld = universe[worldId];
    final terrain = atWorld['terrains'][index];
    assert(terrain != null, 'Terrain not found, id: $index');
    return terrain;
  }

  static dynamic getTerrain(int left, int top, {String? worldId}) {
    worldId ??= world['id'];
    final atWorld = universe[worldId];
    return getTerrainById(GameLogic.tilePos2Index(left, top, atWorld['width']),
        worldId: worldId);
  }

  static dynamic getNpc(dynamic id) {
    final npc = GameData.game['npcs'][id];
    assert(npc != null, 'NPC not found, id: $id');
    return npc;
  }

  static List getNpcsAtLocation(dynamic location) {
    final npcs = [];

    final locationNpc = location['npcId'];
    if (locationNpc != null) {
      final npc = GameData.game['npcs'][locationNpc];
      npcs.add(npc);
    }

    final companions =
        GameData.hero['companions'].map((id) => GameData.getCharacter(id));
    npcs.addAll(companions);

    final characters = GameData.game['characters'].values.where((char) {
      if (char['id'] == GameData.hero['id']) return false;
      if (char['locationId'] != location['id']) return false;
      return true;
    });
    npcs.addAll(characters);

    return npcs;
  }

  static List getNpcsOnWorldMap({String? worldId}) {
    worldId ??= world['id'];
    final npcs = (GameData.game['characters'].values as Iterable).where(
        (char) =>
            (char['id'] != GameData.hero?['id']) &&
            (char['locationId'] == null) &&
            (char['worldId'] == worldId) &&
            (char['worldPosition'] != null));
    return npcs.toList();
  }

  static Iterable getNpcsAtWorldMapPosition(int left, int top,
      {String? worldId}) {
    worldId ??= world['id'];
    final npcs = (game['characters'].values as Iterable).where(
      (char) =>
          char['id'] != GameData.hero?['id'] &&
          char['locationId'] == null &&
          char['worldId'] == worldId &&
          char['worldPosition'] != null &&
          char['worldPosition']?['left'] ==
              GameData.hero?['worldPosition']['left'] &&
          char['worldPosition']?['top'] ==
              GameData.hero?['worldPosition']['top'],
    );
    return npcs;
  }

  static dynamic getCharacter(dynamic id) {
    final character = GameData.game['characters'][id];
    assert(character != null, 'Character not found, id: $id');
    return character;
  }

  static dynamic getLocation(dynamic id) {
    final location = GameData.game['locations'][id];
    assert(location != null, 'Location not found, id: $id');
    return location;
  }

  static dynamic getSect(dynamic id) {
    final sect = GameData.game['sects'][id];
    assert(sect != null, 'sect not found, id: $id');
    return sect;
  }

  static void addMonthly(
    String activityId,
    String targetId, {
    dynamic data,
  }) {
    data ??= GameData.game;
    final monthly = data['flags']['monthly'][activityId];
    if (monthly is List) {
      if (!monthly.contains(targetId)) {
        monthly.add(targetId);
      } else {
        engine.warning('activity [$activityId] record already exist.');
      }
    } else {
      engine.warning('monthly activity [$activityId] does not exist.');
    }
  }

  static bool checkMonthly(
    String activityId,
    String targetId, {
    dynamic data,
  }) {
    data ??= GameData.game;
    final monthly = data['flags']['monthly'][activityId];
    if (monthly is List) {
      return monthly.contains(targetId);
    } else {
      engine.warning('monthly activity [$activityId] does not exist.');
      return false;
    }
  }

  static Future<void> init() async {
    if (_isInitted) {
      throw 'Game data is already initted!';
    }
    if (!engine.isInitted) {
      throw 'Game engine is not initted yet!';
    }

    final docsDataString = await rootBundle.loadString('docs/wiki.json5');
    wikiData.addAll(JSON5.parse(docsDataString));
    wikiTreeNodes = await buildWikiTreeNodesFromData(
      wikiData,
      root: {
        'id': "/",
        'title': "wiki_root_title",
        'path': "docs/docs/readme.md",
      },
    );

    final tilesDataString =
        await rootBundle.loadString('assets/data/tiles.json5');
    tiles.addAll(JSON5.parse(tilesDataString));

    final mapsDataString =
        await rootBundle.loadString('assets/data/maps.json5');
    maps.addAll(JSON5.parse(mapsDataString));

    final mapComponentsDataString =
        await rootBundle.loadString('assets/data/map_components.json5');
    mapComponents.addAll(JSON5.parse(mapComponentsDataString));

    final battleCardDataString =
        await rootBundle.loadString('assets/data/cards.json5');
    battleCards.addAll(JSON5.parse(battleCardDataString));

    final battleCardAffixDataString =
        await rootBundle.loadString('assets/data/card_affixes.json5');
    battleCardAffixes.addAll(JSON5.parse(battleCardAffixDataString));

    final itemsDataString =
        await rootBundle.loadString('assets/data/items.json5');
    items.addAll(JSON5.parse(itemsDataString));

    final craftablesDataString =
        await rootBundle.loadString('assets/data/craftables.json5');
    craftables.addAll(JSON5.parse(craftablesDataString));

    final passiveTreeDataString =
        await rootBundle.loadString('assets/data/passive_tree.json5');
    passiveTree.addAll(JSON5.parse(passiveTreeDataString));

    final passiveDataString =
        await rootBundle.loadString('assets/data/passives.json5');
    passives.addAll(JSON5.parse(passiveDataString));

    final statusEffectDataString =
        await rootBundle.loadString('assets/data/status_effect.json5');
    statusEffects.addAll(JSON5.parse(statusEffectDataString));

    final journalsDataString =
        await rootBundle.loadString('assets/data/journals.json5');
    journals.addAll(JSON5.parse(journalsDataString));

    final questsDataString =
        await rootBundle.loadString('assets/data/quests.json5');
    quests.addAll(JSON5.parse(questsDataString));

    // 载入动画，其中皮肤动画需要特殊处理
    // 每个皮肤保存了所有的站姿，实际游戏运行时会分拆开来
    final animationsDataString =
        await rootBundle.loadString('assets/data/animation.json5');
    final animationsData = JSON5.parse(animationsDataString);
    for (final animId in animationsData.keys) {
      if (animId == 'skinAnimationTemplate') {
        final Map templateData = animationsData[animId];
        List skinIds = templateData['skins'] ?? [];
        for (final skinId in skinIds) {
          final battleAnimationSpriteSheetId = 'character/battle_$skinId.png';

          for (final genre in kCultivationGenres) {
            // 每一个皮肤对于每个流派而言有不同的站姿和启动和返回动作
            final Map skinAnimData = utils.deepCopy(templateData);
            skinAnimData.remove('skins');

            skinAnimData['stand'] = skinAnimData['${genre}_stand'];
            skinAnimData['stand']['width'] = _kSkinAnimationWidth;
            skinAnimData['stand']['height'] = _kSkinAnimationHeight;
            skinAnimData['stand']['stepTime'] = _kSkinAnimationStepTime2;
            skinAnimData['stand']['loop'] = true;
            skinAnimData['stand']['spriteSheet'] = battleAnimationSpriteSheetId;

            skinAnimData['before_melee_startup'] =
                skinAnimData['${genre}_before_melee_startup'];
            skinAnimData['before_melee_startup']['width'] =
                _kSkinAnimationWidth;
            skinAnimData['before_melee_startup']['height'] =
                _kSkinAnimationHeight;
            skinAnimData['before_melee_startup']['stepTime'] =
                _kSkinAnimationStepTime1;
            skinAnimData['before_melee_startup']['spriteSheet'] =
                battleAnimationSpriteSheetId;

            skinAnimData['after_melee_recovery'] =
                skinAnimData['${genre}_after_melee_recovery'];
            skinAnimData['after_melee_recovery']['width'] =
                _kSkinAnimationWidth;
            skinAnimData['after_melee_recovery']['height'] =
                _kSkinAnimationHeight;
            skinAnimData['after_melee_recovery']['stepTime'] =
                _kSkinAnimationStepTime1;
            skinAnimData['after_melee_recovery']['spriteSheet'] =
                battleAnimationSpriteSheetId;

            for (final g in kCultivationGenres) {
              skinAnimData.remove('${g}_stand');
              skinAnimData.remove('${g}_before_melee_startup');
              skinAnimData.remove('${g}_after_melee_recovery');
            }

            for (final actionId in _kActionIds) {
              skinAnimData[actionId]['width'] = _kSkinAnimationWidth;
              skinAnimData[actionId]['height'] = _kSkinAnimationHeight;
              skinAnimData[actionId]['stepTime'] = _kSkinAnimationStepTime1;
              skinAnimData[actionId]['spriteSheet'] =
                  battleAnimationSpriteSheetId;
            }

            final skinAnimId = '${skinId}_$genre';
            animations[skinAnimId] = skinAnimData;
          }

          final image = await Flame.images
              .load('animation/$battleAnimationSpriteSheetId');
          final sheet = SpriteSheet(
            image: image,
            srcSize: Vector2(_kSkinAnimationWidth, _kSkinAnimationHeight),
          );
          spriteSheets[battleAnimationSpriteSheetId] = sheet;
        }
      } else {
        final animDataCollection = animationsData[animId];
        animations[animId] = animDataCollection;
        for (final animData in animDataCollection.values) {
          final assetId = animData['spriteSheet'];
          if (spriteSheets.containsKey(assetId)) {
            continue;
          }
          final image = await Flame.images.load('animation/$assetId');
          final sheet = SpriteSheet(
            image: image,
            srcSize: Vector2(animData['width'], animData['height']),
          );
          spriteSheets[assetId] = sheet;
        }
      }
    }

    final spriteSheetDataString =
        await rootBundle.loadString('assets/data/sprite_sheet.json5');
    final List spriteSheetsData = JSON5.parse(spriteSheetDataString);
    for (final spriteSheetData in spriteSheetsData) {
      final assetId = spriteSheetData['assetId'];
      assert(assetId != null);
      double? srcWidth = spriteSheetData['width'];
      double? srcHeight = spriteSheetData['height'];
      assert(srcWidth != null && srcHeight != null);
      final image = await Flame.images.load(assetId);
      final sheet = SpriteSheet(
        image: image,
        srcSize: Vector2(srcWidth!, srcHeight!),
      );
      spriteSheets[assetId] = sheet;
    }

    // 拼接技能树节点的描述
    for (final passiveTreeNodeData in passiveTree.values) {
      final bool isAttribute = passiveTreeNodeData['isAttribute'] == true;

      final nodeDescription = StringBuffer();

      if (isAttribute) {
        // nodeDescription.writeln(
        //     '<bold yellow>${engine.locale('passivetree_attribute_any')}</>\n ');
        String description =
            engine.locale('passivetree_attribute_any_description');
        List<String> lines = description.split('\n');
        for (final line in lines) {
          nodeDescription.writeln('<lightBlue>$line</>');
        }
      } else {
        String? title = passiveTreeNodeData['title'];
        if (title != null) {
          final nodeTitle = engine.locale(title);
          nodeDescription.writeln('<bold yellow>$nodeTitle</>\n ');
          String? comment = passiveTreeNodeData['comment'];
          if (comment != null) {
            comment = engine.locale(comment);
            nodeDescription.writeln('<italic grey>$comment</>\n ');
          }
        }
        final passivesData = passiveTreeNodeData['passives'];
        assert(
            passivesData is List, 'passiveTreeNodeData: $passiveTreeNodeData');
        for (final passiveData in passivesData) {
          final String dataId = passiveData['id'];
          String? description = passiveData['description'];
          if (description == null) {
            final passiveRawData = GameData.passives[dataId];
            assert(passiveRawData != null, 'passiveData: $passiveData');
            description = engine.locale(passiveRawData['description']);
            if (passiveRawData['increment'] != null) {
              final int level = passiveData['level'];
              final num increment = passiveRawData['increment'];
              final int value = (level * increment).round();
              description =
                  description.interpolate(['${value < 0 ? '' : '+'}$value']);
            }
          } else {
            description = engine.locale(description);
          }
          nodeDescription.writeln('<lightBlue>$description</>');
        }
      }

      // final requirement = passiveTreeNodeData['requirement'];
      // if (requirement != null) {
      //   nodeDescription.writeln(
      //       ' \n<grey>${engine.locale('requirement')}: ${engine.locale('cultivationRank_$requirement')}</>');
      // }

      passiveTreeNodeData['description'] = nodeDescription.toString();
    }

    _isInitted = true;
  }

  static Future<void> registerModuleEventHandlers() async {
    engine.hetu.invoke('main');

    for (final id in engine.mods.keys) {
      if (engine.mods[id]?['enabled'] == true) {
        final moduleConfig = {'version': kGameVersion};
        engine.hetu.invoke('main', module: id, positionalArgs: [moduleConfig]);
      }
    }
  }

  /// 将dart侧从json5载入的游戏数据保存到游戏存档中
  static void initGameData() {
    engine.info('初始化当前载入的模组...');

    engine.hetu.invoke(
      'init',
      namedArgs: {
        'mapsData': GameData.maps,
        'battleCardsData': GameData.battleCards,
        'battleCardAffixesData': GameData.battleCardAffixes,
        'itemsData': GameData.items,
        'craftablesData': GameData.craftables,
        'passivesData': GameData.passives,
        'journalsData': GameData.journals,
        'questsData': GameData.quests,
      },
    );

    for (final id in engine.mods.keys) {
      if (engine.mods[id]?['enabled'] == true) {
        final moduleConfig = {'version': kGameVersion};
        engine.hetu.invoke('init', module: id, positionalArgs: [moduleConfig]);
      }
    }

    // 将模组按照优先级重新排序
    final mods = (game['mods'].values as Iterable).toList();
    mods.sort((mod1, mod2) {
      return (mod2['priority'] ?? 0).compareTo(mod1['priority'] ?? 0);
    });
    engine.hetu.invoke('sortMods', positionalArgs: [mods]);
  }

  /// 每次执行 createGame 都会重置游戏内的 game 对象上的数据
  static Future<void> createGame(
    String saveName, {
    Map<String, dynamic> arguments = const {},
    String? mainWorldId,
    int? seed,
    bool enableTutorial = true,
    bool isEditorMode = false,
  }) async {
    engine.clearLogs();

    engine.hetu.invoke('createGame', positionalArgs: [
      saveName
    ], namedArgs: {
      'seed': seed,
      'mainWorldId': mainWorldId,
      'enableTutorial': enableTutorial,
    });

    game = engine.hetu.fetch('game');
    flags = game['flags'];
    universe = engine.hetu.fetch('universe');
    history = engine.hetu.fetch('history');
    hero = engine.hetu.fetch('hero');
    random = engine.hetu.fetch('random');

    initGameData();

    if (!isEditorMode) {
      await registerModuleEventHandlers();
    }

    if (mainWorldId != null) {
      engine.pushScene(
        mainWorldId,
        constructorId: Scenes.worldmap,
        arguments: arguments,
        onAfterLoaded: () {
          engine.setLoading(false);
        },
      );
    }
  }

  static Future<List<String>> _loadGame({
    required dynamic gameData,
    required dynamic universeData,
    required dynamic historyData,
    dynamic scenesData,
    bool isEditorMode = false,
  }) async {
    engine.clearLogs();

    engine.hetu.invoke('loadGameFromJsonData', namedArgs: {
      'gameData': gameData,
      'universeData': universeData,
      'historyData': historyData,
    });

    if (!isEditorMode) {
      await registerModuleEventHandlers();
    }

    List<String> sceneIds = [];
    Map<String, String> constructorIds = {};
    Map<String, dynamic> argumentIds = {};
    if (scenesData != null) {
      assert(scenesData is List);
      for (final sceneData in scenesData) {
        final sceneId = sceneData['sceneId'];
        sceneIds.add(sceneId);
        final constructorId = sceneData['constructorId'];
        if (constructorId != null) {
          constructorIds[sceneId] = constructorId;
        }
        final arguments = sceneData['arguments'];
        if (arguments != null) {
          argumentIds[sceneId] = arguments;
        }
      }
    }
    engine.loadSceneConstructorIds(constructorIds);
    engine.loadSceneArguments(argumentIds);

    game = engine.hetu.fetch('game');
    flags = game['flags'];
    universe = engine.hetu.fetch('universe');
    history = engine.hetu.fetch('history');
    hero = engine.hetu.fetch('hero');
    random = engine.hetu.fetch('random');

    return sceneIds;
  }

  static void loadZoneColors(TileMap map) {
    final colors = engine.hetu.invoke('getCurrentWorldZoneColors');
    engine.info('刷新地图 ${map.id} 上色信息');
    engine.loadTileMapZoneColors(map, colors);
  }

  /// 从存档中读取游戏数据
  /// 在这一步中，并不会创建地图对应的场景
  /// 如果存档中包含场景数据，则会返回场景名称列表
  static Future<void> loadGame(SaveInfo info,
      {bool isEditorMode = false}) async {
    // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
    engine.setLoading(true, tip: engine.locale(kTips.random));
    await Future.delayed(const Duration(milliseconds: 250));
    await engine.clearAllCachedScene(
        except: Scenes.mainmenu, triggerOnStart: false);

    engine.info('从 [${info.savePath}] 载入游戏存档。');
    final gameSave = await File(info.savePath).open();
    final gameDataString = utf8.decoder
        .convert((await gameSave.read(await gameSave.length())).toList());
    await gameSave.close();
    final gameData = json5Decode(gameDataString);

    final universeSave =
        await File(info.savePath + kUniverseSaveFilePostfix).open();
    final universeDataString = utf8.decoder.convert(
        (await universeSave.read(await universeSave.length())).toList());
    await universeSave.close();
    final universeData = json5Decode(universeDataString);

    final historySave =
        await File(info.savePath + kHistorySaveFilePostfix).open();
    final historyDataString = utf8.decoder
        .convert((await historySave.read(await historySave.length())).toList());
    await historySave.close();
    final historyData = json5Decode(historyDataString);

    dynamic scenesData;
    final isSceneSaveExist =
        await File(info.savePath + kScenesSaveFilePostfix).exists();
    if (isSceneSaveExist) {
      final scenesSave =
          await File(info.savePath + kScenesSaveFilePostfix).open();
      final scenesDataString = utf8.decoder
          .convert((await scenesSave.read(await scenesSave.length())).toList());
      await scenesSave.close();
      scenesData = json5Decode(scenesDataString);
    }

    final sceneIds = await _loadGame(
      gameData: gameData,
      universeData: universeData,
      historyData: historyData,
      scenesData: scenesData,
      isEditorMode: isEditorMode,
    );

    final completer = Completer<void>();
    if (sceneIds.isNotEmpty) {
      for (var i = 0; i < sceneIds.length; ++i) {
        final sceneId = sceneIds[i];
        final constructorId = engine.cachedConstructorIds[sceneId];
        final arguments = engine.cachedArguments[sceneId];
        if (constructorId == Scenes.worldmap) {
          await engine.pushScene(
            sceneId,
            constructorId: constructorId,
            arguments: {
              'id': sceneId,
              'method': 'load',
            },
            onAfterLoaded: i == sceneIds.length - 1
                ? () {
                    engine.setLoading(false);
                    completer.complete();
                  }
                : null,
          );
        } else {
          await engine.pushScene(
            sceneId,
            constructorId: constructorId,
            arguments: arguments,
            onAfterLoaded: i == sceneIds.length - 1
                ? () {
                    engine.setLoading(false);
                    completer.complete();
                  }
                : null,
          );
        }
      }
    } else {
      await engine.pushScene(
        info.currentWorldId,
        constructorId: Scenes.worldmap,
        arguments: {
          'id': info.currentWorldId,
          'savePath': info.savePath,
          'method': 'load',
        },
        onAfterLoaded: () {
          engine.setLoading(false);
          completer.complete();
        },
      );
    }
    return completer.future;
  }

  static Future<List<String>> loadPreset(String filename,
      {bool isEditorMode = false}) async {
    engine.info('从 [$filename] 载入游戏预设。');

    final gameSave = 'assets/save/$filename$kGameSaveFileExtension';
    final gameDataString = await rootBundle.loadString(gameSave);
    final gameData = json5Decode(gameDataString);

    final universeSave = '$gameSave$kUniverseSaveFilePostfix';
    final universeDataString = await rootBundle.loadString(universeSave);
    final universeData = json5Decode(universeDataString);

    final historySave = '$gameSave$kHistorySaveFilePostfix';
    final historyDataString = await rootBundle.loadString(historySave);
    final historyData = json5Decode(historyDataString);

    return await _loadGame(
      gameData: gameData,
      universeData: universeData,
      historyData: historyData,
      isEditorMode: isEditorMode,
    );
  }

  static void switchWorld(String worldId, {bool clearCache = false}) {
    if (engine.hasSceneInSequence(worldId)) {
      engine.popSceneTill(worldId, clearCache: clearCache);
    } else if (engine.hasScene(worldId)) {
      engine.switchScene(worldId);
    } else {
      engine.pushScene(
        worldId,
        constructorId: Scenes.worldmap,
        arguments: {
          'id': worldId,
          'method': 'load',
        },
      );
    }
  }

  static Future<SpriteAnimationWithTicker> createAnimationFromData(
      String path, String state) async {
    final cacheId = '$path/$state';
    final cachedAnim = _cachedAnimations[cacheId];
    if (cachedAnim != null) {
      if (!cachedAnim.isLoaded) {
        await cachedAnim.load();
      }
      return cachedAnim.clone();
    } else {
      final animData = GameData.animations[path][state];
      if (animData == null) {
        final err = 'Could not found animation state data for [$path/$state]';
        engine.error(err);
        throw err;
      }
      double? srcWidth = animData['width'];
      double? srcHeight = animData['height'];
      assert(srcWidth != null && srcHeight != null,
          'Animation data has no width or height. [$path/$state]: $animData');
      final Vector2 srcSize = Vector2(srcWidth!, srcHeight!);
      SpriteSheet? spriteSheet = GameData.spriteSheets[animData['spriteSheet']];
      double offsetX = animData['offsetX'] ?? 0;
      double offsetY = animData['offsetY'] ?? 0;
      final anim = SpriteAnimationWithTicker(
        // animationId: animData['assetId'],
        spriteSheet: spriteSheet,
        srcSize: srcSize,
        renderRect: Rect.fromLTWH(
          offsetX,
          offsetY,
          srcWidth * kSpriteScale,
          srcHeight * kSpriteScale,
        ),
        stepTime: animData['stepTime'] ?? kDefaultAnimationStepTime,
        loop: animData['loop'] ?? false,
        scale: animData['scale'] ?? kSpriteScale,
        from: animData['from'],
        to: animData['to'],
        row: animData['row'],
      );
      _cachedAnimations[cacheId] = anim;
      await anim.load();
      return anim;
    }
  }

  static CustomGameCard getSiteCard(
    dynamic siteData, {
    void Function()? onPreviewed,
    void Function()? onUnpreviewed,
  }) {
    final id = siteData['id'];
    final card = CustomGameCard(
      id: id,
      deckId: id,
      data: siteData,
      anchor: Anchor.center,
      borderRadius: 15.0,
      spriteId: 'location/site_frame.png',
      title: siteData['name'],
      titleConfig: GameUI.siteTitleConfig,
      showTitle: true,
      enablePreview: true,
      focusOnPreviewing: true,
      focusedPriority: kSiteCardPriority,
      focusedSize: GameUI.siteCardFocusedSize,
      focusedOffset: Vector2(
          (GameUI.siteCardFocusedSize.x - GameUI.siteCardSize.x) / 2,
          (GameUI.siteCardSize.y - GameUI.siteCardFocusedSize.y) / 2),
      illustrationRelativePaddings:
          const EdgeInsets.fromLTRB(0.0428, 0.025, 0.0428, 0.025),
      illustrationSpriteId: siteData['image'],
      onPreviewed: onPreviewed,
      onUnpreviewed: onUnpreviewed,
    );
    card.index = siteData['priority'] ?? 0;
    return card;
  }

  static CustomGameCard createSiteCard({
    String? id,
    required String spriteId,
    required String title,
    Vector2? position,
    int index = 0,
    void Function()? onPreviewed,
    void Function()? onUnpreviewed,
  }) {
    final card = CustomGameCard(
      id: id ?? spriteId,
      deckId: id ?? spriteId,
      borderRadius: 20.0,
      spriteId: 'location/site_frame.png',
      title: title,
      titleConfig: GameUI.siteTitleConfig,
      showTitle: true,
      size: GameUI.siteCardSize,
      preferredSize: GameUI.siteCardSize,
      position: position,
      enablePreview: true,
      focusOnPreviewing: true,
      focusedPriority: kSiteCardPriority,
      focusedSize: GameUI.siteCardFocusedSize,
      focusedOffset: Vector2(
          -(GameUI.siteCardFocusedSize.x - GameUI.siteCardSize.x) / 2,
          GameUI.siteCardSize.y - GameUI.siteCardFocusedSize.y),
      illustrationRelativePaddings:
          const EdgeInsets.fromLTRB(0.0428, 0.025, 0.0428, 0.025),
      illustrationSpriteId: spriteId,
      onPreviewed: onPreviewed,
      onUnpreviewed: onUnpreviewed,
    );
    card.index = index;
    return card;
  }

  static String _getPassivesDescription(dynamic passivesData) {
    final builder = StringBuffer();
    if (passivesData.isEmpty) {
      builder.writeln('<grey>${engine.locale('none')}</>');
    } else {
      final List skillList = (passivesData.values as Iterable)
          .where((value) => value != null)
          .toList();
      skillList.sort((data1, data2) {
        return ((data2['priority'] ?? 0) as int)
            .compareTo((data1['priority'] ?? 0) as int);
      });
      for (final skillData in skillList) {
        bool isAfflicted = false;
        String description;
        if ((skillData['id'] as String).endsWith('_rank')) {
          final int rank = skillData['level'];
          assert(rank > 0);
          final rankString = engine.locale('cultivationRank_$rank');
          description = engine
              .locale(skillData['description'], interpolations: [rankString]);
        } else {
          description = engine.locale(skillData['description']);
          final value = skillData['value'];
          if (value != null) {
            isAfflicted = value < 0;
            description =
                description.interpolate(['${isAfflicted ? '' : '+'}$value']);
          }
        }
        if (isAfflicted) {
          builder.writeln('<red>$description</>');
        } else {
          builder.writeln('<lightBlue>$description</>');
        }
      }
    }
    return builder.toString();
  }

  static String getPassivesDescription({
    dynamic character,
    String? title,
  }) {
    character ??= GameData.hero;
    final desc = StringBuffer();
    if (title != null) {
      desc.writeln('$title\n ');
    }

    final passivesDescription = _getPassivesDescription(character['passives']);
    final potionPassivesDescription =
        _getPassivesDescription(character['potionPassives']);

    desc.writeln(
        '${engine.locale('passivetree_passives_description_title')}\n ');
    desc.writeln(passivesDescription);
    desc.writeln(' ');

    desc.writeln(
        '${engine.locale('passivetree_potion_passives_description_title')}\n ');
    desc.writeln(potionPassivesDescription);

    return desc.toString();
  }

  static String getItemDescription(
    dynamic itemData, {
    bool isInventory = false,
    dynamic priceFactor,
    bool isSell = false,
    bool isDetailed = false,
    bool showDetailedHint = true,
  }) {
    final description = StringBuffer();
    String title = itemData['name'];
    final stackSize = itemData['stackSize'] ?? 1;
    if (stackSize > 1) {
      title = '$title × $stackSize';
    }
    final rarity = itemData['rarity'];
    final type = itemData['type'];
    final category = itemData['category'];
    final bool isIdentified = itemData['isIdentified'] == true;
    final bool isEquippable = itemData['isEquippable'] == true;
    final bool isCursed = itemData['isCursed'] == true;
    final bool isUsable = itemData['isUsable'] == true;
    final bool isUntradable = itemData['isUntradable'] == true;

    final level = itemData['level'];
    final levelString =
        level != null ? '(${engine.locale('level2')}: $level)' : '';

    String titleString;
    if (isIdentified) {
      titleString = isDetailed
          ? '<bold $rarity t7>$title $levelString</>'
          : '<bold $rarity t7>$title</>';
    } else {
      titleString =
          '<bold grey t7>${engine.locale('unidentified3')}${engine.locale(category)}</>';
    }
    final rarityString =
        '<grey>${engine.locale('rarity')}: </><$rarity>${engine.locale(rarity)}</>';
    String typeString = type is List
        ? type.map((e) => engine.locale(e)).join(', ')
        : engine.locale(type);
    typeString = ' <grey>${engine.locale('type')}: $typeString</>';
    String priceString = '';
    if (isUntradable && isInventory) {
      priceString = '<grey>, </><red>${engine.locale('untradable')}</>';
    }

    description.writeln(titleString);
    if (engine.config.debugMode) {
      description.writeln('<grey>[${itemData['id']}]</> - press `c` to copy');
    }
    description.writeln('$rarityString$typeString$priceString');

    // description.writeln(kSeparateLine);
    final flavortext = itemData['flavortext'];
    if (flavortext != null) {
      final split = flavortext.split('\n');
      for (final line in split) {
        description.writeln('<lightGreen>$line</>');
      }
    }

    final chargeData = itemData['chargeData'];
    if (isIdentified && chargeData != null && isInventory) {
      final int maxCharge = chargeData['max'];
      final int currentCharge = chargeData['current'];
      final int shardsPerCharge = chargeData['shardsPerCharge'];
      description.writeln(
          '<lightBlue>${engine.locale('currentCharges', interpolations: [
            currentCharge,
            maxCharge,
          ])}</>');
      description.writeln(
          '<lightBlue>${engine.locale('shardsPerCharge', interpolations: [
            shardsPerCharge,
          ])}</>');
      description.writeln(kSeparateLine);
    }

    final extraDescription = StringBuffer();
    final Map<String, String> explanations = {};
    final affixList = itemData['affixes'];
    if (affixList is List && affixList.isNotEmpty) {
      for (var i = 0; i < affixList.length; i++) {
        final passiveData = affixList[i];
        String descriptionString = engine.locale(passiveData['description']);
        num? value = passiveData['value'];
        bool isAfflicted = false;
        if (value != null) {
          isAfflicted = value < 0;
          descriptionString = descriptionString
              .interpolate(['${isAfflicted ? '' : '+'}$value']);
        }
        final passiveRawData = passives[passiveData['id']];
        final List? tags = passiveRawData['tags'];
        if (tags != null && tags.isNotEmpty) {
          for (final tag in tags) {
            explanations[tag] =
                '<grey>「${engine.locale(tag)}」- ${engine.locale('${tag}_description')}</>';
          }
        }

        if (i != 0 && isDetailed) {
          final level = passiveData['level'];
          final levelString =
              level != null ? ' (${engine.locale('level2')}: $level)' : '';
          descriptionString = '$descriptionString $levelString';
        }

        if (isAfflicted) {
          extraDescription.writeln('<red>$descriptionString</>');
        } else {
          if (i == 0) {
            extraDescription.writeln(descriptionString);
          } else {
            extraDescription.writeln('<lightBlue>$descriptionString</>');
          }
        }
      }
    }

    if (!isIdentified) {
      if (extraDescription.isNotEmpty) {
        description.writeln('<red>${engine.locale('unidentified')}</>');
      }
    } else {
      if (extraDescription.isNotEmpty) {
        description.writeln(kSeparateLine);
        description.write(extraDescription.toString());
      }
    }

    if (isIdentified && explanations.isNotEmpty) {
      if (isDetailed) {
        description.writeln(kSeparateLine);
        for (final tag in explanations.keys) {
          description.writeln(explanations[tag]);
        }
      } else if (showDetailedHint) {
        description.writeln(kSeparateLine);
        description.writeln('<grey>${engine.locale('explanation_hint')}</>');
      }
    }

    if (priceFactor == null) {
      if (isIdentified && isInventory) {
        if (itemData['equippedPosition'] == null) {
          if (category == 'cardpack') {
            description.writeln('<yellow>${engine.locale('cardpackHint')}</>');
          } else if (isEquippable) {
            description
                .writeln('<yellow>${engine.locale('equippableHint')}</>');
            if (isCursed) {
              description.writeln('<red>${engine.locale('cursedItemHint')}</>');
            }
          } else if (isUsable) {
            if (category == 'material_pack') {
              description
                  .writeln('<yellow>${engine.locale('hint_materialpack')}</>');
            } else {
              description.writeln('<yellow>${engine.locale('usableHint')}</>');
            }
          }
        } else {
          if (isCursed) {
            description.writeln('<red>${engine.locale('cursedItemHint')}</>');
          } else {
            description
                .writeln('<yellow>${engine.locale('unequippableHint')}</>');
          }
        }
      }
    } else {
      final useShard = priceFactor['useShard'] == true;
      final estimatePriceRange = priceFactor['estimatePriceRange'];
      if (estimatePriceRange == null) {
        final price = GameLogic.calculateItemPrice(
          itemData,
          priceFactor: priceFactor,
          isSell: isSell,
        );
        description.writeln('<yellow>${engine.locale('price')}: $price '
            '${engine.locale(useShard ? 'shard' : 'money2')}</>');
      } else {
        assert(itemData['isIdentified'] == false);
        final estimatedPrice = GameLogic.estimateItemPrice(
            itemData['category'], itemData['rank'],
            range: estimatePriceRange);
        description.writeln('<yellow>${engine.locale('estimatedPrice')}: '
            '$estimatedPrice ${engine.locale(useShard ? 'shard' : 'money2')}</>');
      }
      if (engine.config.debugMode) {
        description.writeln('<grey>basePrice: ${itemData['price']}</>');
      }
    }

    final out = description.toString().trim();
    return out;
  }

  /// 返回值是一个元祖，第一个字符串是卡面描述，第二个是详细描述
  static (String, String) getBattleCardDescription(
    dynamic cardData, {
    bool isDetailed = false,
    bool showRequirement = true,
    bool showDetailedHint = true,
    bool showDebugId = true,
  }) {
    final List affixes = cardData['affixes'];
    final int cardLevel = cardData['level'];
    final int cardRank = cardData['rank'];
    final bool isIdentified = cardData['isIdentified'] == true;
    String title = cardData['name'];

    assert(affixes.isNotEmpty);
    // final mainAffix = affixes[0];

    final description = StringBuffer();
    final extraDescription = StringBuffer();

    final levelPrefix = engine.locale('level2');

    String titleString = isDetailed
        ? '<bold rank$cardRank t7>$title ($levelPrefix $cardLevel)</>'
        : '<bold rank$cardRank t7>$title</>';
    final rankString =
        '<grey>${engine.locale('cultivationRank')}:</> <rank$cardRank>${engine.locale('cultivationRank_$cardRank')}, </>';
    final genreString =
        '<grey>${engine.locale('genre')}: ${engine.locale(cardData['genre'])}, </>';
    final categoryString =
        '<grey>${engine.locale('category')}: ${engine.locale(cardData['category'])}</>';

    extraDescription.writeln(titleString);
    if (engine.config.debugMode && showDebugId) {
      extraDescription
          .writeln('<grey>[${cardData['id']}]</> - press `c` to copy');
    }
    extraDescription.writeln('$rankString$genreString$categoryString');
    extraDescription.writeln(kSeparateLine);

    final Map<String, String> explanations = {};
    for (var i = 0; i < affixes.length; ++i) {
      final affix = affixes[i];
      final affixDescriptionRaw = engine.locale(affix['description']);
      final affixDescription =
          affixDescriptionRaw.interpolate(affix['value']).split(RegExp('\n'));

      if (isIdentified) {
        for (var line in affixDescription) {
          if (i == 0) {
            description.writeln(line);
            extraDescription.writeln(line);
          } else {
            // 某些词条没有数值变化，也没有等级，不需要显示
            if (affix['value'] != null && isDetailed) {
              line += ' ($levelPrefix ${affix['level']})';
            }
            extraDescription.writeln('<lightBlue>$line</>');
          }
        }

        final List? tags = affix['tags'];
        if (tags != null && tags.isNotEmpty) {
          for (final tag in tags) {
            explanations[tag] =
                '<grey>「${engine.locale(tag)}」- ${engine.locale('${tag}_description')}</>';
          }
        }
      } else {
        continue;
      }
    }

    if (!isIdentified) {
      description.writeln('<red>${engine.locale('unidentified')}</>');
      extraDescription.writeln('<red>${engine.locale('unidentified')}</>');
    }

    if (explanations.isNotEmpty) {
      if (isDetailed) {
        extraDescription.writeln(kSeparateLine);
        for (final tag in explanations.keys) {
          extraDescription.writeln(explanations[tag]);
        }
      } else if (showDetailedHint) {
        extraDescription.writeln(kSeparateLine);
        extraDescription
            .writeln('<grey>${engine.locale('explanation_hint')}</>');
      }
    }

    if (isIdentified && showRequirement) {
      String? requirementString = GameLogic.checkRequirements(cardData);
      if (requirementString != null) {
        extraDescription.writeln(requirementString);
      }
    }

    if (isIdentified && affixes.length > 1) {
      description.writeln(
          '<lightBlue>+ ${affixes.length - 1} ${engine.locale('extraAffix')}</>');
    }

    return (
      description.toString().trim(),
      extraDescription.toString().trim(),
    );
  }

  static dynamic createBattleCardDataByFilter({
    dynamic filter,
    isIdentified = true,
  }) {
    final cardData = engine.hetu.invoke(
      'BattleCard',
      namedArgs: {
        'kind': (filter['isBasic'] == true ? 'none' : filter['kind']),
        'genre': (filter['isBasic'] == true ? 'none' : filter['genre']),
        'category': (filter['isBasic'] == true ? 'attack' : filter['category']),
        'rank': filter?['rank'],
        'isIdentified': isIdentified,
      },
    );

    return cardData;
  }

  static CustomGameCard createBattleCard(dynamic data,
      {bool deepCopyData = false}) {
    assert(data != null && data['id'] != null, 'Invalid battle card data!');
    assert(_isInitted, 'Game data is not loaded yet!');
    assert(GameUI.isInitted, 'Game UI is not initted yet!');

    final cardData = deepCopyData ? utils.deepCopy(data) : data;

    final String id = cardData['id'];
    final String image = cardData['image'];
    final String title = cardData['name'];
    final int cardRank = cardData['rank'];

    final (description, extraDescription) = getBattleCardDescription(cardData);

    return CustomGameCard(
      id: id,
      // deckId: id,
      data: cardData,
      preferredSize: GameUI.deckbuildingCardSize,
      spriteId: 'battlecard/border4.png',
      illustrationRelativePaddings:
          const EdgeInsets.fromLTRB(0.074, 0.135, 0.074, 0.235),
      illustrationSpriteId: image,
      title: title,
      titleRelativePaddings: const EdgeInsets.fromLTRB(0.2, 0.05, 0.2, 0.865),
      titleConfig: ScreenTextConfig(
        anchor: Anchor.center,
        outlined: true,
        textStyle: TextStyle(
          color: getColorFromRank(cardRank),
          fontFamily: GameUI.fontFamilyKaiti,
          fontSize: 14.0,
        ),
      ),
      descriptionRelativePaddings:
          const EdgeInsets.fromLTRB(0.108, 0.735, 0.108, 0.08),
      descriptionConfig: const ScreenTextConfig(
        anchor: Anchor.center,
        textStyle: TextStyle(
          fontFamily: GameUI.fontFamilyBlack,
          fontSize: 8.0,
          color: Colors.black,
        ),
        overflow: ScreenTextOverflow.wordwrap,
      ),
      description: description.toString(),
      glowSpriteId: 'battlecard/glow.png',
      enablePreview: true,
    );
  }

  static String getQuestBriefDescription(dynamic quest) {
    final desc = StringBuffer();

    final kind = quest['kind'];
    final int difficulty = quest['difficulty'] ?? 0;
    final String difficultyLable = kDifficultyLabels[difficulty]!;
    final timeLimit = quest['timeLimit'];
    desc.writeln('<bold rank$difficulty t7>${engine.locale('quest_$kind')}</>');
    desc.writeln(
        '${engine.locale('difficulty')}: <rank$difficulty>${engine.locale(difficultyLable)}</>');
    desc.write(
        '${engine.locale('timeLimit')}: <yellow>${timeLimit ~/ kTicksPerDay} ${engine.locale('ageDay')}</>');

    return desc.toString();
  }

  static String getQuestRewardDescription(List reward,
      {bool isFinished = false}) {
    final desc = StringBuffer();
    // desc.writeln('${engine.locale('reward')}:');
    for (var i = 0; i < reward.length; ++i) {
      if (i > 0) {
        desc.write(', ');
      }
      final itemInfo = reward[i];
      final amount = itemInfo['amount'] ?? 1;
      switch (itemInfo['type']) {
        case 'material':
          final kind = itemInfo['kind'];
          desc.write('$amount ${engine.locale(kind)}');
        case 'prototype':
          final id = itemInfo['id'];
          desc.write('$amount ${engine.locale(id)}');
        case 'equipment':
          final kind = itemInfo['kind'];
          final rarity = itemInfo['rarity'];
          desc.write('$amount ${engine.locale(rarity)}${engine.locale(kind)}');
        case 'cardpack':
          final rank = itemInfo['rank'] ?? 0;
          final genre = itemInfo['genre'];
          final kind = itemInfo['kind'];
          final rankString =
              engine.locale('cultivationRank_$rank') + engine.locale('rank2');
          final genreString = genre != null ? engine.locale(genre) : '';
          final kindString =
              kind != null ? engine.locale('battlecard_$kind') : '';
          final name =
              rankString + genreString + kindString + engine.locale('cardpack');
          desc.write('$amount $name');
        case 'contribution':
          final amount = itemInfo['amount'] ?? 0;
          final sectId = itemInfo['sectId'];
          if (sectId != null && hero['sectId'] != sectId) {
            desc.write('${amount ~/ 2} ${engine.locale('contribution')}');
            desc.write(' (${engine.locale('contribution_note')})');
          } else {
            desc.write('$amount ${engine.locale('contribution')}');
          }
        default:
          desc.write(engine.locale('unknown_item'));
      }
    }
    return desc.toString();
  }

  static String getQuestBudgetDescription(dynamic budget,
      {bool isFinished = false}) {
    // final desc = StringBuffer();
    final kind = budget['kind'];
    final amount = budget['amount'];
    // desc.write('${engine.locale('budget')}: ');
    // desc.writeln('<lightGreen>$amount ${engine.locale(kind)}</>');
    // return desc.toString();
    return '$amount ${engine.locale(kind)}';
  }

  static String getQuestTimeLimitDescription(dynamic journal) {
    final startDate = journal['timestamp'] + journal['quest']?['timeLimit'];
    final timeString =
        engine.hetu.invoke('getDateTimeString', positionalArgs: [startDate]);
    return timeString;
  }

  static String getQuestDetailDescription(dynamic quest) {
    final desc = StringBuffer();
    final brief = GameData.getQuestBriefDescription(quest);
    desc.write(brief);
    desc.writeln(kSeparateLine);
    desc.writeln('${engine.locale('quest_content')}:');
    final kind = quest['kind'];
    desc.writeln(engine.locale('quest_${kind}_description',
        interpolations: quest['interpolations']));
    final reward = quest['reward'];
    final budget = quest['budget'];
    if (reward != null || budget != null) {
      desc.writeln(kSeparateLine);
    }
    if (budget != null) {
      final budgetDesc = getQuestBudgetDescription(budget);
      desc.writeln('<lightGreen>${engine.locale('budget')}: $budgetDesc</>');
    }
    if (reward != null) {
      final rewardDesc = getQuestRewardDescription(reward);
      // final lines = rewardDesc.split('\n');
      // for (final line in lines) {
      //   desc.writeln('  $line');
      // }
      desc.writeln('<yellow>${engine.locale('reward')}: $rewardDesc</>');
    }
    return desc.toString();
  }

  static List<String> getCharacterInformationRow(dynamic character) {
    final row = <String>[];
    row.add(character['name']);
    // 性别
    final bool isFemale = character['isFemale'];
    row.add(engine.locale(isFemale ? 'female' : 'male'));
    final age = engine.hetu
        .invoke('getCharacterAgeString', positionalArgs: [character]);
    // 年龄
    row.add(age);
    // 等级和境界
    row.add('${character['level']}');
    row.add(engine.locale('cultivationRank_${character['rank']}'));
    // 名声
    final fame = engine.hetu
        .invoke('getCharacterFameString', positionalArgs: [character]);
    row.add(fame);
    final homeLocationId = character['homeLocationId'];
    final homeLocation = GameData.game['locations'][homeLocationId];
    row.add(homeLocation?['name'] ?? engine.locale('none'));
    // 门派名字
    String sectName = engine.locale('none');
    final sectId = character['sectId'];
    if (sectId != null) {
      final sect = GameData.getSect(sectId);
      sectName = sect['name'];
    }
    row.add(sectName);
    // 称号
    final titleId = character['titleId'];
    row.add(titleId != null ? engine.locale(titleId) : engine.locale('none'));
    // 多存一个隐藏的 id 信息，用于点击事件
    row.add(character['id']);
    return row;
  }

  static List<String> getMemberInformationRow(dynamic character) {
    final sectId = character['sectId'];
    assert(sectId != null, 'Character has no sect: ${character['name']}');

    final row = <String>[];
    row.add(character['name']);
    // 性别
    final bool isFemale = character['isFemale'];
    row.add(engine.locale(isFemale ? 'female' : 'male'));
    final age = engine.hetu
        .invoke('getCharacterAgeString', positionalArgs: [character]);
    // 年龄
    row.add(age);
    // 等级和境界
    row.add('${character['level']}');
    row.add(engine.locale('cultivationRank_${character['rank']}'));

    // 职位
    final titleId = character['titleId'];
    row.add(titleId != null ? engine.locale(titleId) : engine.locale('none'));
    // 功勋
    final sect = GameData.getSect(sectId);
    final memberData = sect['membersData'][character['id']];
    final contribution = memberData['contribution'] ?? 0;
    row.add(contribution.toString());
    // 上级
    final superiorId = memberData['superiorId'];
    if (superiorId == null) {
      row.add(engine.locale('none'));
    } else {
      final superior = GameData.getCharacter(superiorId);
      row.add(superior['name']);
    }
    // 汇报地点
    final reportCityId = memberData['reportCityId'];
    if (reportCityId == null) {
      row.add(engine.locale('none'));
    } else {
      final reportLocation = GameData.getLocation(reportCityId);
      row.add(reportLocation['name']);
    }

    // 多存一个隐藏的 id 信息，用于点击事件
    row.add(character['id']);
    return row;
  }

  static List<String> getCityInformationRow(dynamic location) {
    assert(location['category'] == 'city');

    final row = <String>[];
    row.add(location['name']);
    final worldPosition = location['worldPosition'];
    row.add('[${worldPosition['left']},${worldPosition['top']}]');
    // 类型
    row.add(engine.locale(location['kind']));
    // 规模
    row.add(location['development'].toString());
    // 居民
    row.add(location['residents'].length.toString());
    // 门派名字
    String sectName = engine.locale('none');
    final sectId = location['sectId'];
    if (sectId != null) {
      final sect = GameData.getSect(sectId);
      sectName = sect['name'];
    }
    row.add(sectName);
    // 管理者
    String? managerId = location['managerId'];
    if (managerId != null) {
      final manager = GameData.getCharacter(managerId);
      row.add(manager['name']);
    } else {
      row.add(engine.locale('none'));
    }
    // 多存一个隐藏的 id 信息，用于点击事件
    row.add(location['id']);
    return row;
  }

  static List<String> getSiteInformationRow(dynamic location) {
    assert(location['category'] == 'site');

    final row = <String>[];
    row.add(location['name']);
    if (location['worldPosition'] != null) {
      final worldPosition = location['worldPosition'];
      row.add('[${worldPosition['left']},${worldPosition['top']}]');
    } else if (location['atCityId'] != null) {
      final atCityId = location['atCityId'];
      final atCity = GameData.getLocation(atCityId);
      row.add(atCity['name']);
    }
    // 类型
    row.add(engine.locale(location['kind']));
    // 规模
    row.add(location['development'].toString());
    // 门派名字
    String sectName = engine.locale('none');
    final sectId = location['sectId'];
    if (sectId != null) {
      final sect = GameData.getSect(sectId);
      sectName = sect['name'];
    }
    row.add(sectName);
    // 管理者
    String? managerId = location['managerId'];
    if (managerId != null) {
      final manager = GameData.getCharacter(managerId);
      row.add(manager['name']);
    } else {
      row.add(engine.locale('none'));
    }
    // 多存一个隐藏的 id 信息，用于点击事件
    row.add(location['id']);
    return row;
  }

  static List<String> getSectInformationRow(dynamic sect) {
    final row = <String>[];
    row.add(sect['name']);
    // 掌门
    final headId = sect['headId'];
    final head = GameData.getCharacter(headId);
    row.add(head['name']);
    // 类型
    row.add(engine.locale(sect['category']));
    // 流派
    row.add(engine.locale(sect['genre']));
    // 总堂
    final headquarters = GameData.getLocation(sect['headquartersLocationId']);
    row.add(headquarters['name']);
    // 城市数量
    final locationIds = sect['locationIds'] as List;
    row.add(locationIds
        .where((id) {
          final location = GameData.getLocation(id);
          return location['category'] == 'city';
        })
        .length
        .toString());
    // 成员数量
    row.add(sect['membersData'].length.toString());
    row.add('${sect['recruitMonth']}${engine.locale('dateMonth')}');
    // 多存一个隐藏的 id 信息，用于点击事件
    row.add(sect['id']);
    return row;
  }

  /// return: (isPaused, isDeveloping, progress, max, statusString, costDescription)
  static (bool, int, int, String, String) getLocationDevelopmentStatus(
      dynamic location) {
    final status = location['updateStatus'] ?? {};

    final bool isPaused = status['isPaused'] == true;
    final bool isDeveloping = status['isDeveloping'] == true;
    final int progress = status['progress'] ?? 0;
    final int max = status['max'] ?? 0;

    String statusString = '';
    if (isDeveloping) {
      if (isPaused) {
        statusString =
            '<bold red>${engine.locale('updateStatusDevelopingPaused')}</>';
      } else {
        statusString =
            '<bold yellow>${engine.locale('updateStatusDeveloping')}</>';
      }
    } else {
      if (isPaused) {
        statusString = '<bold red>${engine.locale('updateStatusPaused')}</>';
      } else {
        statusString =
            '<bold lightGreen>${engine.locale('updateStatusNormal')}</>';
      }
    }

    String costDescription = '';
    final cost = status['cost'];
    if (cost != null) {
      StringBuffer desc = StringBuffer();
      desc.writeln(
          '<grey>${engine.locale('maintainanceCost_description')}</>\n ');
      desc.writeln('${engine.locale('maintainanceCostPerDay')}:');
      for (final materialId in cost.keys) {
        final amount = cost[materialId];
        if (amount == null) continue;
        if (isDeveloping) {
          desc.writeln('<yellow>${engine.locale(materialId)}: $amount</>');
        } else {
          desc.writeln('${engine.locale(materialId)}: $amount');
        }
      }
      costDescription = desc.toString();
    } else {
      costDescription =
          '${engine.locale('maintainanceCostPerDay')}:\n \n${engine.locale('none')}';
    }

    return (isDeveloping, progress, max, statusString, costDescription);
  }

  static String getLocationDevelopmentCostDescription(
      Map<String, int> developmentCost) {
    StringBuffer desc = StringBuffer();
    desc.writeln('<grey>${engine.locale('developmentCost_description')}</>\n ');
    final int days = developmentCost['days']!;
    desc.writeln('${engine.locale('developmentDays')}: $days\n ');
    desc.writeln(
        '${engine.locale('maintainanceCostIncreasedToDuringDevelopment')}:');
    for (final materialId in developmentCost.keys) {
      if (materialId == 'days') continue;
      final amount = developmentCost[materialId];
      if (amount == null) continue;
      desc.writeln('${engine.locale(materialId)}: $amount');
    }
    return desc.toString();
  }

  static String getWorldDescription() {
    final desc = StringBuffer();

    // 获取主角信息
    final hero = GameData.hero;
    final heroLocationId = hero['locationId'];
    final heroHomeLocationId = hero['homeLocationId'];

    // 1. 世界各个据点概况（只包括非隐藏的城市据点）
    final locations = GameData.game['locations'].values as Iterable;
    final cities = locations.where((loc) =>
        loc['category'] == 'city' &&
        loc['isHidden'] != true &&
        loc['isDiscovered'] == true);

    if (cities.isNotEmpty) {
      desc.writeln('城市：');
      for (final city in cities) {
        final cityName = city['name'];
        final development = city['development'] ?? 0;
        final kind = city['kind'];
        final kindName = engine.locale(kind);

        desc.write('$cityName（$kindName，规模：$development');

        // 所属门派
        final sectId = city['sectId'];
        if (sectId != null) {
          final sect = GameData.getSect(sectId);
          desc.write('，所属门派：${sect['name']}');
        } else {
          desc.write('，无门派管辖');
        }

        desc.writeln('）');

        // 如果是主角所在或居住的城市，添加更多信息
        if (city['id'] == heroLocationId || city['id'] == heroHomeLocationId) {
          // 获取该城市的角色列表
          final charactersInCity =
              (GameData.game['characters'].values as Iterable)
                  .where((char) =>
                      char['id'] != hero['id'] &&
                      (char['locationId'] == city['id'] ||
                          char['homeLocationId'] == city['id']))
                  .toList();

          if (charactersInCity.isNotEmpty) {
            desc.write('  居民：');
            final names = charactersInCity.map((char) {
              final name = char['name'];
              final titleId = char['titleId'];
              if (titleId != null) {
                final title = engine.locale(titleId);
                return '$name（$title）';
              }
              return name;
            });
            desc.writeln(names.join('、'));
          }
        }
      }

      desc.writeln();
    }

    // 2. 世界门派概况
    desc.writeln('门派：');
    final sects = GameData.game['sects'].values as Iterable;
    for (final sect in sects) {
      final sectName = sect['name'];
      final category = sect['category'];
      final categoryName = engine.locale(category);
      final genre = sect['genre'];
      final genreName = engine.locale(genre);
      final development = sect['development'] ?? 0;

      // 成员数量（排除已离开的成员）
      final membersData = sect['membersData'];
      final activeMembers =
          membersData.values.where((m) => m['isAbsent'] != true).length;

      // 掌门信息
      final headId = sect['headId'];
      final head = GameData.getCharacter(headId);
      final headName = head['name'];
      final headRank = head['rank'];
      final headRankName = engine.locale('cultivationRank_$headRank');

      // 总堂位置
      final headquartersLocationId = sect['headquartersLocationId'];
      final headquarters = GameData.getLocation(headquartersLocationId);
      final headquartersName = headquarters['name'];

      desc.writeln(
          '- $sectName（$categoryName，$genreName，规模：$development级，成员：$activeMembers人，掌门：$headName（$headRankName），总堂位于$headquartersName）');
    }

    return desc.toString().trim();
  }

  static String getLocationDescription() {
    final desc = StringBuffer();

    final currentNation = engine.context.read<GameState>().currentNation;
    final currentTerrain = engine.context.read<GameState>().currentTerrain;
    final currentLocation = engine.context.read<GameState>().currentLocation;

    desc.writeln('国家：${currentNation != null ? currentNation!['name'] : '无'}');
    desc.writeln(
        '城市：${currentTerrain != null && currentTerrain.cityId != null ? currentTerrain.cityId : '无'}');
    desc.writeln(
        '坐标：[${currentTerrain != null ? '[${currentTerrain.left},${currentTerrain.top}](${' ${engine.locale(currentTerrain.data?['kind'])}'})' : '未知'}]');
    desc.writeln(
        '场景：${currentLocation != null ? currentLocation!['name'] : '无'}');

    return desc.toString().trim();
  }

  static String getCharacterDescription(dynamic character) {
    final desc = StringBuffer();

    // 1. 基本信息
    final name = character['name'];
    final isFemale = character['isFemale'];
    final gender = engine.locale(isFemale ? '女' : '男');
    desc.writeln('姓名：$name');
    desc.writeln('性别：$gender');

    // 年龄
    final age = engine.hetu
        .invoke('getCharacterAgeString', positionalArgs: [character]);
    desc.writeln('年龄：$age');

    // 等级和境界
    final level = character['level'];
    final rank = character['rank'];
    final rankName = engine.locale('cultivationRank_$rank');
    desc.writeln('等级：$level');
    desc.writeln('境界：$rankName');

    // 流派
    final cultivationFavor = character['cultivationFavor'];
    if (cultivationFavor != null) {
      final favorName = engine.locale(cultivationFavor);
      desc.writeln('流派：$favorName');
    }

    // 名声和恶名
    final fameString = engine.hetu
        .invoke('getCharacterFameString', positionalArgs: [character]);
    final infamyString = engine.hetu
        .invoke('getCharacterInfamyString', positionalArgs: [character]);
    desc.writeln('名声：$fameString');
    desc.writeln('恶名：$infamyString');

    desc.writeln();

    // 所属门派和职位
    final sectId = character['sectId'];
    if (sectId != null) {
      final sect = GameData.getSect(sectId);
      final sectName = sect['name'];
      desc.write('门派：$sectName');

      final titleId = character['titleId'];
      if (titleId != null) {
        final title = engine.locale(titleId);
        desc.writeln('职位：$title');
      }
    } else {
      desc.writeln('门派：无');
    }

    // 住宅所在城市
    final homeLocationId = character['homeLocationId'];
    if (homeLocationId != null) {
      final homeLocation = GameData.getLocation(homeLocationId);
      desc.writeln('家宅：${homeLocation['name']}');
    } else {
      desc.writeln('家宅：无固定住所');
    }

    desc.writeln();

    // 3. 性格与动机
    // 主要动机
    final motivations = character['motivations'];
    if (motivations != null && motivations.isNotEmpty) {
      final motivationNames =
          motivations.map((m) => engine.locale(m)).join('、');
      desc.writeln('动机：$motivationNames');
    }

    // 性格特质
    final personality = character['personality'];
    if (personality != null && personality.isNotEmpty) {
      desc.write('性格特质：');
      final traits = <String>[];
      for (final traitId in personality.keys) {
        final value = personality[traitId];
        if (value != null) {
          String traitDesc = '';
          if (value >= 25) {
            traitDesc = '非常${engine.locale(traitId)}';
          } else if (value >= 0) {
            traitDesc = '较为${engine.locale(traitId)}';
          } else if (value < 0) {
            traitDesc = '较不${engine.locale(traitId)}';
          } else if (value < 25) {
            traitDesc = '很不${engine.locale(traitId)}';
          }
          if (traitDesc.isNotEmpty) {
            traits.add(traitDesc);
          }
        }
      }
      desc.writeln(traits.join('、'));
    }

    desc.writeln();

    // 4. 人际关系

    // 家庭关系
    final familyRelationships = character['familyRelationships'];
    // 配偶
    final spouseIds = familyRelationships['spouseIds'];
    if (spouseIds != null && spouseIds.isNotEmpty) {
      final spouses =
          spouseIds.map((id) => GameData.getCharacter(id)['name']).join('、');
      desc.writeln('配偶：$spouses');
    }

    // 父母
    final fatherId = familyRelationships['fatherId'];
    final motherId = familyRelationships['motherId'];
    if (fatherId != null || motherId != null) {
      if (fatherId != null) {
        desc.writeln('父亲：${GameData.getCharacter(fatherId)['name']}');
      }
      if (motherId != null) {
        desc.writeln('母亲：${GameData.getCharacter(motherId)['name']}');
      }
    }

    // 子女
    final childIds = familyRelationships['childIds'];
    if (childIds != null && childIds.isNotEmpty) {
      final children =
          childIds.map((id) => GameData.getCharacter(id)['name']).join('、');
      desc.writeln('子女：$children');
    }

    // 兄弟姐妹
    final siblingIds = familyRelationships['siblingIds'];
    if (siblingIds != null && siblingIds.isNotEmpty) {
      final siblings =
          siblingIds.map((id) => GameData.getCharacter(id)['name']).join('、');
      desc.writeln('兄弟姐妹：$siblings');
    }

    // 师徒关系
    final shituRelationships = character['shituRelationships'];
    if (shituRelationships != null) {
      // 师父
      final shifuIds = shituRelationships['shifuIds'];
      if (shifuIds != null && shifuIds.isNotEmpty) {
        final shifus =
            shifuIds.map((id) => GameData.getCharacter(id)['name']).join('、');
        desc.writeln('师父：$shifus');
      }

      // 徒弟
      final tudiIds = shituRelationships['tudiIds'];
      if (tudiIds != null && tudiIds.isNotEmpty) {
        final tudis = tudiIds
            .map((id) => GameData.getCharacter(id)['name'])
            .take(5)
            .join('、');
        final more = tudiIds.length > 5 ? '等${tudiIds.length}人' : '';
        desc.writeln('徒弟：$tudis$more');
      }

      // 同门
      final tongmenIds = shituRelationships['tongmenIds'];
      if (tongmenIds != null && tongmenIds.isNotEmpty) {
        final tongmen = tongmenIds
            .map((id) => GameData.getCharacter(id)['name'])
            .take(5)
            .join('、');
        final more = tongmenIds.length > 5 ? '等${tongmenIds.length}人' : '';
        desc.writeln('同门：$tongmen$more');
      }
    }

    // 其他重要关系
    final romanceIds = character['romanceIds'];
    if (romanceIds.isNotEmpty) {
      final romanceNames =
          romanceIds.map((id) => GameData.getCharacter(id)['name']).join('、');
      desc.writeln('暧昧：$romanceNames');
    }

    final friendIds = character['friendIds'];
    if (friendIds.isNotEmpty) {
      final friendNames =
          friendIds.map((id) => GameData.getCharacter(id)['name']).join('、');
      desc.writeln('朋友：$friendNames');
    }

    final enemyIds = character['enemyIds'];
    if (enemyIds.isNotEmpty) {
      final enemyNames =
          enemyIds.map((id) => GameData.getCharacter(id)['name']).join('、');
      desc.writeln('敌人：$enemyNames');
    }

    return desc.toString().trim();
  }

  /// 获取精简版角色信息，用于作为用户角色信息提供给LLM
  static String getCharacterDescriptionSimple(dynamic character) {
    final desc = StringBuffer();

    // 基本信息
    final name = character['name'];
    final isFemale = character['isFemale'];
    final gender = engine.locale(isFemale ? '女' : '男');
    desc.writeln('姓名：$name');
    desc.writeln('性别：$gender');

    // 年龄
    final age = engine.hetu
        .invoke('getCharacterAgeString', positionalArgs: [character]);
    desc.writeln('年龄：$age');

    // 等级和境界
    final level = character['level'];
    final rank = character['rank'];
    final rankName = engine.locale('cultivationRank_$rank');
    desc.writeln('等级：$level');
    desc.writeln('境界：$rankName');

    // 所属门派和职位
    final sectId = character['sectId'];
    if (sectId != null) {
      final sect = GameData.getSect(sectId);
      final sectName = sect['name'];
      desc.write('门派：$sectName');

      final titleId = character['titleId'];
      if (titleId != null) {
        final title = engine.locale(titleId);
        desc.writeln('职位：$title');
      }
    } else {
      desc.writeln('门派：无');
    }

    return desc.toString().trim();
  }

  /// 获取两个角色之间的羁绊关系描述
  /// [subject] 是NPC角色，[target] 是用户角色
  /// 返回从NPC视角看待用户角色的关系描述
  static String getCharacterBondDescription(dynamic subject, dynamic target) {
    final desc = StringBuffer();

    // 获取NPC对用户的羁绊数据
    final bonds = subject['bonds'];
    final bond = bonds?[target['id']];

    assert(bond != null,
        'No bond data between ${subject['name']} and ${target['name']}');

    final score = bond['score'] ?? 0.0;

    // 好感度及其含义

    String attitudeDesc;
    if (score >= 40) {
      attitudeDesc = '你们关系非常亲密。';
    } else if (score >= 25) {
      attitudeDesc = '你们关系友好。';
    } else if (score >= 10) {
      attitudeDesc = '你对其有好感。';
    } else if (score <= -10) {
      attitudeDesc = '你对其有些反感。';
    } else if (score <= -25) {
      attitudeDesc = '你对其很讨厌。';
    } else if (score <= -40) {
      attitudeDesc = '你们是死敌。';
    } else {
      attitudeDesc = '你对其态度中立。';
    }
    desc.writeln(attitudeDesc);

    return desc.toString().trim();
  }

  /// 生成世界和主角信息，用于LLM的 system prompt
  static String getLlmChatSystemPrompt1() {
    // 世界设定
    final worldDesc = getWorldDescription();

    final prompt = kSystemPromptTemplate1.interpolate([worldDesc]);

    return prompt;
  }

  /// 生成对话场景设定，包含NPC信息、用户信息和关系描述，用于LLM的 system prompt
  static String getLlmChatSystemPrompt2(dynamic npc, {String? objective}) {
    // NPC角色设定
    final npcDesc = getCharacterDescription(npc);

    // 用户角色简要信息
    final heroDesc = getCharacterDescriptionSimple(hero);

    // 关系描述
    final bondDesc = getCharacterBondDescription(npc, hero);

    final objectiveDesc = objective?.isNotBlank == true ? objective : '只是闲聊。';

    final locationDesc = getLocationDescription();

    final prompt = kSystemPromptTemplate2.interpolate([
      npcDesc,
      heroDesc,
      bondDesc,
      objectiveDesc,
      locationDesc,
    ]);

    return prompt;
  }
}
