import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/hetu_test_utils.dart';

void main() {
  test('易伤数据使用逐段受伤与整牌结束回调，不再随回合衰减', () {
    final status =
        loadJson5File('assets/data/status_effect.json5')['vulnerable'];
    expect(status['callbacks'], ['self_taking_damage', 'opponent_used_card']);
    expect(status['callbacks'], isNot(contains('self_turn_end')));
  });

  test('易伤强化攻击牌每一段并在整牌后消耗，排除非卡牌伤害', () {
    final hetu = createTestHetu();
    hetu.eval('var Constants');
    hetu.assign('Constants', {'elementAilments': {}});
    hetu.eval(
        File('scripts/main/cardgame/status_script.ht').readAsStringSync());
    final result = hetu.eval('''
      final target = {
        amount: 4,
        removals: [],
        removeStatusEffect: function(id, {amount, percentage, force}) {
          this.removals.add(id)
          this.amount = 0
          return 4
        },
      }
      final attacker = {
        cardFlags: {isResolvingCard: true, category: 'attack'},
      }
      final effect = {id: 'vulnerable', amount: 4}
      final first = {baseChange: 0}
      final second = {baseChange: 0}
      StatusScript.vulnerable_self_taking_damage(
        target, attacker, effect, first)
      StatusScript.vulnerable_self_taking_damage(
        target, attacker, effect, second)
      final beforeConsumption = target.amount
      StatusScript.vulnerable_opponent_used_card(
        target, attacker, effect, {})
      final afterAttack = target.amount

      target.amount = 4
      attacker.cardFlags.category = 'buff'
      StatusScript.vulnerable_opponent_used_card(
        target, attacker, effect, {})
      final afterBuff = target.amount

      attacker.cardFlags.category = 'attack'
      attacker.cardFlags.isResolvingCard = false
      final nonCardDamage = {baseChange: 0}
      StatusScript.vulnerable_self_taking_damage(
        target, attacker, effect, nonCardDamage)
      [
        first.baseChange,
        second.baseChange,
        beforeConsumption,
        afterAttack,
        afterBuff,
        nonCardDamage.baseChange,
        target.removals,
      ]
    ''');
    expect(result, [
      4,
      4,
      4,
      0,
      4,
      0,
      ['vulnerable']
    ]);
  });
}
