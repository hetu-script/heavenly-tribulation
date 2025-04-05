import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hetu_script/utils/math.dart' as math;
import 'package:samsara/samsara.dart';

import '../common.dart';
import '../widgets/dialog/timeflow.dart';
import '../scene/game_dialog/selection_dialog.dart';
import '../engine.dart';
import '../scene/game_dialog/game_dialog_content.dart';
import '../widgets/dialog/select_menu.dart';
import '../state/view_panels.dart';
import '../widgets/dialog/input_slider.dart';
import '../scene/common.dart';
import '../state/new_prompt.dart';
import '../state/hoverinfo.dart';
import 'common.dart';
import 'data.dart';

/// 战斗结束后生命恢复比例计算时，
/// 战斗中使用的卡牌使用过的数量的阈值
const kBaseAfterBattleHPRestoreRate = 0.25;
const kBattleCardsCount = 16;

/// 根据人物当前境界，获取不同境界卡牌的概率
const kCardObtainProbabilityByRank = {
  1: {
    1: 1,
  },
  2: {
    1: 0.7,
    2: 0.3,
  },
  3: {
    1: 0.6,
    2: 0.25,
    3: 0.15,
  },
  4: {
    1: 0.5,
    2: 0.25,
    3: 0.15,
    4: 0.1,
  },
  5: {
    1: 0.45,
    2: 0.25,
    3: 0.15,
    4: 0.1,
    5: 0.05,
  }
};

const kBattleCardPriceRatio = 10;
const kAddAffixCostRatio = 10;
const kRerollAffixCostRatio = 20;
const kReplaceAffixCostRatio = 20;
const kUpgradeCardCostRatio = 10;
const kUpgradeRankCostRatio = 10;
const kCraftScrollCostRatio = 10;

const _kCardCraftOperations = {
  'addAffix',
  'rerollAffix',
  'replaceAffix',
  'upgradeCard',
  'upgradeRank',
  'dismantle',
  'craftScroll',
};

abstract class GameLogic {
  static bool truthy(dynamic value) => engine.hetu.interpreter.truthy(value);

  static int minLevelForRank(int rank) {
    assert(rank >= 0);
    return rank == 0 ? 0 : ((rank - 1) * 10 + 5);
  }

  static int maxLevelForRank(int rank) {
    assert(rank >= 0);
    return rank == kCultivationRankMax ? 100 : (rank + 1) * 10;
  }

  static int expForLevel(int level, [int? difficulty]) {
    difficulty ??= 1;
    return (difficulty * (level) * (level)) * 10 + level * 100 + 40;
  }

