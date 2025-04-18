import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/state/states.dart';
import 'package:provider/provider.dart';
import 'package:hetu_script/utils/math.dart' as math;
import 'package:samsara/samsara.dart';

import '../common.dart';
import '../widgets/dialog/timeflow.dart';
import '../scene/game_dialog/selection_dialog.dart';
import '../engine.dart';
import '../scene/game_dialog/game_dialog_content.dart';
import '../widgets/dialog/select_menu.dart';
import '../widgets/dialog/input_slider.dart';
import '../scene/common.dart';
import 'data.dart';

abstract class GameLogic {
  static bool truthy(dynamic value) => engine.hetu.interpreter.truthy(value);

  static int ticksOfYear = 0;
  static int ticksOfMonth = 0;
  static int ticksOfDay = 0;
  static int year = 0;
  static int month = 0;
  static int day = 0;
  static String timeOfDay = '';

  static void calculateTimestamp() {
    final int timestamp = GameData.gameData['timestamp'];
    ticksOfYear = (timestamp % kTicksPerYear) + 1;
    ticksOfMonth = (timestamp % kTicksPerMonth) + 1;
    ticksOfDay = (timestamp % kTicksPerDay) + 1;
    year = (timestamp ~/ kTicksPerYear) + 1;
    month = (ticksOfYear ~/ kTicksPerMonth) + 1;
    day = (ticksOfMonth ~/ kTicksPerDay) + 1;
    timeOfDay = kTimeOfDay[ticksOfDay]!;

    engine.info('游戏时间: [$year年$month月$day日$timeOfDay]');
  }

  static int generateZone(dynamic world) {
    int count = 0;
    List indexed = [];

    void updateTileZone2(dynamic tile, dynamic world, [dynamic zone]) {
      if (tile['spriteIndex'] == null) return;
      if (tile['zoneId'] != null) return;
      engine.debug(
          'processing: ${tile['left']},${tile['top']}, spriteIndex: ${tile['spriteIndex']}');
      if (zone == null) {
        final category =
            kTileSpriteIndexToZoneCategory[tile['spriteIndex']] as String;
        zone = engine.hetu.invoke('Zone', namedArgs: {'category': category});
        tile['zoneId'] = zone['id'];
        ++count;
      } else {
        tile['zoneId'] = zone['id'];
      }
      indexed.add(tile['index']);
      engine.hetu
          .invoke('addTerrainToZone', positionalArgs: [tile, world, zone]);

      final neighbors = engine.hetu.invoke('getMapTileNeighbors',
          positionalArgs: [tile['left'], tile['top'], world]);
      for (final neighbor in neighbors) {
        engine.debug(
            'neighbor: ${neighbor['left']},${neighbor['top']}, spriteIndex: ${neighbor['spriteIndex']}');
        if (indexed.contains(neighbor['index'])) continue;
        if (neighbor['zoneId'] != null) continue;
        if (neighbor['spriteIndex'] == null) continue;
        if (neighbor['spriteIndex'] == tile['spriteIndex']) {
          updateTileZone2(neighbor, world, zone);
        }
      }
    }

    dynamic unzonedTile = (world['terrains'] as List).firstWhere(
      (tile) => (tile['spriteIndex'] != null && tile['zoneId'] == null),
      orElse: () => null,
    );
    while (unzonedTile != null) {
      updateTileZone2(unzonedTile, world);

      unzonedTile = (world['terrains'] as List).firstWhere(
        (tile) => (tile['spriteIndex'] != null && tile['zoneId'] == null),
        orElse: () => null,
      );
    }

    engine.debug('生成了 $count 个地域。');

    return count;
  }

  static int minLevelForRank(int rank) {
    assert(rank >= 0);
    return rank == 0 ? 0 : ((rank - 1) * 10 + 6);
  }

  static int maxLevelForRank(int rank) {
    assert(rank >= 0);
    if (rank == kCultivationRankMax) {
      return kMaxLevelForRank8;
    } else {
      return (rank + 1) * 10 + 5;
    }
  }

  static int expForLevel(int level, [int? difficulty]) {
    difficulty ??= 1;
    return (difficulty * (level) * (level)) * 10 + level * 100 + 40;
  }

  // // 组织中每个等级的人数上限
  // // 数字越大，等级越高，[jobRankMax]是掌门，人数只有1
  // function maxMemberOfJobRank(n: integer, jobRankMax) {
  //   assert(n >= 0 && n <= jobRankMax)
  //   return ((jobRankMax - n) + 1) * ((jobRankMax - n) + 1)
  // }

  // // 组织可以拥有的人数上限取决于组织发展度
  // // 发展度 0，掌门 1 人，rank 1：4 人
  // function maxMemberOfDevelopment(n: integer) {
  //   let number = 0
  //   for (const i in range(n + 2)) {
  //     number += (i + 1) * (i + 1)
  //   }
  //   return number
  // }

  static int getCardCraftOperationCost(String operation, dynamic cardData) {
    assert(kCardOperations.contains(operation));
    switch (operation) {
      case 'dismantle':
        return calculateBattleCardPrice(cardData);
      case 'addAffix':
        return (expForLevel(cardData['level']) * kAddAffixCostRate).round();
      case 'rerollAffix':
        return (expForLevel(cardData['level']) * kRerollAffixCostRate).round();
      case 'replaceAffix':
        return (expForLevel(cardData['level']) * kReplaceAffixCostRate).round();
      case 'upgradeCard':
        return (expForLevel(cardData['level']) * kUpgradeCardCostRate).round();
      case 'upgradeRank':
        return (expForLevel(cardData['rank']) * kUpgradeRankCostRate).round();
      case 'craftScroll':
        return (expForLevel(cardData['level']) * kCraftScrollCostRate).round();
      default:
        engine.error('未知的卡牌操作类型 $operation');
        return 0;
    }
  }

