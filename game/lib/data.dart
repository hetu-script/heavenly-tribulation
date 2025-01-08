import 'dart:io';
import 'dart:convert';
// import 'dart:math' as math;

// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:hetu_script/utils/collection.dart';
// import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:samsara/cardgame/cardgame.dart';
import 'package:json5/json5.dart';
import 'package:samsara/samsara.dart';
// import 'package:samsara/utils/json.dart';
// import 'package:hetu_script/utils/uid.dart';

import 'ui.dart';
import 'common.dart';
import 'engine.dart';
import 'scene/common.dart';

const kSepareteLine = '——————————————————';

/// 游戏数据，大部分以JSON或者Hetu Struct形式保存
/// 这个类是纯静态类，方法都是有关读取和保存的
/// 游戏逻辑等操作这些数据的代码另外写在logic目录下的文件中
abstract class GameData {
  static Map<String, dynamic> editorToolItemsData = {};
  static Map<String, dynamic> animationsData = {};
  static Map<String, dynamic> battleCardData = {};
  static Map<String, dynamic> battleCardAffixesData = {};
  static Map<String, dynamic> statusEffectsData = {};
  static Map<String, dynamic> itemsData = {};
  static Map<String, dynamic> passiveData = {};
  // static Map<String, dynamic> supportSkillData = {};
  static Map<String, dynamic> skillTreeData = {};
  // static Map<String, dynamic> supportSkillTreeData = {};

  static Map<String, String> organizationCategoryNames = {};
  static Map<String, String> cultivationGenreNames = {};
  static Map<String, String> constructableSiteCategoryNames = {};

  /// 游戏本身的数据，包含角色，对象，等等。但这里不包括地图数据。
  static dynamic data;

