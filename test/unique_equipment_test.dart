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
            level: namedArgs['level'] ?? 0),
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
      external function calculatePassiveAffixValue(valueData, {level = 0}) -> integer
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
        'scry_focus',
        'scry_upgrade',
        'ailment_to_mana_echo',
      ],
      'five_elements_pearl': [
        'five_elements_pearl',
        'ailmentMultiplier',
        'ailmentThreshold',
        'ailment_inflict_focus',
      ],
      'heavenly_mechanism_disc': [
        'turnStartExtraDraw',
        'non_spellcraft_tax',
        'deckMinSizeReduce',
        'battleDrawBonus',
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
          orderedEquals(entry.value.take(rank + 1)));
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
            final minAffixLevel =
                increment.abs() < 1 ? (1 / increment.abs()).ceil() : 1;
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

  test('观星升级每回合只处理第一次选中牌且支持连续升级', () {
    final hetu = createStatusHetu();
    final result = hetu.eval('''
      function upgradeCard(card, {inBattle = false}) { card.level += 1 }
      final self = {turnFlags: {}}
      final first = {chosen: {level: 0}}
      final second = {chosen: {level: 0}}
      StatusScript.scry_upgrade_self_scry(self, null, {upgradeChosen: 1}, first)
      StatusScript.scry_upgrade_self_scry(self, null, {upgradeChosen: 1}, second)
      final beforeReset = [first.chosen.level, second.chosen.level]
      self.turnFlags = {}
      StatusScript.scry_upgrade_self_scry(self, null, {upgradeChosen: 2}, second)
      [beforeReset, second.chosen.level]
    ''');
    expect(result, [
      [1, 0],
      2,
    ]);
  });

  test('首次元素异常转灵气过滤普通减益且每回合只触发一次', () {
    final hetu = createStatusHetu();
    final result = hetu.eval('''
      final self = {
        turnFlags: {},
        gains: [],
        addStatusEffect: function(id, {amount}) {
          this.gains.add([id, amount])
        },
      }
      final effect = {resourceId: 'energy_positive_spell'}
      StatusScript.first_ailment_to_mana_self_gained_debuff(
        self, null, effect, {id: 'speed_slow'})
      StatusScript.first_ailment_to_mana_self_gained_debuff(
        self, null, effect, {id: 'ailment_fire'})
      StatusScript.first_ailment_to_mana_self_gained_debuff(
        self, null, effect, {id: 'ailment_ice'})
      final beforeReset = self.gains.length
      self.turnFlags = {}
      StatusScript.first_ailment_to_mana_self_gained_debuff(
        self, null, effect, {id: 'ailment_poison'})
      [beforeReset, self.gains]
    ''');
    expect(result, [
      1,
      [
        ['energy_positive_spell', 1],
        ['energy_positive_spell', 1],
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
              turnStartExtraDraw: {
                count: 1,
                costIncrease: {amount: 1, notGenres: ['spellcraft']},
              },
            },
          },
          second: {
            'equipment:item-b:0': {
              battleStatus: 'scry_retention',
              turnStartExtraDraw: {
                count: 1,
                costIncrease: {amount: 1, notGenres: ['spellcraft']},
              },
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
    expect(result['turnStartExtraDraw']['costIncrease']['amount'], 1);
    expect(result['turnStartExtraDraw']['costIncrease']['notGenres'],
        ['spellcraft']);
    expect(result['battleStatus']['scry_retention'], 2);
  });
}