  /// 检查英雄是否满足某个对象的需求
  /// 需求包括：境界，流派，属性等等
  /// 如果满足需求，返回 null
  /// 否则返回一个包含了具体信息的富文本字符串
  static String? checkRequirements(dynamic entityData,
      {bool checkIdentified = false}) {
    final StringBuffer description = StringBuffer();

    if (checkIdentified && entityData['isIdentified'] != true) {
      return '<red>${engine.locale('unidentified3')}</>';
    }

    final heroRank = GameData.heroData['rank'];
    final entityRank = entityData['rank'];
    bool requirementsMet = true;
    final int? rankRequirement = entityData['rank'];
    if (rankRequirement != null) {
      if (heroRank < rankRequirement) {
        requirementsMet = false;
        description.writeln(
            '<red>${engine.locale('rank_requirement')}: ${engine.locale('cultivationRank_$rankRequirement')}</>');
      }
      final String? genreRequirement = entityData['genre'];
      if (genreRequirement != null) {
        if (kCultivationGenres.contains(genreRequirement)) {
          bool hasGenreRankPassive = false;
          final passive =
              GameData.heroData['passives']['${genreRequirement}_rank'];
          if (passive != null) {
            final int genreRank = passive['level'];
            if (genreRank >= entityRank) {
              hasGenreRankPassive = true;
            }
          }

          if (!hasGenreRankPassive) {
            requirementsMet = false;
            description.writeln(
                '<red>${engine.locale('genre_requirement')}: ${engine.locale('cultivationRank_$rankRequirement')}·${engine.locale(genreRequirement)}</>');
          }
        }
      }
    }
    final String? equipmentRequirement = entityData['equipment'];
    if (equipmentRequirement != null) {
      if (GameData.heroData['passives']['equipment_$equipmentRequirement'] ==
          null) {
        requirementsMet = false;
        description.writeln(
            '<red>${engine.locale('equipment_requirement')}: ${engine.locale(equipmentRequirement)}</>');
      }
    }
    final attributeRequirement = entityData['requirement'];
    if (attributeRequirement != null) {
      for (final attr in kBattleAttributes) {
        final int? attrRequirement = attributeRequirement[attr];
        if (attrRequirement == null) continue;
        final int attrValue = GameData.heroData['stats'][attr];
        if (attrValue < attrRequirement) {
          requirementsMet = false;
          description.writeln(
              '<red>${engine.locale('attribute_requirement')}: ${engine.locale(attr)} - $attrRequirement</>');
        }
      }
    }
    final info = description.toString();
    return requirementsMet ? null : info;
  }

  /// 计算分解卡牌所能获得的灵光数
  static int calculateBattleCardPrice(dynamic cardData) {
    final int level = cardData['level'];
    final int price = (expForLevel(level) * kBattleCardPriceRate).round();
    return price;
  }

  /// 计算购买或卖出物品时的价格
  ///
  /// [priceFactor] 交易物品时，需要支付的价格相比商品基础价格的乘数
  /// key为`base`, `sell`, category、kind 或 id，value 为价格乘数
  /// category，kind 和 id 分开保存，叠加计算
  /// 出售有单独的影响因子
  /// ```javascript
  /// {
  ///   useShard: true,
  ///   base: 1.0,
  ///   sell: 0.5,
  ///   category: {
  ///     weapon: 1.0,
  ///   },
  ///   kind: {
  ///     sword: 1.0,
  ///   },
  /// }
  /// ```
  /// 将所有匹配的乘数乘在一起，然后再乘以物品本身的price
  ///
  /// 游戏端不会显示具体的影响因子数值，只是会根据数值偏离1.0的程度显示：
  /// 1.0 = 正常
  /// 大于1.0时：
  /// 1.0-1.3: 略微昂贵
  /// 1.3-1.6: 昂贵
  /// 1.6+: 非常昂贵
  /// 小于1.0时：
  /// 0.7-1.0: 略微便宜
  /// 0.4-0.7: 便宜
  /// 0.1-0.4: 非常便宜
  static int calculateItemPrice(dynamic itemData,
      {dynamic priceFactor, bool isSell = true}) {
    final int price = itemData['price'] ?? 0;

    if (priceFactor == null) {
      return price;
    } else {
      final double base = priceFactor['base'] ?? kBaseBuyRate; // 基础值：1.0
      final double sell = priceFactor['sell'] ?? kBaseSellRate; // 基础值：0.5

      final double category =
          priceFactor['category']?[itemData['category']] ?? 1.0;
      final double kind = priceFactor['kind']?[itemData['kind']] ?? 1.0;

      double ratio = base * category * kind * (isSell ? sell : 1.0);
      final min = isSell ? kMinSellRate : kMinBuyRate;
      if (ratio < min) ratio = min;

      int finalPrice = (price * ratio).ceil();

      if (priceFactor['useShard'] == true) {
        finalPrice = (finalPrice / kShardToMoneyRate).ceil();
      }

      return finalPrice;
    }
  }

  /// 参考 [calculateItemPrice]
  static int calculateMaterialPrice(String materialId,
      {dynamic priceFactor, bool isSell = true}) {
    assert(kMaterialBasePriceByKind.containsKey(materialId));
    final price = kMaterialBasePriceByKind[materialId] as int;

    if (priceFactor == null) {
      return price;
    } else {
      final double base = priceFactor['base'] ?? kBaseBuyRate; // 基础值：1.0
      final double sell = priceFactor['sell'] ?? kBaseSellRate; // 基础值：0.5

      final double kind = priceFactor['kind']?[materialId] ?? 1.0;

      double finalPrice = price * base * kind * (isSell ? sell : 1.0);

      if (priceFactor['useShard'] == true) {
        finalPrice /= kShardToMoneyRate;
      }

      return finalPrice.ceil();
    }
  }

