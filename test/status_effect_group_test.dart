import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/hovertip.dart';
import 'package:heavenly_tribulation/data/game.dart';
import 'package:heavenly_tribulation/data/common.dart';
import 'package:heavenly_tribulation/scene/battle/battle.dart';
import 'package:heavenly_tribulation/scene/battle/battledeck_zone.dart';
import 'package:heavenly_tribulation/scene/battle/character.dart';
import 'package:heavenly_tribulation/scene/battle/status_effect.dart';
import 'package:heavenly_tribulation/scene/battle/status_effect_group.dart';
import 'package:heavenly_tribulation/ui.dart';

import 'support/hetu_test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  StatusEffect createEffect(
    String id,
    String groupId,
    int amount,
  ) {
    GameData.statusEffects[id] = {
      'id': id,
      'title': 'status_$id',
      'description': 'status_${id}_description',
      'isPermanent': true,
      'displayGroup': groupId,
    };
    return StatusEffect(id: id, amount: amount);
  }

  tearDown(() {
    GameData.statusEffects.remove('test_scry_a');
    GameData.statusEffects.remove('test_scry_b');
    GameData.statusEffects.remove('test_damage_a');
    GameData.statusEffects.remove('test_damage_b');
  });

  test('真实状态数据的显示分组均有配置且图标存在', () {
    final statuses = loadJson5File('assets/data/status_effect.json5');
    final counts = <String, int>{};
    for (final data in statuses.values) {
      final groupId = data['displayGroup'];
      if (groupId == null) continue;
      expect(data['isPermanent'], isTrue);
      expect(kStatusDisplayGroups, contains(groupId));
      counts[groupId] = (counts[groupId] ?? 0) + 1;
    }
    expect(counts, {
      'scry': 5,
      'kind_damage': 17,
      'elemental_resist': 8,
      'attack_type': 8,
      'turn_start_resource': 6,
    });
    for (final config in kStatusDisplayGroups.values) {
      expect(File('assets/images/${config.icon}').existsSync(), isTrue);
    }
  });

  test('分组组件动态维护成员，重复加入不会产生副本', () {
    final first = createEffect('test_scry_a', 'scry', 1);
    final second = createEffect('test_scry_b', 'scry', 1);
    final group = StatusEffectGroup(
      config: kStatusDisplayGroups['scry']!,
      effect: first,
    );
    group.addEffect(second);
    group.addEffect(second);
    expect(group.effects, [first, second]);

    group.removeEffect(first);
    expect(group.effects, [second]);
    expect(group.isEmpty, isFalse);
    group.removeEffect(second);
    expect(group.isEmpty, isTrue);
  });

  test('数值分组显示各成员当前数值而不求和', () {
    final first = createEffect('test_damage_a', 'kind_damage', 3);
    final second = createEffect('test_damage_b', 'kind_damage', 7);
    final group = StatusEffectGroup(
      config: kStatusDisplayGroups['kind_damage']!,
      effect: first,
    );
    group.addEffect(second);

    final description = group.description;
    expect(description, contains('status_test_damage_a：3%'));
    expect(description, contains('status_test_damage_b：7%'));
    expect(description, isNot(contains('10%')));

    first.amount = 4;
    expect(group.description, contains('status_test_damage_a：4%'));
  });

  test('资源分组按成员参数显示最终产出值', () {
    final first = createEffect('test_damage_a', 'turn_start_resource', 1);
    final second = createEffect('test_damage_b', 'turn_start_resource', 1);
    first.data['resourceAmount'] = 2;
    second.data['resourceAmount'] = 4;
    final group = StatusEffectGroup(
      config: kStatusDisplayGroups['turn_start_resource']!,
      effect: first,
    );
    group.addEffect(second);

    expect(group.description, contains('status_test_damage_a：2'));
    expect(group.description, contains('status_test_damage_b：4'));
    expect(group.description, isNot(contains('2%')));
  });

  test('属性面板资源读取统一使用聚合后的状态参数', () {
    final character = {
      'stats': {
        'battleStatusParams': {
          'turn_start_gain_vigor': {'resourceAmount': 2},
          'turn_start_gain_mana': {'resourceAmount': 5},
        },
      },
    };
    expect(kTurnStartResourceStatusIds, hasLength(6));
    expect(getTurnStartResourceAmount(character, 'turn_start_gain_vigor'), 2);
    expect(getTurnStartResourceAmount(character, 'turn_start_gain_mana'), 5);
    expect(getTurnStartResourceAmount(character, 'turn_start_gain_chakra'), 0);
  });

  test('真实战斗角色按显示分组合并图标并保持逻辑状态独立', () async {
    final statuses = loadJson5File('assets/data/status_effect.json5');
    const ids = [
      'scry_upgrade',
      'scry_shield',
      'key_branch_spellcraft_overflow'
    ];
    for (final id in ids) {
      GameData.statusEffects[id] = statuses[id];
    }
    GameUI.setSize(Vector2(1440, 810));
    final scene = BattleScene(
      heroData: const {},
      enemyData: const {},
      isSneakAttack: false,
      backgroundImageId: '',
    );
    final character = _TestBattleCharacter(
      data: {
        'life': 100,
        'stats': {'battleLifeMax': 100},
      },
      deckZone: BattleDeckZone(
        position: Vector2.zero(),
        hovertipDirection: HovertipDirection.topLeft,
      ),
    );

    try {
      await scene.world.add(character);
      character.addStatusEffect('scry_upgrade',
          amount: 1, handleCallback: false);
      character.addStatusEffect('scry_shield',
          amount: 1, handleCallback: false);
      character.addStatusEffect('key_branch_spellcraft_overflow',
          amount: 1, handleCallback: false);

      expect(character.permanentEffects, hasLength(3));
      expect(character.permanentDisplayEffects, hasLength(2));
      final group = character.permanentDisplayEffects
          .whereType<StatusEffectGroup>()
          .single;
      expect(group.id, 'scry');
      expect(group.effects, hasLength(2));

      character.removeStatusEffect('scry_upgrade', amount: 1);
      expect(character.permanentEffects, hasLength(2));
      expect(character.permanentDisplayEffects, hasLength(2));
      expect(group.effects, hasLength(1));

      character.removeStatusEffect('scry_shield', amount: 1);
      expect(character.permanentEffects, hasLength(1));
      expect(character.permanentDisplayEffects, hasLength(1));
      expect(character.permanentDisplayEffects.single, isA<StatusEffect>());

      character.removeStatusEffect('key_branch_spellcraft_overflow', amount: 1);
      expect(character.permanentDisplayEffects, isEmpty);
    } finally {
      for (final id in ids) {
        GameData.statusEffects.remove(id);
      }
    }
  });
}

class _TestBattleCharacter extends BattleCharacter {
  _TestBattleCharacter({
    required super.data,
    required super.deckZone,
  }) : super(
          isHero: true,
          skinId: 'test',
        );

  @override
  Future<void> onLoad() async {}
}
