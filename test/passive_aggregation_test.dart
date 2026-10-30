import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:heavenly_tribulation/logic/logic.dart';

void main() {
  String loadPassiveSource() {
    final source =
        File('scripts/main/data/character/battle_entity.ht').readAsStringSync();
    return source.substring(source.indexOf('struct PassiveData'));
  }

  Hetu createHetu() {
    final hetu = Hetu()..init();
    hetu.interpreter.bindExternalFunction(
      'calculatePassiveAffixContribution',
      ({positionalArgs, namedArgs}) =>
          GameLogic.calculatePassiveAffixContribution(
        positionalArgs.first,
        level: namedArgs['level'] ?? 0,
      ),
      override: true,
    );
    hetu.interpreter.bindExternalFunction(
      'getTribulationCountForRank',
      ({positionalArgs, namedArgs}) => -1,
      override: true,
    );
    hetu.eval('var game; var Constants;');
    hetu.assign('game', {
      'passives': {
        'dexterity': {
          'id': 'dexterity',
          'description': 'passive_dexterity_description',
          'increment': 0.5,
        },
        'decreaseTribulationDifficulty': {
          'id': 'decreaseTribulationDifficulty',
          'description': 'passive_decreaseTribulationDifficulty_description',
        },
      },
    });
    hetu.assign('Constants', {
      'baseLife': 100,
      'baseLifePerLevel': 10,
      'baseResistMax': 75,
      'baseTurnActionThreshold': 10,
      'baseCritThreshold': 10,
      'baseAilmentThreshold': 10,
      'baseLightRadius': 3,
      'baseMonthlyIdentifyCardsMax': 1,
      'baseMeditateSpeed': 1,
      'basePlainMoveSpeed': 1.0,
      'baseMountainMoveSpeed': 1.0,
      'baseWaterMoveSpeed': 1.0,
      'baseMountainMoveStaminaCost': 1.0,
      'baseWaterMoveStaminaCost': 1.0,
      'battleHandSizeMax': 10,
      'baseCritMultiplier': 150,
      'baseAilmentMultiplier': 100,
      'minChargeThreshold': 5,
      'maxChargeThreshold': 15,
      'minTurnActionThreshold': 5,
      'maxTurnActionThreshold': 15,
    });
    hetu.eval('''
      external function calculatePassiveAffixContribution(valueData, {level = 0}) -> number
      external function getTribulationCountForRank(rank) -> integer
      final kItemCategoryPotion = 'potion'
      final engine = {
        info: function(message) {},
        warning: function(message) {},
      }
      function entityLose(entity, item, {amount = 1}) {
        delete entity.inventory[item.id]
        return true
      }
      ${loadPassiveSource()}
    ''');
    return hetu;
  }

  void initializeCharacter(Hetu hetu) {
    hetu.eval('''
      final character = {
        level: 1,
        rank: 0,
        charisma: 0,
        wisdom: 0,
        luck: 0,
        dexterity: 0,
        spirituality: 0,
        strength: 0,
        perception: 0,
        willpower: 0,
        passivesRaw: {},
        ephemeralPassivesRaw: {},
        passives: {},
        ephemeralPassives: {},
        stats: {},
      }
    ''');
  }

  void addNeutralStats(Hetu hetu) {
    final ids = RegExp(r'character\.passives\.([A-Za-z0-9_]+)')
        .allMatches(loadPassiveSource())
        .map((match) => match.group(1)!)
        .toSet();
    for (final kind in [
      'punch',
      'kick',
      'qinna',
      'dianxue',
      'sword',
      'sabre',
      'spear',
      'staff',
      'bow',
      'dart',
      'firebend',
      'airbend',
      'waterbend',
      'earthbend',
      'lightning_control',
      'sigil',
      'power_word',
    ]) {
      ids.add('increase_damage_$kind');
    }
    final idList = ids.map((id) => "'$id'").join(',');
    hetu.eval('''
      for (final id in [$idList]) {
        characterAddPassiveSource(character, _createPassiveSource({
          id: id,
          description: 'passive_neutral_description',
          increment: 0,
        },
        sourceKey: 'test:neutral:\${id}',
        sourceType: 'script',
        sourceId: 'neutral',
        isMain: false))
        characterAddPassiveSource(character, _createPassiveSource({
          id: id,
          description: 'passive_neutral_description',
          increment: 0,
        },
        sourceKey: 'test:neutral:\${id}',
        sourceType: 'script',
        sourceId: 'neutral',
        isMain: false), isEphemeral: true)
      }
    ''');
  }

  test('同 ID 数值按来源未取整贡献汇总，移除只影响目标来源', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    hetu.eval('''
      final affix = {
        id: 'dexterity',
        description: 'passive_dexterity_description',
        increment: 0.5,
      }
      characterAddPassiveSource(character, _createPassiveSource(affix,
        sourceKey: 'equipment:item-a:0', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 0))
      characterAddPassiveSource(character, _createPassiveSource(affix,
        sourceKey: 'equipment:item-b:0', sourceType: 'equipment', sourceId: 'item-b', affixIndex: 0))
      characterRecalculatePassives(character)
    ''');
    dynamic character = hetu.fetch('character');
    expect(character['passives']['dexterity']['value'], 1);
    expect(character['passives']['dexterity']['level'], 2);
    expect(character['passives']['dexterity']['sourceCount'], 2);

    hetu.eval('''
      characterRemovePassiveSource(character, 'dexterity', 'equipment:item-a:0')
      characterRecalculatePassives(character)
    ''');
    character = hetu.fetch('character');
    expect(character['passivesRaw']['dexterity'].length, 1);
    expect(character['passives']['dexterity']['value'], 1);
    expect(character['passives']['dexterity']['sourceCount'], 1);
  });

  test('sourceKey 天然幂等，快照嵌套机制配置与原型独立', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    hetu.eval('''
      final affix = {
        id: 'turnStartExtraDraw',
        description: 'passive_turnStartExtraDraw_description',
        turnStartExtraDraw: {count: 1, costIncrease: {amount: 1}},
      }
      final source = _createPassiveSource(affix,
        sourceKey: 'equipment:item-a:0', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 0)
      source.turnStartExtraDraw.count = 2
      source.turnStartExtraDraw.costIncrease.amount = 3
      characterAddPassiveSource(character, source)
      characterAddPassiveSource(character, source)
    ''');
    final character = hetu.fetch('character');
    final affix = hetu.fetch('affix');
    expect(character['passivesRaw']['turnStartExtraDraw'].length, 1);
    expect(affix['turnStartExtraDraw']['count'], 1);
    expect(affix['turnStartExtraDraw']['costIncrease']['amount'], 1);
  });

  test('重复机制来源正确聚合，装备刷新和重算保持幂等', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      final affix = {
        id: 'turnStartExtraDraw',
        description: 'passive_turnStartExtraDraw_description',
        statsBonus: {scryBonus: 1},
        turnStartExtraDraw: {
          count: 1,
          costIncrease: {amount: 1, notGenres: ['spellcraft']},
        },
      }
      final itemA = {
        id: 'item-a',
        affixes: [affix],
      }
      final itemB = {
        id: 'item-b',
        affixes: [affix],
      }
      _addEquipmentPassiveSources(character, itemA)
      _addEquipmentPassiveSources(character, itemB)
      characterCalculateStats(character)
    ''');
    dynamic character = hetu.fetch('character');
    expect(character['stats']['turnStartExtraDraw']['count'], 2);
    expect(character['stats']['scryBonus'], 2);

    hetu.eval('characterCalculateStats(character)');
    character = hetu.fetch('character');
    expect(character['stats']['turnStartExtraDraw']['count'], 2);
    expect(character['stats']['scryBonus'], 2);

    hetu.eval('''
      itemA.affixes[0].turnStartExtraDraw.count = 2
      characterRefreshEquipmentPassives(character, itemA)
      characterCalculateStats(character)
    ''');
    character = hetu.fetch('character');
    expect(character['passivesRaw']['turnStartExtraDraw'].length, 2);
    expect(character['stats']['turnStartExtraDraw']['count'], 3);
    expect(character['stats']['scryBonus'], 2);

    hetu.eval('''
      characterRemovePassiveSourcesByOwner(character, 'equipment', 'item-a')
      characterCalculateStats(character)
    ''');
    character = hetu.fetch('character');
    expect(character['stats']['turnStartExtraDraw']['count'], 1);
    expect(character['stats']['scryBonus'], 1);
  });

  test('单条临时效果覆盖，战后只清除非永久来源', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    hetu.eval('''
      characterSetEphemeralPassive(character, 'dexterity', level: 1)
      characterSetEphemeralPassive(character, 'dexterity', level: 2)
      final permanentAffix = {
        id: 'persistent',
        description: 'passive_persistent_description',
        increment: 0.5,
        isPermanent: true,
      }
      characterAddPassiveSource(character, _createPassiveSource(permanentAffix,
        sourceKey: 'potion:item-c:0', sourceType: 'potion', sourceId: 'item-c', affixIndex: 0),
        isEphemeral: true)
      characterRecalculatePassives(character)
    ''');
    dynamic character = hetu.fetch('character');
    expect(character['ephemeralPassivesRaw']['dexterity'].length, 1);
    expect(character['ephemeralPassives']['dexterity']['value'], 1);
    expect(character['ephemeralPassivesRaw']['persistent'].length, 1);

    hetu.eval('''
      characterClearEphemeralPassives(character)
      characterRecalculatePassives(character)
    ''');
    character = hetu.fetch('character');
    expect(character['ephemeralPassivesRaw']['dexterity'], isNull);
    expect(character['ephemeralPassives']['dexterity'], isNull);
    expect(character['ephemeralPassives']['persistent']['value'], 1);
  });

  test('普通 battleStatus 使用聚合值且同脚本不重复绑定', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      final affix = {
        id: 'battle_status_test',
        description: 'passive_battle_status_test_description',
        increment: 0.5,
        battleStatus: 'test_status',
      }
      characterAddPassiveSource(character, _createPassiveSource(affix,
        sourceKey: 'equipment:item-a:0', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 0))
      characterAddPassiveSource(character, _createPassiveSource(affix,
        sourceKey: 'equipment:item-b:0', sourceType: 'equipment', sourceId: 'item-b', affixIndex: 0))
      characterCalculateStats(character)
    ''');
    final character = hetu.fetch('character');
    expect(character['passives']['battle_status_test']['value'], 1);
    expect(character['stats']['battleStatus'].length, 1);
    expect(character['stats']['battleStatus']['test_status'], 1);
  });

  test('治疗丹药通过真实服用入口恢复生命并消耗物品', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      character.life = 50.0
      character.inventory = {}
      final potion = {
        id: 'potion-heal',
        name: '治疗丹药',
        category: kItemCategoryPotion,
        affixes: [
          {id: 'heal', value: 20, level: 1},
        ],
      }
      character.inventory[potion.id] = potion
      characterCalculateStats(character)
      characterConsumePotion(character, potion)
    ''');
    final character = hetu.fetch('character');
    expect(character['life'], 70.0);
    expect(character['inventory'], isEmpty);
  });

  test('渡劫减难写入临时聚合并在消费时精确移除来源', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      characterSetEphemeralPassive(character, 'decreaseTribulationDifficulty')
      characterCalculateStats(character)
    ''');
    dynamic character = hetu.fetch('character');
    expect(
        character['ephemeralPassives']['decreaseTribulationDifficulty'],
        isNotNull);

    hetu.eval('''
      characterRemovePassiveSource(character, 'decreaseTribulationDifficulty',
        'script:ephemeral:decreaseTribulationDifficulty', isEphemeral: true)
      characterCalculateStats(character)
    ''');
    character = hetu.fetch('character');
    expect(character['ephemeralPassivesRaw']['decreaseTribulationDifficulty'],
        isNull);
    expect(character['ephemeralPassives']['decreaseTribulationDifficulty'],
        isNull);
  });
}