  static List<dynamic> getFilteredItems(
    dynamic characterData, {
    required ItemType type,
    dynamic filter,
  }) {
    final inventoryData = characterData['inventory'];

    final String? category = filter?['category'];
    final String? kind = filter?['kind'];
    final String? id = filter?['id'];
    final bool? isIdentified = filter?['isIdentified'];

    final filteredItems = [];
    for (var itemData in inventoryData.values) {
      if (itemData['equippedPosition'] != null) {
        continue;
      }
      if (category != null && category != itemData['category']) {
        continue;
      }
      if (kind != null && kind != itemData['kind']) {
        continue;
      }
      if (id != null && id != itemData['id']) {
        continue;
      }
      if (isIdentified != null && isIdentified != itemData['isIdentified']) {
        continue;
      }
      if (type == ItemType.customer) {
        if (itemData['isUntradable'] == true) continue;
        if (kUntradableItemKinds.contains(itemData['kind'])) {
          continue;
        }
      }
      if (type == ItemType.merchant) {
        if (kUntradableItemKinds.contains(itemData['kind'])) {
          continue;
        }
      }

      filteredItems.add(itemData);
    }

    return filteredItems;
  }

  /// 根据角色当前的流派等级和境界，获得战斗卡牌
  static List<String> obtainCultivationCards() {
    final List<String> result = [];

    /// genreLevels 是一个数组，代表每个流派的等级
    /// 内容示例：
    /// [
    ///   { genreId: 'flying_sword', probability: 0.7 },
    ///   { genreId: 'spellcraft', probability: 0.2 },
    ///   { genreId: 'avatar', probability: 0.1 },
    ///   ...
    /// ]

    // final probabilityTotal = genreLevels.reduce((a, b) => a.level + b.level);

    // genreLevels.sort((a, b) => b.level.compareTo(a.level));

    return result;
  }

  /// 为某个角色解锁某个天赋树节点
  /// 注意这里不会检查和处理技能点，而是直接增加某个天赋
  static bool characterUnlockPassiveTreeNode(
    dynamic characterData,
    String nodeId, {
    String? selectedAttributeId,
  }) {
    final unlockedNodes = characterData['unlockedPassiveTreeNodes'];
    if (unlockedNodes[nodeId] != null) {
      return false;
    }

    final passiveTreeNodeData = GameData.passiveTree[nodeId];
    if (passiveTreeNodeData == null) {
      engine.warn('天赋树节点 $nodeId 不存在');
      return false;
    }
    bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;

    if (selectedAttributeId == null) {
      final r = math.Random().nextDouble();
      if (r < 0.4) {
        selectedAttributeId = characterData['mainAttribute'];
      } else {
        selectedAttributeId = kBattleAttributes.random;
      }
    } else {
      assert(kBattleAttributes.contains(selectedAttributeId));
    }

    if (isAttribute) {
      // 属性点类的node，记录的是选择的具体属性的名字
      unlockedNodes[nodeId] = selectedAttributeId;
      engine.hetu.invoke(
        'characterSetPassive',
        positionalArgs: [characterData, selectedAttributeId],
        namedArgs: {'level': kAttributeAnyLevel},
      );
    } else {
      unlockedNodes[nodeId] = true;
      final List nodePassiveData = passiveTreeNodeData['passives'];
      for (final data in nodePassiveData) {
        engine.hetu.invoke(
          'characterSetPassive',
          positionalArgs: [characterData, data['id']],
          namedArgs: {
            'level': data['level'] ?? 1,
          },
        );
      }
    }

    return true;
  }

  static void characterRefundPassiveTreeNode(
    dynamic characterData,
    String nodeId,
  ) {
    final passiveTreeNodeData = GameData.passiveTree[nodeId];
    final unlockedNodes = characterData['unlockedPassiveTreeNodes'];
    bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;

    if (isAttribute) {
      final attributeId = unlockedNodes[nodeId];
      assert(kBattleAttributes.contains(attributeId));
      // engine.hetu.invoke('refundPassive',
      //     namespace: 'Player', positionalArgs: ['lifeMax']);
      engine.hetu.invoke(
        'characterSetPassive',
        positionalArgs: [characterData, attributeId],
        namedArgs: {'level': -kAttributeAnyLevel},
      );
    } else {
      final List nodePassiveData = passiveTreeNodeData['passives'];
      for (final data in nodePassiveData) {
        engine.hetu.invoke(
          'characterSetPassive',
          positionalArgs: [characterData, data['id']],
          namedArgs: {'level': -(data['level'] ?? 1)},
        );
      }
    }
    unlockedNodes.remove(nodeId);
  }

  static void characterAllocateSkills(dynamic characterData) {
    final genre = characterData['cultivationFavor'];
    final style = characterData['cultivationStyle'];
    final int rank = characterData['rank'];
    final int level = characterData['level'];

    final List<String>? rankPath = kCultivationRankPaths[genre];
    final List<String>? stylePath = kCultivationStylePaths[genre]?[style];
    assert(rankPath != null, 'genre: genre');
    assert(stylePath != null, 'genre: $genre, style: $style');

    int count = 0;
    for (var i = 0; i < rank; ++i) {
      assert(i < rankPath!.length);
      final nodeId = rankPath![i];
      final unlocked = characterUnlockPassiveTreeNode(characterData, nodeId);
      if (unlocked) {
        count++;
      }
    }

    for (var i = 0; i < level - rank; ++i) {
      assert(i < stylePath!.length);
      final nodeId = stylePath![i];
      final unlocked = characterUnlockPassiveTreeNode(characterData, nodeId);
      if (unlocked) {
        count++;
      }
    }

    engine.hetu
        .invoke('characterCalculateStats', positionalArgs: [characterData]);

    engine.info(
        '为角色 ${characterData['name']} (rank: ${characterData['rank']}, level: ${characterData['level']}) 在 ${engine.locale('genre')} ${engine.locale(genre)} 的 ${engine.locale(style)} 路线上解锁了 $count 个天赋树节点');
  }

