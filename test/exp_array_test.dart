import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:json5/json5.dart';

import 'package:heavenly_tribulation/logic/logic.dart';
import 'package:heavenly_tribulation/scene/cultivation/exp_array.dart';

void main() {
  String loadExpArraySource() {
    final source = File('scripts/main/binding/player.ht').readAsStringSync();
    final start = source.indexOf('  /// 聚灵阵冥想');
    final end = source.indexOf('\n}', start);
    return source.substring(start, end);
  }

  Hetu createHetu(Map<String, dynamic> passives) {
    final hetu = Hetu(
      config: HetuConfig(
        allowImplicitNullToZeroConversion: true,
        allowImplicitEmptyValueToFalseConversion: true,
      ),
    )..init();
    hetu.interpreter.bindExternalFunction(
      'calculatePassiveAffixValue',
      ({positionalArgs, namedArgs}) => GameLogic.calculatePassiveAffixValue(
        positionalArgs.first,
        level: namedArgs['level'] ?? 0,
        isGreater: namedArgs['isGreater'] ?? false,
      ),
      override: true,
    );
    hetu.interpreter.bindExternalFunction(
      'minLevelForRank',
      ({positionalArgs, namedArgs}) =>
          GameLogic.minLevelForRank(positionalArgs.first),
      override: true,
    );
    hetu.interpreter.bindExternalFunction(
      'maxLevelForRank',
      ({positionalArgs, namedArgs}) =>
          GameLogic.maxLevelForRank(positionalArgs.first),
      override: true,
    );
    hetu.eval('var game; var hero;');
    hetu.assign('game', {'passives': passives});
    hetu.assign('hero', {
      'ephemeralPassivesRaw': <String, dynamic>{},
      'ephemeralPassives': <String, dynamic>{},
      'stats': <String, dynamic>{},
    });
    hetu.eval('''
      external function calculatePassiveAffixValue(valueData, {level = 0, isGreater = false}) -> integer
      external function minLevelForRank(rank) -> integer
      external function maxLevelForRank(rank) -> integer
      final kEphemeralScopeBattlePreparation = 'battle_preparation'
      final random = {
        nextIterable: function(values) { return values.first },
      }
      function getRandomLevel(min, max) { return min }
      ${loadExpArraySource()}
    ''');
    return hetu;
  }

  Map<String, dynamic> loadPassives() {
    return Map<String, dynamic>.from(
        json5Decode(File('assets/data/passives.json5').readAsStringSync())
            as Map);
  }

  test('聚灵阵轮数在 0～5 发展度分别为 1、2、3、3、3、3', () {
    expect(List.generate(6, getExpArrayMaxRounds), [1, 2, 3, 3, 3, 3]);
  });

  test('词条生成返回独立实例、不写英雄并支持同批排除与类别耗尽', () {
    final passives = loadPassives();
    final hetu = createHetu(passives);
    final first = hetu.invoke('getExpArrayBuff', positionalArgs: ['attack', 5]);
    expect(first, isNotNull);
    expect(first['ephemeralScope'], 'battle_preparation');
    expect(identical(first, passives[first['id']]), isFalse);
    expect(hetu.fetch('hero')['ephemeralPassivesRaw'], isEmpty);

    final second = hetu.invoke('getExpArrayBuff', positionalArgs: [
      'attack',
      5
    ], namedArgs: {
      'excludeIds': [first['id']]
    });
    expect(second['id'], isNot(first['id']));

    final attackIds = passives.values
        .where((affix) =>
            affix['isEphemeral'] == true && affix['ephemeralType'] == 'attack')
        .map((affix) => affix['id'])
        .toList();
    final exhausted = hetu.invoke('getExpArrayBuff',
        positionalArgs: ['attack', 5], namedArgs: {'excludeIds': attackIds});
    expect(exhausted, isNull);
  });

  test('能量类别按 rank 提供候选，类别无候选时返回空', () {
    final hetu = createHetu(loadPassives());
    expect(
        hetu.invoke('getExpArrayBuff', positionalArgs: ['energy', 2]), isNull);
    final affix = hetu.invoke('getExpArrayBuff', positionalArgs: ['energy', 3]);
    expect(affix['id'], 'start_turn_with_energy_positive_life');
    expect(affix['value'], isNotNull);
  });

  test('太古预览在副本上满级强化且不修改原实例或公共原型', () {
    final passives = loadPassives();
    final hetu = createHetu(passives);
    final affix = hetu.invoke('getExpArrayBuff', positionalArgs: ['attack', 3]);
    final originalValue = affix['value'];
    final originalLevel = affix['level'];
    final preview =
        hetu.invoke('upgradeExpArrayBuffToGreater', positionalArgs: [affix, 3]);
    expect(preview['isGreater'], true);
    expect(preview['level'], GameLogic.maxLevelForRank(3));
    expect(preview['value'], greaterThan(originalValue));
    expect(affix['value'], originalValue);
    expect(affix['level'], originalLevel);
    expect(affix['isGreater'], isNot(true));
    expect(passives[affix['id']]['level'], isNull);
  });

  test('无 greater 或最终取整无提升的词条不进入凝炼，机制变化可预览', () {
    final hetu = createHetu(loadPassives());
    expect(
        hetu.invoke('getExpArrayGreaterPreview', positionalArgs: [
          {'id': 'plain', 'level': 1, 'value': 1},
          3,
        ]),
        isNull);
    expect(
        hetu.invoke('getExpArrayGreaterPreview', positionalArgs: [
          {
            'id': 'rounded',
            'increment': 0.001,
            'level': 1,
            'value': 0,
            'greater': true,
          },
          3,
        ]),
        isNull);
    final mechanism = hetu.invoke('getExpArrayGreaterPreview', positionalArgs: [
      {
        'id': 'mechanism',
        'level': 1,
        'greater': {
          'data': {
            'statusParams': {'manaBonus': 1}
          }
        },
      },
      3,
    ]);
    expect(mechanism['isGreater'], true);
    expect(mechanism['level'], GameLogic.maxLevelForRank(3));
  });
}