  static BuildContext? ctx;

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static Future<void> init(BuildContext context) async {
    final editorToolItemsString =
        await rootBundle.loadString('assets/data/editor_tools.json5');
    editorToolItemsData = JSON5.parse(editorToolItemsString);

    // final cardsDataString =
    //     await rootBundle.loadString('assets/data/cards.json5');
    // cardsData = JSON5.parse(cardsDataString);

    final battleCardDataString =
        await rootBundle.loadString('assets/data/cards.json5');
    battleCardData = JSON5.parse(battleCardDataString);

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
    passiveData = JSON5.parse(passiveDataString);

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
          final passiveRawData = GameData.passiveData[dataId];
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

    ctx = context;
    engine.hetu.invoke('build', positionalArgs: [context]);

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
  static void loadGameData() {
    engine.hetu.invoke('init', namedArgs: {
      'itemsData': GameData.itemsData,
      'battleCardData': GameData.battleCardData,
      'battleCardAffixesData': GameData.battleCardAffixesData,
      // 'skillTreeData': GameData.skillTreeData,
      // 'supportSkillTreeData': GameData.supportSkillTreeData,
      'passiveData': GameData.passiveData,
      // 'supportSkillData': GameData.supportSkillData,
    });
  }

  static Future<void> newGame(String worldId, [String? saveName]) async {
    worldIds.clear();
    currentWorldId = worldId;
    worldIds.add(worldId);

    data = engine.hetu.invoke('newGame', positionalArgs: [saveName]);

    loadGameData();

    for (final id in GameConfig.modules.keys) {
      if (GameConfig.modules[id]?['enabled'] == true) {
        final moduleConfig = {'version': kGameVersion};
        engine.hetu.invoke('init', module: id, positionalArgs: [moduleConfig]);
      }
    }

    await registerModuleEventHandlers();

    isGameCreated = true;
  }

  static String? currentWorldId;
  static Set<String> worldIds = {};

  static Future<void> _loadGame({
    required dynamic gameData,
    required dynamic universeData,
    required dynamic historyData,
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

    await registerModuleEventHandlers();

    isGameCreated = true;
  }

  static Future<void> loadGame(String savePath,
      {bool isEditorMode = false}) async {
    worldIds.clear();
    currentWorldId = null;
    engine.info('从 [$savePath] 载入游戏存档。');
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
    );
  }

  static Future<void> loadPresetSave(String filename) async {
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
      {bool isDetailed = false}) {
    final description = StringBuffer();
    final title = itemData['name'];
    final rarity = itemData['rarity'];
    final category = itemData['category'];
    final level = itemData['level'];

    final titleString = '<bold $rarity t5>$title</>';
    final rarityString =
        '<grey>${engine.locale('rarity')}: </><$rarity>${engine.locale(rarity)}, </>';
    final categoryString =
        '<grey>${engine.locale('category')}: ${engine.locale(category)}, </>';
    final levelString = '<grey>${engine.locale('level')}: $level</>';

    description.writeln(titleString);
    description.writeln('$rarityString$categoryString$levelString');

    final affixList = itemData['affixes'];
    if (affixList is List) {
      assert(affixList.isNotEmpty);
      description.writeln(kSepareteLine);
      for (var i = 0; i < affixList.length; i++) {
        final passiveData = affixList[i];
        String descriptionString = engine.locale(passiveData['description']);
        num? value = passiveData['value'];
        if (value != null) {
          descriptionString = descriptionString.interpolate([value]);
        }
        if (i == 0) {
          description.writeln(descriptionString);
          // if (affixList.length > 1) {
          //   description.writeln(kSepareteLine);
          // }
        } else {
          description.writeln('<lightBlue>$descriptionString</>');
        }
      }
    }

    description.writeln(kSepareteLine);
    final flavorText = itemData['flavorText'];
    if (flavorText != null) {
      description.writeln('<grey>${engine.locale(flavorText)}</>');
    }
    final out = description.toString().trim();
    return out;
  }

  /// 返回值是一个元祖，第一个字符串是卡面描述，第二个是详细描述，第三个bool是角色是否可用此卡牌
  /// 如果没有传递characterData，则永远返回true
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
        ? '<bold rank$cardRank t5>$title ($levelPrefix $cardLevel)</>'
        : '<bold rank$cardRank t5>$title</>';
    final rankString =
        '<grey>${engine.locale('cultivationRank')}:</> <rank$cardRank>${engine.locale('cultivationRank_$cardRank')}, </>';
    final genreString =
        '<grey>${engine.locale('genre')}: ${engine.locale(mainAffix['genre'])}, </>';
    final categoryString =
        '<grey>${engine.locale('category')}: ${engine.locale(cardData['category'])}</>';

    extraDescription.writeln(titleString);
    extraDescription.writeln('$rankString$genreString$categoryString');
    extraDescription.writeln(kSepareteLine);

    final Map<String, String> explanations = {};
    for (final affix in affixes) {
      final affixDescriptionRaw = engine.locale(affix['description']);
      assert(affix['value'] is List);
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
            if (isDetailed) {
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
      description.writeln('<red>${engine.locale('identify_hint')}</>');
      extraDescription.writeln('<red>${engine.locale('identify_hint')}</>');
    }

    if (explanations.isNotEmpty) {
      extraDescription.writeln(kSepareteLine);
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
      preferredSize: GameUI.libraryCardSize,
      spriteId: 'battlecard/border4.png',
      illustrationRelativePaddings:
          const EdgeInsets.fromLTRB(0.046, 0.1225, 0.046, 0.214),
      illustrationSpriteId: image,
      title: title,
      titleRelativePaddings:
          const EdgeInsets.fromLTRB(0.16, 0.046, 0.16, 0.8775),
      titleConfig: ScreenTextConfig(
        anchor: Anchor.center,
        outlined: true,
        textStyle: TextStyle(
          color: getColorFromRank(cardRank),
          fontFamily: GameUI.fontFamily,
          fontSize: 15.0,
        ),
      ),
      descriptionRelativePaddings:
          const EdgeInsets.fromLTRB(0.08, 0.735, 0.08, 0.08),
      descriptionConfig: const ScreenTextConfig(
        anchor: Anchor.center,
        textStyle: TextStyle(
          fontFamily: 'NotoSansMono',
          // fontFamily: GameUI.fontFamily,
          fontSize: 11.0,
          color: Colors.black,
        ),
        overflow: ScreenTextOverflow.wordwrap,
      ),
      description: description.toString(),
      enablePreview: true,
    );
  }

  // static GameCard getBattleCardById(String cardId) {
  //   assert(_isInitted, 'Game data is not loaded yet!');
  //   assert(GameUI.isInitted, 'Game UI is not initted yet!');

  //   final data = cardsData[cardId];
  //   assert(data != null, 'Failed to load card data: [$cardId]');
  //   final String id = data['id'];

  //   return GameCard(
  //     id: id,
  //     deckId: id,
  //     script: id,
  //     data: data,
  //     // title: data['title'][engine.locale.languageId],
  //     // description: data['rules'][engine.locale.languageId],
  //     size: GameUI.libraryCardSize,
  //     spriteId: 'cultivation/library/$id.png',
  //     // focusedPriority: 1000,
  //     // illustrationSpriteId: 'cards/illustration/$id.png',
  //     // illustrationHeightRatio: kCardIllustrationHeightRatio,
  //     // showTitle: true,
  //     // titleStyle: const ScreenTextConfig(
  //     //   colorTheme: ScreenTextColorTheme.light,
  //     //   anchor: Anchor.topCenter,
  //     //   padding: EdgeInsets.only(
  //     //       top: kLibraryCardHeight * kCardIllustrationHeightRatio),
  //     //   textStyle: TextStyle(fontSize: 16),
  //     // ),
  //     // showDescription: true,
  //     // descriptionStyle: const ScreenTextConfig(
  //     //   colorTheme: ScreenTextColorTheme.dark,
  //     // ),
  //   );
  // }
}

abstract class PrebuildDecks {
  // static List<GameCard> _getCards(List<String> cardIds) {
  //   return cardIds.map((e) => GameData.getBattleCard(e)).toList();
  // }

  // static const List<String> _basic = [
  //   'defend_normal',
  //   'attack_normal',
  //   'attack_normal',
  //   'attack_normal',
  // ];

  // static const List<String> _blade_1 = [
  //   'defend_normal',
  //   'blade_4',
  //   'blade_3',
  //   'blade_1',
  // ];

  // static const List<String> _blade_2 = [
  //   'blade_4',
  //   'blade_6',
  //   'blade_7',
  //   'blade_8',
  // ];

  // static const List<String> _blade_3 = [
  //   'blade_9',
  //   'blade_10',
  //   'blade_7',
  //   'blade_8',
  // ];

  // static const _allDecks = [
  //   _basic,
  //   ..._bladeDecks,
  // ];

  // static const _bladeDecks = [
  //   _blade_1,
  //   _blade_2,
  //   _blade_3,
  // ];

  // static List<GameCard> get random => _getCards(_allDecks.random());
  // static List<GameCard> get randomBlade => _getCards(_bladeDecks.random());

  // static List<GameCard> get basic => _getCards(_basic);
  // static List<GameCard> get blade1 => _getCards(_blade_1);
  // static List<GameCard> get blade2 => _getCards(_blade_2);
  // static List<GameCard> get blade3 => _getCards(_blade_3);
}
