import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:samsara/richtext.dart';
import 'package:heavenly_tribulation/data/constants.dart';
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
      GameData.hero['inventory']['equipped-sword'] = {
        'kind': 'sword',
        'equippedPosition': 0,
      };
      expect(GameLogic.checkRequirements({'equipment': 'sword'}), isNull);
      expect(GameLogic.checkRequirements({'equipment': 'sabre'}), isNotNull);
      expect(
        GameLogic.checkRequirements({
          'equipment': ['sabre', 'sword'],
        }),
        isNull,
      );

      GameData.hero['inventory']['equipped-sword']['isInvalid'] = true;
      expect(GameLogic.checkRequirements({'equipment': 'sword'}), isNotNull);
      GameData.hero['inventory']['equipped-sword']['isInvalid'] = false;
      expect(GameLogic.checkRequirements({'equipment': 'sword'}), isNull);
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

  test('装备属性要求按 kind、等级和原型覆盖计算', () {
    for (final kind in kEquipmentKinds) {
      expect(kEquipmentAttributeRequirementProfiles[kind], isNotNull,
          reason: kind);
    }
    expect(GameLogic.calculateEquipmentAttributeRequirements('sword', 15),
        {'dexterity': 23});
    expect(GameLogic.calculateEquipmentAttributeRequirements('armor', 35),
        {'strength': 44});
    expect(GameLogic.calculateEquipmentAttributeRequirements('ring', 65),
        {'spirituality': 65});
    expect(
      GameLogic.calculateEquipmentAttributeRequirements('pearl', 20,
          override: {'attribute': 'willpower', 'base': 5, 'factor': 0}),
      {'willpower': 5},
    );
  });

  test('卡牌需求使用指定角色的生效装备', () {
    final previousHero = GameData.hero;
    try {
      GameData.hero = {
        'equipments': <String, dynamic>{},
        'inventory': <String, dynamic>{},
      };
      final npc = {
        'equipments': {'0': 'npc-sword'},
        'inventory': {
          'npc-sword': {'kind': 'sword', 'equippedPosition': 0},
        },
      };
      expect(
        GameLogic.checkCardRequirements({'equipment': 'sword'}, character: npc),
        isNull,
      );
      expect(
          GameLogic.checkCardRequirements({'equipment': 'sword'}), isNotNull);
    } finally {
      GameData.hero = previousHero;
    }
  });

  test('富文本标签内容支持斜杠且不影响后续标签', () {
    final spans = buildFlutterRichText('<red>属性需求：灵力 50/98</><grey>后续</>');
    final children = spans.single.children!;
    final requirement = children[0] as TextSpan;
    final following = children[1] as TextSpan;

    expect(requirement.text, '属性需求：灵力 50/98');
    expect(requirement.style?.color, Colors.red);
    expect(following.text, '后续');
    expect(following.style?.color, Colors.grey);
  });
}
