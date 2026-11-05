import 'package:flutter_test/flutter_test.dart';
import 'package:samsara/richtext.dart';

import 'package:heavenly_tribulation/data/game.dart';
import 'package:heavenly_tribulation/global.dart';

void main() {
  test('详细浮窗在流派境界行后显示多色动态费用', () {
    engine.loadLocaleDataFromJSON({
      'zh': {
        'languageId': 'zh',
        'cost': '费用',
        'none': '无',
        'genre': '流派',
        'category': '类别',
        'cultivationRank': '境界',
        'cultivationRank_3': '结丹',
        'level2': '等级',
        'spellcraft': '悟道',
        'attack': '攻击',
        'test_card_affix': '效果 {0}',
        'status_energy_positive_life': '元气',
        'status_energy_positive_spell': '灵气',
      },
    });
    RichTextIcons.registerAll(const {
      'battlecard_cost_life': 'icon/cost/qi_basic.png',
      'battlecard_cost_spell': 'icon/cost/qi_mana.png',
    });

    final cardData = {
      'id': 'test_card',
      'name': '测试卡',
      'level': 30,
      'rank': 3,
      'genre': 'spellcraft',
      'category': 'attack',
      'isIdentified': true,
      'coloredCost': {
        'life': 1,
        'spell': {'base': 2, 'isDynamic': true},
      },
      'affixes': [
        {
          'description': 'test_card_affix',
          'value': [1]
        },
      ],
    };

    final (_, hoverDescription) = GameData.getBattleCardDescription(
      cardData,
      showAffixes: true,
      showRequirement: false,
      showDebugId: false,
    );
    final lines = hoverDescription.split('\n');

    expect(
      RichTextIcons.resolveFlutterAsset('battlecard_cost_life'),
      'assets/images/icon/cost/qi_basic.png',
    );
    expect(lines[2],
        '<grey>费用:</> 元气<icon=battlecard_cost_life></>（1）、灵气<icon=battlecard_cost_spell></>（2+X）');
  });

  test('无费用卡显示费用无', () {
    engine.loadLocaleDataFromJSON({
      'zh': {
        'languageId': 'zh',
        'cost': '费用',
        'none': '无',
        'genre': '流派',
        'category': '类别',
        'cultivationRank': '境界',
        'cultivationRank_0': '无境界',
        'level2': '等级',
        'attack': '攻击',
        'test_card_affix': '效果 {0}',
      },
    });

    final cardData = {
      'id': 'test_free_card',
      'name': '免费卡',
      'level': 1,
      'rank': 0,
      'genre': null,
      'category': 'attack',
      'isIdentified': true,
      'coloredCost': <String, dynamic>{},
      'affixes': [
        {
          'description': 'test_card_affix',
          'value': [1]
        },
      ],
    };

    final (_, hoverDescription) = GameData.getBattleCardDescription(
      cardData,
      showAffixes: true,
      showRequirement: false,
      showDebugId: false,
    );

    expect(hoverDescription.split('\n')[2], '<grey>费用:</> 无');
  });
}