  static int getCardCraftOperationCost(String operation, dynamic cardData) {
    assert(_kCardCraftOperations.contains(operation));
    switch (operation) {
      case 'addAffix':
        return expForLevel(cardData['level']) ~/ kAddAffixCostRatio;
      case 'rerollAffix':
        return expForLevel(cardData['level']) ~/ kRerollAffixCostRatio;
      case 'replaceAffix':
        return expForLevel(cardData['level']) ~/ kReplaceAffixCostRatio;
      case 'upgradeCard':
        return expForLevel(cardData['level']) ~/ kUpgradeCardCostRatio;
      case 'upgradeRank':
        return expForLevel(cardData['rank']) * kUpgradeRankCostRatio;
      case 'dismantle':
        return calculateBattleCardPrice(cardData);
      case 'craftScroll':
        return expForLevel(cardData['level']) ~/ kCraftScrollCostRatio;
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
        assert(kMainCultivationGenres.contains(genreRequirement));
        final passive =
            GameData.heroData['passives']['${genreRequirement}_rank'];
        bool hasGenreRankPassive = false;
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
    final int price = expForLevel(level) ~/ kBattleCardPriceRatio;
    return price;
  }

  /// 计算购买或卖出物品时的价格
  static int calculateItemPrice(dynamic itemData,
      {dynamic priceFactor, bool isSell = true}) {
    final price = itemData['price'] ?? 0;

    if (priceFactor == null) {
      return price;
    } else {
      final double base = priceFactor['base'] ?? kBaseBuyRate;
      final double sell = priceFactor['sell'] ?? kBaseSellRate;

      final double category =
          priceFactor['category']?[itemData['category']] ?? 1.0;
      final double kind = priceFactor['kind']?[itemData['kind']] ?? 1.0;
      final double id = priceFactor['id']?[itemData['id']] ?? 1.0;

      double finalPrice = isSell
          ? price * sell * category * kind * id
          : price * base * category * kind * id;

      if (priceFactor['useShard'] == true) {
        finalPrice /= kMoneyToShardRate;
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
      if (type == ItemType.customer || type == ItemType.merchant) {
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
    ///   { genreId: 'dao', probability: 0.2 },
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

    selectedAttributeId ??= characterData['cultivationFavor'];

    if (isAttribute) {
      // 属性点类的node，记录的是选择的具体属性的名字
      unlockedNodes[nodeId] = selectedAttributeId;
      engine.hetu.invoke(
        'characterGainPassive',
        positionalArgs: [characterData, selectedAttributeId],
        namedArgs: {'level': kAttributeAnyLevel},
      );
    } else {
      unlockedNodes[nodeId] = true;
      final List nodePassiveData = passiveTreeNodeData['passives'];
      for (final data in nodePassiveData) {
        engine.hetu.invoke(
          'characterGainPassive',
          positionalArgs: [characterData, data['id']],
          namedArgs: {
            'level': data['level'] ?? 1,
          },
        );
      }
    }

    return true;
  }

  static void characterAllocateSkills(dynamic characterData) {
    final genre = characterData['cultivationFavor'];
    final style = characterData['cultivationStyle'];
    final int rank = characterData['rank'];
    final int level = characterData['level'];

    final List<String>? rankPath = kCultivationRankPaths[genre];
    final List<String>? stylePath = kCultivationStylePaths[genre]?[style];
    assert(rankPath != null);
    assert(stylePath != null);

    int count = 0;
    for (var i = 0; i < rank; ++i) {
      assert(i < rankPath!.length);
      final nodeId = rankPath![i];
      final unlocked = characterUnlockPassiveTreeNode(characterData, nodeId,
          selectedAttributeId: kBattleAttributes.random);
      if (unlocked) {
        count++;
      }
    }

    for (var i = 0; i < level - rank; ++i) {
      assert(i < stylePath!.length);
      final nodeId = stylePath![i];
      final unlocked = characterUnlockPassiveTreeNode(characterData, nodeId,
          selectedAttributeId: genre);
      if (unlocked) {
        count++;
      }
    }

    engine.hetu
        .invoke('characterCalculateStats', positionalArgs: [characterData]);

    engine.info(
        '为角色 ${characterData['name']} 在 ${engine.locale('genre')} ${engine.locale('style')} 路线上解锁了 $count 个天赋树节点');
  }

  static dynamic characterHasPassive(dynamic characterData, String passiveId) {
    return characterData['passives']?[passiveId];
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
        'refundPassive',
        namespace: 'Player',
        positionalArgs: [attributeId],
        namedArgs: {'level': kAttributeAnyLevel},
      );
    } else {
      final List nodePassiveData = passiveTreeNodeData['passives'];
      for (final data in nodePassiveData) {
        engine.hetu.invoke(
          'refundPassive',
          namespace: 'Player',
          positionalArgs: [data['id']],
          namedArgs: {'level': data['level'] ?? 1},
        );
      }
    }
    unlockedNodes.remove(nodeId);
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

  static String? checkDeckRequirement(List<dynamic> cards) {
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
          selectedValue: GameData.worldIds
              .firstWhere((element) => element != GameData.currentWorldId)),
    );
  }

  /// 角色渡劫检测，返回值 true 代表将进入天道挑战
  /// 此时将不会正常升级，但仍会扣掉经验值
  static bool checkTribulation() {
    final level = GameData.heroData['level'];
    final rank = GameData.heroData['rank'];
    final currentRankLevelMax = maxLevelForRank(rank);
    final nextRankLevelMin = minLevelForRank(rank + 1);

    bool doTribulation = false;
    if (level > nextRankLevelMin) {
      if (level == 5 && rank == 0) {
        doTribulation = true;
      } else if (level == currentRankLevelMax) {
        doTribulation = true;
      } else {
        final probability = math.gradualValue(
            level - nextRankLevelMin, currentRankLevelMax - nextRankLevelMin);
        final r = math.Random().nextDouble();
        if (r < probability) {
          doTribulation = true;
        }
      }

      if (doTribulation) {
        showTribulation(nextRankLevelMin + 5, rank + 1);
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
    if (selected != 'do_tribulation') return;

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
      //         engine.context, engine.locale('help_tribulation_beforeBattle'));
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
  }

  static void heroRest() async {
    final selected =
        await SelectionDialog.show(engine.context, selectionsData: {
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
    int ticks = 0;
    switch (selected) {
      case 'rest1Days':
        ticks = kTicksPerDay;
      case 'rest10Days':
        ticks = kTicksPerDay * 10;
      case 'rest30Days':
        ticks = kTicksPerDay * 30;
      case 'restTillTommorow':
        ticks = engine.hetu.invoke('getTicksTillNextDay');
      case 'restTillNextMonth':
        ticks = engine.hetu.invoke('getTicksTillNextMonth');
      case 'restTillFullHealth':
        ticks =
            GameData.heroData['stats']['lifeMax'] - GameData.heroData['life'];
        if (ticks == 0) {
          GameDialogContent.show(
              engine.context, engine.locale('alreadyFullHealthNoNeedRest'));
        }
    }

    if (ticks > 0) {
      TimeflowDialog.show(
        context: engine.context,
        max: ticks,
        onProgress: () {
          engine.hetu
              .invoke('restoreLife', namespace: 'Player', positionalArgs: [1]);
        },
      );
    }
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
      case 'scroll':
        if (itemData['prototypeId'] == 'identify_scroll') {
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
        }
      case 'material':
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

    final int shards = GameData.heroData['materials']['shard'];
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
}