  static dynamic characterHasPassive(dynamic characterData, String passiveId) {
    return characterData['passives']?[passiveId];
  }

  // 返回值依次是：卡组下限，消耗牌上限，持续牌上限
  static Map<String, int> getDeckLimitForRank(int rank) {
    assert(rank >= 0);
    int limit;
    if (rank == 0) {
      limit = 3;
    } else {
      limit = rank + 2;
    }
    final ephemeralMax = rank ~/ 5 + 1;
    return {
      'limit': limit,
      'ephemeralMax': ephemeralMax,
    };
  }

  static String? checkDeckRequirement(Iterable<dynamic> cards) {
    final deckLimit = getDeckLimitForRank(GameData.heroData['rank']);

    if (cards.length < deckLimit['limit']!) {
      return 'deckbuilding_cards_not_enough';
    }

    for (final card in cards) {
      final valid = checkRequirements(card, checkIdentified: true);
      if (valid != null) {
        return 'deckbuilding_card_invalid';
      }
    }

    return null;
  }

  static double getHPRestoreRateAfterBattle(int turnCount) {
    assert(turnCount > 0);
    final rate = kBaseAfterBattleHPRestoreRate -
        kBaseAfterBattleHPRestoreRate *
            math.gradualValue(turnCount - 1, kBattleCardsCount, power: 0.5);

    return rate;
  }

  static Future<String?> selectWorldId() async {
    return await showDialog(
      context: engine.context,
      builder: (context) => SelectMenuDialog(
          selections: {for (var element in GameData.worldIds) element: element},
          selectedValue:
              GameData.worldIds.firstWhere((id) => id != GameData.world['id'])),
    );
  }

  static Future<String?> selectLocationId() async {
    final selections = <String, String>{};
    final locationsData = GameData.gameData['locations'];
    if (locationsData.isEmpty) return null;

    for (final element in locationsData.keys) {
      selections[element] = element;
    }
    return await showDialog(
      context: engine.context,
      builder: (context) {
        return SelectMenuDialog(
          selections: selections,
          selectedValue: null,
        );
      },
    );
  }

  static Future<String?> selectOrganizationId() async {
    final selections = <String, String>{};
    final organizationsData = GameData.gameData['organizations'];
    if (organizationsData.isEmpty) return null;

    for (final element in organizationsData.keys) {
      selections[element] = element;
    }
    return await showDialog(
      context: engine.context,
      builder: (context) {
        return SelectMenuDialog(
          selections: selections,
          selectedValue: null,
        );
      },
    );
  }

  static Future<String?> selectObjectId() async {
    final selections = <String, String>{};
    if (GameData.world['objects'].isEmpty) return null;

    for (final element in GameData.world['objects'].keys) {
      selections[element] = element;
    }
    return await showDialog(
      context: engine.context,
      builder: (context) {
        return SelectMenuDialog(
          selections: selections,
          selectedValue: null,
        );
      },
    );
  }

  /// 角色渡劫检测，返回值 true 代表将进入天道挑战
  /// 此时将不会正常升级，但仍会扣掉经验值
  static bool checkTribulation() {
    final level = GameData.heroData['level'];
    final rank = GameData.heroData['rank'];
    final currentRankMaxLevel = maxLevelForRank(rank);
    final currentRankMinLevel = minLevelForRank(rank);
    final nextRankMinLevel = minLevelForRank(rank + 1);

    bool doTribulation = false;
    if (level > currentRankMinLevel) {
      if (level == 5 && rank == 0) {
        doTribulation = true;
      } else if (level == currentRankMaxLevel) {
        doTribulation = true;
      } else {
        final probability = math.gradualValue(level - currentRankMinLevel,
            currentRankMaxLevel - currentRankMinLevel);
        final r = math.Random().nextDouble();
        if (r < probability) {
          doTribulation = true;
        }
      }

      if (doTribulation) {
        showTribulation(nextRankMinLevel + 5, rank + 1);
      }
    }

    return doTribulation;
  }

  // 进入天道战斗
  static void showTribulation(int level, int rank) async {
    await GameDialogContent.show(
        engine.context, engine.locale('help_tribulation'));

    final selected =
        await SelectionDialog.show(engine.context, selectionsData: {
      'selections': {
        'do_tribulation': engine.locale('do_tribulation'),
        'forgetIt': engine.locale('forgetIt'),
      },
    });
    if (selected == 'do_tribulation') {
      final enemey = engine.hetu.invoke(
        'BattleEntity',
        namedArgs: {
          'isFemale': false,
          'name': engine.locale('theHeavenlyWay'),
          'icon': 'illustration/man_in_shadow.png',
          'level': level,
          'rank': rank,
        },
      );
      characterAllocateSkills(enemey);
      engine.hetu.invoke('generateDeck', positionalArgs: [enemey]);

      final arg = {
        'id': Scenes.battle,
        'hero': GameData.heroData,
        'enemy': enemey,
        // 'onBattleStart': () {
        //   bool? hintedTribulation =
        //       GameData.gameData['flags']['hintedTribulation'];
        //   if (hintedTribulation == null || hintedTribulation == false) {
        //     GameDialogContent.show(
        //         engine.context, engine.locale('hint_tribulation_beforeBattle'));
        //     GameData.gameData['flags']['hintedTribulation'] = true;
        //   }
        // },
        'onBattleEnd': (bool? result) {
          if (result == true) {
            engine.hetu.invoke('levelUp', namespace: 'Player');
            final rank = engine.hetu.invoke('rankUp', namespace: 'Player');
            engine.context.read<NewRankState>().update(rank: rank);
          }
        },
      };
      engine.pushScene(Scenes.battle, arguments: arg);
    } else {
      GameDialogContent.show(
          engine.context, engine.locale('hint_cancel_tribulation'));
    }
  }

