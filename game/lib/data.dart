import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:hetu_script/utils/collection.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:json5/json5.dart';
import 'package:samsara/samsara.dart';

import 'ui.dart';
import 'common.dart';
import 'engine.dart';
import 'scene/common.dart';

const kSeparateLine = '————————————————';

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
  static Map<String, dynamic> tilesData = {};
  static Map<String, dynamic> animationsData = {};
  static Map<String, dynamic> battleCardsData = {};
  static Map<String, dynamic> battleCardAffixesData = {};
  static Map<String, dynamic> statusEffectsData = {};
  static Map<String, dynamic> itemsData = {};
  static Map<String, dynamic> passivesData = {};
  // static Map<String, dynamic> supportSkillData = {};
  static Map<String, dynamic> skillTreeData = {};
  // static Map<String, dynamic> supportSkillTreeData = {};

  static Map<String, String> organizationCategoryNames = {};
  static Map<String, String> cultivationGenreNames = {};
  static Map<String, String> constructableSiteCategoryNames = {};

  /// 游戏本身的数据，包含角色，对象，等等。但这里不包括地图数据。
  static dynamic data;

  static late BuildContext context;

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static Future<void> init({required BuildContext flutterContext}) async {
    final tilesDataString =
        await rootBundle.loadString('assets/data/tiles.json5');
    tilesData = JSON5.parse(tilesDataString);

    // final cardsDataString =
    //     await rootBundle.loadString('assets/data/cards.json5');
    // cardsData = JSON5.parse(cardsDataString);

    final battleCardDataString =
        await rootBundle.loadString('assets/data/cards.json5');
    battleCardsData = JSON5.parse(battleCardDataString);

    final battleCardAffixDataString =
        await rootBundle.loadString('assets/data/card_affixes.json5');
    battleCardAffixesData = JSON5.parse(battleCardAffixDataString);

    final animationDataString =
        await rootBundle.loadString('assets/data/animation.json5');
    animationsData = JSON5.parse(animationDataString);

    final statusEffectDataString =
        await rootBundle.loadString('assets/data/status_effect.json5');
    statusEffectsData = JSON5.parse(statusEffectDataString);

    final itemsDataString =
        await rootBundle.loadString('assets/data/items.json5');
    itemsData = JSON5.parse(itemsDataString);

    final passiveDataString =
        await rootBundle.loadString('assets/data/passives.json5');
    passivesData = JSON5.parse(passiveDataString);

    // final supportSkillDataString =
    //     await rootBundle.loadString('assets/data/skills_support.json5');
    // supportSkillData = JSON5.parse(supportSkillDataString);

    final skillTreeDataString =
        await rootBundle.loadString('assets/data/skilltree.json5');
    skillTreeData = JSON5.parse(skillTreeDataString);

    // 拼接技能树节点的描述
    for (final skillTreeNodeData in skillTreeData.values) {
      final bool isAttribute = skillTreeNodeData['isAttribute'] == true;

      StringBuffer nodeDescription = StringBuffer();
      final nodeTitle = engine.locale(skillTreeNodeData['title']);
      nodeDescription.writeln('<bold yellow>$nodeTitle</>');
      nodeDescription.writeln(' ');
      String? comment = skillTreeNodeData['comment'];
      if (comment != null) {
        comment = engine.locale(comment);
        nodeDescription.writeln('<italic grey>$comment</>');
        nodeDescription.writeln(' ');
      }

      if (isAttribute) {
        String description = engine.locale(skillTreeNodeData['description']);
        nodeDescription.writeln('<lightBlue>$description</>');
      } else {
        final List nodeData = skillTreeNodeData['passives'];
        for (final passiveData in nodeData) {
          final dataId = passiveData['id'];
          final passiveRawData = GameData.passivesData[dataId];
          assert(passiveRawData != null);
          String description = engine.locale(passiveRawData['description']);
          if (passiveRawData['increment'] != null) {
            final level = passiveData['level'];
            final increment = passiveRawData['increment'];
            description = description.interpolate([level * increment]);
          }
          nodeDescription.writeln('<lightBlue>$description</>');
        }
      }

      final rankRequirement = skillTreeNodeData['rank'] ?? 0;
      if (rankRequirement > 0) {
        nodeDescription.writeln(' ');
        nodeDescription.writeln(
            '<grey>${engine.locale('requirement')}: ${engine.locale('cultivationRank_$rankRequirement')}</>');
      }

      skillTreeNodeData['description'] = nodeDescription.toString();
    }

    // final supportSkillTreeDataString =
    //     await rootBundle.loadString('assets/data/skilltree_support.json5');
    // supportSkillTreeData = JSON5.parse(supportSkillTreeDataString);

    for (final key in kOrganizationCategories) {
      organizationCategoryNames[key] = engine.locale(key);
    }
    for (final key in kMainCultivationGenres) {
      cultivationGenreNames[key] = engine.locale(key);
    }
    for (final key in kConstructableSiteCategories) {
      constructableSiteCategoryNames[key] = engine.locale(key);
    }

    context = flutterContext;
    engine.hetu.invoke('build', positionalArgs: [flutterContext]);

    _isInitted = true;
  }

  static Future<void> registerModuleEventHandlers() async {
    engine.hetu.invoke('main');

    for (final id in GameConfig.modules.keys) {
      if (GameConfig.modules[id]?['enabled'] == true) {
        final moduleConfig = {'version': kGameVersion};
        engine.hetu.invoke('main', module: id, positionalArgs: [moduleConfig]);
      }
    }
  }

  /// wether started a new game or load from a save.
  static bool isGameCreated = false;

  /// 将dart侧从json5载入的游戏数据保存到游戏存档中
  static void initGameData() {
    engine.hetu.invoke('init', namedArgs: {
      'itemsData': GameData.itemsData,
      'battleCardsData': GameData.battleCardsData,
      'battleCardAffixesData': GameData.battleCardAffixesData,
      'passivesData': GameData.passivesData,
    });
  }

  /// 每次执行 createGame 都会重置游戏内的 game 对象上的数据
  static Future<void> createGame(
    String worldId, {
    String? saveName,
    bool isEditorMode = false,
  }) async {
    engine.debug('创建新游戏：[$worldId]');

    worldIds.clear();
    currentWorldId = worldId;
    worldIds.add(worldId);

    data = engine.hetu.invoke('createGame', positionalArgs: [saveName]);

    initGameData();

    for (final id in GameConfig.modules.keys) {
      if (GameConfig.modules[id]?['enabled'] == true) {
        final moduleConfig = {'version': kGameVersion};
        engine.hetu.invoke('init', module: id, positionalArgs: [moduleConfig]);
      }
    }

    if (!isEditorMode) {
      await registerModuleEventHandlers();
    }

    isGameCreated = true;
  }

  static String? currentWorldId;
  static Set<String> worldIds = {};

  static Future<void> _loadGame({
    required dynamic gameData,
    required dynamic universeData,
    required dynamic historyData,
    bool isEditorMode = false,
  }) async {
    data = engine.hetu.invoke('loadGameFromJsonData', namedArgs: {
      'gameData': gameData,
      'universeData': universeData,
      'historyData': historyData,
    });

    currentWorldId = engine.hetu.invoke('getCurrentWorldId');

    final ids = engine.hetu.invoke('getWorldIds');

    for (final id in ids) {
      worldIds.add(id);
    }

    if (!isEditorMode) {
      await registerModuleEventHandlers();
    }

    isGameCreated = true;
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
    final gameData = jsonDecode(gameDataString);

    final universeSave = await File(savePath + kUniverseSaveFilePostfix).open();
    final universeDataString = utf8.decoder.convert(
        (await universeSave.read(await universeSave.length())).toList());
    await universeSave.close();
    final universeData = jsonDecode(universeDataString);

    final historySave = await File(savePath + kHistorySaveFilePostfix).open();
    final historyDataString = utf8.decoder
        .convert((await historySave.read(await historySave.length())).toList());
    await historySave.close();
    final historyData = jsonDecode(historyDataString);

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
    final gameData = jsonDecode(gameDataString);

    final universeSave = '$gameSave$kUniverseSaveFilePostfix';
    final universeDataString = await rootBundle.loadString(universeSave);
    final universeData = jsonDecode(universeDataString);

    final historySave = '$gameSave$kHistorySaveFilePostfix';
    final historyDataString = await rootBundle.loadString(historySave);
    final historyData = jsonDecode(historyDataString);

    await _loadGame(
      gameData: gameData,
      universeData: universeData,
      historyData: historyData,
      isEditorMode: isEditorMode,
    );
  }

  static CustomGameCard getSiteCard(dynamic siteData) {
    final id = siteData['id'];
    final card = CustomGameCard(
      id: id,
      deckId: id,
      data: siteData,
      anchor: Anchor.center,
      borderRadius: 15.0,
      illustrationSpriteId: siteData['image'],
      spriteId: 'location/site/site_frame.png',
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
    );
    return card;
  }

  static CustomGameCard getExitSiteCard({String? spriteId}) {
    spriteId ??= 'exit_card';
    final exit = CustomGameCard(
      id: 'exit',
      deckId: 'exit',
      borderRadius: 20.0,
      illustrationSpriteId: 'location/site/$spriteId.png',
      spriteId: 'location/site/site_frame.png',
      title: engine.locale('exit'),
      titleConfig: GameUI.siteTitleConfig,
      showTitle: true,
      position: GameUI.siteExitCardPositon,
      size: GameUI.siteCardSize,
      enablePreview: true,
      focusOnPreviewing: true,
      focusedPriority: kSiteCardPriority,
      focusedSize: GameUI.siteCardFocusedSize,
      focusedOffset: Vector2(
          -(GameUI.siteCardFocusedSize.x - GameUI.siteCardSize.x) / 2,
          GameUI.siteCardSize.y - GameUI.siteCardFocusedSize.y),
    );
    return exit;
  }

  static String getDescriptiomFromItemData(dynamic itemData,
      {bool isDetailed = false, dynamic characterData}) {
    final description = StringBuffer();
    final title = itemData['name'];
    final rarity = itemData['rarity'];
    final category = itemData['category'];

    final level = itemData['level'];
    final levelString =
        level != null ? '(${engine.locale('level')}: $level)' : '';

    final titleString = isDetailed
        ? '<bold $rarity t7>$title $levelString</>'
        : '<bold $rarity t7>$title</>';
    final rarityString =
        '<grey>${engine.locale('rarity')}: </><$rarity>${engine.locale(rarity)}, </>';
    final categoryString =
        '<grey>${engine.locale('category')}: ${engine.locale(category)}</>';

    description.writeln(titleString);
    description.writeln('$rarityString$categoryString');

    final affixList = itemData['affixes'];
    if (affixList is List) {
      assert(affixList.isNotEmpty);
      description.writeln(kSeparateLine);
      for (var i = 0; i < affixList.length; i++) {
        final passiveData = affixList[i];
        String descriptionString = engine.locale(passiveData['description']);
        num? value = passiveData['value'];
        if (value != null) {
          descriptionString = descriptionString.interpolate([value]);
        }
        final level = passiveData['level'];
        final levelString =
            level != null ? ' (${engine.locale('level')}: $level)' : '';
        if (i == 0) {
          description.writeln(descriptionString);
          // if (affixList.length > 1) {
          //   description.writeln(kSepareteLine);
          // }
        } else {
          if (isDetailed) {
            description
                .writeln('<lightBlue>$descriptionString $levelString</>');
          } else {
            description.writeln('<lightBlue>$descriptionString</>');
          }
        }
      }
    }

    description.writeln(kSeparateLine);
    final flavortext = itemData['flavortext'];
    if (flavortext != null) {
      description.writeln('<grey>$flavortext</>');
    }

    if (itemData['equippedPosition'] == null) {
      switch (category) {
        case 'equipment':
          description.writeln('<green>${engine.locale('equippableHint')}</>');
        case 'consumable':
          description.writeln('<green>${engine.locale('usableHint')}</>');
        case 'quest':
          description.writeln('<yellow>${engine.locale('questItem')}</>');
      }
    }

    final out = description.toString().trim();
    return out;
  }

  /// 返回值是一个元祖，第一个字符串是卡面描述，第二个是详细描述
  static (String, String) getDescriptionFromCardData(dynamic cardData,
      {bool isDetailed = false, dynamic characterData}) {
    final List affixes = cardData['affixes'];
    final int cardLevel = cardData['level'];
    final int cardRank = cardData['rank'];
    final String title = cardData['name'];
    final bool isIdentified = cardData['isIdentified'] == true;

    assert(affixes.isNotEmpty);
    final mainAffix = affixes[0];

    final description = StringBuffer();
    final extraDescription = StringBuffer();

    final levelPrefix = engine.locale('level');

    String? requirementString;

    final titleString = isDetailed
        ? '<bold rank$cardRank t7>$title ($levelPrefix $cardLevel)</>'
        : '<bold rank$cardRank t7>$title</>';
    final rankString =
        '<grey>${engine.locale('cultivationRank')}:</> <rank$cardRank>${engine.locale('cultivationRank_$cardRank')}, </>';
    final genreString =
        '<grey>${engine.locale('genre')}: ${engine.locale(mainAffix['genre'])}, </>';
    final categoryString =
        '<grey>${engine.locale('category')}: ${engine.locale(cardData['category'])}</>';

    extraDescription.writeln(titleString);
    extraDescription.writeln('$rankString$genreString$categoryString');
    extraDescription.writeln(kSeparateLine);

    final Map<String, String> explanations = {};
    for (final affix in affixes) {
      final affixDescriptionRaw = engine.locale(affix['description']);
      final affixDescription =
          affixDescriptionRaw.interpolate(affix['value']).split(RegExp('\n'));

      if (isIdentified) {
        final bool isMainAffix = affix['isMain'] ?? false;

        if (isMainAffix && characterData != null) {
          final String? equipment = affix['equipment'];
          if (equipment != null) {
            if (characterData['passives']['equipment_$equipment'] == null) {
              requirementString =
                  '<red>${engine.locale('equipment_requirement')}: ${engine.locale(equipment)}</>';
            }
          }
        }

        for (var line in affixDescription) {
          if (isMainAffix) {
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

        final Iterable tags = affix['tags'];
        if (tags.isNotEmpty) {
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
      extraDescription.writeln(kSeparateLine);
      if (isDetailed) {
        for (final tag in explanations.keys) {
          extraDescription.writeln(explanations[tag]);
        }
      } else {
        extraDescription
            .writeln('<grey>${engine.locale('explanation_hint')}</>');
      }
    }

    if (isIdentified && requirementString != null) {
      extraDescription.writeln(requirementString);
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

  static CustomGameCard createBattleCardFromData(dynamic data,
      {bool deepCopyData = false}) {
    assert(data != null && data['id'] != null, 'Invalid battle card data!');
    assert(_isInitted, 'Game data is not loaded yet!');
    assert(GameUI.isInitted, 'Game UI is not initted yet!');

    final cardData = deepCopyData ? deepCopy(data) : data;

    final String id = cardData['id'];
    final String image = cardData['image'];
    final String title = cardData['name'];
    final int cardRank = cardData['rank'];

    final (description, extraDescription) =
        getDescriptionFromCardData(cardData);

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
}
