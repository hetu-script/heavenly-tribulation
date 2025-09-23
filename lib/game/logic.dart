import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/state/states.dart';
import 'package:heavenly_tribulation/widgets/character/profile.dart';
import 'package:heavenly_tribulation/widgets/common.dart';
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
import '../widgets/organization/organization.dart';
import '../widgets/location/location.dart';

abstract class GameLogic {
  static bool truthy(dynamic value) => engine.hetu.interpreter.truthy(value);

  static int ticksOfYear = 0;
  static int ticksOfMonth = 0;
  static int ticksOfDay = 0;
  static int year = 0;
  static int month = 0;
  static int day = 0;
  static String timeOfDay = '';

  static String getDatetimeString() {
    return '$year${engine.locale('dateYear')}$month${engine.locale('dateMonth')}$day${engine.locale('dateDay')}${engine.locale(timeOfDay)}';
  }

  static (int, String) calculateTimestamp() {
    final int timestamp = GameData.game['timestamp'];
    ticksOfYear = (timestamp % kTicksPerYear) + 1;
    ticksOfMonth = (timestamp % kTicksPerMonth) + 1;
    ticksOfDay = (timestamp % kTicksPerDay) + 1;
    year = (timestamp ~/ kTicksPerYear) + 1;
    month = (ticksOfYear ~/ kTicksPerMonth) + 1;
    day = (ticksOfMonth ~/ kTicksPerDay) + 1;
    timeOfDay = kTimeOfDay[ticksOfDay]!;

    final datetimeString = getDatetimeString();

    return (timestamp, datetimeString);
  }

  static int generateZone(dynamic world) {
    int count = 0;
    List indexed = [];

    void updateTileZone2(dynamic tile, dynamic world, [dynamic zone]) {
      if (tile['spriteIndex'] == null) return;
      if (tile['zoneId'] != null) return;
      // engine.debug(
      //     'processing: ${tile['left']},${tile['top']}, spriteIndex: ${tile['spriteIndex']}');
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
        // engine.debug(
        //     'neighbor: ${neighbor['left']},${neighbor['top']}, spriteIndex: ${neighbor['spriteIndex']}');
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
    return rank == 0 ? 0 : (rank * 10 - 5);
  }

  static int maxLevelForRank(int rank) {
    assert(rank >= 0);
    return (rank + 2) * 10 - 5;
  }

  static int expForLevel(int level) {
    return ((level * level) * 10 + level * 100 + 40) ~/ 3 * 2;
  }

  /// 获取额外词条数量，卡牌和装备共用一个算法
  static (int, int, int, int) getMinMaxExtraAffixCount(int rank) {
    assert(rank >= 0 && rank <= kCultivationRankMax);
    int minExtra = 0;
    int maxExtra = 0;
    int minGreater = 0;
    int maxGreater = 0;
    if (rank > 0) {
      if (rank < 5) {
        minExtra = rank - 1;
        maxExtra = rank;
      } else {
        minExtra = maxExtra = 4;
        minGreater = rank - 5;
        maxGreater = rank - 4;
      }
    }
    return (minExtra, maxExtra, minGreater, maxGreater);
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
    // 名声
    final fame = engine.hetu
        .invoke('getCharacterFameString', positionalArgs: [character]);
    row.add(fame);
    // 门派名字
    String organizationName = engine.locale('none');
    final organizationId = character['organizationId'];
    if (organizationId != null) {
      organizationName = GameData.game['organizations'][organizationId]['name'];
    }
    row.add(organizationName);
    // 称号
    final titleId = character['titleId'];
    row.add(titleId != null ? engine.locale(titleId) : engine.locale('none'));
    row.add('${character['level']}');
    row.add(engine.locale('cultivationRank_${character['rank']}'));
    // 多存一个隐藏的 id 信息，用于点击事件
    row.add(character['id']);
    return row;
  }

  static List<String> getLocationInformationRow(dynamic location) {
    final row = <String>[];
    row.add(location['name']);
    // 类型
    row.add(engine.locale(location['kind']));
    // 发展度
    row.add(location['development'].toString());
    // 居民
    row.add(location['residents'].length.toString());
    // 门派名字
    String organizationName = engine.locale('none');
    final organizationId = location['organizationId'];
    if (organizationId != null) {
      organizationName = GameData.game['organizations'][organizationId]['name'];
    }
    row.add(organizationName);
    // 多存一个隐藏的 id 信息，用于点击事件
    row.add(location['id']);
    return row;
  }

  static List<String> getOrganizationInformationRow(dynamic organization) {
    final row = <String>[];
    row.add(organization['name']);
    // 掌门
    row.add(organization['headId']);
    // 类型
    row.add(engine.locale(organization['category']));
    // 流派
    row.add(engine.locale(organization['genre']));
    // 总堂
    final headquarters =
        GameData.game['locations'][organization['headquartersId']];
    assert(headquarters != null,
        'organization headquarters not found, ${organization['id']}, ${organization['headquartersId']}');
    row.add(headquarters['name']);
    // 据点数量
    row.add(organization['locationIds'].length.toString());
    // 成员数量
    row.add(organization['members'].length.toString());
    // 多存一个隐藏的 id 信息，用于点击事件
    row.add(organization['id']);
    return row;
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
      case 'replaceAffix':
        return (expForLevel(cardData['level']) * kReplaceAffixCostRate).round();
      case 'rerollAffix':
        return (expForLevel(cardData['level']) * kRerollAffixCostRate).round();
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

    final heroRank = GameData.hero['rank'];
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
          final passive = GameData.hero['passives']['${genreRequirement}_rank'];
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
      if (GameData.hero['passives']['equipment_$equipmentRequirement'] ==
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
        final int attrValue = GameData.hero['stats'][attr];
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
  static int calculateItemPrice(
    dynamic itemData, {
    dynamic priceFactor,
    bool? useShard,
    bool isSell = true,
  }) {
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

      useShard ??= priceFactor['useShard'] == true;
      if (useShard) {
        final shardToMoneyRate = kMaterialBasePriceByKind['shard'] as int;
        finalPrice = (finalPrice / shardToMoneyRate).ceil();
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
        final shardToMoneyRate = kMaterialBasePriceByKind['shard'] as int;
        finalPrice /= shardToMoneyRate;
      }

      return finalPrice.ceil();
    }
  }

  static List<dynamic> getFilteredItems(
    dynamic character, {
    required ItemType type,
    dynamic filter,
    bool filterShard = false,
  }) {
    final inventoryData = character['inventory'];

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
        if (filterShard && itemData['kind'] == 'shard') {
          continue;
        }
      }

      filteredItems.add(itemData);
    }

    return filteredItems;
  }

