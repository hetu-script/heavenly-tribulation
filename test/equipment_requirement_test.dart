import 'package:flutter_test/flutter_test.dart';
import 'package:heavenly_tribulation/data/game.dart';
import 'package:heavenly_tribulation/logic/logic.dart';

void main() {
  test('卡牌装备需求直接读取当前装备种类，不依赖 equipment 被动', () {
    final previousHero = GameData.hero;
    try {
      GameData.hero = {
        'rank': 0,
        'level': 0,
        'passives': {
          'equipment_sword': {'id': 'equipment_sword'},
        },
        'equipments': <String, dynamic>{'0': null},
        'inventory': <String, dynamic>{},
      };
      expect(GameLogic.checkRequirements({'equipment': 'sword'}), isNotNull);

      GameData.hero['equipments']['0'] = 'equipped-sword';
      GameData.hero['inventory']['equipped-sword'] = {'kind': 'sword'};
      expect(GameLogic.checkRequirements({'equipment': 'sword'}), isNull);
      expect(GameLogic.checkRequirements({'equipment': 'sabre'}), isNotNull);
      expect(
        GameLogic.checkRequirements({
          'equipment': ['sabre', 'sword'],
        }),
        isNull,
      );
    } finally {
      GameData.hero = previousHero;
    }
  });

  test('卡牌境界不是使用限制，其他系统的显式境界检查不受影响', () {
    final previousHero = GameData.hero;
    try {
      GameData.hero = {
        'rank': 0,
        'level': 0,
        'equipments': <String, dynamic>{},
        'inventory': <String, dynamic>{},
      };
      final card = {'rank': 5};

      expect(GameLogic.checkCardRequirements(card), isNull);
      expect(
        GameLogic.checkRequirements(card, checkRank: true),
        isNotNull,
      );
    } finally {
      GameData.hero = previousHero;
    }
  });
}
