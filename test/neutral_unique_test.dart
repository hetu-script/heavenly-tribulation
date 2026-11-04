import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';

import 'support/hetu_test_utils.dart';

void main() {
  Hetu createScriptHetu() {
    final hetu = createTestHetu();
    final source = File('scripts/main/logic/logic.ht').readAsStringSync();
    final start = source.indexOf('function _mergeGreaterMechanismData');
    final end = source.indexOf('const _kMoneyRewardRate', start);
    hetu.eval(source.substring(start, end));
    hetu.eval(File('scripts/main/cardgame/card_script.ht').readAsStringSync());
    return hetu;
  }

  test('归元功记录实际消耗并按门槛提供护甲与护盾', () {
    final hetu = createScriptHetu();
    final result = hetu.eval('''
      final self = {
        mana: 3,
        lifeMax: 100,
        cardFlags: {},
        statuses: [],
        hasStatusEffect: function(id) {
          if (id == 'energy_positive_life') return this.mana
          return 0
        },
        removeStatusEffect: function(id, {amount, percentage, force}) {
          this.mana -= amount
          return amount
        },
        changeLife: function(value, {isHeal, damageType}) {},
        addStatusEffect: function(id, {amount, source, params}) {
          this.statuses.add({id: id, amount: amount})
        },
      }
      CardScript.heal_vigor_all(self, null, {}, {value: [10]})
      CardScript.defend_by_vigor_consumed(
        self, null, {}, {threshold: 3, buffId: 'defense', value: [2]})
      CardScript.gain_status_by_vigor_consumed(
        self, null, {}, {threshold: 3, buffId: 'buff_shield', count: 1})
      final low = Object.create(self)
      low.mana = 2
      low.cardFlags = {}
      low.statuses = []
      CardScript.heal_vigor_all(low, null, {}, {value: [10]})
      CardScript.defend_by_vigor_consumed(
        low, null, {}, {threshold: 3, buffId: 'defense', value: [2]})
      CardScript.gain_status_by_vigor_consumed(
        low, null, {}, {threshold: 3, buffId: 'buff_shield', count: 1})
      [
        self.cardFlags.lastVigorConsumed,
        self.mana,
        self.statuses.length,
        self.statuses[0].id,
        self.statuses[0].amount,
        self.statuses[1].id,
        self.statuses[1].amount,
        low.cardFlags.lastVigorConsumed,
        low.statuses.length,
      ]
    ''');
    expect(result, [3, 0, 2, 'defense', 6, 'buff_shield', 1, 2, 0]);
  });

  test('归元功额外净化随机移除一层普通负面状态', () {
    final hetu = createScriptHetu();
    final result = hetu.eval('''
      final Constants = {debuffs: ['vulnerable']}
      final random = {nextIterable: function(values) { return values.first }}
      final self = {
        cardFlags: {lastVigorConsumed: 3},
        vulnerable: 1,
        removed: [],
        hasStatusEffect: function(id) { return this[id] ?? 0 },
        removeStatusEffect: function(id, {amount, percentage, force}) {
          this[id] -= amount
          this.removed.add([id, amount])
          return amount
        },
      }
      CardScript.cleanse_by_vigor_consumed(self, null, {}, {threshold: 3, count: 1})
      [self.vulnerable, self.removed]
    ''');
    expect(result, [
      0,
      [
        ['vulnerable', 1]
      ]
    ]);
  });

  test('先天功分别检查元气门槛，太极转化不消耗元气', () {
    final hetu = createScriptHetu();
    final result = hetu.eval('''
      final self = {
        mana: 3,
        statuses: [],
        hasStatusEffect: function(id) { return this.mana },
        addStatusEffect: function(id, {amount, source, params}) {
          this.statuses.add({id: id, amount: amount})
        },
      }
      CardScript.gain_status_by_energy_count(self, null, {}, {
        resourceId: 'energy_positive_life', resourceThreshold: 3,
        buffId: 'defense', value: [5],
      })
      CardScript.gain_status_by_energy_count(self, null, {}, {
        resourceId: 'energy_positive_life', resourceThreshold: 3,
        buffId: 'energy_positive_ultimate', count: 1,
      })
      CardScript.gain_status_and_resource(self, null, {}, {
        buffId: 'buff_shield', statusAmount: 2,
        resourceId: 'energy_negative_life', resourceAmount: 1,
      })
      [
        self.mana,
        self.statuses[0].amount,
        self.statuses[1].id,
        self.statuses[1].amount,
        self.statuses[2].amount,
        self.statuses[3].id,
        self.statuses[3].amount,
      ]
    ''');
    expect(result, [
      3,
      5,
      'energy_positive_ultimate',
      1,
      2,
      'energy_negative_life',
      1,
    ]);
  });

  test('参玄功只升级并减费主词条提供的抽牌记录', () {
    final hetu = createScriptHetu();
    final result = hetu.eval('''
      function upgradeCard(card, {inBattle}) {
        card.upgrades = (card.upgrades ?? 0) + 1
      }
      final first = {upgrades: 0, costs: []}
      final second = {upgrades: 0, costs: []}
      final other = {upgrades: 0, costs: []}
      final self = {
        cardFlags: {lastDrawnCards: [first, second]},
        applyTurnCostModifier: function(card, {delta}) { card.costs.add(delta) },
      }
      CardScript.draw_cards_upgrade(self, null, {}, {value: [1]})
      CardScript.draw_cards_cost_reduction(self, null, {}, {value: [1]})
      [first.upgrades, second.upgrades, other.upgrades, first.costs, second.costs, other.costs]
    ''');
    expect(result, [
      1,
      1,
      0,
      [-1],
      [-1],
      <dynamic>[]
    ]);

    final affixes = loadJson5File('assets/data/card_affixes.json5');
    expect(affixes['draw_cards_upgrade']['priority'], 20);
    expect(affixes['draw_cards_cost_reduction']['priority'], 10);
    expect(affixes['draw_cards_neutral']['priority'] ?? 0, 0);
  });

  test('万化归墟按实际支付元气结算伤害、超额护甲与下回合产出', () {
    final hetu = createScriptHetu();
    final result = hetu.eval('''
      final self = {
        cardFlags: {paidCost: {energy_positive_life: 5}},
        turnFlags: {},
        statuses: [],
        addStatusEffect: function(id, {amount, source, params}) {
          this.statuses.add({id: id, amount: amount})
        },
      }
      final opponent = {
        hits: [],
        takeDamage: function(details) { this.hits.add(details.baseValue) },
      }
      final card = {
        affixes: [{coloredCost: {life: {base: 3, isDynamic: true}}}],
      }
      CardScript.attack_by_paid_resource(self, opponent, card, {
        resourceId: 'energy_positive_life', value: [2],
        kind: 'power_word', cardType: 'curse', damageType: 'pure',
      })
      CardScript.defend_by_excess_paid(self, opponent, card, {
        resourceId: 'energy_positive_life', value: [3],
      })
      CardScript.gain_resource_next_turn(self, opponent, card, {
        resourceId: 'energy_positive_life', value: [2],
      })
      [
        opponent.hits,
        self.statuses[0].id,
        self.statuses[0].amount,
        self.turnFlags.pendingResources.energy_positive_life,
      ]
    ''');
    expect(result, [
      [10],
      'defense',
      6,
      2,
    ]);
  });

  test('狭路相逢主脚本固定造成三段伤害', () {
    final hetu = createScriptHetu();
    final result = hetu.eval('''
      final opponent = {
        hits: [],
        takeDamage: function(details) { this.hits.add(details.baseValue) },
      }
      CardScript.attack_multiple(null, opponent, {}, {
        value: [8, 3], kind: 'punch', cardType: 'unarmed', damageType: 'physical',
      })
      opponent.hits
    ''');
    expect(result, [8, 8, 8]);
  });
}
