import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hetu_script/utils/collection.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:json5/json5.dart';
import 'package:samsara/samsara.dart';

import 'ui.dart';
import 'common.dart';
import '../engine.dart';
import '../scene/common.dart';
import 'logic/logic.dart';

const _kSkinAnimationWidth = 288.0;
const _kSkinAnimationHeight = 112.0;
const _kSkinAnimationStepTime1 = 0.1;
const _kSkinAnimationStepTime2 = 0.7;

const _kActionIds = [
  'defeat',
  'dodge',
  'hit',
  'melee_startup',
  'melee_recovery',
  'attack_bow',
  'attack_kick',
  'attack_punch',
  'attack_sabre',
  'attack_spear',
  'attack_sword',
  'attack_staff',
  'attack_spell',
  'attack_spell_recovery',
  'buff_kick',
  'buff_punch',
  'buff_sabre',
  'buff_spear',
  'buff_sword',
  'buff_staff',
  'buff_spell',
];

abstract class GameMusic {
  static const menu = 'chinese-oriental-tune-06-12062.mp3';
  static const worldmap = 'ghuzheng-fantasie-23506.mp3';
  static const location = 'vietnam-bamboo-flute-143601.mp3';
  static const battle = 'war-drums-173853.mp3';
}

abstract class GameSound {
  static const buff = 'buffer-spell-88994.mp3';
  static const debuff = 'bone-break-8-218516.mp3';
  static const block = 'shield-block-shortsword-143940.mp3';
  static const enhance = 'dagger_drawn2-89025.mp3';
  static const fire = 'lighting-a-fire-14421.mp3';

  static const craft = 'hammer-hitting-an-anvil-25390.mp3';
  static const cardDealt = 'playing-cards-being-delt-29099.mp3';
  static const cardDealt2 = 'card-sounds-35956.mp3';
  static const cardFlipping = 'card-flipping-75622.mp3';
}

/// 游戏数据，大部分以JSON或者Hetu Struct形式保存
/// 这个类是纯静态类，方法都是有关读取和保存的
/// 游戏逻辑等操作这些数据的代码另外写在logic目录下的文件中
abstract class GameData {
  static final Map<String, dynamic> animations = {};
  static final Map<String, SpriteSheet> spriteSheets = {};
  static final Map<String, SpriteAnimationWithTicker> _cachedAnimations = {};

  static final Map<String, dynamic> tiles = {};
  static final Map<String, dynamic> mapComponents = {};
  static final Map<String, dynamic> battleCards = {};
  static final Map<String, dynamic> battleCardAffixes = {};
  static final Map<String, dynamic> statusEffects = {};
  static final Map<String, dynamic> prototypes = {};
  static final Map<String, dynamic> passives = {};
  static final Map<String, dynamic> passiveTree = {};
  static final Map<String, dynamic> craftables = {};
  static final Map<String, dynamic> journals = {};

  static final Map<String, dynamic> maps = {};

  static final Map<String, (String, String)> attributeNames = {};
  static final Map<String, String> organizationCategoryNames = {};
  static final Map<String, String> cultivationGenreNames = {};
  static final Map<String, String> cityKindNames = {};
  static final Map<String, String> siteKindNames = {};

  static Set<String> worldIds = {};

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  /// 游戏本身的数据，包含角色，对象，以及地图和时间线。
  static dynamic game, universe, world, history, hero;

  static math.Random random = math.Random();

