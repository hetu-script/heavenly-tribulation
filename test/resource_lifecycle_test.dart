import 'package:flutter_test/flutter_test.dart';
import 'package:heavenly_tribulation/scene/battle/common.dart';

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
}