  static void heroRest() async {
    dialog.pushSelection({
      'id': 'restOption',
      'selections': {
        'rest1Days': engine.locale('rest1Days'),
        'rest10Days': engine.locale('rest10Days'),
        'rest30Days': engine.locale('rest30Days'),
        'restTillTommorow': engine.locale('restTillTommorow'),
        'restTillNextMonth': engine.locale('restTillNextMonth'),
        'restTillFullHealth': engine.locale('restTillFullHealth'),
        'cancel': engine.locale('cancel'),
      },
    });
    await dialog.execute();
    final selected = dialog.checkSelected('restOption');
    int ticks = 0;
    switch (selected) {
      case 'rest1Days':
        ticks = kTicksPerDay;
      case 'rest10Days':
        ticks = kTicksPerDay * 10;
      case 'rest30Days':
        ticks = kTicksPerDay * 30;
      case 'restTillTommorow':
        ticks = kTicksPerDay - ticksOfDay;
      case 'restTillNextMonth':
        ticks = kTicksPerMonth - ticksOfMonth;
      case 'restTillFullHealth':
        ticks =
            (GameData.heroData['stats']['lifeMax'] - GameData.heroData['life'])
                .floor();
        if (ticks <= 0) {
          GameDialogContent.show(
              engine.context, engine.locale('alreadyFullHealthNoNeedRest'));
        }
    }
    if (ticks <= 0) return;

    TimeflowDialog.show(
      context: engine.context,
      max: ticks,
      onProgress: () {
        engine.hetu
            .invoke('restoreLife', namespace: 'Player', positionalArgs: [1]);
        return false;
      },
    );
  }

  static void heroWork(dynamic location, dynamic npc) async {
    final kind = location['kind'];
    if (!kWorkMounths.containsKey(kind)) {
      engine.warn('非可工作场所：${location['name']}($kind)');
      return;
    }

    void notEnoughStamina() async {
      dialog.pushDialog({
        'name': npc?['name'],
        'icon': npc?['icon'],
        'image': npc?['image'],
        'lines': [engine.locale('hint_notEnoughHealthToWork')]
      });
      await dialog.execute();
    }

    if (GameData.heroData['life'] <= 1) {
      notEnoughStamina();
      return;
    }

    final months = kWorkMounths[kind] as List;
    if (!months.contains(month)) {
      dialog.pushDialog({
        'name': npc?['name'],
        'icon': npc?['icon'],
        'image': npc?['image'],
        'lines': [engine.locale('hint_notWorkSeason')]
      });
      await dialog.execute();
      return;
    }

    final baseSalary = kWorkBaseSalaries[kind] as int;
    final baseStaminaCost = kWorkBaseStaminaCost[kind] as int;

    dialog.pushSelection({
      'id': 'workOption',
      'selections': {
        'work10Days': engine.locale('work10Days'),
        'work30Days': engine.locale('work30Days'),
        'workTillNextMonth': engine.locale('workTillNextMonth'),
        'workTillHealthExhausted': engine.locale('workTillHealthExhausted'),
        'cancel': engine.locale('cancel'),
      },
    });
    await dialog.execute();
    final selected = dialog.checkSelected('workOption');
    int ticks = 0;
    switch (selected) {
      case 'work10Days':
        ticks = kTicksPerDay * 10;
      case 'work30Days':
        ticks = kTicksPerDay * 30;
      case 'workTillNextMonth':
        ticks = kTicksPerMonth - ticksOfMonth;
      case 'workTillHealthExhausted':
        ticks = (GameData.heroData['life'].floor() - 1) ~/ baseStaminaCost;
        if (ticks <= 0) {
          notEnoughStamina();
          return;
        }
    }
    if (ticks <= 0) return;

    final finalTicks = await TimeflowDialog.show(
      context: engine.context,
      max: ticks,
      onProgress: () {
        engine.hetu.invoke('setLife',
            namespace: 'Player',
            positionalArgs: [GameData.heroData['life'].floor() - 1]);
        return GameData.heroData['life'] <= 1;
      },
    );

    engine.play('coins-31879.mp3');
    engine.hetu.invoke('collect', namespace: 'Player', positionalArgs: [
      'money'
    ], namedArgs: {
      'amount': finalTicks * baseSalary,
    });
  }

  static double getMoveCostOnHill() {
    double cost = kBaseMoveCostOnHill;
    final skill = GameData.heroData['passives']['stamina_cost_reduce_on_hill'];
    cost -= cost * (skill?['value'] ?? 0) / 100;
    return cost;
  }

  static double getMoveCostOnWater() {
    double cost = kBaseMoveCostOnWater;
    final skill = GameData.heroData['passives']['stamina_cost_reduce_on_water'];
    cost -= cost * (skill?['value'] ?? 0) / 100;
    return cost;
  }

  static void onUseItem(itemData) {
    final isIdentified = itemData['isIdentified'] == true;
    if (!isIdentified) {
      GameDialogContent.show(
          engine.context, engine.locale('hint_unidentifiedItem'));
      return;
    }
    if (itemData['useCustomLogic'] == true) {
      engine.hetu
          .invoke('onGameEvent', positionalArgs: ['onUseItem', itemData]);
      return;
    }
    switch (itemData['category']) {
      case 'cardpack':
        engine.pushScene(Scenes.library, arguments: {
          'cardpacks': {itemData},
          'enableCardCraft': engine.scene?.id == Scenes.mainmenu,
          'enableScrollCraft': engine.scene?.id == Scenes.mainmenu,
        });
      case 'identify_scroll':
        engine.context.read<ViewPanelState>().toogle(
          ViewPanels.itemSelect,
          arguments: {
            'characterData': GameData.heroData,
            'title': engine.locale('selectItem'),
            'filter': {'isIdentified': false},
            'onSelect': (Iterable selectedItemsData) async {
              if (selectedItemsData.isEmpty) return;
              assert(selectedItemsData.length == 1);
              final selectedItem = selectedItemsData.first;
              selectedItem['isIdentified'] = true;
              engine.play('hammer-hitting-an-anvil-25390.mp3');
              engine.hetu.invoke('lose',
                  namespace: 'Player', positionalArgs: [itemData]);
            },
          },
        );
      case 'material_pack':
        engine.hetu.invoke('lose',
            namespace: 'Player',
            positionalArgs: [itemData],
            namedArgs: {'incurIncident': false});
        engine.hetu.invoke(
          'collect',
          namespace: 'Player',
          positionalArgs: [itemData['kind']],
          namedArgs: {'amount': itemData['stackSize']},
        );
        engine.play('pickup_item-64282.mp3');
      // case 'exp_pack':
      //   engine.hetu.invoke('gainExp',
      //       namespace: 'Player', positionalArgs: [itemData['stackSize']]);
      //   engine.hetu
      //       .invoke('lose', namespace: 'Player', positionalArgs: [itemData]);
      //   engine.play('magic-smite-6012.mp3');
    }
  }

