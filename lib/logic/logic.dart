import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hetu_script/utils/math.dart' as math;
import 'package:hetu_script/utils/collection.dart' as utils;

import '../data/common.dart';
import '../data/game.dart';
import '../global.dart';
import '../scene/common.dart';
import '../state/states.dart';
import '../scene/game_dialog/game_dialog_content.dart';
import '../widgets/timeflow.dart';
import '../widgets/dialog/select_menu.dart';
import '../widgets/dialog/input_slider.dart';
import '../widgets/information.dart';
import '../widgets/view/quest_view.dart';
import '../widgets/character/profile.dart';
import '../widgets/dialog/input_name.dart';

part 'character.dart';
part 'location.dart';
part 'sect.dart';

// 为城市分配领地时候的最大循环数
const _kMaxCityTerritorySize = 100;

const _kLandCityTerritoryTerrainKinds = {
  'plain',
  'forest',
  'shore',
  'shelf',
  'lake'
};

const _kHintDyingVariants = 5;

const _kBasicDungeonShardCost = 1;

const _kGameFlagsUpdateDay = 1;
const _kSectUpdateDay = 6;

// 获得门派奖赏的每月最低贡献值
const _kSectExpectedMonthlyContribution = 16;

final class GameLogic {
  static bool truthy(dynamic value) => engine.hetu.interpreter.truthy(value);

  static int ticksOfYear = 0;
  static int ticksOfMonth = 0;
  static int ticksOfDay = 0;
  static int ticksOfTime = 0;
  static int year = 1;
  static int month = 1;
  static int day = 1;
  static int time = 1;
  static String timeString = '';

  static String getDatetimeString({bool withTime = true}) {
    return '$year${engine.locale('dateYear')}$month${engine.locale('dateMonth')}$day${engine.locale('dateDay')}${withTime ? engine.locale(timeString) : ''}';
  }

  /// 游戏内的时间
  static (int, String) calculateTimestamp() {
    final int timestamp = GameData.game['timestamp'];
    ticksOfYear = timestamp % kTicksPerYear;
    ticksOfMonth = timestamp % kTicksPerMonth;
    ticksOfDay = timestamp % kTicksPerDay;
    ticksOfTime = timestamp % kTicksPerTime;

    year = (timestamp ~/ kTicksPerYear) + 1; // 当前年数
    month = (ticksOfYear ~/ kTicksPerMonth) + 1; // 当前月数 1-12
    day = (ticksOfMonth ~/ kTicksPerDay) + 1; // 当前月的天数 1-30
    time = (ticksOfDay ~/ kTicksPerTime) + 1; // 当前的时刻 1-4
    timeString = kTimeStrings[time]!; // 清晨、下午、傍晚、午夜

    final datetimeString = getDatetimeString();
    return (timestamp, datetimeString);
  }

