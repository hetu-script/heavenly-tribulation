import 'package:flutter_test/flutter_test.dart';
import 'package:heavenly_tribulation/data/game.dart';
import 'package:heavenly_tribulation/global.dart';

import 'support/hetu_test_utils.dart';

void main() {
  test('天赋树机制词条使用原型参数替换描述占位', () {
    engine.loadLocaleDataFromJSON({
      'zh': {
        'languageId': 'zh',
        'passive_scry_upgrade_description': '每回合第一次观星后，选中的牌等级 +{0}',
        'passive_scry_shield_description': '每回合第一次观星后，获得 {0} 层护盾',
        'passive_scry_mana_description': '每回合第一次观星后，获得 {0} 点灵气',
        'passive_scry_all_damage_description': '每回合第一次观星后，获得 {0} 层无极之气',
        'passive_spirituality_description': '灵力 {0}',
      }
    });
    final passives = loadJson5File('assets/data/passives.json5');
    final statuses = loadJson5File('assets/data/status_effect.json5');
    const scryIds = [
      'scry_upgrade',
      'scry_shield',
      'scry_mana',
      'scry_all_damage',
    ];
    for (final id in [...scryIds, 'spirituality']) {
      GameData.passives[id] = passives[id];
    }
    for (final id in scryIds) {
      GameData.statusEffects[id] = statuses[id];
    }

    try {
      final descriptions = {
        for (final id in scryIds)
          id: GameData.getPassiveTreeAffixDescription({'id': id}),
      };
      expect(descriptions['scry_upgrade'], contains('等级 +1'));
      expect(descriptions['scry_shield'], contains('获得 1 层护盾'));
      expect(descriptions['scry_mana'], contains('获得 1 点灵气'));
      expect(descriptions['scry_all_damage'], contains('获得 1 层无极之气'));
      for (final description in descriptions.values) {
        expect(description, isNot(contains('{0}')));
      }

      final attribute = GameData.getPassiveTreeAffixDescription({
        'id': 'spirituality',
        'level': 30,
      });
      expect(attribute, '灵力 +15');
    } finally {
      for (final id in [...scryIds, 'spirituality']) {
        GameData.passives.remove(id);
      }
      for (final id in scryIds) {
        GameData.statusEffects.remove(id);
      }
    }
  });
}