  static void onChargeItem(itemData) async {
    assert(itemData['chargeData'] != null);
    final chargeData = itemData['chargeData'];
    if (chargeData['current'] >= chargeData['max']) {
      GameDialogContent.show(
          engine.context, engine.locale('hint_itemFullyCharged'));
      return;
    }

    final int shards = GameData.heroData['materials']['shard'] ?? 0;
    final int shardsPerCharge = chargeData['shardsPerCharge'];
    if (shards < shardsPerCharge) {
      GameDialogContent.show(
          engine.context, engine.locale('hint_notEnoughShard'));
      return;
    }

    final int chargeLimit = chargeData['max'] - chargeData['current'];
    assert(chargeLimit > 0);
    final max = math.min(shards ~/ shardsPerCharge, chargeLimit);

    final int? value = await showDialog(
      context: engine.context,
      builder: (context) => InputSliderDialog(
        min: shardsPerCharge,
        max: max * shardsPerCharge,
        divisions: max - 1,
        title: engine.locale('chargeItem'),
        labelBuilder: (value) => '${engine.locale('shardsCost')}: $value',
      ),
    );

    if (value == null) return;

    final charge = value ~/ shardsPerCharge;

    chargeData['current'] += charge;
    engine.hetu.invoke('exhaust', namespace: 'Player', namedArgs: {
      'kind': 'shard',
      'amount': value,
    });

    engine.info('物品 ${itemData['name']} 增加了 $charge 充能次数');
    engine.play('electric-sparks-68814.mp3');
  }

  /// 异步函数，在显示场景窗口之前执行
  static Future<dynamic> tryEnterLocation(dynamic locationData) async {
    engine.debug('正在尝试进入据点 [${locationData['name']}]');
    // [result] 值是 true 意味着不会进入场景
    dynamic result;
    if (locationData['isDiscovered'] != true) {
      // TODO: 第一次发现据点事件
      if (locationData['isHidden'] == true) {
        dialog.pushDialog({
          'lines': [engine.locale('hint_sensedUndiscovered')],
        });
        await dialog.execute();
        result = true;
      } else {
        engine.hetu.invoke('discoverLocation', positionalArgs: [locationData]);
        dialog.pushDialog({
          'lines': [
            engine
                .locale('firstDiscover', interpolations: [locationData['name']])
          ],
        });
        await dialog.execute();
      }
    }

    result = await engine.hetu.invoke('onGameEvent',
        positionalArgs: ['onBeforeEnterLocation', locationData]);

    if (result == null) {
      engine.pushScene(
        locationData['id'],
        constructorId: Scenes.location,
        arguments: {'location': locationData},
      );
    }
  }

  static void onAfterEnterLocation(dynamic locationData) async {
    await engine.hetu.invoke('onGameEvent',
        positionalArgs: ['onAfterEnterLocation', locationData]);

    if (locationData['kind'] == 'home') {
      final ownerId = locationData['ownerId'];
      if (ownerId != GameData.heroData['id']) {
        final owner = GameData.gameData['characters'][ownerId];
        if (owner['locationId'] != locationData['id']) {
          GameDialogContent.show(
              engine.context,
              engine.locale('hint_visitEmptyHome',
                  interpolations: [owner['name']]));
        }
      }
    }
  }

  static void tryInteractObject(String objectId, dynamic terrainData) {
    final objectsData = engine.hetu.fetch('objects', namespace: 'world');
    final objectData = objectsData[objectId];
    engine.hetu.invoke('onInteractMapObject',
        positionalArgs: [objectData, terrainData]);
  }

  /// 和门派总堂的定灵碑交互
  /// 如果并非此组织成员，无法使用
  static void onInteractCultivationStele(
    dynamic organizationData, {
    dynamic locationData,
    bool? enableCultivate,
  }) async {
    if (GameData.heroData['organizationId'] == organizationData['id']) {
      engine.pushScene(Scenes.cultivation, arguments: {
        'location': locationData,
        'enableCultivate': locationData == null ? enableCultivate : false,
        'onEnterScene': () async {
          if (GameData.gameData['flags']['hintedCultivation'] != true) {
            GameData.gameData['flags']['hintedCultivation'] = true;

            dialog.pushDialog(
              {
                'name': engine.locale('servant'),
                'icon': 'illustration/npc/servant_head.png',
                'lines': [
                  engine.locale('hint_tutorial'),
                ]
              },
            );
            dialog.pushSelection({
              'id': 'tutorial',
              'selections': {
                'listenTutorial': engine.locale('listenTutorial'),
                'forgetIt': engine.locale('forgetIt'),
              },
            });
            await dialog.execute();
            final selected = dialog.checkSelected('tutorial');

            final item = engine.hetu.invoke('Materialpack', namedArgs: {
              'kind': 'shard',
              'amount': 5,
            });
            engine.hetu
                .invoke('acquire', namespace: 'Player', positionalArgs: [item]);

            if (selected == 'listenTutorial') {
              dialog.pushDialog(
                {
                  'name': engine.locale('servant'),
                  'icon': 'illustration/npc/servant_head.png',
                  'lines': engine.locale('hint_cultivation').split('\n'),
                },
                imageId: 'illustration/npc/servant.png',
              );
              await dialog.execute();
            }

            dialog.pushDialog(
              {
                'name': engine.locale('servant'),
                'icon': 'illustration/npc/servant_head.png',
                'lines': engine.locale('hint_cultivation2').split('\n'),
              },
              imageId: 'illustration/npc/servant.png',
            );
            await dialog.execute();

            engine.context.read<NewItemsState>().update(items: [item]);
          }
        },
      });
    } else {
      dialog.pushDialog(
        {
          'name': engine.locale('servant'),
          'icon': 'illustration/npc/servant_head.png',
          'lines': [
            engine.locale('hint_organizationFacilityNotMember'),
          ]
        },
        imageId: 'illustration/npc/servant.png',
      );
      await dialog.execute();
    }
  }