  static void generateCityTerritory(dynamic world) {
    final cities = GameData.game['locations'].values.where(
      (location) =>
          location['category'] == 'city' && location['worldId'] == world['id'],
    );

    // 给城市添加一个控制的地块作为领地
    // 只能添加边界地块
    void addTileToCityTerritory(dynamic city, int tileIndex, Set terrainKinds) {
      assert(terrainKinds.isNotEmpty);
      final List territoryIndexes = city['territoryIndexes'];
      assert(!territoryIndexes.contains(tileIndex));
      territoryIndexes.add(tileIndex);
      final List borderIndexes = city['borderIndexes'];
      assert(borderIndexes.contains(tileIndex) || borderIndexes.isEmpty);
      borderIndexes.remove(tileIndex);

      final tile = world['terrains'][tileIndex];
      tile['cityId'] = city['id'];

      final neighbors = engine.hetu.invoke(
        'getTileNeighbors',
        positionalArgs: [tile['left'], tile['top']],
        namedArgs: {'terrainKinds': terrainKinds},
      );
      for (final neighbor in neighbors.values) {
        final neighborIndex = neighbor['index'];
        if (territoryIndexes.contains(neighborIndex)) continue;
        if (borderIndexes.contains(neighborIndex)) continue;
        borderIndexes.add(neighborIndex);
      }
    }

    Map<int, Set<dynamic>> cityTerrainKinds = {};

    for (var i = 0; i < _kMaxCityTerritorySize; ++i) {
      for (final city in cities) {
        final int cityIndex = city['terrainIndex'];
        final terrain = world['terrains'][cityIndex];
        final terrainKind = terrain['kind'];
        Set? terrainKinds = cityTerrainKinds[cityIndex];
        if (terrainKinds == null) {
          if (_kLandCityTerritoryTerrainKinds.contains(terrainKind)) {
            terrainKinds =
                cityTerrainKinds[cityIndex] = _kLandCityTerritoryTerrainKinds;
          } else {
            terrainKinds = cityTerrainKinds[cityIndex] = {terrainKind};
          }
        }

        final List territoryIndexes = city['territoryIndexes'];
        final List borderIndexes = city['borderIndexes'];
        if (borderIndexes.isEmpty) {
          if (territoryIndexes.isEmpty) {
            // 城市没有任何领地，以城市本身的地块开始
            addTileToCityTerritory(city, cityIndex, terrainKinds);
          }
        } else {
          final availableTileIndexes = borderIndexes.toList();
          // 复制一份用来随机化领地扩张顺序
          availableTileIndexes.shuffle(GameData.random);
          int? selectedIndex;
          for (final tileIndex in availableTileIndexes) {
            final borderTile = world['terrains'][tileIndex];
            if (borderTile['cityId'] != null ||
                borderTile['locationId'] != null) {
              // 因为城市扩张是并行进行的
              // 因此有可能当前边界地块已经被别的城市占领了
              borderIndexes.remove(tileIndex);
              continue;
            }
            selectedIndex = tileIndex;
          }
          if (selectedIndex != null) {
            addTileToCityTerritory(city, selectedIndex, terrainKinds);
          }
        }
      }
    }

    // 检查被完全围起来的地块，将其划归给邻近的城市
    final unoccupiedTiles = world['terrains'].where(
      (tile) => tile['cityId'] == null,
    );
    for (final tile in unoccupiedTiles) {
      final neighbors = engine.hetu.invoke(
        'getTileNeighbors',
        positionalArgs: [tile['left'], tile['top']],
      );
      if (neighbors.isEmpty) continue;

      final firstNeighbor = neighbors.values.first;
      final firstCityId = firstNeighbor['cityId'];
      if (firstCityId == null) continue;

      final firstCity = GameData.game['locations'][firstCityId];

      if (neighbors.length == 1) {
        addTileToCityTerritory(firstCity, tile['index'],
            cityTerrainKinds[firstCity['terrainIndex']]!);
      } else {
        bool isLocked = true;
        for (final neighbor in neighbors.values.skip(1)) {
          if (neighbor['cityId'] != firstCityId) {
            isLocked = false;
            break;
          }
        }
        if (isLocked) {
          addTileToCityTerritory(firstCity, tile['index'],
              cityTerrainKinds[firstCity['terrainIndex']]!);
        }
      }
    }

    engine.info('生成了 ${cities.length} 个城市的领地范围。');
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

      final neighbors = engine.hetu.invoke('getTileNeighbors',
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

    engine.info('生成了 $count 个地域。');
    return count;
  }

  /// 计算某个境界的最低等级
  static int minLevelForRank(int rank) {
    assert(rank >= 0);
    return rank == 0 ? 0 : (rank * 10 - 5);
  }

  /// 计算某个境界的最高等级
  static int maxLevelForRank(int rank) {
    assert(rank >= 0);
    return (rank + 2) * 10 - 5;
  }

  /// 计算达到某个声望等级所需的声望
  static int fameForRank(int rank) {
    return rank * (rank + 1) * 10;
  }

  /// 计算升级到某个等级所需的总经验值
  static int expForLevel(int level) {
    return ((level * level) * 10 + level * 100 + 40) ~/ 3 * 2;
  }

  /// 计算某个职位等级所需的功勋值
  static int contributionForJobRank(int jobRank) {
    assert(jobRank >= 0 && jobRank <= kJobRankMax);
    // int r = kJobRankMax - jobRank;
    int r = jobRank;
    int n;
    if (r == 0) {
      n = 0;
    } else {
      n = math.pow(3, r) * 100 ~/ 3 + r * r * 100;
    }
    return n;
  }

  /// 计算某个城市规模对应的可修建建筑数量
  /// 城市本身自带的会堂、交易所和总部，不包含在这个数量中，需要另外加上
  static int calculateMaxSiteCountForCity(dynamic city) {
    final int development = city['development'];
    final bool isCapitalCity = city['isCapitalCity'] == true;
    return isCapitalCity ? development * 2 + 4 : development * 2 + 3;
  }

  static int maxCityCountForSectDevelopment(int development) {
    return development * development * development + 1;
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

  static int getTribulationCountForRank(int rank) {
    if (rank <= 0) {
      return -1;
    } else {
      var count = 128;
      for (var i = 0; i < rank; ++i) {
        count = count ~/ 2;
      }
      return count;
    }
  }

  static Map<String, int> getLifeSpanForRank(int rank) {
    assert(rank >= 0 && rank <= kCultivationRankMax);

    return {
      'min': rank * rank * 10 + (rank + 1) * 60,
      'max': rank * rank * 20 + (rank + 1) * 80 + 20,
    };
  }

  // TODO: 对于灵宝、神照、混元，境界仅仅影响随机数概率
  // 对于破境，则必须使用 [当前境界 + 1] 的破境丹
  static Map<String, dynamic> getCardCraftMaterial(
      String operation, dynamic cardData) {
    assert(kCardOperations.contains(operation));
    switch (operation) {
      case 'dismantle':
        return {'exp': calculateBattleCardPrice(cardData)};
      case 'addAffix':
        return {
          'id': 'craftmaterial_addAffix',
          'rank'
              'count': 1,
        };
      case 'replaceAffix':
        return {
          'id': 'craftmaterial_replaceAffix',
          'count': 1,
        };
      case 'rerollAffix':
        return {
          'id': 'craftmaterial_rerollAffix',
          'count': 1,
        };
      case 'upgradeRank':
        final int rank = cardData['rank']!;
        if (rank < kCultivationRankMax) {
          return {
            'id': 'craftmaterial_upgrade_rank${rank + 1}',
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
    final equipmentRequirement = entityData['equipment'];
    if (equipmentRequirement != null) {
      if (equipmentRequirement is List) {
        bool hasAnyEquipment = false;
        for (final req in equipmentRequirement) {
          assert(req is String,
              'Invalid equipment requirement on card data: [$req]');
          if (GameData.hero['passives']['equipment_$req'] != null) {
            hasAnyEquipment = true;
            break;
          }
        }
        if (!hasAnyEquipment) {
          requirementsMet = false;
          description.writeln(
              '<red>${engine.locale('equipment_requirement')}: ${equipmentRequirement.map((r) => engine.locale(r)).join(',')}</>');
        }
      } else {
        assert(equipmentRequirement is String,
            'Invalid equipment requirement on card data: [$equipmentRequirement]');
        if (GameData.hero['passives']['equipment_$equipmentRequirement'] ==
            null) {
          requirementsMet = false;
          description.writeln(
              '<red>${engine.locale('equipment_requirement')}: ${engine.locale(equipmentRequirement)}</>');
        }
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
      final double base = priceFactor['base'] ?? kBuyRateBase; // 基础值：1.0
      final double sell = priceFactor['sell'] ?? kSellRateBase; // 基础值：0.5

      final double category =
          priceFactor['category']?[itemData['category']] ?? 1.0;
      final double kind = priceFactor['kind']?[itemData['kind']] ?? 1.0;

      double ratio = base * category * kind * (isSell ? sell : 1.0);
      final min = isSell ? kMinSellRate : kMinBuyRate;
      if (ratio < min) ratio = min;

      int finalPrice = (price * ratio).ceil();

      useShard ??= priceFactor['useShard'] == true;
      if (useShard) {
        final shardToMoneyRate = kMaterialPrice['shard'] as int;
        finalPrice = (finalPrice / shardToMoneyRate).ceil();
      }

      return finalPrice;
    }
  }

  /// 参考 [calculateItemPrice]
  static int calculateMaterialPrice(String materialId,
      {dynamic priceFactor, bool isSell = true}) {
    assert(kMaterialPrice.containsKey(materialId));
    double price = (kMaterialPrice[materialId]!).toDouble();

    if (priceFactor == null) {
      return price.round();
    } else {
      final double base = priceFactor['base'] ?? kBuyRateBase; // 基础值：1.0
      final double sell = priceFactor['sell'] ?? kSellRateBase; // 基础值：0.5

      final double kind = priceFactor['kind']?[materialId] ?? 1.0;

      price = price * base * kind * (isSell ? sell : 1.0);

      if (priceFactor['useShard'] == true) {
        final shardToMoneyRate = kMaterialPrice['shard'] as int;
        price /= shardToMoneyRate;
      }

      return price.round();
    }
  }

  static int estimateItemPrice(
    String category,
    int rank, {
    String range = 'normal',
    bool useShard = false,
  }) {
    assert(kEstimatePriceRange.contains(range));
    int price;
    if (kItemWithAffixCategories.contains(category)) {
      final minLevel = minLevelForRank(rank);
      final maxLevel = maxLevelForRank(rank);
      final extraAffixCount = getMinMaxExtraAffixCount(rank);
      final int minExtra = extraAffixCount['minExtra']!;
      final int maxExtra = extraAffixCount['maxExtra']!;
      int level;
      int affixCount;
      switch (range) {
        case 'cheap':
          level = minLevel;
          affixCount = minExtra;
        case 'normal':
          level = (minLevel + maxLevel) ~/ 2;
          affixCount = (minExtra + maxExtra) ~/ 2;
        case 'expensive':
          level = maxLevel;
          affixCount = maxExtra;
        default:
          throw ('estimatedPrice range should be `cheap`, `normal`, or `expensive`: $range');
      }
      price = (rank * rank + 1) *
          (level + 1) *
          (affixCount + 1) *
          (kItemPriceByCategory[category] ?? kUnknownItemPrice);
    } else {
      price = (rank * rank + 1) *
          (kItemPriceByCategory[category] ?? kUnknownItemPrice);
    }

    if (useShard) {
      final shardToMoneyRate = kMaterialPrice['shard'] as int;
      price = price ~/ shardToMoneyRate;
    }

    return price;
  }

  static List<dynamic> getFilteredItems(
    dynamic character, {
    required ItemType type,
    dynamic filter,
    bool filterShard = false,
  }) {
    final inventoryData = character['inventory'];

    final int? minRank = filter?['minRank'];
    final int? maxRank = filter?['maxRank'];
    final int? rank = filter?['rank'];
    final String? category = filter?['category'];
    final String? kind = filter?['kind'];
    final String? id = filter?['id'];
    final bool? isIdentified = filter?['isIdentified'];

    final filteredItems = [];
    for (var itemData in inventoryData.values) {
      if (itemData['equippedPosition'] != null) {
        continue;
      }
      if (rank != null && itemData['rank'] != rank) {
        continue;
      }
      if (minRank != null && itemData['rank'] < minRank) {
        continue;
      }
      if (maxRank != null && itemData['rank'] > maxRank) {
        continue;
      }
      if (category != null && itemData['category'] != category) {
        continue;
      }
      if (kind != null && itemData['kind'] != kind) {
        continue;
      }
      if (id != null && itemData['id'] != id) {
        continue;
      }
      if (isIdentified != null && isIdentified != itemData['isIdentified']) {
        continue;
      }
      if (type == ItemType.customer) {
        if (kUntradableItemKinds.contains(itemData['kind'])) continue;
        if (itemData['isUntradable'] == true) continue;
      }
      if (type == ItemType.merchant) {
        if (kUntradableItemKinds.contains(itemData['kind'])) continue;
        if (itemData['isUntradable'] == true) continue;
        if (filterShard && itemData['kind'] == 'shard') continue;
      }

      filteredItems.add(itemData);
    }

    return filteredItems;
  }

  static Future<Iterable<dynamic>> selectItem({
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
      final r = GameData.random.nextDouble();
      if (r < 0.4) {
        selectedAttributeId = character['mainAttribute'];
      } else {
        selectedAttributeId = GameData.random.nextIterable(kBattleAttributes);
      }
    } else {
      assert(kBattleAttributes.contains(selectedAttributeId));
    }
    assert(selectedAttributeId != null);

    if (isAttribute) {
      // 属性点类的node，记录的是选择的具体属性的名字
      unlockedNodes[nodeId] = selectedAttributeId;
      engine.hetu.invoke(
        'characterSetPassive',
        positionalArgs: [character, selectedAttributeId],
        namedArgs: {'level': kPassiveTreeAttributeAnyLevel},
      );
    } else {
      unlockedNodes[nodeId] = true;
      final List nodePassiveData = passiveTreeNodeData['passives'];
      for (final data in nodePassiveData) {
        engine.hetu.invoke(
          'characterSetPassive',
          positionalArgs: [character, data['id']],
          namedArgs: {'level': data['level'] ?? 1},
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
        namedArgs: {'level': -kPassiveTreeAttributeAnyLevel},
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
      {bool rejuvenate = true}) {
    final genre = character['cultivationFavor'];
    final style = character['cultivationStyle'];
    final int rank = character['rank'];
    final int level = character['level'];

    final List<String>? rankPath = kCultivationRankPaths[genre];
    final List<String>? stylePath = kCultivationStylePaths[genre]?[style];
    assert(rankPath != null, 'genre: $genre');
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
        '${character['name']} (rank: ${character['rank']}, level: ${character['level']}) 在 ${engine.locale('genre')} ${engine.locale(genre)} 的 ${engine.locale(style)} 路线上解锁了 $count 个天赋树节点');
  }

  static dynamic characterHasPassive(dynamic character, String passiveId) {
    return character['passives']?[passiveId];
  }

  // 返回值依次是：卡组下限，消耗牌上限，持续牌上限
  static Map<String, int> getDeckLimitForRank(int rank) {
    assert(rank >= 0);
    final limit = rank + 3;
    final ongoingMax = (rank + 1) ~/ 3;
    return {
      'limit': limit,
      'ongoingMax': ongoingMax,
      // 'ephemeralMax': ephemeralMax,
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
    final rate = kLifeRestoreRateAfterBattle -
        kLifeRestoreRateAfterBattle *
            math.gradualValue(roundCount, kBattleCardsCount, power: 0.5);

    return rate;
  }

  static Future<String?> selectWorldId() async {
    return showDialog(
      context: engine.context,
      builder: (context) => SelectMenuDialog(
          selections: {for (var element in GameData.worldIds) element: element},
          selectedValue:
              GameData.worldIds.firstWhere((id) => id != GameData.world['id'])),
    );
  }

  static Future<String?> selectCharacter({
    Iterable? ids,
    Iterable? datas,
    bool confirmationOnSelect = true,
  }) async {
    return showDialog(
      context: engine.context,
      builder: (context) => InformationView(
        showCloseButton: false,
        mode: InformationMode.selectCharacter,
        confirmationOnSelect: confirmationOnSelect,
        characterIds: ids,
        characters: datas,
      ),
    );
  }

  static Future<String?> selectLocation({
    Iterable? ids,
    Iterable? datas,
    bool confirmationOnSelect = true,
  }) async {
    return showDialog(
      context: engine.context,
      builder: (context) => InformationView(
        showCloseButton: false,
        mode: InformationMode.selectCity,
        confirmationOnSelect: confirmationOnSelect,
        locationIds: ids,
        locations: datas,
      ),
    );
  }

  static Future<String?> selectSite({
    Iterable? ids,
    Iterable? datas,
    bool confirmationOnSelect = true,
  }) async {
    return showDialog(
      context: engine.context,
      builder: (context) => InformationView(
        showCloseButton: false,
        mode: InformationMode.selectSite,
        confirmationOnSelect: confirmationOnSelect,
        locationIds: ids,
        locations: datas,
      ),
    );
  }

  static Future<String?> selectSect({
    Iterable? ids,
    Iterable? datas,
    bool confirmationOnSelect = true,
  }) async {
    return showDialog(
      context: engine.context,
      builder: (context) => InformationView(
        showCloseButton: false,
        mode: InformationMode.selectSect,
        confirmationOnSelect: confirmationOnSelect,
        sectIds: ids,
        sects: datas,
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
    return showDialog(
      context: engine.context,
      builder: (context) {
        return SelectMenuDialog(
          selections: selections,
          selectedValue: null,
        );
      },
    );
  }

  static Future<String?> selectSectId() async {
    final selections = <String, String>{};
    final sects = GameData.game['sects'];
    if (sects.isEmpty) return null;

    for (final element in sects.keys) {
      selections[element] = element;
    }
    return showDialog(
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
    return showDialog(
      context: engine.context,
      builder: (context) {
        return SelectMenuDialog(
          selections: selections,
          selectedValue: null,
        );
      },
    );
  }

  static Future<String?> selectFrom(
    Iterable list, {
    bool barrierDismissible = true,
  }) async {
    final selections = <String, String>{};

    for (final element in list) {
      selections[element] = engine.locale(element);
    }
    return showDialog(
      context: engine.context,
      builder: (context) {
        return SelectMenuDialog(
          barrierDismissible: barrierDismissible,
          selections: selections,
          selectedValue: null,
        );
      },
    );
  }

  /// 角色渡劫检测，返回值 null 表示没有服用破境丹
  /// true 表示渡劫成功 false 表示失败
  /// 此时将不会正常升级，但仍会扣掉经验值
  static bool? checkTribulation() {
    final rank = GameData.hero['rank'];

    final potionData = GameData.hero['potionPassives']['upgradeRank'];
    if (potionData == null) return null;

    final bool consumedUpgradeRankPotion = potionData['level'] == rank;
    if (!consumedUpgradeRankPotion) return null;

    final level = GameData.hero['level'];
    final minLevel = minLevelForRank(rank);
    final maxLevel = maxLevelForRank(rank);

    bool doTribulation = false;
    // if (GameData.flags['tribulation'] == true) {
    //   doTribulation = true;
    // } else {
    if (level > minLevel) {
      if (level == maxLevel) {
        doTribulation = true;
      } else {
        final chance = math.gradualValue(level - minLevel, maxLevel - minLevel);
        final r = GameData.random.nextDouble();
        if (r < chance) {
          doTribulation = true;
        }
      }
    }
    // }

    // GameData.flags['tribulation'] = doTribulation;
    if (doTribulation) {
      showTribulation(maxLevel, rank + 1);
    }

    return doTribulation;
  }

  // 进入天道战斗
  static void showTribulation(int level, int rank) async {
    await GameDialogContent.show(
        engine.context, engine.locale('hint_tribulation_1'));

    if (GameData.game['enableTutorial'] == true) {
      if (GameData.flags['tutorial']['tribulation'] != true) {
        GameData.flags['tutorial']['tribulation'] = true;

        await GameDialogContent.show(
            engine.context, engine.locale('hint_tribulation_2'));
      }
    }

    await GameDialogContent.show(
        engine.context, engine.locale('hint_tribulation_3'));

    dialog.pushSelection('tribulation', ['do_tribulation', 'forgetIt']);
    await dialog.execute();
    final selected = dialog.checkSelected('tribulation');
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

      engine.context.read<EnemyState>().show(
        enemy,
        loseOnEscape: true,
        onBattleEnd: (bool result, int roundCount) {
          if (result) {
            GameData.flags['tribulation'] = false;
            engine.hetu.invoke('levelUp', namespace: 'Player');
            final rank = engine.hetu.invoke('rankUp', namespace: 'Player');
            promptNewRank(rank);
          }
        },
      );
    } else {
      GameDialogContent.show(
          engine.context, engine.locale('hint_tribulation_4'));
    }
  }

  static Future<void> promptItems(List items) async {
    final completer = Completer();
    engine.context
        .read<ItemsPromptState>()
        .update(items: items, completer: completer);
    return completer.future;
  }

  static Future<String?> promptJournal(
    dynamic journal, {
    Map<String, String>? selectionsRaw,
    List<dynamic>? selections,
    List<dynamic>? interpolations,
    Completer? completer,
  }) async {
    final completer = Completer<String?>();
    engine.context.read<JournalPromptState>().update(
          journal: journal,
          selectionsRaw: selectionsRaw,
          selections: selections,
          interpolations: interpolations,
          completer: completer,
        );
    return completer.future;
  }

  static Future<void> promptNewRank(int rank) async {
    final completer = Completer();
    engine.context
        .read<RankPromptState>()
        .update(rank: rank, completer: completer);
    return completer.future;
  }

  static void onUseItem(dynamic itemData) async {
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
        final items = await selectItem(
          character: GameData.hero,
          title: engine.locale('selectItem'),
          filter: {'isIdentified': false},
          multiSelect: false,
        );
        if (items.isNotEmpty) {
          final selectedItem = items.first;
          selectedItem['isIdentified'] = true;
          engine.play('hammer-hitting-an-anvil-25390.mp3');
          engine.hetu
              .invoke('lose', namespace: 'Player', positionalArgs: [itemData]);
        }
      case kItemCategoryMaterialPack:
        engine.hetu.invoke('lose',
            namespace: 'Player',
            positionalArgs: [itemData],
            namedArgs: {'incurIncident': false});
        engine.hetu.invoke(
          'collect',
          namespace: 'Player',
          positionalArgs: [itemData['kind'], itemData['stackSize']],
        );
        engine.play('pickup_item-64282.mp3');
      // case kItemCategoryExppack:
      //   engine.hetu.invoke('gainExp',
      //       namespace: 'Player', positionalArgs: [itemData['stackSize']]);
      //   engine.hetu
      //       .invoke('lose', namespace: 'Player', positionalArgs: [itemData]);
      //   engine.play('magic-smite-6012.mp3');
      case kItemCategoryPotion:
        engine.play('drink-sip-and-swallow-6974.mp3');
        engine.hetu.invoke(
          'consumePotion',
          namespace: 'Player',
          positionalArgs: [itemData],
        );
      case 'craftmaterial_rerollAffix':
        engine.play('drink-sip-and-swallow-6974.mp3');
        engine.hetu.invoke(
          'generateAttributes',
          positionalArgs: [GameData.hero],
        );
        GameDialogContent.show(
            engine.context, engine.locale('hint_generateAttributes'));
        engine.hetu.invoke('lose', namespace: 'Player', positionalArgs: [
          itemData
        ], namedArgs: {
          'amount': 1,
        });
        engine.hetu
            .invoke('characterCalculateStats', positionalArgs: [GameData.hero]);
      case 'craftmaterial_upgrade':
        engine.play('drink-sip-and-swallow-6974.mp3');
        engine.hetu.invoke(
          'characterSetUpgradeRankPotionPassive',
          positionalArgs: [GameData.hero, itemData['rank']],
        );
        engine.hetu.invoke('lose', namespace: 'Player', positionalArgs: [
          itemData
        ], namedArgs: {
          'amount': 1,
        });
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

    if (max < 1) {
      dialog.pushDialog(engine.locale('hint_notEnoughShard'));
      return;
    }

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
    engine.hetu.invoke(
      'exhaust',
      namespace: 'Player',
      positionalArgs: ['shard', value],
    );

    engine.info('物品 ${itemData['name']} 增加了 $charge 充能次数');
    engine.play('electric-sparks-68814.mp3');
  }

  static void heroRest(dynamic location) => _heroRest(location);

  static Future<void> heroWork(dynamic location) => _heroWork(location);

  static Future<void> heroAcquireQuest(
      dynamic quest, dynamic location, dynamic sect) async {
    final budget = quest['budget'];
    if (budget != null) {
      final items = await engine.hetu.invoke(
        'loot',
        namespace: 'Player',
        positionalArgs: [
          [budget]
        ],
      );
      await GameLogic.promptItems(items);
    }
    final package = quest['package'];
    if (package != null) {
      await engine.hetu
          .invoke('unpack', namespace: 'Player', positionalArgs: [package]);
    }
    final journal = engine.hetu.invoke('createJournalByQuest',
        namespace: 'Player', positionalArgs: [quest]);
    if (quest['kind'] == 'escort') {
      final escortType = engine.hetu.invoke(
        'initEscort',
        positionalArgs: [journal['quest']],
      );
      dialog.pushDialog(
        'quest_escort_greeting_$escortType',
        characterId: package['characterId'],
      );
      await dialog.execute();
      final npcs = GameData.getNpcsAtLocation(location);
      gameState.updateNpcs(npcs);
    } else {
      await GameLogic.promptJournal(journal);
    }
  }

  static void openDepositBox(dynamic home) {
    engine.context
        .read<MerchantState>()
        .show(home, merchantType: MerchantType.depositBox);
  }

  static Future<void> onInteractNpc(dynamic location) =>
      _onInteractNpc(location);

  static Future<void> onInteractCharacter(dynamic character) =>
      _onInteractCharacter(character);

  /// 更新游戏逻辑，将时间向前推进指定的 ticks
  /// 如果遇到了一些特殊事件可能提前终止
  /// 这会影响一些连续进行的动作，例如探索或者修炼等等
  /// 如果时间没有推进到下一个日期，返回 false，否则返回 true
  static Future<bool> updateGame({
    int ticks = kTicksPerTime,
    bool updateEntity = true,
    bool updateUI = true,
    bool updateWorldMap = true,
    bool force = false,
    bool showPerformance = false,
  }) async {
    final before = getDatetimeString();
    GameData.game['timestamp'] += ticks;
    final (timestamp, after) = calculateTimestamp();

    // 如果时间没有推进到下一个日期，则不进行任何更新，除非 force 为 true
    if (before == after && !force) return false;

    final int tik = DateTime.now().millisecondsSinceEpoch;
    if (updateUI) {
      gameState.updateDatetime(timestamp: timestamp, datetimeString: after);
    }
    if (time == 1) {
      engine.debug(
          '--------${GameLogic.getDatetimeString(withTime: false)}--------');
    }

    if (updateEntity || force) {
      // 每个月 1 日刷新玩家事件标记
      if ((time == 1 && day == _kGameFlagsUpdateDay) || force) {
        // 重置玩家自己的每月行动
        engine.hetu.invoke('resetHeroMonthly');
      }

      // 触发每个角色的刷新事件
      final chars = GameData.game['characters'].values.toList();
      for (final character in chars) {
        if (character == GameData.hero) continue;
        // 角色事件每个角色不同，会随机分配在某一天
        // 这是为了减缓同时更新大量角色的压力
        if ((time == 1 && day == character['updateDay']) || force) {
          if (character['flags']['updated'] != true || force) {
            _updateCharacterMonthly(character);
          }
        }
      }
      // 每个建筑每月会根据其属性而消耗维持费用和获得收入
      // 生产类建筑每天都会刷新生产进度
      // 商店类建筑会刷新物品和银两
      // 刷新任务，无论之前的任务是否还存在，非组织拥有的第三方建筑每个月只会有一个任务
      final locs = GameData.game['locations'].values.toList();
      for (final location in locs) {
        if (GameData.hero != null &&
            location['managerId'] == GameData.hero['id']) {
          continue;
        }
        // 场景每月重置
        if ((time == 1 && day == location['updateDay']) || force) {
          if (location['flags']['monthly']['updated'] != true || force) {
            _updateLocationMonthly(location);
          }
        }
        // 场景每日维护
        if ((time == 1) || force) {
          _updateLocationDaily(location);
        }
      }
      // 触发每个组织的刷新事件
      final orgs = GameData.game['sects'].values.toList();
      for (final sect in orgs) {
        if (sect['headId'] == GameData.hero?['id']) continue;
        // 组织每月 6 日刷新
        if ((time == 1 && day == _kSectUpdateDay) || force) {
          if (sect['flags']['monthly']['updated'] != true || force) {
            _updateSectMonthly(sect);
          }
        }
      }
    }

    // 每一个野外地块，每个月固定时间会随机刷新一个野外遭遇
    // 野外遭遇包括NPC事件、随机副本等等
    // for (const terrain in world.terrains) {
    //   if (data.timestamp % kTicksPerMonth == 0) {
    //     updateTerrain(terrain)
    //   }
    // }

    if (GameData.hero != null) {
      for (final itemId in GameData.hero['equipments'].values) {
        if (itemId == null) continue;
        final itemData = GameData.hero['inventory'][itemId];
        if (itemData['isUpdatable'] != true) continue;
        engine.info('触发装备物品 ${itemData['name']} 刷新事件');
        await engine.hetu
            .invoke('onGameEvent', positionalArgs: ['onUpdateItem', itemData]);
      }
    }

    engine.hetu.invoke('handleBabies');

    if (showPerformance) {
      engine.info(
          'game update took: ${DateTime.now().millisecondsSinceEpoch - tik}ms');
    }

    return true;
  }

  /// 角色濒死，tribulationCount += 1，返回自宅
  static Future<void> onDying() => _onDying();

  static void tryInteractObject(String objectId, dynamic terrainData) {
    final objectsData = engine.hetu.fetch('objects', namespace: 'world');
    final objectData = objectsData[objectId];
    engine.hetu.invoke('onInteractMapObject',
        positionalArgs: [objectData, terrainData]);
  }

  /// 异步函数，在显示场景窗口之前执行
  static Future<dynamic> tryEnterLocation(dynamic location) =>
      _tryEnterLocation(location);

  static Future<void> onAfterEnterLocation(dynamic location) =>
      _onAfterEnterLocation(location);

  static void tryEnterDungeon({
    int? rank,
    bool isBasic = false,
    String dungeonId = 'dungeon_1',
    bool pushScene = true,
  }) =>
      _tryEnterDungeon(
        rank: rank,
        isBasic: isBasic,
        dungeonId: dungeonId,
        pushScene: pushScene,
      );

  static void onInteractDungeonEntrance({
    dynamic sect,
    dynamic location,
  }) =>
      _onInteractDungeonEntrance(
        sect: sect,
        location: location,
      );

  static Map<String, int> calculateLocationDevelopmentCost(dynamic location) =>
      _calculateLocationDevelopmentCost(location);

  static bool tryStartLocationDevelopment(dynamic location,
          {Map<String, int>? cost}) =>
      _tryStartLocationDevelopment(location, cost: cost);

  static Future<void> cancelLocationDevelopment(dynamic location) =>
      _cancelLocationDevelopment(location);

  static void onInteractExpArray(
    dynamic sect, {
    dynamic location,
  }) =>
      _onInteractExpArray(
        sect,
        location: location,
      );

  static void onInteractCardLibraryDesk({
    dynamic sect,
    dynamic location,
  }) =>
      _onInteractCardLibraryDesk(
        sect: sect,
        location: location,
      );

  static Future<void> showMeeting(
          dynamic sect, dynamic location, dynamic superior) =>
      _showMeeting(sect, location, superior);

  static void heroDepositToLocationStorage(
      dynamic location, dynamic depositData) {
    if (depositData.isEmpty) return;
    bool hasEnough = true;
    for (final materialId in depositData.keys) {
      final amount = depositData[materialId] ?? 0;
      if (amount <= 0) continue;
      if ((GameData.hero['materials'][materialId] ?? 0) < amount) {
        hasEnough = false;
        dialog.pushDialog(
          'hint_notEnough',
          npcId: location['npcId'],
          interpolations: [
            engine.locale(materialId),
          ],
        );
        dialog.execute();
        break;
      }
    }
    if (hasEnough) {
      for (final materialId in depositData.keys) {
        final amount = depositData[materialId] ?? 0;
        if (amount <= 0) continue;
        engine.hetu.invoke('exhaust',
            namespace: 'Player', positionalArgs: [materialId, amount]);
        engine.hetu.invoke('entityCollect',
            positionalArgs: [location, materialId, amount],
            namedArgs: {'onStorage': true});
      }
    }
  }
}
