import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:json5/json5.dart';
import 'package:heavenly_tribulation/logic/logic.dart';

void main() {
  test('额外词条与太古数量按境界增长', () {
    expect(
      [for (var rank = 0; rank <= 5; rank++) GameLogic.getMinMaxExtraAffixCount(rank)],
      [
        {'minExtra': 0, 'maxExtra': 1, 'minGreater': 0, 'maxGreater': 0},
        {'minExtra': 0, 'maxExtra': 2, 'minGreater': 0, 'maxGreater': 0},
        {'minExtra': 0, 'maxExtra': 3, 'minGreater': 0, 'maxGreater': 0},
        {'minExtra': 0, 'maxExtra': 3, 'minGreater': 0, 'maxGreater': 1},
        {'minExtra': 0, 'maxExtra': 3, 'minGreater': 0, 'maxGreater': 2},
        {'minExtra': 0, 'maxExtra': 3, 'minGreater': 0, 'maxGreater': 3},
      ],
    );
  });

  test('太古数值按显式配置转换且普通公式不变', () {
    const valueData = {'base': 10, 'increment': 2};
    expect(GameLogic.calculateCardAffixValue(valueData), 10);
    expect(
      GameLogic.calculateCardAffixValue(valueData,
          greater: {'mode': 'multiply', 'factor': 1.5}),
      15,
    );
    expect(
      GameLogic.calculateCardAffixValue(valueData,
          greater: {'mode': 'add', 'amount': 1}),
      11,
    );
    expect(
      GameLogic.calculateCardAffixValue(valueData,
          greater: {'mode': 'set', 'amount': 30}),
      30,
    );

    final passive = <String, dynamic>{'increment': 0.5};
    expect(
      GameLogic.calculatePassiveAffixContribution(passive, level: 1),
      0.5,
    );
    expect(
      GameLogic.calculatePassiveAffixContribution(passive,
          level: 1, isGreater: true),
      0.5,
    );
    passive['greater'] = {
      'values': [
        {'mode': 'multiply', 'factor': 1.5}
      ]
    };
    expect(
      GameLogic.calculatePassiveAffixContribution(passive,
          level: 1, isGreater: true),
      0.75,
    );
    passive['greater'] = true;
    expect(
      GameLogic.calculatePassiveAffixContribution(passive,
          level: 1, isGreater: true),
      0.75,
    );
  });

  test('牌库下限使用独立绝对最小值', () {
    expect(GameLogic.getDeckMinSizeForRank(0), 10);
    expect(GameLogic.getDeckMinSizeForRank(5), 20);
    expect(GameLogic.getDeckMinSizeForRank(0, deckMinSizeReduce: -20), 5);
    expect(GameLogic.getDeckMinSizeForRank(5, deckMinSizeReduce: -30), 5);
  });

  test('太古机制配置深拷贝合并且重复解析幂等', () {
    final source = File('scripts/main/logic/logic.ht').readAsStringSync();
    final start = source.indexOf('function _mergeGreaterMechanismData');
    final end = source.indexOf('const _kMoneyRewardRate', start);
    final hetu = Hetu()..init();
    final result = hetu.eval('''
      ${source.substring(start, end)}
      final original = {
        isGreater: true,
        description: 'normal',
        scryOptions: {othersCostChange: 1, upgradeChosen: 1},
        greater: {
          description: 'greater',
          data: {scryOptions: {upgradeChosen: 1, scryBonus: 1}},
          alt: {scryOptions: {othersCostChange: 0}},
        },
      }
      final resolved = resolveGreaterAffix(original)
      final repeated = resolveGreaterAffix(resolved)
      [
        resolved.scryOptions.othersCostChange,
        resolved.scryOptions.upgradeChosen,
        resolved.scryOptions.scryBonus,
        resolved.description,
        repeated.scryOptions.upgradeChosen,
        original.scryOptions.othersCostChange,
        original.scryOptions.upgradeChosen,
        original.scryOptions.scryBonus,
      ]
    ''');
    expect(result, [0, 2, 1, 'greater', 2, 1, 1, null]);
  });

  Hetu createCardHetu() {
    Map<String, dynamic> loadData(String path) =>
        Map<String, dynamic>.from(json5Decode(File(path).readAsStringSync()) as Map);
    final cards = loadData('assets/data/cards.json5');
    final affixes = loadData('assets/data/card_affixes.json5');
    final hetu = Hetu(
      config: HetuConfig(
        allowImplicitNullToZeroConversion: true,
        allowImplicitEmptyValueToFalseConversion: true,
      ),
    )..init();
    hetu.interpreter.bindExternalFunction(
      'calculateCostValue',
      ({positionalArgs, namedArgs}) =>
          GameLogic.calculateCostValue(positionalArgs[0], positionalArgs[1]),
      override: true,
    );
    hetu.interpreter.bindExternalFunction(
      'calculateCardAffixValue',
      ({positionalArgs, namedArgs}) => GameLogic.calculateCardAffixValue(
        positionalArgs.first,
        level: namedArgs['level'] ?? 0,
        rank: namedArgs['rank'] ?? 0,
        greater: namedArgs['greater'],
      ),
      override: true,
    );
    hetu.interpreter.bindExternalFunction(
      'getMinMaxExtraAffixCount',
      ({positionalArgs, namedArgs}) =>
          GameLogic.getMinMaxExtraAffixCount(positionalArgs.first),
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
    hetu.eval('var game;');
    hetu.assign('game', {
      'battleCards': cards,
      'battleCardAffixes': affixes,
    });
    hetu.eval('''
      external function calculateCostValue(valueData, rank) -> integer
      external function calculateCardAffixValue(valueData, {level = 0, rank = 0, greater}) -> integer
      external function getMinMaxExtraAffixCount(rank) -> Map
      external function minLevelForRank(rank) -> integer
      external function maxLevelForRank(rank) -> integer
      final kEntityTypeBattleCard = 'battle_card'
      final kEntityTypeItem = 'item'
      final kCultivationRankMax = 5
      final Constants = {
        genreColoredCost: {spellcraft: 'spell'},
        colorlessCostColorId: 'life',
        maxNormalExtraAffixCount: 3,
        greaterAffixGenerationChance: 0.05,
        greaterAffixCraftChance: 0.05,
        greaterAffixRankUpChance: 0.25,
        rankUpExtraAffixChance: 0.25,
        defaultGreaterAffixFactor: 1.5,
        uniqueCardChance: 0,
        rankToRarity: ['common', 'rare', 'epic', 'legendary', 'mythic', 'arcane'],
        materialBasePrice: {},
      }
      final engine = {
        locale: function(id, {interpolations}) { return id },
        warning: function(message) {},
        error: function(message) {},
        info: function(message) {},
      }
      final random = {
        nextInt: function(max) { return max - 1 },
        nextDouble: function() { return 0.0 },
        nextIterable: function(values) { return values.first },
        nearInt: function(value) { return value },
      }
      final crypto = {
        randomUID: function({withTime}) { return 'test-card-uid' },
      }
      function getRandomLevel(min, max) { return min }
      function generateSkillName({kind}) { return 'test-card' }
      ${File('scripts/main/cardgame/card.ht').readAsStringSync()}
    ''');
    return hetu;
  }

  test('普通卡真实构造与打造遵守槽位、太古上限和破境保留', () {
    final hetu = createCardHetu();
    dynamic card = hetu.invoke('BattleCard', namedArgs: {
      'affixId': 'fireball',
      'rank': 2,
    });
    expect(card['affixes'], hasLength(4));
    expect(card['affixes'].where((affix) => affix['isGreater'] == true), isEmpty);

    final originalIds = card['affixes'].map((affix) => affix['id']).toList();
    hetu.invoke('upgradeRank', positionalArgs: [card, 3]);
    expect(card['rank'], 3);
    expect(card['affixes'].map((affix) => affix['id']).toList(), originalIds);
    final greater = card['affixes'].singleWhere((affix) => affix['isGreater'] == true);
    expect(greater['isFreezed'], true);
    expect(greater['rank'], 3);
    expect(greater['level'], GameLogic.maxLevelForRank(3));

    final affixCount = card['affixes'].length;
    final result = hetu.invoke('addAffix', positionalArgs: [card, 3]);
    expect(result, isNull);
    expect(card['affixes'], hasLength(affixCount));
    expect(card['affixes'].where((affix) => affix['isGreater'] == true), hasLength(1));

    hetu.invoke('rerollAffix', positionalArgs: [card, 3]);
    expect(card['affixes'], hasLength(affixCount));
    expect(card['affixes'].where((affix) => affix['isGreater'] == true), hasLength(1));
  });

  test('混元只有纯机制可变词条时仍执行太古判定', () {
    final hetu = createCardHetu();
    final result = hetu.eval('''
      final card = BattleCard(affixId: 'fireball', rank: 3)
      card.affixes = [card.affixes.first]
      final attune = Object.create(game.battleCardAffixes.attune)
      card.affixes.add(attune)
      final warning = rerollAffix(card, 3)
      [warning, attune.valueData, attune.isGreater, attune.isFreezed]
    ''');
    expect(result, [null, null, true, true]);
  });

  test('rank 0 普通卡构造不产生太古', () {
    final hetu = createCardHetu();
    final card = hetu.invoke('BattleCard', namedArgs: {
      'affixId': 'blank_default',
      'rank': 0,
    });
    expect(card['affixes'].where((affix) => affix['isGreater'] == true), isEmpty);
  });

  test('普通卡直接生成只在结丹后产生太古并使用满级强化值', () {
    final hetu = createCardHetu();
    final card = hetu.invoke('BattleCard', namedArgs: {
      'affixId': 'fireball',
      'rank': 3,
    });
    expect(card['affixes'], hasLength(4));
    final greater = card['affixes'].singleWhere((affix) => affix['isGreater'] == true);
    final valueData = greater['valueData'][0];
    final expected = GameLogic.calculateCardAffixValue(
      valueData,
      level: GameLogic.maxLevelForRank(3),
      rank: 3,
      greater: greater['greater'] == true
          ? {'mode': 'multiply', 'factor': 1.5}
          : greater['greater']['values'][0],
    );
    expect(greater['level'], GameLogic.maxLevelForRank(3));
    expect(greater['value'][0], expected);
    expect(card['affixes'][0]['isGreater'], isNot(true));
  });

  test('七张悟道绝世卡均为三条固定额外词条且化神全部太古', () {
    final hetu = createCardHetu();
    const ids = [
      'spellcraft_scry_draw',
      'spellcraft_ailments_by_used_elements',
      'spellcraft_element_amplify',
      'spellcraft_ailments_to_mana',
      'spellcraft_handcards_to_mana',
      'spellcraft_draw_cards_reduce_cost',
      'spellcraft_ultimate_spell',
    ];
    for (final id in ids) {
      final card = hetu.invoke('BattleCard', namedArgs: {
        'affixId': id,
        'rank': 5,
      });
      expect(card['affixes'], hasLength(4), reason: id);
      expect(card['affixes'][0]['isGreater'], isNot(true), reason: id);
      expect(card['affixes'].skip(1).every((affix) => affix['isGreater'] == true),
          isTrue,
          reason: id);
    }
  });

  test('天机术逐境破境与直接高境界生成的固定成长一致', () {
    final hetu = createCardHetu();
    final card = hetu.invoke('BattleCard', namedArgs: {
      'affixId': 'spellcraft_scry_draw',
      'rank': 1,
    });
    final expectedIds = [
      'spellcraft_scry_draw_affix_1',
      'spellcraft_scry_draw_affix_2',
      'spellcraft_scry_draw_affix_5',
    ];
    for (var rank = 1; rank <= 5; rank++) {
      expect(card['affixes'].skip(1).map((affix) => affix['id']).toList(),
          expectedIds.take(rank + 1 > 3 ? 3 : rank + 1));
      expect(card['affixes'].skip(1).where((affix) => affix['isGreater'] == true),
          hasLength(rank < 3 ? 0 : rank - 2));
      if (rank < 5) hetu.invoke('upgradeRank', positionalArgs: [card, rank + 1]);
    }
  });
}
