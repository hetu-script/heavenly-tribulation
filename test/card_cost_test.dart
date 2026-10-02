import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:heavenly_tribulation/scene/battle/card_cost.dart';

void main() {
  const mana = 'energy_positive_spell';
  const wildcard = 'energy_positive_ultimate';

  test('真实 Hetu 费用求值保留动态零费用，基线独立，Dart 可读取 HTStruct', () {
    final hetu = Hetu()..init();
    final cardSource = File('scripts/main/cardgame/card.ht').readAsStringSync();
    final costSource = cardSource.substring(
        0, cardSource.indexOf('function getCardRankUpProbability'));
    final commonSource = File('scripts/main/data/common.ht').readAsStringSync();
    final formulaStart = commonSource.indexOf('function calculateCostValue(');
    final formulaEnd = commonSource.indexOf('\n}', formulaStart) + 2;
    hetu.eval('''
      final Constants = { colorlessCostColorId: 'life' }
      ${commonSource.substring(formulaStart, formulaEnd)}
      $costSource
      final card = {
        rank: 5,
        affixes: [{coloredCost: {spell: {base: 0, isDynamic: true}}}],
      }
      updateCardCost(card)
    ''');
    final dynamic card = hetu.fetch('card');
    expect(isDynamicCardCost(card['coloredCost']['spell']), isTrue);
    expect(cardCostBase(card['coloredCost']['spell']), 0);
    modifyCardCost(card['coloredCost'], 'spell', 2);
    clearReducibleCardCosts(card['coloredCost']);
    expect(cardCostBase(card['coloredCost']['spell']), 2);
    expect(cardCostBase(card['originalColoredCost']['spell']), 0);
    expect(
        calculateCardPayment(card['coloredCost'], {mana: 7}).paid, {mana: 7});
    hetu.eval(
        'card.affixes[0].coloredCost.spell.base = 10\nupdateCardCost(card)');
    expect(cardCostBase(card['coloredCost']['spell']), 10);
  });

  test('真实伤害脚本消费 paidCost，不再次耗尽后来获得的气', () {
    final hetu = Hetu()..init();
    hetu.eval(File('scripts/main/cardgame/card_script.ht').readAsStringSync());
    final result = hetu.eval('''
      final self = {cardFlags: {paidCost: {energy_positive_spell: 7}}, mana: 2}
      final opponent = {
        hits: [],
        takeDamage: function(details) { this.hits.add(details.baseValue) },
      }
      final affix = {
        resourceId: 'energy_positive_spell', value: [4],
        kind: 'firebend', cardType: 'spell', damageType: 'fire',
      }
      CardScript.attack_by_paid_resource(self, opponent, {}, affix)
      self.cardFlags.paidCost = {}
      CardScript.attack_by_paid_resource(self, opponent, {}, affix)
      [opponent.hits[0], opponent.hits.length, self.mana]
    ''');
    expect(result, [28, 1, 2]);
  });

  test('X 支付全部本色气，允许零气，不耗尽太极', () {
    final costs = {
      'spell': {'base': 0, 'isDynamic': true}
    };
    final payment = calculateCardPayment(costs, {mana: 7, wildcard: 4});
    expect(payment.paid, {mana: 7});
    expect(payment.missing, isEmpty);
    expect(calculateCardPayment(costs, {}).paid, isEmpty);
    expect(calculateCardPayment(costs, {}).missing, isEmpty);
  });

  test('10+X 必须覆盖门槛，失败不产生部分支付', () {
    final costs = {
      'spell': {'base': 10, 'isDynamic': true}
    };
    final rejected = calculateCardPayment(costs, {mana: 9, wildcard: 20},
        wildcardForbidden: true);
    expect(rejected.missing, {mana: (10, 9)});
    expect(rejected.paid, isEmpty);
    for (final stock in [10, 12]) {
      expect(
          calculateCardPayment(costs, {mana: stock}, wildcardForbidden: true)
              .paid,
          {mana: stock});
    }
    expect(calculateCardPayment(costs, {mana: 9, wildcard: 20}).paid,
        {mana: 9, wildcard: 1});
  });

  test('队列按顺序预占，先普通费用再动态耗尽', () {
    final stock = {mana: 12};
    final first = calculateCardPayment({'spell': 2}, stock);
    for (final entry in first.paid.entries) {
      stock[entry.key] = stock[entry.key]! - entry.value;
    }
    final dynamicPayment = calculateCardPayment({
      'spell': {'base': 10, 'isDynamic': true}
    }, stock, wildcardForbidden: true);
    expect(dynamicPayment.paid, {mana: 10});
    for (final entry in dynamicPayment.paid.entries) {
      stock[entry.key] = stock[entry.key]! - entry.value;
    }
    expect(calculateCardPayment({'spell': 1}, stock).missing, isNotEmpty);
  });

  test('动态减费豁免、加费与还原保留 X；普通减费保持下限', () {
    final costs = <String, dynamic>{
      'spell': {'base': 0, 'isDynamic': true}
    };
    expect(modifyCardCost(costs, 'spell', -10), 0);
    expect(modifyCardCost(costs, 'spell', 2), 2);
    expect(cardCostBase(costs['spell']), 2);
    expect(modifyCardCost(costs, 'spell', -2, restoring: true), -2);
    expect(isDynamicCardCost(costs['spell']), isTrue);
    costs['spell'] = 3;
    expect(modifyCardCost(costs, 'spell', -5), -3);
    expect(costs['spell'], 0);
  });

  test('费用置零保留动态门槛并清除普通条目', () {
    final costs = <String, dynamic>{
      'spell': {'base': 10, 'isDynamic': true},
      'life': 2,
    };
    clearReducibleCardCosts(costs);
    expect(cardCostBase(costs['spell']), 10);
    expect(isDynamicCardCost(costs['spell']), isTrue);
    expect(costs['life'], 0);
  });

  test('元气为零时有色费用仍可支付，免费牌始终可支付', () {
    expect(calculateCardPayment({'spell': 2}, {mana: 2}).missing, isEmpty);
    expect(calculateCardPayment({'spell': 2}, {wildcard: 2}).missing, isEmpty);
    expect(calculateCardPayment({'life': 1}, {mana: 2}).missing, isNotEmpty);
    expect(calculateCardPayment({}, {}).missing, isEmpty);
  });
}
