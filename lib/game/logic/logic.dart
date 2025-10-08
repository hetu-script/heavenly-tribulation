import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/state/states.dart';
import 'package:provider/provider.dart';
import 'package:hetu_script/utils/math.dart' as math;
import 'package:samsara/samsara.dart';

import '../common.dart';
import '../../widgets/dialog/timeflow.dart';
import '../../scene/game_dialog/selection_dialog.dart';
import '../../engine.dart';
import '../../scene/game_dialog/game_dialog_content.dart';
import '../../widgets/dialog/select_menu.dart';
import '../../widgets/dialog/input_slider.dart';
import '../../scene/common.dart';
import '../data.dart';
import '../../widgets/entity_listview.dart';

import '../../widgets/organization/organization.dart';
import '../../widgets/location/functional/bounty_quest.dart';
import '../../widgets/location/location.dart';
import '../../widgets/character/profile.dart';
import '../../widgets/common.dart';

import 'common.dart';

part 'character.dart';
part 'location.dart';

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
      final spriteIndex = tile['spriteIndex'];
      if (spriteIndex == null) return;
      if (tile['zoneId'] != null) return;
      // engine.debug(
      //     'processing: ${tile['left']},${tile['top']}, spriteIndex: ${tile['spriteIndex']}');
      if (zone == null) {
        assert(kTileSpriteIndexToZoneCategory.containsKey(spriteIndex));
        final String category = kTileSpriteIndexToZoneCategory[spriteIndex]!;
        zone = engine.hetu.invoke('Zone', namedArgs: {'category': category});
        tile['zoneId'] = zone['id'];
        ++count;
      } else {
        tile['zoneId'] = zone['id'];
      }
      indexed.add(tile['index']);
      engine.hetu.invoke('addTerrainToZone', positionalArgs: [tile, zone]);

      final neighbors = engine.hetu.invoke('getNeighborTiles',
          positionalArgs: [tile['left'], tile['top']]);
      for (final neighbor in neighbors.values) {
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
  /// ```
  /// {
  ///   'minExtra': minExtra,
  ///   'maxExtra': maxExtra,
  ///   'minGreater': minGreater,
  ///   'maxGreater': maxGreater
  /// }
  /// ```
  static Map<String, int> getMinMaxExtraAffixCount(int rank) {
    assert(rank >= 0 && rank <= kCultivationRankMax);
    int minExtra = 0;
    int maxExtra = 0;
    int minGreater = 0;
    int maxGreater = 0;
    if (rank > 0) {
      minExtra = rank - 1;
      maxExtra = rank + 1;
    }
    if (rank > 2) {
      minGreater = rank - 3;
      maxGreater = rank - 2;
    }
    return {
      'minExtra': minExtra,
      'maxExtra': maxExtra,
      'minGreater': minGreater,
      'maxGreater': maxGreater
    };
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
    final homeLocationId = character['homeLocationId'];
    final homeLocation = GameData.game['locations'][homeLocationId];
    row.add(homeLocation?['name'] ?? engine.locale('none'));
    // 门派名字
    String organizationName = engine.locale('none');
    final organizationId = character['organizationId'];
    if (organizationId != null) {
      final organization = GameData.getOrganization(organizationId);
      organizationName = organization['name'];
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

  static List<String> getCityInformationRow(dynamic location) {
    assert(location['category'] == 'city');

    final row = <String>[];
    row.add(location['name']);
    final worldPosition = location['worldPosition'];
    row.add('[${worldPosition['left']}, ${worldPosition['top']}]');
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
      final organization = GameData.getOrganization(organizationId);
      organizationName = organization['name'];
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
        GameData.getLocation(organization['headquartersLocationId']);
    row.add(headquarters['name']);
    // 据点数量
    row.add(organization['locationIds'].length.toString());
    // 成员数量
    row.add(organization['members'].length.toString());
    row.add('${organization['recruitMonth']}${engine.locale('dateMonth')}');
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

  static Map<String, dynamic> getCardCraftMaterial(
      String operation, dynamic cardData) {
    assert(kCardOperations.contains(operation));
    switch (operation) {
      case 'dismantle':
        return {'exp': calculateBattleCardPrice(cardData)};
      case 'addAffix':
        return {
          'materialId': 'craftmaterial_addAffix',
          'count': 1,
        };
      case 'replaceAffix':
        return {
          'materialId': 'craftmaterial_replaceAffix',
          'count': 1,
        };
      case 'rerollAffix':
        return {
          'materialId': 'craftmaterial_rerollAffix',
          'count': 1,
        };
      case 'upgradeRank':
        final int rank = cardData['rank']!;
        if (rank < kCultivationRankMax) {
          return {
            'materialId': 'craftmaterial_upgradeRank${rank + 1}',
            'count': 1,
          };
        } else {
          return {};
        }
      case 'craftScroll':
        return {
          'exp':
              (expForLevel(cardData['level']) * kCraftScrollCostRate).round(),
          'paperCount': 1,
        };
      default:
        engine.error('未知的卡牌操作类型 $operation');
        return {};
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
    if (cardData['genre'] == 'scroll') {
      return 0;
    }
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
        final shardToMoneyRate = kMaterialBasePrice['shard'] as int;
        finalPrice = (finalPrice / shardToMoneyRate).ceil();
      }

      return finalPrice;
    }
  }

  /// 参考 [calculateItemPrice]
  static int calculateMaterialPrice(String materialId,
      {dynamic priceFactor, bool isSell = true}) {
    assert(kMaterialBasePrice.containsKey(materialId));
    final price = kMaterialBasePrice[materialId] as int;

    if (priceFactor == null) {
      return price;
    } else {
      final double base = priceFactor['base'] ?? kBaseBuyRate; // 基础值：1.0
      final double sell = priceFactor['sell'] ?? kBaseSellRate; // 基础值：0.5

      final double kind = priceFactor['kind']?[materialId] ?? 1.0;

      double finalPrice = price * base * kind * (isSell ? sell : 1.0);

      if (priceFactor['useShard'] == true) {
        final shardToMoneyRate = kMaterialBasePrice['shard'] as int;
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

    engine.debug(
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

  static double getHPRestoreRateAfterBattle(int roundCount) {
    final rate = kBaseAfterBattleHPRestoreRate -
        kBaseAfterBattleHPRestoreRate *
            math.gradualValue(roundCount, kBattleCardsCount, power: 0.5);

    return rate;
  }

  static Future<String?> selectWorld() async {
    return showDialog(
      context: engine.context,
      builder: (context) => SelectMenuDialog(
          selections: {for (var element in GameData.worldIds) element: element},
          selectedValue:
              GameData.worldIds.firstWhere((id) => id != GameData.world['id'])),
    );
  }

  static Future<String?> selectCharacter([List? ids]) async {
    return showDialog(
      context: engine.context,
      barrierDismissible: false,
      builder: (context) => EntityListView(
        showCloseButton: false,
        mode: EntityListViewMode.selectCharacter,
        characters: ids,
      ),
    );
  }

  static Future<String?> selectLocation([List? ids]) async {
    return showDialog(
      context: engine.context,
      barrierDismissible: false,
      builder: (context) => EntityListView(
        showCloseButton: false,
        mode: EntityListViewMode.selectLocation,
        locationIds: ids,
      ),
    );
  }

  static Future<String?> selectOrganization([List? ids]) async {
    return showDialog(
      context: engine.context,
      barrierDismissible: false,
      builder: (context) => EntityListView(
        showCloseButton: false,
        mode: EntityListViewMode.selectOrganization,
        organizationIds: ids,
      ),
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

      engine.context.read<EnemyState>().show(
        enemy,
        // prebattlePreventClose: true,
        // onBattleStart: () {
        //   bool? hintedTribulation =
        //       GameData.gameData['flags']['hintedTribulation'];
        //   if (hintedTribulation == null || hintedTribulation == false) {
        //     GameDialogContent.show(
        //         engine.context, engine.locale('hint_tribulation_beforeBattle'));
        //     GameData.gameData['flags']['hintedTribulation'] = true;
        //   }
        // },
        onBattleEnd: (bool result, int roundCount) {
          if (result) {
            engine.hetu.invoke('levelUp', namespace: 'Player');
            final rank = engine.hetu.invoke('rankUp', namespace: 'Player');
            promptNewRank(rank);
          }
        },
      );

      // engine.pushScene(
      //   Scenes.battle,
      //   arguments: {
      //     'id': Scenes.battle,
      //     'hero': GameData.hero,
      //     'enemy': enemy,
      //   },
      // );
    } else {
      GameDialogContent.show(
          engine.context, engine.locale('hint_cancel_tribulation'));
    }
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

  static Future<void> promptItems(List items) async {
    engine.setCursor(Cursors.normal);
    final completer = Completer();
    engine.context
        .read<NewItemsState>()
        .update(items: items, completer: completer);
    return completer.future;
  }

  static Future<void> promptJournal(dynamic journal) async {
    engine.setCursor(Cursors.normal);
    final completer = Completer();
    engine.context
        .read<NewJournalState>()
        .update(journal: journal, completer: completer);
    return completer.future;
  }

  static Future<void> promptNewRank(int rank) async {
    engine.setCursor(Cursors.normal);
    final completer = Completer();
    engine.context
        .read<NewRankState>()
        .update(rank: rank, completer: completer);
    return completer.future;
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

    engine.debug('物品 ${itemData['name']} 增加了 $charge 充能次数');
    engine.play('electric-sparks-68814.mp3');
  }

  static void heroRest() => _heroRest();

  static Future<void> heroWork(dynamic location, dynamic npc) =>
      _heroWork(location, npc);

  static void onInteractDepositBox(dynamic home) {
    engine.context.read<MerchantState>().show(
          home,
          merchantType: MerchantType.depositBox,
        );
  }

  static Future<void> onInteractNpc(dynamic npc, dynamic location) =>
      _onInteractNpc(npc, location);

  static Future<void> onInteractCharacter(dynamic character) =>
      _onInteractCharacter(character);

  /// 更新游戏逻辑，将时间向前推进一帧（tick），可以设定连续更新的帧数
  /// 如果遇到了一些特殊事件可能提前终止
  /// 这会影响一些连续进行的动作，例如探索或者修炼等等
  static void updateGame({
    int tick = 1,
    bool timeflow = true,
    bool udpateWorldMap = true,
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
        engine.hetu.invoke('resetPlayerMonthly');
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
          engine.hetu.invoke('replenishCityhall', positionalArgs: [location]);
        case 'tradinghouse':
          engine.hetu
              .invoke('replenishTradingHouse', positionalArgs: [location]);
        case 'exparray':
          engine.hetu.invoke('replenishExpArray', positionalArgs: [location]);
        case 'library':
          engine.hetu.invoke('replenishLibrary', positionalArgs: [location]);
        case 'auctionhouse':
          engine.hetu
              .invoke('replenishAuctionHouse', positionalArgs: [location]);
        case 'alchemylab':
          engine.hetu.invoke('replenishAlchemyLab', positionalArgs: [location]);
        case 'runelab':
          engine.hetu.invoke('replenishRuneLab', positionalArgs: [location]);
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

  /// 异步函数，在显示场景窗口之前执行
  static Future<dynamic> tryEnterLocation(dynamic location) async {
    engine.debug('正在尝试进入据点 [${location['name']}]');
    // [result] 值是 true 意味着不会进入场景
    final result = await engine.hetu.invoke('onGameEvent',
        positionalArgs: ['onBeforeEnterLocation', location]);
    if (truthy(result)) return;

    engine.context.read<HoverContentState>().hide();
    engine.context.read<ViewPanelState>().clearAll();
    GameLogic.updateGame();
    engine.pushScene(
      location['id'],
      constructorId: Scenes.location,
      arguments: {'location': location},
    );
  }

  static void onAfterEnterLocation(dynamic location) =>
      _onAfterEnterLocation(location);

  static void tryInteractObject(String objectId, dynamic terrainData) {
    final objectsData = engine.hetu.fetch('objects', namespace: 'world');
    final objectData = objectsData[objectId];
    engine.hetu.invoke('onInteractMapObject',
        positionalArgs: [objectData, terrainData]);
  }

  static void tryEnterDungeon({
    int? rank,
    bool isBasic = false,
    String dungeonId = 'dungeon_1',
    bool pushScene = true,
  }) {
    if (isBasic) {
      engine.hetu.invoke('resetDungeon', namedArgs: {
        'rank': rank ?? 0,
        'isBasic': true,
      });
      if (!pushScene) return;
      engine.pushScene(
        'dungeon_1',
        constructorId: Scenes.worldmap,
        arguments: {
          'id': 'dungeon_1',
          'method': 'load',
        },
      );
    } else {
      engine.context.read<ItemSelectState>().show(
        GameData.hero,
        title: engine.locale('selectItem'),
        filter: rank != null
            ? {'kind': 'dungeon_ticket_rank$rank'}
            : {'category': 'dungeon_ticket'},
        multiSelect: false,
        onSelect: (Iterable<dynamic> items) {
          if (items.isEmpty) return;
          assert(items.length == 1);
          final selectedItem = items.first;
          engine.hetu.invoke('lose',
              namespace: 'Player', positionalArgs: [selectedItem]);
          engine.hetu.invoke('resetDungeon', namedArgs: {
            'rank': selectedItem['rank'],
            'isBasic': false,
          });
          if (!pushScene) return;
          engine.pushScene(
            dungeonId,
            constructorId: Scenes.worldmap,
            arguments: {
              'id': dungeonId,
              'method': 'load',
            },
          );
        },
      );
    }
  }

  static void onInteractDungeonEntrance({
    dynamic organization,
    dynamic location,
  }) =>
      _onInteractDungeonEntrance(
        organization: organization,
        location: location,
      );

  static void onInteractExpArray(
    dynamic organization, {
    dynamic location,
  }) =>
      _onInteractExpArray(
        organization,
        location: location,
      );

  static void onInteractCardLibraryDesk({
    dynamic organization,
    dynamic location,
  }) =>
      _onInteractCardLibraryDesk(
        organization: organization,
        location: location,
      );
}