  /// 和门派藏书阁的功法图录交互
  /// 如果并非此组织成员，无法使用
  static void onInteractCardLibraryDesk(
    dynamic organizationData, {
    dynamic locationData,
  }) async {
    assert(organizationData != null);

    if (GameData.heroData['organizationId'] == organizationData['id']) {
      engine.pushScene(Scenes.library, arguments: {
        'enableCardCraft':
            organizationData['techs']['enableCardCraft'] ?? false,
        'enableScrollCraft':
            organizationData['techs']['enableScrollCraft'] ?? false,
        'onEnterScene': () async {
          if (GameData.gameData['flags']['hintedCardLibrary'] != true) {
            GameData.gameData['flags']['hintedCardLibrary'] = true;

            dialog.pushDialog(
              {
                'name': engine.locale('servant'),
                'icon': 'illustration/npc/servant_head.png',
                'lines': [
                  engine.locale('hint_tutorial'),
                ]
              },
            );
            dialog.pushSelection({
              'id': 'tutorial',
              'selections': {
                'listenTutorial': engine.locale('listenTutorial'),
                'forgetIt': engine.locale('forgetIt'),
              },
            });
            await dialog.execute();
            final selected = dialog.checkSelected('tutorial');

            final item =
                engine.hetu.invoke('Cardpack', namedArgs: {'isBasic': true});
            engine.hetu
                .invoke('acquire', namespace: 'Player', positionalArgs: [item]);

            if (selected == 'listenTutorial') {
              dialog.pushDialog(
                {
                  'name': engine.locale('servant'),
                  'icon': 'illustration/npc/servant_head.png',
                  'lines': engine.locale('hint_cardLibrary').split('\n'),
                },
                imageId: 'illustration/npc/servant.png',
              );
              await dialog.execute();
            }

            dialog.pushDialog(
              {
                'name': engine.locale('servant'),
                'icon': 'illustration/npc/servant_head.png',
                'lines': engine.locale('hint_cardLibrary2').split('\n'),
              },
              imageId: 'illustration/npc/servant.png',
            );
            await dialog.execute();

            engine.context.read<NewItemsState>().update(items: [item]);
          }
        },
      });
    } else {
      await GameDialogContent.show(engine.context, {
        'name': engine.locale('servant'),
        'icon': 'illustration/npc/servant_head.png',
        'image': 'illustration/npc/servant.png',
        'lines': [
          engine.locale('hint_organizationFacilityNotMember'),
        ]
      });
    }
  }

  /// 更新游戏逻辑，将时间向前推进一帧（tick），可以设定连续更新的帧数
  /// 如果遇到了一些特殊事件可能提前终止
  /// 这会影响一些连续进行的动作，例如探索或者修炼等等
  static void updateGame({
    tick = 1,
    timeflow = true,
    autoCultivate = false,
    autoWork = false,
  }) async {
    final int tik = DateTime.now().millisecondsSinceEpoch;

    if (timeflow) {
      if (ticksOfDay == 1) {
        engine.log('--------$year}年$month月$day日$ticksOfDay--------');
      }
    }

    final int timestamp = GameData.gameData['timestamp'];

    for (var i = 0; i < tick; ++i) {
      engine.hetu.invoke('handleBabies');

      if (day == 1 && ticksOfDay == 1) {
        // 重置玩家自己的每月行动
        engine.hetu.invoke('resetPlayerMonthlyActivities');
      }

      // 每个建筑每月会根据其属性而消耗维持费用和获得收入
      // 生产类建筑每天都会刷新生产进度
      // 商店类建筑会刷新物品和银两
      // 刷新任务，无论之前的任务是否还存在，非组织拥有的第三方建筑每个月只会有一个任务
      for (final locationData in GameData.gameData['locations'].values) {
        // 月度事件
        if (day == 1 && ticksOfDay == 1) {
          updateLocationMonthly(locationData);
          // 年度事件
          if (month == kLocationYearlyUpdateMonth) {
            updateLocationYearlyStart(locationData);
          } else if (month == kLocationYearlyUpdateMonth + 1) {
            updateLocationYearlyEnd(locationData);
          }
        }
      }

      // 触发每个组织的刷新事件
      for (final organizationData
          in GameData.gameData['organizations'].values) {
        // 月度事件
        if (day == 1 && ticksOfDay == 1) {
          updateOrganizationMonthly(organizationData);

          // 年度事件
          if (month == kOrganizationYearlyUpdateMonth) {
            updateOrganizationYearlyStart(organizationData);
          } else if (month == kOrganizationYearlyUpdateMonth + 1) {
            updateOrganizationYearlyEnd(organizationData);
          }
        }
      }

      // 触发每个角色的刷新事件
      for (final characterData in GameData.gameData['characters'].values) {
        // 月度事件
        if (day == 1 && ticksOfDay == 1) {
          updateCharacterMonthly(characterData);

          // 年度事件
          if (month == kCharacterYearlyUpdateMonth) {
            updateCharacterYearlyStart(characterData);
          } else if (month == kCharacterYearlyUpdateMonth + 1) {
            updateCharacterYearlyEnd(characterData);
          }
        }
      }

      // 每一个野外地块，每个月固定时间会随机刷新一个野外遭遇
      // 野外遭遇包括NPC事件、随机副本等等
      // for (const terrain in world.terrains) {
      //   if (game.timestamp % kTicksPerMonth == 0) {
      //     updateTerrain(terrain)
      //   }
      // }

      if (timeflow) {
        engine.hetu.assign('timestamp', timestamp + 1, namespace: 'game');
        calculateTimestamp();

        engine.context.read<GameTimestampState>().update();
      }

      if (GameData.heroData != null) {
        for (final itemId in GameData.heroData['equipments'].values) {
          if (itemId == null) continue;
          final itemData = GameData.heroData['inventory'][itemId];
          engine.debug('触发装备物品 ${itemData['name']} 刷新事件');
          await engine.hetu.invoke('onGameEvent',
              positionalArgs: ['onUpdateItem', itemData]);
        }
      }
    }

    engine.log(
        'game update took: ${DateTime.now().millisecondsSinceEpoch - tik}ms');
  }

