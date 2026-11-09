import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:heavenly_tribulation/data/common.dart';
import 'package:heavenly_tribulation/logic/logic.dart';

import 'support/hetu_test_utils.dart';

void main() {
  String loadLevelUpSource() {
    final source = File('scripts/main/binding/player.ht').readAsStringSync();
    final start = source.indexOf('  function levelUp');
    final end = source.indexOf('\n  function rankUp', start);
    return source.substring(start, end);
  }

  test('真实 levelUp 脚本每次升级获得一点，经验不足时不发点数', () {
    final hetu = createTestHetu(relaxedConversions: true);
    bindGameLogicFunctions(hetu);
    hetu.interpreter.bindExternalFunction(
      'expForLevel',
      ({positionalArgs, namedArgs}) =>
          GameLogic.expForLevel(positionalArgs[0]),
      override: true,
    );
    hetu.eval('var hero;');
    hetu.assign('hero', {
      'name': '测试角色',
      'rank': 0,
      'level': 0,
      'skillPoints': 1,
      'exp': GameLogic.expForLevel(0) + 5,
    });
    hetu.eval('''
      $kGameLogicExternalDeclarations
      external function expForLevel(level) -> integer
      final Constants = {
        passiveSkillPointsPerLevel: $kPassiveSkillPointsPerLevel,
      }
      final engine = {
        info: function(message) {},
        warning: function(message) {},
        locale: function(id, {interpolations}) { return id },
      }
      ${loadLevelUpSource()}
      levelUp(incurIncident: false)
    ''');

    dynamic hero = hetu.fetch('hero');
    expect(hero['level'], 1);
    expect(hero['skillPoints'], 2);
    expect(hero['exp'], 5);
    expect(hero['expForLevel'], GameLogic.expForLevel(1));

    hetu.eval('levelUp(incurIncident: false)');
    hero = hetu.fetch('hero');
    expect(hero['level'], 1);
    expect(hero['skillPoints'], 2);
    expect(hero['exp'], 5);
  });
}