  static dynamic getTerrain(int index) {
    final terrain = GameData.world['terrains'][index];
    assert(terrain != null, 'Terrain not found, id: $index');
    return terrain;
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

  static dynamic getOrganization(dynamic id) {
    final organization = GameData.game['organizations'][id];
    assert(organization != null, 'Organization not found, id: $id');
    return organization;
  }

  static Future<void> init() async {
    if (_isInitted) {
      throw 'Game data is already initted!';
    }
    if (!engine.isInitted) {
      throw 'Game engine is not initted yet!';
    }

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
            final Map skinAnimData = deepCopy(templateData);
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
    // animations.addAll(animationsData);

    final spriteSheetDataString =
        await rootBundle.loadString('assets/data/sprite_sheet.json5');
    final spriteSheetsData = JSON5.parse(spriteSheetDataString);
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

    final tilesDataString =
        await rootBundle.loadString('assets/data/tiles.json5');
    tiles.addAll(JSON5.parse(tilesDataString));

    final mapComponentsDataString =
        await rootBundle.loadString('assets/data/map_components.json5');
    mapComponents.addAll(JSON5.parse(mapComponentsDataString));

    final battleCardDataString =
        await rootBundle.loadString('assets/data/cards.json5');
    battleCards.addAll(JSON5.parse(battleCardDataString));

    final battleCardAffixDataString =
        await rootBundle.loadString('assets/data/card_affixes.json5');
    battleCardAffixes.addAll(JSON5.parse(battleCardAffixDataString));

    final statusEffectDataString =
        await rootBundle.loadString('assets/data/status_effect.json5');
    statusEffects.addAll(JSON5.parse(statusEffectDataString));

    final itemsDataString =
        await rootBundle.loadString('assets/data/items.json5');
    prototypes.addAll(JSON5.parse(itemsDataString));

    final passiveDataString =
        await rootBundle.loadString('assets/data/passives.json5');
    passives.addAll(JSON5.parse(passiveDataString));

    // final supportSkillDataString =
    //     await rootBundle.loadString('assets/data/skills_support.json5');
    // supportSkillData = JSON5.parse(supportSkillDataString);

    final passiveTreeDataString =
        await rootBundle.loadString('assets/data/passive_tree.json5');
    passiveTree.addAll(JSON5.parse(passiveTreeDataString));

    final craftablesDataString =
        await rootBundle.loadString('assets/data/craftables.json5');
    craftables.addAll(JSON5.parse(craftablesDataString));

    final journalsDataString =
        await rootBundle.loadString('assets/data/journals.json5');
    journals.addAll(JSON5.parse(journalsDataString));

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

    final mapsDataString =
        await rootBundle.loadString('assets/data/maps.json5');
    maps.addAll(JSON5.parse(mapsDataString));

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
    engine.debug('初始化当前载入的模组...');

    engine.hetu.invoke(
      'init',
      namedArgs: {
        'prototypesData': GameData.prototypes,
        'craftablesData': GameData.craftables,
        'battleCardsData': GameData.battleCards,
        'battleCardAffixesData': GameData.battleCardAffixes,
        'passivesData': GameData.passives,
        'journalsData': GameData.journals,
        'mapsData': GameData.maps,
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
    String? seedString,
    bool enableTutorial = true,
    bool isEditorMode = false,
  }) async {
    worldIds.clear();

    engine.hetu.invoke('createGame', positionalArgs: [
      saveName
    ], namedArgs: {
      'seedString': seedString,
      'enableTutorial': enableTutorial,
    });

    game = engine.hetu.fetch('game');
    universe = engine.hetu.fetch('universe');
    history = engine.hetu.fetch('history');
    hero = engine.hetu.fetch('hero');
    random = engine.hetu.fetch('random');

    initGameData();

    if (!isEditorMode) {
      await registerModuleEventHandlers();
    }
  }

  static Future<void> _loadGame({
    required dynamic gameData,
    required dynamic universeData,
    required dynamic historyData,
    bool isEditorMode = false,
  }) async {
    engine.hetu.invoke('loadGameFromJsonData', namedArgs: {
      'gameData': gameData,
      'universeData': universeData,
      'historyData': historyData,
    });

    worldIds.clear();
    final ids = engine.hetu.invoke('getWorldIds');
    worldIds.addAll(ids);

    if (!isEditorMode) {
      await registerModuleEventHandlers();
    }

    game = engine.hetu.fetch('game');
    universe = engine.hetu.fetch('universe');
    history = engine.hetu.fetch('history');
    hero = engine.hetu.fetch('hero');
    random = engine.hetu.fetch('random');
  }

  /// 从存档中读取游戏数据
  /// 在这一步中，并不会创建地图对应的场景
  static Future<void> loadGame(String savePath,
      {bool isEditorMode = false}) async {
    worldIds.clear();
    engine.debug('从 [$savePath] 载入游戏存档。');
    final gameSave = await File(savePath).open();
    final gameDataString = utf8.decoder
        .convert((await gameSave.read(await gameSave.length())).toList());
    await gameSave.close();
    final gameData = json5Decode(gameDataString);

    final universeSave = await File(savePath + kUniverseSaveFilePostfix).open();
    final universeDataString = utf8.decoder.convert(
        (await universeSave.read(await universeSave.length())).toList());
    await universeSave.close();
    final universeData = json5Decode(universeDataString);

    final historySave = await File(savePath + kHistorySaveFilePostfix).open();
    final historyDataString = utf8.decoder
        .convert((await historySave.read(await historySave.length())).toList());
    await historySave.close();
    final historyData = json5Decode(historyDataString);

    await _loadGame(
      gameData: gameData,
      universeData: universeData,
      historyData: historyData,
      isEditorMode: isEditorMode,
    );
  }

  static Future<void> loadPreset(String filename,
      {bool isEditorMode = false}) async {
    engine.debug('从 [$filename] 载入游戏预设。');

    final gameSave = 'assets/save/$filename$kGameSaveFileExtension';
    final gameDataString = await rootBundle.loadString(gameSave);
    final gameData = json5Decode(gameDataString);

    final universeSave = '$gameSave$kUniverseSaveFilePostfix';
    final universeDataString = await rootBundle.loadString(universeSave);
    final universeData = json5Decode(universeDataString);

    final historySave = '$gameSave$kHistorySaveFilePostfix';
    final historyDataString = await rootBundle.loadString(historySave);
    final historyData = json5Decode(historyDataString);

    await _loadGame(
      gameData: gameData,
      universeData: universeData,
      historyData: historyData,
      isEditorMode: isEditorMode,
    );
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

  static CustomGameCard getSiteCard(dynamic siteData) {
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

  static String getPassivesDescription([dynamic character]) {
    character ??= GameData.hero;
    final builder = StringBuffer();

    final passivesDescription = _getPassivesDescription(character['passives']);
    final potionPassivesDescription =
        _getPassivesDescription(character['potionPassives']);

    builder.writeln(
        '${engine.locale('passivetree_passives_description_title')}\n ');
    builder.writeln(passivesDescription);
    builder.writeln(' ');

    builder.writeln(
        '${engine.locale('passivetree_potion_passives_description_title')}\n ');
    builder.writeln(potionPassivesDescription);

    return builder.toString();
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
    final title = itemData['name'];
    final rarity = itemData['rarity'];
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
    final categoryString =
        '<grey>, ${engine.locale('category')}: ${engine.locale(category)}</>';
    String priceString = '';
    if (isUntradable && isInventory) {
      priceString = '<grey>, </><red>${engine.locale('untradable')}</>';
    }

    description.writeln(titleString);
    if (engine.config.debugMode) {
      description.writeln('<grey>[${itemData['id']}]</> - press `c` to copy');
    }
    description.writeln('$rarityString$categoryString$priceString');

    // description.writeln(kSeparateLine);
    final flavortext = itemData['flavortext'];
    if (flavortext != null) {
      description.writeln('<lightGreen>$flavortext</>');
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
      final price = GameLogic.calculateItemPrice(
        itemData,
        priceFactor: priceFactor,
        isSell: isSell,
      );
      description.writeln(
          '<yellow>${engine.locale('price')}: $price ${engine.locale(useShard ? 'shard' : 'money')}</>');
      if (engine.config.debugMode) {
        description.writeln(
            '<grey>${engine.locale('basePrice')}: ${itemData['price']}</>');
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

    final cardData = deepCopyData ? deepCopy(data) : data;

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
          fontFamily: GameUI.fontFamily,
          fontSize: 14.0,
        ),
      ),
      descriptionRelativePaddings:
          const EdgeInsets.fromLTRB(0.108, 0.735, 0.108, 0.08),
      descriptionConfig: const ScreenTextConfig(
        anchor: Anchor.center,
        textStyle: TextStyle(
          fontFamily: 'NotoSansMono',
          // fontFamily: GameUI.fontFamily,
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
    final timeLimitDays = quest['timeLimitDays'];
    desc.writeln('<bold rank$difficulty t7>${engine.locale('quest_$kind')}</>');
    desc.writeln(
        '${engine.locale('difficulty')}: <rank$difficulty>${engine.locale(difficultyLable)}</>');
    desc.writeln(
        '${engine.locale('timeLimit')}: <yellow>$timeLimitDays ${engine.locale('ageDay')}</>');

    return desc.toString();
  }

  static String getQuestBudgetDescription(dynamic budget) {
    final desc = StringBuffer();
    final kind = budget['kind'];
    final amount = budget['amount'];
    desc.writeln('<lightGreen>${engine.locale('budget')}: </>');
    desc.writeln('<lightGreen>$amount ${engine.locale(kind)}</>');
    return desc.toString();
  }

  static String getQuestRewardDescription(List reward) {
    final desc = StringBuffer();
    desc.writeln('<lightGreen>${engine.locale('reward')}: </>');
    for (final itemInfo in reward) {
      if (itemInfo['type'] == 'material') {
        final kind = itemInfo['kind'];
        final amount = itemInfo['amount'];
        desc.writeln('<lightGreen>$amount ${engine.locale(kind)}</>');
      }
    }
    return desc.toString();
  }

  static String getBountyDetailDescription(dynamic quest) {
    final desc = StringBuffer();

    final brief = GameData.getQuestBriefDescription(quest);
    desc.write(brief);
    desc.writeln(kSeparateLine);
    desc.writeln('${engine.locale('quest_content')}:');

    final kind = quest['kind'];
    assert(kQuestKinds.contains(kind), 'Unknown bounty kind: $kind');
    switch (kind) {
      case 'purchase_material':
        desc.writeln(engine.locale('quest_purchase_material_description',
            interpolations: quest['interpolations']));
        desc.writeln(kSeparateLine);
        final budget = getQuestBudgetDescription(quest['budget']);
        desc.writeln(budget);
      case 'purchase_item':
        desc.writeln(engine.locale('quest_purchase_item_description',
            interpolations: quest['interpolations']));
        desc.writeln(kSeparateLine);
        final budget = getQuestBudgetDescription(quest['budget']);
        desc.writeln(budget);
      case 'deliver_material':
        desc.writeln(engine.locale('quest_deliver_material_description',
            interpolations: quest['interpolations']));
        desc.writeln(kSeparateLine);
        final reward = getQuestRewardDescription(quest['reward']);
        desc.writeln(reward);
      case 'deliver_item':
        desc.writeln(engine.locale('quest_deliver_item_description',
            interpolations: quest['interpolations']));
        desc.writeln(kSeparateLine);
        final reward = getQuestRewardDescription(quest['reward']);
        desc.writeln(reward);
      case 'escort':
        desc.writeln(engine.locale('quest_escort_description',
            interpolations: quest['interpolations']));
        desc.writeln(kSeparateLine);
        final reward = getQuestRewardDescription(quest['reward']);
        desc.writeln(reward);
      case 'discover_location':
        final targetLocationId = quest['targetLocationId'];
        final targetLocation = GameData.getLocation(targetLocationId);
        final organizationId = quest['organizationId'];
        final organization = GameData.getOrganization(organizationId);
        desc.writeln(engine
            .locale('quest_discover_location_description', interpolations: [
          organization['name'],
          targetLocation['name'],
        ]));
        desc.writeln(kSeparateLine);
        final reward = getQuestRewardDescription(quest['reward']);
        desc.writeln(reward);
    }

    return desc.toString();
  }
}