  /// 据点年度更新开始
  static void updateLocationYearlyStart(dynamic locationData) {
    engine.debug('${locationData['id']} 的年度更新开始');
  }

  /// 据点年度更新结束
  static void updateLocationYearlyEnd(dynamic locationData) {
    engine.debug('${locationData['id']} 的年度更新结束');
  }

  /// 据点月度更新
  static void updateLocationMonthly(dynamic locationData) {
    engine.debug('${locationData['id']} 的月度更新');

    if (locationData['category'] == 'city') {
    } else if (locationData['category'] == 'site') {
      // 交易类场景每个月刷新物品
      switch (locationData['kind']) {
        case 'cityhall':
          engine.hetu
              .invoke('replenishCityhallExp', positionalArgs: [locationData]);
        case 'tradinghouse':
          engine.hetu.invoke('replenishTradingHouseMaterials',
              positionalArgs: [locationData]);
        case 'auctionhouse':
          engine.hetu.invoke('replenishAuctionHouseItems',
              positionalArgs: [locationData]);
      }
    }
  }

  /// 组织年度更新开始
  static void updateOrganizationYearlyStart(organizationData) {
    engine.debug('${organizationData['id']} 的年度更新开始');

    organizationData['isRecruiting'] = true;
    engine.debug('${organizationData['id']} 的招募活动本月开始。');
  }

  /// 组织年度更新结束
  static void updateOrganizationYearlyEnd(organizationData) {
    engine.debug('${organizationData['id']} 的年度更新结束');

    organizationData['isRecruiting'] = false;
    engine.debug('${organizationData['id']} 的招募活动已经结束。');
  }

  /// 组织月度更新
  static void updateOrganizationMonthly(organizationData) {
    engine.debug('${organizationData['id']} 的月度更新');
  }

  /// 角色年度更新开始
  static void updateCharacterYearlyStart(characterData) {
    engine.debug('${characterData['id']} 的年度更新开始');
  }

  /// 角色年度更新结束
  static void updateCharacterYearlyEnd(characterData) {
    engine.debug('${characterData['id']} 的年度更新结束');
  }

  /// 角色月度更新
  static void updateCharacterMonthly(characterData) {
    engine.debug('${characterData['id']} 的月度更新');
  }

  /// 角色濒死，tribulationCount += 1，返回自宅
  static void onDying() {}

  static void onInteractCharacter(dynamic character) async {
    if (character['entityType'] != 'character') {
      assert(character['entityType'] == 'npc');
      final location =
          GameData.gameData['locations'][character['atLocationId']];
      assert(location != null, 'npc.atLocationId is null!');
      onInteractNpc(character, location);
      return;
    } else {
      engine.hetu.invoke('onIneractCharacter', positionalArgs: [character]);
    }
  }

  static void onInteractNpc(dynamic npc, dynamic location) async {
    engine.debug('正在和 NPC [${npc.id}] 互动。');
    if (npc['useCustomLogic'] == true) {
      engine.debug('NPC [${npc.id}] 使用自定义逻辑。');
      engine.hetu.invoke('onGameEvent',
          positionalArgs: ['onInteractNpc', npc, location]);
      return;
    }

    switch (location['kind']) {
      case 'tradinghouse':
        // final months = kWorkMounths['tradinghouse'] as List;
        dialog.pushSelection({
          'id': 'tradinghouse',
          'selections': {
            'workHere': {
              'text': engine.locale('workHere'),
              'description': engine.locale('startWork_description'),
            },
            'trade': engine.locale('trade'),
            'cancel': engine.locale('cancel'),
          }
        });
        await dialog.execute();
        final selected = dialog.checkSelected('tradinghouse');
        switch (selected) {
          case 'workHere':
            heroWork(location, npc);
          case 'trade':
            engine.context.read<MerchantState>().show(
                  location,
                  materialMode: true,
                  priceFactor: location['priceFactor'],
                );
        }
      case 'auctionhouse':
        dialog.pushSelection({
          'id': 'auctionhouse',
          'selections': {
            'workHere': {
              'text': engine.locale('workHere'),
              'description': engine.locale('startWork_description'),
            },
            'trade': engine.locale('trade'),
            'cancel': engine.locale('cancel'),
          },
        });
        await dialog.execute();
        final selected = dialog.checkSelected('auctionhouse');
        switch (selected) {
          case 'workHere':
            heroWork(location, npc);
          case 'trade':
            engine.context.read<MerchantState>().show(
                  location,
                  useShard: true,
                  priceFactor: location['priceFactor'],
                );
        }
      case 'workshop':
    }
  }
}
