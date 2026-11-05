import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heavenly_tribulation/data/common.dart';
import 'package:heavenly_tribulation/scene/battle/common.dart';

import 'support/hetu_test_utils.dart';

void main() {
  test('太极之气与阴气在回合开始保留，其余阳气清空', () {
    const clearedResources = [
      'energy_positive_life',
      'energy_positive_spell',
      'energy_positive_weapon',
      'energy_positive_unarmed',
      'energy_positive_curse',
    ];
    for (final id in clearedResources) {
      expect(shouldClearResourceAtTurnStart(id), isTrue, reason: id);
    }

    expect(shouldClearResourceAtTurnStart('energy_positive_ultimate'), isFalse);
    for (final id in kNegativeResourceQi) {
      expect(shouldClearResourceAtTurnStart(id), isFalse, reason: id);
    }
  });

  test('死气在产出阶段结算，仍有剩余才扣血且不自动消耗', () {
    final statusData = loadJson5File('assets/data/status_effect.json5');
    final callbacks = statusData['energy_negative_life']['callbacks'] as List;
    expect(callbacks, contains('self_produce_resources'));
    expect(callbacks, isNot(contains('self_turn_start')));

    final hetu = createTestHetu();
    hetu.eval('var Constants');
    hetu.assign('Constants', {'elementAilments': kElementAilmentIds});
    hetu.eval(
        File('scripts/main/cardgame/status_script.ht').readAsStringSync());
    final result = hetu.eval('''
      final self = {
        lifeMax: 100,
        losses: [],
        changeLife: function(value, {isHeal, damageType}) {
          this.losses.add(value)
        },
      }
      StatusScript.energy_negative_life_self_produce_resources(
        self, null, {amount: 0}, {})
      final remaining = {id: 'energy_negative_life', amount: 2}
      StatusScript.energy_negative_life_self_produce_resources(
        self, null, remaining, {})
      StatusScript.energy_negative_life_self_produce_resources(
        self, null, remaining, {})
      [self.losses, remaining.amount]
    ''');
    expect(result, [
      [-5, -5],
      2,
    ]);
  });
}
