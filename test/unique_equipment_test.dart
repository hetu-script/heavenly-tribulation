import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:json5/json5.dart';

import 'package:heavenly_tribulation/data/common.dart';
import 'package:heavenly_tribulation/logic/logic.dart';
import 'package:heavenly_tribulation/scene/battle/scry.dart';

void main() {
  Map<String, dynamic> loadData(String path) {
    return Map<String, dynamic>.from(
        json5Decode(File(path).readAsStringSync()) as Map);
  }

  String loadItemConstructorSource() {
    final source = File('scripts/main/data/item/item.ht').readAsStringSync();
    return source.substring(
      source.indexOf('function calculatePrice'),
      source.indexOf('function entityHasItem'),
    );
  }

  String loadCreateLootSource() {
    final source = File('scripts/main/data/item/item.ht').readAsStringSync();
    return source.substring(source.indexOf('function createLoot'));
  }

  Hetu createItemHetu(
      Map<String, dynamic> items, Map<String, dynamic> passives) {
    for (final prototype in items.values) {
      prototype['isRankedItem'] ??= false;
      prototype['isUntradable'] ??= false;
    }
    final hetu = Hetu()..init();
    hetu.interpreter.bindExternalFunction(
        'calculateItemBasePrice', ({positionalArgs, namedArgs}) => 1,
        override: true);
    hetu.interpreter.bindExternalFunction(
        'calculatePassiveAffixValue',
        ({positionalArgs, namedArgs}) => GameLogic.calculatePassiveAffixValue(
            positionalArgs[0],
            level: namedArgs['level'] ?? 0,
            isGreater: namedArgs['isGreater'] ?? false),
        override: true);
    hetu.interpreter.bindExternalFunction(
        'minLevelForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.minLevelForRank(positionalArgs[0]),
        override: true);
    hetu.interpreter.bindExternalFunction(
        'maxLevelForRank',
        ({positionalArgs, namedArgs}) =>
            GameLogic.maxLevelForRank(positionalArgs[0]),
        override: true);
    hetu.eval('var game');
    hetu.assign('game', {'items': items, 'passives': passives});
    hetu.eval('''
      external function calculateItemBasePrice(item) -> integer
      external function calculatePassiveAffixValue(valueData, {level = 0, isGreater = false}) -> integer
      external function minLevelForRank(rank) -> integer
      external function maxLevelForRank(rank) -> integer

      final kEntityTypeItem = 'item'
      final kRarityCommon = 'common'
      final kCultivationRankMax = 5
      final Constants = {
        rankToRarity: ['common', 'rare', 'epic', 'legendary', 'mythic', 'arcane'],
        materialBasePrice: {},
        maxNormalExtraAffixCount: 3,
      }
      final kRarity = {
        common: {rank: 0, color: 0},
        rare: {rank: 1, color: 1},
        epic: {rank: 2, color: 2},
        legendary: {rank: 3, color: 3},
        mythic: {rank: 4, color: 4},
        arcane: {rank: 5, color: 5},
      }
      final engine = {
        locale: function(id) { return id },
      }
      final random = {
        nextInt: function(max) { return 0 },
      }
      final crypto = {
        randomUID: function({withTime}) { return 'test-item-uid' },
      }
      function getRandomLevel(min, max) {
        if (min >= max) return min
        return min + random.nextInt(max - min + 1)
      }
      ${loadItemConstructorSource()}
      ${loadCreateLootSource()}
    ''');
    return hetu;
  }

  Hetu createStatusHetu() {
    final hetu = Hetu()..init();
    hetu.eval('var Constants');
    hetu.assign('Constants', {'elementAilments': kElementAilmentIds});
    hetu.eval(
        File('scripts/main/cardgame/status_script.ht').readAsStringSync());
    return hetu;
  }

  test('五件绝世装备经真实 createItemById 生成并正确解锁', () {
    final items = loadData('assets/data/items.json5');
    final passives = loadData('assets/data/passives.json5');
    final hetu = createItemHetu(items, passives);
    final expected = <String, List<String>>{
      'heaven_peeking_mirror': [
        'heaven_peeking_mirror',
        'scry_upgrade',
        'scry_shield',
        'scry_mana',
      ],
      'five_elements_pearl': [
        'five_elements_pearl',
        'ailmentMultiplier',
        'ailmentThreshold',
        'ailment_inflict_focus',
      ],
      'heavenly_mechanism_disc': [
        'heavenly_mechanism_disc',
        'battleDrawBonus',
        'handSizeMax',
        'spellcraft_cost_down',
      ],
      'spirit_storing_amulet': [
        'energyRetainSpell',
        'lifeMax',
        'persistent',
        'spell_mana_trickle',
      ],
      'spirit_gathering_banner': [
        'spirit_gathering_banner',
        'mana_threshold_guard',
        'spellcraft_cost_down',
        'turnStartExtraDraw',
      ],
    };
    final expectedGreater = <String, int>{
      'heaven_peeking_mirror': 0,
      'five_elements_pearl': 0,
      'heavenly_mechanism_disc': 1,
      'spirit_storing_amulet': 2,
      'spirit_gathering_banner': 3,
    };

    for (final entry in expected.entries) {
      final id = entry.key;
      final prototype = items[id];
      final rank = prototype['rank'] as int;
      final item = hetu.invoke('createItemById', positionalArgs: [id]);
      final affixes = item['affixes'] as List;
      expect(affixes.map((affix) => affix['id']),
          orderedEquals(entry.value.take(rank + 2)));
      expect(prototype['affixes'], hasLength(4));
      expect(affixes[0]['isGreater'], isNot(true));
      expect(affixes.where((affix) => affix['isGreater'] == true),
          hasLength(expectedGreater[id]!));
      expect(
          item['level'],
          inInclusiveRange(GameLogic.minLevelForRank(rank),
              GameLogic.maxLevelForRank(rank)));

      for (final affix in affixes) {
        final raw = passives[affix['id']];
        final increment = raw['increment'];
        if (increment is num) {
          if (affix['isGreater'] == true) {
            expect(affix['level'], GameLogic.maxLevelForRank(rank));
          } else {
            final minAffixLevel = increment != 0 && increment.abs() < 1
                ? (1 / increment.abs()).ceil()
                : 1;
            expect(affix['level'],
                inInclusiveRange(minAffixLevel, item['level'] as int));
          }
          expect(affix['value'], isNotNull);
        } else if (affix['isGreater'] == true) {
          expect(affix['level'], GameLogic.maxLevelForRank(rank));
        } else {
          expect(affix['level'], isNull);
        }
      }
    }
  });

  test('绝世装备按最低境界与指定高境界生成，prototype 奖励透传 rank', () {
    final items = loadData('assets/data/items.json5');
    final hetu = createItemHetu(items, loadData('assets/data/passives.json5'));
    final lower = hetu.invoke('createItemById',
        positionalArgs: ['heaven_peeking_mirror'], namedArgs: {'rank': 0});
    expect(lower['rank'], 1);
    expect(lower['affixes'], hasLength(3));

    for (final prototype
        in items.values.where((item) => item['isUnique'] == true)) {
      final item = hetu.invoke('createItemById',
          positionalArgs: [prototype['id']], namedArgs: {'rank': 5});
      expect(item['rank'], 5);
      expect(item['rarity'], 'arcane');
      expect(item['affixes'], hasLength(4));
      expect(item['affixes'][0]['isGreater'], isNot(true));
      expect(item['affixes'].where((affix) => affix['isGreater'] == true),
          hasLength(3));
      expect(
          item['level'],
          inInclusiveRange(
              GameLogic.minLevelForRank(5), GameLogic.maxLevelForRank(5)));
    }

    final loot = hetu.eval('''
      createLoot([{type: 'prototype', id: 'heaven_peeking_mirror', rank: 5}])
    ''');
    expect(loot.first['rank'], 5);
    expect(loot.first['affixes'].where((affix) => affix['isGreater'] == true),
        hasLength(3));
  });

  test('天机盘主词条固定降低牌库下限，太古抽牌为固定 +2', () {
    final hetu = createItemHetu(
      loadData('assets/data/items.json5'),
      loadData('assets/data/passives.json5'),
    );
    final item = hetu
        .invoke('createItemById', positionalArgs: ['heavenly_mechanism_disc']);
    expect(item['affixes'][0]['statsBonus']['deckMinSizeReduce'], -2);
    expect(item['affixes'][0]['greater'], isNull);
    expect(item['affixes'][1]['isGreater'], true);
    expect(item['affixes'][1]['value'], 2);
    expect(item['affixes'][1]['level'], GameLogic.maxLevelForRank(3));
  });

  test('物品显式 level 在真实生成路径中保持不变', () {
    final hetu = createItemHetu(
      loadData('assets/data/items.json5'),
      loadData('assets/data/passives.json5'),
    );
    final item = hetu.invoke('createItemById',
        positionalArgs: ['heaven_peeking_mirror'], namedArgs: {'level': 17});
    expect(item['level'], 17);
  });

  test('观星最终查看数不超过 5 且不超过牌库剩余数', () {
    expect(kScryCardCountMax, 5);
    expect(getScryCardCount(count: 6, deckSize: 6), 5);
    expect(getScryCardCount(count: 6, deckSize: 4), 4);
    expect(getScryCardCount(count: 3, deckSize: 0), 0);
  });

  test('观星升级按 turnCount 每回合只处理第一次选中牌', () {
    final hetu = createStatusHetu();
    final result = hetu.eval('''
      function upgradeCard(card, {inBattle = false}) { card.level += 1 }
      final self = {turnCount: 1}
      final effect = {upgradeChosen: 1}
      final first = {chosen: {level: 0}}
      final second = {chosen: {level: 0}}
      StatusScript.scry_upgrade_self_scry(self, null, effect, first)
      StatusScript.scry_upgrade_self_scry(self, null, effect, second)
      final beforeNextTurn = [first.chosen.level, second.chosen.level]
      self.turnCount += 1
      effect.upgradeChosen = 2
      StatusScript.scry_upgrade_self_scry(self, null, effect, second)
      [beforeNextTurn, second.chosen.level]
    ''');
    expect(result, [
      [1, 0],
      2,
    ]);
  });

  test('观星护盾每回合只触发一次且太古参数生效', () {
    final hetu = createStatusHetu();
    final result = hetu.eval('''
      final self = {
        turnCount: 1,
        gains: [],
        addStatusEffect: function(id, {amount}) {
          this.gains.add([id, amount])
        },
      }
      final effect = {shieldAmount: 1}
      StatusScript.scry_shield_self_scry(self, null, effect, {})
      StatusScript.scry_shield_self_scry(self, null, effect, {})
      self.turnCount += 1
      effect.shieldAmount = 2
      StatusScript.scry_shield_self_scry(self, null, effect, {})
      self.gains
    ''');
    expect(result, [
      ['buff_shield', 1],
      ['buff_shield', 2],
    ]);
  });

  test('观星灵气在产出前登记、产出后直接获得且每回合只触发一次', () {
    final hetu = createStatusHetu();
    final result = hetu.eval('''
      final self = {
        turnCount: 1,
        turnFlags: {},
        gains: [],
        addStatusEffect: function(id, {amount}) {
          this.gains.add([id, amount])
        },
      }
      final beforeProduction = {resourceId: 'energy_positive_spell', manaBonus: 1}
      StatusScript.scry_mana_self_scry(self, null, beforeProduction, {})
      StatusScript.scry_mana_self_scry(self, null, beforeProduction, {})
      final pending = self.turnFlags['pendingResources']['energy_positive_spell']
      StatusScript.scry_mana_self_produce_resources(self, null, beforeProduction, {})
      final afterProduction = {
        resourceId: 'energy_positive_spell', manaBonus: 2,
        lastResourceProductionTurn: 1,
      }
      StatusScript.scry_mana_self_scry(self, null, afterProduction, {})
      StatusScript.scry_mana_self_scry(self, null, afterProduction, {})
      [pending, self.gains]
    ''');
    expect(result, [
      1,
      [
        ['energy_positive_spell', 2],
      ],
    ]);
  });

  test('聚气成势只在灵气达到 5 点时减伤 20%', () {
    final hetu = createStatusHetu();
    final result = hetu.eval('''
      final self = {
        mana: 4,
        hasStatusEffect: function(id) { return this.mana },
      }
      final effect = {
        resourceId: 'energy_positive_spell', threshold: 5, reductionPercent: 20,
      }
      final below = {percentageChange2: 0.0}
      StatusScript.mana_threshold_guard_self_taking_damage(
        self, null, effect, below)
      self.mana = 5
      final reached = {percentageChange2: 0.0}
      StatusScript.mana_threshold_guard_self_taking_damage(
        self, null, effect, reached)
      [below.percentageChange2, reached.percentageChange2]
    ''');
    expect(result[0], 0);
    expect(result[1], closeTo(-0.2, 1e-9));
  });

  test('灵气细流复用产出阶段脚本获得 1 灵气', () {
    final hetu = createStatusHetu();
    final result = hetu.eval('''
      final self = {
        gains: [],
        addStatusEffect: function(id, {amount}) {
          this.gains.add([id, amount])
        },
      }
      StatusScript.turn_start_mana_bonus_self_produce_resources(
        self, null, {manaBonus: 1}, {})
      self.gains
    ''');
    expect(result, [
      ['energy_positive_spell', 1],
    ]);
  });

  test('真实被动聚合叠加额外抽牌并合并同名战斗状态', () {
    final source =
        File('scripts/main/data/character/battle_entity.ht').readAsStringSync();
    const startMarker = '  final battleStatusMap = {}';
    const endMarker = '  character.stats.energyRetain = energyRetainMap';
    final start = source.indexOf(startMarker);
    final end = source.indexOf(endMarker, start) + endMarker.length;
    final aggregationSource = source.substring(start, end);
    final hetu = Hetu()..init();
    final result = hetu.eval('''
      function aggregateForTest(character) {
        $aggregationSource
        return character.stats
      }
      final character = {
        passivesRaw: {
          first: {
            'equipment:item-a:0': {
              battleStatus: 'scry_retention',
              turnStartExtraDraw: {count: 1},
            },
          },
          second: {
            'equipment:item-b:0': {
              battleStatus: 'scry_retention',
              turnStartExtraDraw: {count: 1},
            },
          },
        },
        ephemeralPassivesRaw: {},
        passives: {},
        ephemeralPassives: {},
        stats: {},
      }
      aggregateForTest(character)
    ''');
    expect(result['turnStartExtraDraw']['count'], 2);
    expect(result['turnStartExtraDraw']['costIncrease'], isNull);
    expect(result['battleStatus']['scry_retention'], 2);
  });
}