  static Future<Iterable<dynamic>> showItemSelect({
    required dynamic character,
    String? title,
    dynamic filter,
    bool multiSelect = false,
  }) {
    final completer = Completer<Iterable<dynamic>>();
    engine.context.read<ItemSelectState>().show(
      character,
      title: title,
      filter: filter,
      multiSelect: multiSelect,
      onSelect: (Iterable<dynamic> items) {
        completer.complete(items);
      },
    );
    return completer.future;
  }

  /// 为某个角色解锁某个天赋树节点
  /// 注意这里不会检查和处理技能点，而是直接增加某个天赋
  static bool characterUnlockPassiveTreeNode(
    dynamic character,
    String nodeId, {
    String? selectedAttributeId,
  }) {
    final unlockedNodes = character['unlockedPassiveTreeNodes'];
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
        selectedAttributeId = character['mainAttribute'];
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
        positionalArgs: [character, selectedAttributeId],
        namedArgs: {'level': kAttributeAnyLevel},
      );
    } else {
      unlockedNodes[nodeId] = true;
      final List nodePassiveData = passiveTreeNodeData['passives'];
      for (final data in nodePassiveData) {
        engine.hetu.invoke(
          'characterSetPassive',
          positionalArgs: [character, data['id']],
          namedArgs: {
            'level': data['level'] ?? 1,
          },
        );
      }
    }

    return true;
  }

  static void characterRefundPassiveTreeNode(
    dynamic character,
    String nodeId,
  ) {
    final passiveTreeNodeData = GameData.passiveTree[nodeId];
    final unlockedNodes = character['unlockedPassiveTreeNodes'];
    bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;

    if (isAttribute) {
      final attributeId = unlockedNodes[nodeId];
      assert(kBattleAttributes.contains(attributeId));
      // engine.hetu.invoke('refundPassive',
      //     namespace: 'Player', positionalArgs: ['lifeMax']);
      engine.hetu.invoke(
        'characterSetPassive',
        positionalArgs: [character, attributeId],
        namedArgs: {'level': -kAttributeAnyLevel},
      );
    } else {
      final List nodePassiveData = passiveTreeNodeData['passives'];
      for (final data in nodePassiveData) {
        engine.hetu.invoke(
          'characterSetPassive',
          positionalArgs: [character, data['id']],
          namedArgs: {'level': -(data['level'] ?? 1)},
        );
      }
    }
    unlockedNodes.remove(nodeId);
  }

  static void characterAllocateSkills(dynamic character,
      {bool rejuvenate = false}) {
    final genre = character['cultivationFavor'];
    final style = character['cultivationStyle'];
    final int rank = character['rank'];
    final int level = character['level'];

    final List<String>? rankPath = kCultivationRankPaths[genre];
    final List<String>? stylePath = kCultivationStylePaths[genre]?[style];
    assert(rankPath != null, 'genre: genre');
    assert(stylePath != null, 'genre: $genre, style: $style');

    int count = 0;
    for (var i = 0; i < rank; ++i) {
      assert(i < rankPath!.length);
      final nodeId = rankPath![i];
      final unlocked = characterUnlockPassiveTreeNode(character, nodeId);
      if (unlocked) {
        count++;
      }
    }

    for (var i = 0; i < level - rank; ++i) {
      assert(i < stylePath!.length);
      final nodeId = stylePath![i];
      final unlocked = characterUnlockPassiveTreeNode(character, nodeId);
      if (unlocked) {
        count++;
      }
    }

    engine.hetu.invoke('characterCalculateStats', positionalArgs: [
      character
    ], namedArgs: {
      'rejuvenate': rejuvenate,
    });

    engine.info(
        '为角色 ${character['name']} (rank: ${character['rank']}, level: ${character['level']}) 在 ${engine.locale('genre')} ${engine.locale(genre)} 的 ${engine.locale(style)} 路线上解锁了 $count 个天赋树节点');
  }

  static dynamic characterHasPassive(dynamic character, String passiveId) {
    return character['passives']?[passiveId];
  }

  // 返回值依次是：卡组下限，消耗牌上限，持续牌上限
  static Map<String, int> getDeckLimitForRank(int rank) {
    assert(rank >= 0);
    final limit = rank + 3;
    final ephemeralMax = (rank + 1) ~/ 3;
    return {
      'limit': limit,
      'ephemeralMax': ephemeralMax,
    };
  }

  static String? checkDeckRequirement(Iterable<dynamic> cards) {
    final deckLimit = getDeckLimitForRank(GameData.hero['rank']);

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

  static int getEquipmentMaxForRank(int rank) {
    return (rank + 1) ~/ 2 + 2;
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
    final locations = GameData.game['locations'];
    if (locations.isEmpty) return null;

    for (final element in locations.keys) {
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
    final organizations = GameData.game['organizations'];
    if (organizations.isEmpty) return null;

    for (final element in organizations.keys) {
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
    final level = GameData.hero['level'];
    final rank = GameData.hero['rank'];
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
      final enemy = engine.hetu.invoke(
        'BattleEntity',
        namedArgs: {
          'isFemale': false,
          'name': engine.locale('theHeavenlyWay'),
          'icon': 'illustration/man_in_shadow.png',
          'level': level,
          'rank': rank,
        },
      );
      characterAllocateSkills(enemy, rejuvenate: true);
      engine.hetu.invoke('generateDeck', positionalArgs: [enemy]);

      final arg = {
        'id': Scenes.battle,
        'hero': GameData.hero,
        'enemy': enemy,
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
    dialog.pushSelection('restOption', [
      'rest1Days',
      'rest10Days',
      'rest30Days',
      'restTillTommorow',
      'restTillNextMonth',
      'restTillFullHealth',
      'cancel',
    ]);
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
            (GameData.hero['stats']['lifeMax'] - GameData.hero['life']).floor();
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
    if (!kWorkableMounths.containsKey(kind)) {
      engine.warn('非可工作场所：${location['name']}($kind)');
      return;
    }

    void notEnoughStamina() async {
      dialog.pushDialog(
        'hint_notEnoughHealthToWork',
        name: npc?['name'],
        icon: npc?['icon'],
        illustration: npc?['image'],
      );
      await dialog.execute();
    }

    if (GameData.hero['life'] <= 1) {
      notEnoughStamina();
      return;
    }

    final months = kWorkableMounths[kind] as List;
    if (!months.contains(month)) {
      dialog.pushDialog(
        'hint_notWorkSeason',
        name: npc?['name'],
        icon: npc?['icon'],
        illustration: npc?['image'],
      );
      await dialog.execute();
      return;
    }

    final salary = kWorkBaseSalaries[kind] as int;
    final staminaCost = kWorkBaseStaminaCost[kind] as int;

    dialog.pushSelection('workOption', [
      'work10Days',
      'work30Days',
      'workTillNextMonth',
      'workTillHealthExhausted',
      'cancel',
    ]);
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
        ticks = (GameData.hero['life'] ~/ staminaCost) - 1;
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
            positionalArgs: [GameData.hero['life'] - staminaCost]);
        return GameData.hero['life'] <= staminaCost;
      },
    );

    engine.play('coins-31879.mp3');
    engine.hetu.invoke('collect', namespace: 'Player', positionalArgs: [
      'money'
    ], namedArgs: {
      'amount': finalTicks * salary,
    });
  }

  static double getMoveCostOnHill() {
    double cost = kBaseMoveCostOnHill;
    final skill = GameData.hero['passives']['stamina_cost_reduce_on_hill'];
    cost -= cost * (skill?['value'] ?? 0) / 100;
    return cost;
  }

  static double getMoveCostOnWater() {
    double cost = kBaseMoveCostOnWater;
    final skill = GameData.hero['passives']['stamina_cost_reduce_on_water'];
    cost -= cost * (skill?['value'] ?? 0) / 100;
    return cost;
  }

  static void onUseItem(dynamic itemData) {
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
      case kItemCategoryCardpack:
        engine.pushScene(Scenes.library, arguments: {
          'cardpacks': {itemData},
          'enableCardCraft': engine.scene?.id == Scenes.mainmenu,
          'enableScrollCraft': engine.scene?.id == Scenes.mainmenu,
        });
      case kItemCategoryIdentifyScroll:
        engine.context.read<ItemSelectState>().show(
          GameData.hero,
          title: engine.locale('selectItem'),
          filter: {'isIdentified': false},
          multiSelect: false,
          onSelect: (Iterable<dynamic> items) {
            if (items.isEmpty) return;
            assert(items.length == 1);
            final selectedItem = items.first;
            selectedItem['isIdentified'] = true;
            engine.play('hammer-hitting-an-anvil-25390.mp3');
            engine.hetu.invoke('lose',
                namespace: 'Player', positionalArgs: [itemData]);
          },
        );
      case kItemCategoryMaterialPack:
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
      // case kItemCategoryExppack:
      //   engine.hetu.invoke('gainExp',
      //       namespace: 'Player', positionalArgs: [itemData['stackSize']]);
      //   engine.hetu
      //       .invoke('lose', namespace: 'Player', positionalArgs: [itemData]);
      //   engine.play('magic-smite-6012.mp3');
      case kItemCategoryPotion:
        engine.hetu.invoke(
          'consumePotion',
          namespace: 'Player',
          positionalArgs: [itemData],
        );
        engine.play('drink-sip-and-swallow-6974.mp3');
    }
  }

  static void onChargeItem(dynamic itemData) async {
    assert(itemData['chargeData'] != null);
    final chargeData = itemData['chargeData'];
    if (chargeData['current'] >= chargeData['max']) {
      GameDialogContent.show(
          engine.context, engine.locale('hint_itemFullyCharged'));
      return;
    }

    final int shards = GameData.hero['materials']['shard'] ?? 0;
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

  /// 更新游戏逻辑，将时间向前推进一帧（tick），可以设定连续更新的帧数
  /// 如果遇到了一些特殊事件可能提前终止
  /// 这会影响一些连续进行的动作，例如探索或者修炼等等
  static void updateGame({
    int tick = 1,
    bool timeflow = true,
    bool forceUpdate = false,
  }) async {
    final int tik = DateTime.now().millisecondsSinceEpoch;

    if (timeflow) {
      if (ticksOfDay == 1) {
        engine.log('--------${GameLogic.getDatetimeString()}--------');
      }
    }

    final int timestamp = GameData.game['timestamp'];

    for (var i = 0; i < tick; ++i) {
      engine.hetu.invoke('handleBabies');

      if (forceUpdate || (day == 1 && ticksOfDay == 1)) {
        // 重置玩家自己的每月行动
        engine.hetu.invoke('resetPlayerMonthlyActivities');
      }

      // 每个建筑每月会根据其属性而消耗维持费用和获得收入
      // 生产类建筑每天都会刷新生产进度
      // 商店类建筑会刷新物品和银两
      // 刷新任务，无论之前的任务是否还存在，非组织拥有的第三方建筑每个月只会有一个任务
      for (final location in GameData.game['locations'].values) {
        // 月度事件
        if (forceUpdate || (day == 1 && ticksOfDay == 1)) {
          updateLocationMonthly(location);
          // 年度事件
          if (month == kLocationYearlyUpdateMonth) {
            updateLocationYearlyStart(location);
          } else if (month == kLocationYearlyUpdateMonth + 1) {
            updateLocationYearlyEnd(location);
          }
        }
      }

      // 触发每个组织的刷新事件
      for (final organization in GameData.game['organizations'].values) {
        // 月度事件
        if (forceUpdate || (day == 1 && ticksOfDay == 1)) {
          updateOrganizationMonthly(organization);

          // 年度事件
          if (month == kOrganizationYearlyUpdateMonth) {
            updateOrganizationYearlyStart(organization);
          } else if (month == kOrganizationYearlyUpdateMonth + 1) {
            updateOrganizationYearlyEnd(organization);
          }
        }
      }

      // 触发每个角色的刷新事件
      for (final character in GameData.game['characters'].values) {
        // 月度事件
        if (forceUpdate || (day == 1 && ticksOfDay == 1)) {
          updateCharacterMonthly(character);

          // 年度事件
          if (month == kCharacterYearlyUpdateMonth) {
            updateCharacterYearlyStart(character);
          } else if (month == kCharacterYearlyUpdateMonth + 1) {
            updateCharacterYearlyEnd(character);
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
        engine.context.read<GameTimestampState>().update();
      }

      if (GameData.hero != null) {
        for (final itemId in GameData.hero['equipments'].values) {
          if (itemId == null) continue;
          final itemData = GameData.hero['inventory'][itemId];
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
  static void updateLocationYearlyStart(dynamic location) {
    engine.debug('${location['id']} 的年度更新开始');
  }

  /// 据点年度更新结束
  static void updateLocationYearlyEnd(dynamic location) {
    engine.debug('${location['id']} 的年度更新结束');
  }

  /// 据点月度更新
  static void updateLocationMonthly(dynamic location) {
    engine.debug('${location['id']} 的月度更新');

    if (location['category'] == 'city') {
    } else if (location['category'] == 'site') {
      // 交易类场景每个月刷新物品
      switch (location['kind']) {
        case 'cityhall':
          engine.hetu
              .invoke('replenishCityhallExp', positionalArgs: [location]);
        case 'library':
          engine.hetu
              .invoke('replenishLibraryBooks', positionalArgs: [location]);
        case 'tradinghouse':
          engine.hetu.invoke('replenishTradingHouseMaterials',
              positionalArgs: [location]);
        case 'auctionhouse':
          engine.hetu
              .invoke('replenishAuctionHouseItems', positionalArgs: [location]);
        case 'alchemylab':
          engine.hetu
              .invoke('replenishAlchemyLabPotions', positionalArgs: [location]);
      }
    }
  }

  /// 组织年度更新开始
  static void updateOrganizationYearlyStart(dynamic organization) {
    engine.debug('${organization['id']} 的年度更新开始');

    organization['isRecruiting'] = true;
    engine.debug('${organization['id']} 的招募活动本月开始。');
  }

  /// 组织年度更新结束
  static void updateOrganizationYearlyEnd(dynamic organization) {
    engine.debug('${organization['id']} 的年度更新结束');

    organization['isRecruiting'] = false;
    engine.debug('${organization['id']} 的招募活动已经结束。');
  }

  /// 组织月度更新
  static void updateOrganizationMonthly(dynamic organization) {
    engine.debug('${organization['id']} 的月度更新');
  }

  /// 角色年度更新开始
  static void updateCharacterYearlyStart(dynamic character) {
    engine.debug('${character['id']} 的年度更新开始');
  }

  /// 角色年度更新结束
  static void updateCharacterYearlyEnd(dynamic character) {
    engine.debug('${character['id']} 的年度更新结束');
  }

  /// 角色月度更新
  static void updateCharacterMonthly(dynamic character) {
    engine.debug('${character['id']} 的月度更新');
  }

  /// 角色濒死，tribulationCount += 1，返回自宅
  static void onDying() {}

  static dynamic onInteractCharacter(dynamic character) async {
    if (character['entityType'] != 'character') {
      assert(character['entityType'] == 'npc',
          'invalid character entity type, ${character['entityType']}');
      final location = GameData.game['locations'][character['atLocationId']];
      assert(location != null, 'npc.atLocationId is null!');
      onInteractNpc(character, location);
      return;
    }

    engine.debug('正在和 主要角色 [${character['name']}] 互动。');

    final result = await engine.hetu.invoke('onGameEvent',
        positionalArgs: ['onBeforeInteractCharacter', character]);
    if (truthy(result)) {
      return result;
    }

    final bond = engine.hetu
        .invoke('characterMet', positionalArgs: [character, GameData.hero]);
    if (bond['score'] < 0) {
      // TODO: 商人不会因为好感低而拒绝交易
      dialog.pushDialog('discourse_unfavorRefusal', character: character);
      await dialog.execute();
      return;
    }

    final selections = [
      'characterInformation',
      'talk',
      'trade',
      'show',
    ];
    final hasGifted = (GameData.game['playerMonthly']['gifted'] as List)
        .contains(character.id);
    final hasAttacked = (GameData.game['playerMonthly']['attacked'] as List)
        .contains(character.id);
    final hasStolen = (GameData.game['playerMonthly']['stolen'] as List)
        .contains(character.id);
    if (!hasGifted) selections.add('gift');
    if (!hasAttacked) selections.add('attack');
    if (!hasStolen) selections.add('steal');
    selections.add('relationshipDiscourse');
    selections.add('bye');
    dialog.pushSelection(
      'characterInteraction',
      selections,
    );
    await dialog.execute();
    final selected = dialog.checkSelected('characterInteraction');

    bool interacted = false;
    switch (selected) {
      case 'characterInformation':
        showDialog(
          context: engine.context,
          builder: (context) => CharacterProfileView(
            character: character,
          ),
        );
      case 'talk':
        final topicSelections = [
          'questTopic',
          'characterTopic',
          'organizationTopic',
          'locationTopic',
          'itemTopic',
          'cancel',
        ];
        dialog.pushSelection(
          'topicSelections',
          topicSelections,
        );
        await dialog.execute();
        final topic = dialog.checkSelected('topicSelections');
        switch (topic) {
          case 'questTopic':
            final questsData = GameData.hero['quests'];
            if (questsData.isEmpty) {
              dialog.pushDialog('hint_noQuests', isHero: true);
              dialog.execute();
              return;
            }
            final questsSelections = {};
            for (final quest in questsData.values) {
              questsSelections[quest['id']] = quest['title'];
            }
            questsSelections['cancel'] = engine.locale('cancel');
            dialog.pushSelectionRaw(
                {'id': 'questSelections', 'selections': questsSelections});
            await dialog.execute();
            final selectedQuest = dialog.checkSelected('questSelections');
            if (selectedQuest != 'cancel') {
              engine.hetu.invoke('onGameEvent', positionalArgs: [
                'onInquiryQuest',
                character,
                questsData[selectedQuest]
              ]);
            }
          case 'characterTopic':
            {}
          case 'organizationTopic':
            {}
          case 'locationTopic':
            {}
          case 'itemTopic':
            {}
        }
      case 'show':
        interacted = true;
        // 向角色展示某个物品
        final items =
            await showItemSelect(character: GameData.hero, multiSelect: false);
        final item = items.firstOrNull;
        if (item != null) {
          engine.info('正在向 ${character['name']} 出示 ${item['name']}');
          engine.hetu.invoke('onGameEvent',
              positionalArgs: ['onShowItem', character, item]);
        }
      case 'gift':
        interacted = true;
        final items =
            await showItemSelect(character: GameData.hero, multiSelect: false);
        final item = items.first;
        if (item != null) {
          engine.info('正在向 ${character.name} 赠送 ${item.name}');
          final result = await engine.hetu.invoke('onGameEvent',
              positionalArgs: ['onGiftItem', character, item]);
          if (result) {
            engine.hetu
                .invoke('lose', namespace: 'Player', positionalArgs: [item]);
            engine.hetu
                .invoke('entityAcquire', positionalArgs: [character, item]);
            dialog.pushDialog('discourse_giftAcception', character: character);
            await dialog.execute();
          } else {
            dialog.pushDialog('discourse_giftRefusal', character: character);
            await dialog.execute();
          }
        }
      case 'trade':
        interacted = true;
        // TODO:
        // 根据好感度决定折扣
        // 根据角色技能决定不同物品的折扣
        // 根据角色境界决定使用铜钱还是灵石交易
        double baseRate = kBaseBuyRate;
        final sellRateModifier =
            (bond['score'] * kPriceFavorRate) * kPriceFavorIncrement;
        baseRate -= sellRateModifier;
        if (baseRate < kMinBuyRate) {
          baseRate = kMinBuyRate;
        }
        double sellRate = kBaseSellRate;
        sellRate += sellRateModifier;
        if (sellRate < kMinSellRate) {
          sellRate = kMinSellRate;
        }
        engine.context.read<MerchantState>().show(
              character,
              useShard: true,
              priceFactor: <String, dynamic>{
                'base': baseRate,
                'sell': sellRate,
              },
              type: MerchantType.character,
            );
      case 'attack':
        interacted = true;
        {}
      case 'steal':
        interacted = true;
        {}
      case 'relationshipDiscourse':
        final relationshipSelections = [];

        /// 玩家角色并不能主动发起浪漫关系
        /// 只能有概率的被动触发 NPC 爱上自己的事件
        /// 只有对方爱上自己的情况下，才可以创建婚姻关系
        final bool isCharacterSpouse = engine.hetu
            .invoke('isSpouse', positionalArgs: [character, GameData.hero]);
        if (!isCharacterSpouse) {
          final bool isCharacterRomance = engine.hetu
              .invoke('isRomance', positionalArgs: [character, GameData.hero]);
          if (isCharacterRomance) {
            final bool hasProposed = GameData.game['playerMonthly']['proposed']
                .contains(character['id']);
            if (!hasProposed) {
              relationshipSelections.add('propose');
            }
          }
        } else {
          relationshipSelections.add('divorce');
        }

        // 师徒关系的传授功法
        final bool isCharacterShifu = engine.hetu
            .invoke('isShifu', positionalArgs: [character, GameData.hero]);
        final bool isCharacterTudi = engine.hetu
            .invoke('isTudi', positionalArgs: [GameData.hero, character]);
        // 不允许既是师父又是徒弟
        assert(!(isCharacterShifu && isCharacterTudi));
        final bool hasConsulted =
            GameData.game['playerMonthly']['consulted'].contains(character.id);
        final bool hasTutored =
            GameData.game['playerMonthly']['tutored'].contains(character.id);
        if (isCharacterShifu) {
          if (!hasConsulted) {
            relationshipSelections.add('consult');
          }
        } else if (isCharacterTudi) {
          if (!hasTutored) {
            relationshipSelections.add('tutor');
          }
        } else {
          final int heroLevel = GameData.hero['level'];
          final int heroRank = GameData.hero['rank'];
          final int characterLevel = character['level'];
          final int characterRank = character['rank'];
          if (characterLevel > heroLevel && characterRank > heroRank) {
            final bool hasBaishi =
                GameData.game['playerMonthly']['baishi'].contains(character.id);
            if (!hasBaishi) {
              relationshipSelections.add('baishi');
            }
          } else if (heroLevel > characterLevel && heroRank > characterRank) {
            final bool hasShoutu =
                GameData.game['playerMonthly']['shoutu'].contains(character.id);
            if (!hasShoutu) {
              relationshipSelections.add('shoutu');
            }
          }
        }

        // 组织的加入，招募和开除
        final bool isCharacterHead = engine.hetu
            .invoke('isOrganizationHead', positionalArgs: [character]);
        final bool isHeroHead = engine.hetu
            .invoke('isOrganizationHead', positionalArgs: [GameData.hero]);
        final bool hasApplied =
            GameData.game['playerMonthly']['applied'].contains(character.id);
        final bool hasRecruited =
            GameData.game['playerMonthly']['recruited'].contains(character.id);
        if (isCharacterHead && !hasApplied) {
          relationshipSelections.add('apply');
        }
        if (isHeroHead && !hasRecruited) {
          relationshipSelections.add('recruit');
        }

        relationshipSelections.add('forgetIt');

        dialog.pushSelection(
          'characterRelationshipInteraction',
          relationshipSelections,
        );

        await dialog.execute();
        final selected2 =
            dialog.checkSelected('characterRelationshipInteraction');

        switch (selected2) {
          case 'propose':
            interacted = true;
            {}
          case 'divorce':
            interacted = true;
            {}
          case 'consult':
            interacted = true;
            {}
          case 'tutor':
            interacted = true;
            {}
          case 'baishi':
            interacted = true;
            {}
          case 'shoutu':
            interacted = true;
            {}
          case 'apply':
            interacted = true;
            {}
          case 'recruit':
            interacted = true;
            {}
        }
    }

    if (interacted) {
      // 任何互动操作后，隐藏该角色不能再次互动
      engine.context.read<NpcListState>().hide(character['id']);
    }
  }

  static void onInteractNpc(dynamic npc, dynamic location) async {
    engine.debug('正在和 NPC [${npc['id']}] 互动。');
    if (npc['useCustomLogic'] == true) {
      engine.debug('NPC [${npc.id}] 使用自定义逻辑。');
      engine.hetu.invoke('onGameEvent',
          positionalArgs: ['onInteractNpc', npc, location]);
      return;
    }

    /// 这里的 organization 可能是 null
    final organization =
        GameData.game['organizations'][location['organizationId']];
    final atLocation = GameData.game['locations'][location['atLocationId']];

    bool isManager = false;
    if (organization != null) {
      if (GameData.hero['id'] == organization['headId']) {
        isManager = true;
      } else if (GameData.hero['id'] == location['ownerId']) {
        isManager = true;
      }
    }

    switch (location['kind']) {
      case 'cityhall':
        dialog.pushSelection('cityhall', [
          'cityInformation',
          'cancel',
        ]);
        await dialog.execute();
        final selected = dialog.checkSelected('cityhall');
        switch (selected) {
          case 'cityInformation':
            showDialog(
              context: engine.context,
              builder: (context) => LocationView(
                location: atLocation,
                mode: isManager
                    ? InformationViewMode.manage
                    : InformationViewMode.view,
              ),
            );
        }
      case 'tradinghouse':
        dialog.pushSelection('tradinghouse', [
          'siteInformation',
          {
            'text': 'work',
            'description': 'startWork_description',
          },
          'trade',
          'cancel',
        ]);
        await dialog.execute();
        final selected = dialog.checkSelected('tradinghouse');
        switch (selected) {
          case 'work':
            heroWork(location, npc);
          case 'trade':
            engine.context.read<MerchantState>().show(
                  location,
                  materialMode: true,
                  priceFactor: location['priceFactor'],
                );
        }
      case 'auctionhouse':
        dialog.pushSelection('auctionhouse', [
          'siteInformation',
          {
            'text': 'work',
            'description': 'startWork_description',
          },
          'trade',
          'cancel',
        ]);
        await dialog.execute();
        final selected = dialog.checkSelected('auctionhouse');
        switch (selected) {
          case 'work':
            heroWork(location, npc);
          case 'trade':
            engine.context.read<MerchantState>().show(
              location,
              useShard: location['development'] > 0,
              priceFactor: location['priceFactor'],
              filter: {'category': 'equipment'},
            );
        }
      case 'headquarters':
        dialog.pushSelection('headquarters', [
          'organizationInformation',
          'cancel',
        ]);
        await dialog.execute();
        final selected = dialog.checkSelected('headquarters');
        switch (selected) {
          case 'organizationInformation':
            showDialog(
              context: engine.context,
              builder: (context) => OrganizationView(
                organization: organization,
                mode: isManager
                    ? InformationViewMode.manage
                    : InformationViewMode.view,
              ),
            );
        }
      case 'arena':
        dialog.pushSelection('arena', [
          'siteInformation',
          'cancel',
        ]);
        await dialog.execute();
        final selected = dialog.checkSelected('arena');
        switch (selected) {
          case 'siteInformation':
            {}
        }
      case 'library':
        dialog.pushSelection('library', [
          'siteInformation',
          {
            'text': 'work',
            'description': 'startWork_description',
          },
          'trade',
          'cancel',
        ]);
        await dialog.execute();
        final selected = dialog.checkSelected('library');
        switch (selected) {
          case 'work':
            heroWork(location, npc);
          case 'trade':
            engine.context.read<MerchantState>().show(
                  location,
                  useShard: true,
                  priceFactor: location['priceFactor'],
                  // filter: {'category': 'cardpack'},
                );
        }
      case 'workshop':
        dialog.pushSelection('workshop', [
          'siteInformation',
          {
            'text': 'work',
            'description': 'startWork_description',
          },
          'workbench',
          'cancel',
        ]);
        await dialog.execute();
        final selected = dialog.checkSelected('workshop');
        switch (selected) {
          case 'siteInformation':
            {}
          case 'workbench':
            engine.context.read<ViewPanelState>().toogle(ViewPanels.workbench);
        }
      case 'alchemylab':
        dialog.pushSelection('alchemylab', [
          'siteInformation',
          {
            'text': 'work',
            'description': 'startWork_description',
          },
          'alchemy_furnace',
          'trade',
          'cancel',
        ]);
        await dialog.execute();
        final selected = dialog.checkSelected('alchemylab');
        switch (selected) {
          case 'siteInformation':
            {}
          case 'work':
            heroWork(location, npc);
          case 'alchemy_furnace':
            {}
          case 'trade':
            engine.context.read<MerchantState>().show(
                  location,
                  useShard: true,
                  priceFactor: location['priceFactor'],
                  // filter: {'category': 'potion'},
                );
        }
      case 'arraylab':
        {}
      case 'illusionaltar':
        {}
      case 'divinationaltar':
        {}
      case 'psychictemple':
        {}
      case 'theurgytemple':
        {}
    }
  }

  /// 异步函数，在显示场景窗口之前执行
  static Future<dynamic> tryEnterLocation(dynamic location) async {
    engine.debug('正在尝试进入据点 [${location['name']}]');
    // [result] 值是 true 意味着不会进入场景
    final result = await engine.hetu.invoke('onGameEvent',
        positionalArgs: ['onBeforeEnterLocation', location]);
    if (truthy(result)) return;

    GameLogic.updateGame();
    engine.pushScene(
      location['id'],
      constructorId: Scenes.location,
      arguments: {'location': location},
    );
  }

  static void onAfterEnterLocation(dynamic location) async {
    await engine.hetu.invoke('onGameEvent',
        positionalArgs: ['onAfterEnterLocation', location]);

    if (location['kind'] == 'home') {
      final ownerId = location['ownerId'];
      if (ownerId != GameData.hero['id']) {
        final owner = GameData.game['characters'][ownerId];
        if (owner['locationId'] != location['id']) {
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
    dynamic organization, {
    dynamic location,
    bool? enableCultivate,
  }) async {
    // organizationData可能为 null，此时该据点没有被门派占领
    if (organization == null ||
        GameData.hero['organizationId'] == organization['id']) {
      engine.pushScene(Scenes.cultivation, arguments: {
        'location': location,
        'enableCultivate': location == null ? enableCultivate : false,
        'onEnterScene': () async {
          if (GameData.game['flags']['hintedCultivation'] != true) {
            GameData.game['flags']['hintedCultivation'] = true;

            dialog.pushDialog(
              'hint_tutorial',
              name: engine.locale('servant'),
              icon: 'illustration/npc/servant_head.png',
              illustration: 'illustration/npc/servant.png',
            );
            dialog.pushSelection('tutorial', [
              'listenTutorial',
              'forgetIt',
            ]);
            await dialog.execute();
            final selected = dialog.checkSelected('tutorial');

            if (selected == 'listenTutorial') {
              dialog.pushDialog(
                'hint_cultivation',
                name: engine.locale('servant'),
                icon: 'illustration/npc/servant_head.png',
                illustration: 'illustration/npc/servant.png',
              );
              await dialog.execute();
            }

            // final item = engine.hetu.invoke('Materialpack', namedArgs: {
            //   'kind': 'shard',
            //   'amount': 5,
            // });
            // engine.hetu
            //     .invoke('acquire', namespace: 'Player', positionalArgs: [item]);

            // dialog.pushDialog(
            //   {
            //     'name': engine.locale('servant'),
            //     'icon': 'illustration/npc/servant_head.png',
            //     'lines': engine.locale('hint_cultivation2').split('\n'),
            //   },
            //   imageId: 'illustration/npc/servant.png',
            // );
            // await dialog.execute();

            // engine.context.read<NewItemsState>().update(items: [item]);
          }
        },
      });
    } else {
      dialog.pushDialog(
        'hint_organizationFacilityNotMember',
        name: engine.locale('servant'),
        icon: 'illustration/npc/servant_head.png',
        illustration: 'illustration/npc/servant.png',
      );
      await dialog.execute();
    }
  }

  /// 和门派藏书阁的功法图录交互
  /// 如果并非此组织成员，无法使用
  static void onInteractLibraryDesk({
    dynamic organization,
    dynamic location,
  }) async {
    if (organization == null ||
        GameData.hero['organizationId'] == organization['id']) {
      engine.pushScene(Scenes.library, arguments: {
        'enableCardCraft': true,
        'enableScrollCraft':
            organization?['techs']?['enableScrollCraft'] ?? false,
        'onEnterScene': () async {
          if (GameData.game['flags']['hintedCardLibrary'] != true) {
            GameData.game['flags']['hintedCardLibrary'] = true;

            dialog.pushDialog(
              'hint_tutorial',
              name: engine.locale('servant'),
              icon: 'illustration/npc/servant_head.png',
              illustration: 'illustration/npc/servant.png',
            );
            dialog.pushSelection('tutorial', [
              'listenTutorial',
              'forgetIt',
            ]);
            await dialog.execute();
            final selected = dialog.checkSelected('tutorial');

            if (selected == 'listenTutorial') {
              dialog.pushDialog(
                'hint_cardLibrary',
                name: engine.locale('servant'),
                icon: 'illustration/npc/servant_head.png',
                illustration: 'illustration/npc/servant.png',
              );
              await dialog.execute();
            }

            // final item =
            //     engine.hetu.invoke('Cardpack', namedArgs: {'isBasic': true});
            // engine.hetu
            //     .invoke('acquire', namespace: 'Player', positionalArgs: [item]);

            // dialog.pushDialog(
            //   {
            //     'name': engine.locale('servant'),
            //     'icon': 'illustration/npc/servant_head.png',
            //     'lines': engine.locale('hint_cardLibrary2').split('\n'),
            //   },
            //   imageId: 'illustration/npc/servant.png',
            // );
            // await dialog.execute();

            // engine.context.read<NewItemsState>().update(items: [item]);
          }
        },
      });
    } else if (organization != null) {
      dialog.pushDialog(
        'hint_organizationFacilityNotMember',
        name: engine.locale('servant'),
        icon: 'illustration/npc/servant_head.png',
        illustration: 'illustration/npc/servant.png',
      );
      await dialog.execute();
    }
  }

  /// 和秘境入口交互
  /// 秘境在生成时，会随机产生一个开放月份，只有在开放月份时才能进入。
  /// 秘境如果被某个门派占领，则非门派成员无法进入。
  /// 秘境进入时可以选择境界。无境界无需门票。凝气期以上则需要支付对应境界的秘境石。
  static void onInteractDungeonEntrance(dynamic dungeon) {}
}
