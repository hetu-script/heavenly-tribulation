import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:heavenly_tribulation/logic/logic.dart';

import 'support/hetu_test_utils.dart';
import 'package:heavenly_tribulation/data/game.dart';
import 'package:heavenly_tribulation/global.dart';

void main() {
  String loadPassiveSource() {
    final source =
        File('scripts/main/data/character/battle_entity.ht').readAsStringSync();
    return source.substring(source.indexOf('struct PassiveData'));
  }

  String loadGreaterHelper() {
    final source = File('scripts/main/logic/logic.ht').readAsStringSync();
    final start = source.indexOf('function _mergeGreaterMechanismData');
    final end = source.indexOf('const _kMoneyRewardRate', start);
    return source.substring(start, end);
  }

  Hetu createHetu() {
    final hetu = createTestHetu(relaxedConversions: true);
    bindGameLogicFunctions(hetu);
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
          'ephemeralScope': 'standalone',
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
      $kGameLogicExternalDeclarations
      final kItemCategoryPotion = 'potion'
      final kEphemeralScopeBattlePreparation = 'battle_preparation'
      final kEphemeralScopeStandalone = 'standalone'
      final engine = {
        info: function(message) {},
        warning: function(message) {},
      }
      function entityLose(entity, item, {amount = 1}) {
        delete entity.inventory[item.id]
        return true
      }
      ${loadGreaterHelper()}
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
    expect(character['passives']['dexterity']['level'], isNull);
    expect(character['passives']['dexterity']['increment'], isNull);
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
        turnStartExtraDraw: {count: 1},
      }
      final source = _createPassiveSource(affix,
        sourceKey: 'equipment:item-a:0', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 0)
      source.turnStartExtraDraw.count = 2
      characterAddPassiveSource(character, source)
      characterAddPassiveSource(character, source)
    ''');
    final character = hetu.fetch('character');
    final affix = hetu.fetch('affix');
    expect(character['passivesRaw']['turnStartExtraDraw'].length, 1);
    expect(affix['turnStartExtraDraw']['count'], 1);
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
    expect(character['ephemeralPassives']['decreaseTribulationDifficulty'],
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

  test('主词条不吃太古加成，普通与太古额外来源分别贡献', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    hetu.eval('''
      final affix = {
        id: 'dexterity',
        description: 'passive_dexterity_description',
        increment: 0.5,
        greater: true,
      }
      final mainAffix = _createPassiveSource(affix,
        sourceKey: 'equipment:item-a:0', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 0)
      mainAffix.isGreater = true
      mainAffix.level = 10
      final normalAffix = _createPassiveSource(affix,
        sourceKey: 'equipment:item-a:1', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 1)
      normalAffix.level = 10
      final greaterAffix = _createPassiveSource(affix,
        sourceKey: 'equipment:item-a:2', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 2)
      greaterAffix.isGreater = true
      greaterAffix.level = 45
      characterAddPassiveSource(character, mainAffix)
      characterAddPassiveSource(character, normalAffix)
      characterAddPassiveSource(character, greaterAffix)
      characterRecalculatePassives(character)
    ''');
    final character = hetu.fetch('character');
    expect(character['passives']['dexterity']['value'], 44);
  });

  test('alt 只替换生效快照，状态参数按来源累加', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      final affix = {
        id: 'cost_tax_test',
        description: 'passive_cost_tax_test_description',
        deckCostReduction: {color: 'all', amount: -1},
        isGreater: true,
        greater: {alt: {deckCostReduction: {amount: 0}}},
      }
      characterAddPassiveSource(character, _createPassiveSource(affix,
        sourceKey: 'equipment:item-a:1', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 1))
      final manaAffix = {
        id: 'scry_mana',
        description: 'passive_scry_mana_description',
        battleStatus: 'scry_mana',
        statusParams: {manaBonus: 1},
        isGreater: true,
        greater: true,
      }
      characterAddPassiveSource(character, _createPassiveSource(manaAffix,
        sourceKey: 'equipment:item-a:1', sourceType: 'equipment', sourceId: 'item-a', affixIndex: 1))
      characterAddPassiveSource(character, _createPassiveSource(manaAffix,
        sourceKey: 'equipment:item-b:1', sourceType: 'equipment', sourceId: 'item-b', affixIndex: 1))
      characterCalculateStats(character)
    ''');
    final character = hetu.fetch('character');
    final affix = hetu.fetch('affix');
    expect(affix['deckCostReduction']['amount'], -1);
    expect(character['stats']['deckCostReduction'][0]['amount'], 0);
    expect(
        character['stats']['battleStatusParams']['scry_mana']['manaBonus'], 2);
    expect(character['stats']['battleStatus']['scry_mana'], 1);
  });

  test('真实 scry_upgrade 太古配置经聚合和状态默认值合并后升级 2 级', () {
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final affix = Map<String, dynamic>.from(passives['scry_upgrade'] as Map);
    affix['isGreater'] = true;
    final hetu = createHetu();
    hetu.eval('var scryUpgrade;');
    hetu.assign('scryUpgrade', affix);
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    final chosen = hetu.eval('''
      ${File('scripts/main/cardgame/status_script.ht').readAsStringSync()}
      function upgradeCard(card, {inBattle = false}) { card.level += 1 }
      characterAddPassiveSource(character, _createPassiveSource(scryUpgrade,
        sourceKey: 'equipment:mirror:2', sourceType: 'equipment', sourceId: 'mirror', affixIndex: 2))
      characterCalculateStats(character)
      final params = character.stats.battleStatusParams.scry_upgrade
      final effect = {upgradeChosen: 1 + params.upgradeChosen}
      final self = {turnCount: 1}
      final chosen = {level: 0}
      StatusScript.scry_upgrade_self_scry(self, null, effect, {chosen: chosen})
      [params.upgradeChosen, chosen]
    ''');
    expect(chosen[0], 1);
    expect(chosen[1]['level'], 2);
    expect(affix['greater']['data']['statusParams']['upgradeChosen'], 1);
    expect(affix['greater']['data']['upgradeChosen'], isNull);
  });

  test('天机盘主词条通过 statsBonus 固定降低牌库下限并保留混编加费', () {
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final hetu = createHetu();
    hetu.eval('var discMain;');
    hetu.assign('discMain', passives['heavenly_mechanism_disc']);
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    final stats = hetu.eval('''
      characterAddPassiveSource(character, _createPassiveSource(discMain,
        sourceKey: 'equipment:disc:0', sourceType: 'equipment', sourceId: 'disc', affixIndex: 0))
      characterCalculateStats(character)
      character.stats
    ''');
    expect(stats['deckMinSizeReduce'], -2);
    expect(stats['deckCostReduction'][0]['amount'], -1);
    expect(stats['deckCostReduction'][0]['notGenres'], ['spellcraft']);
    expect(
        GameLogic.getDeckMinSizeForRank(3,
            deckMinSizeReduce: stats['deckMinSizeReduce'] as int),
        14);
  });

  test('整体替换仅清除非永久战前配置并保留永久和独立来源', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      characterSetEphemeralPassive(character, 'dexterity', level: 1)
      final permanentAffix = {
        id: 'persistent', description: 'passive_persistent_description',
        increment: 0.5, isPermanent: true,
      }
      characterAddPassiveSource(character, _createPassiveSource(permanentAffix,
        sourceKey: 'potion:permanent:0', sourceType: 'potion', sourceId: 'permanent', affixIndex: 0),
        isEphemeral: true)
      characterSetEphemeralPassive(character, 'decreaseTribulationDifficulty')
      final newAffix = {
        id: 'dexterity', description: 'passive_dexterity_description',
        increment: 0.5, level: 4,
        sourceKey: 'exp_array:batch-a:0', sourceType: 'exp_array',
        sourceId: 'batch-a', affixIndex: 0,
      }
      characterReplaceBattlePreparationPassives(character, [newAffix])
    ''');
    final character = hetu.fetch('character');
    expect(character['ephemeralPassivesRaw']['dexterity'].keys,
        ['exp_array:batch-a:0']);
    expect(character['ephemeralPassives']['dexterity']['value'], 2);
    expect(character['ephemeralPassivesRaw']['persistent'], isNotNull);
    expect(character['ephemeralPassivesRaw']['decreaseTribulationDifficulty'],
        isNotNull);
    expect(
        character['ephemeralPassivesRaw']['decreaseTribulationDifficulty']
            .values
            .first['ephemeralScope'],
        'standalone');
    final summary = hetu.invoke('characterGetBattlePreparationSummary',
        positionalArgs: [character]);
    expect(summary['count'], 1);
    expect(summary['greaterCount'], 0);
  });

  test('仅主词条丹药只精确更新同 ID 战前来源并保留其他配置', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      final otherAffix = {
        id: 'persistent', description: 'passive_persistent_description',
        increment: 0.5, level: 2,
        sourceKey: 'potion:other:0', sourceType: 'potion', sourceId: 'other', affixIndex: 0,
      }
      characterAddPassiveSource(character, _createPassiveSource(otherAffix,
        sourceKey: 'potion:other:0', sourceType: 'potion', sourceId: 'other', affixIndex: 0),
        isEphemeral: true)
      characterSetEphemeralPassive(character, 'decreaseTribulationDifficulty')
      character.life = 50.0
      character.inventory = {}
      final potion = {
        id: 'potion-new', name: '身法丹', category: kItemCategoryPotion,
        affixes: [
          {id: 'dexterity', description: 'passive_dexterity_description', increment: 0.5, level: 4},
        ],
      }
      character.inventory[potion.id] = potion
      characterConsumePotion(character, potion)
    ''');
    final character = hetu.fetch('character');
    expect(character['ephemeralPassivesRaw']['dexterity'].keys,
        ['potion:potion-new:0']);
    expect(character['ephemeralPassives']['dexterity']['value'], 2);
    expect(character['ephemeralPassivesRaw']['persistent'], isNotNull);
    expect(character['ephemeralPassivesRaw']['decreaseTribulationDifficulty'],
        isNotNull);
    expect(character['inventory'], isEmpty);
  });

  test('含额外词条丹药的整体替换不影响独立主效果', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      characterSetEphemeralPassive(character, 'dexterity', level: 1)
      character.inventory = {}
      final potion = {
        id: 'potion-tribulation', name: '渡劫丹', category: kItemCategoryPotion,
        affixes: [
          {id: 'decreaseTribulationDifficulty', description: 'passive_decreaseTribulationDifficulty_description', level: 1},
          {id: 'persistent', description: 'passive_persistent_description', increment: 0.5, level: 2},
        ],
      }
      character.inventory[potion.id] = potion
      characterConsumePotion(character, potion)
    ''');
    final character = hetu.fetch('character');
    expect(character['ephemeralPassivesRaw']['dexterity'], isNull);
    expect(character['ephemeralPassivesRaw']['persistent'].keys,
        ['potion:potion-tribulation:1']);
    expect(
        character['ephemeralPassivesRaw']['decreaseTribulationDifficulty']
            .values
            .first['ephemeralScope'],
        'standalone');
    expect(character['inventory'], isEmpty);
  });

  test('太古丹药经真实服用入口保留完整快照并生效', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      character.life = 50.0
      character.inventory = {}
      final potion = {
        id: 'potion-greater',
        name: '太古丹药',
        category: kItemCategoryPotion,
        affixes: [
          {id: 'heal', value: 20, level: 1},
          {
            id: 'dexterity',
            description: 'passive_dexterity_description',
            increment: 0.5,
            greater: true,
            isGreater: true,
            level: 45,
          },
        ],
      }
      character.inventory[potion.id] = potion
      characterCalculateStats(character)
      characterConsumePotion(character, potion)
    ''');
    final character = hetu.fetch('character');
    expect(character['life'], 70.0);
    expect(character['ephemeralPassives']['dexterity']['value'], 34);
    expect(
        character['ephemeralPassivesRaw']['dexterity']
            ['potion:potion-greater:1']['isGreater'],
        true);
    expect(character['inventory'], isEmpty);
  });

  test('混合普通与太古来源使用最终机制参数生成描述', () {
    engine.loadLocaleDataFromJSON({
      'zh': {
        'languageId': 'zh',
        'passive_handSizeMax_description': '手牌上限 +{0}',
        'passive_scry_upgrade_description': '每回合第一次观星后，选中的牌等级 +{0}',
      }
    });
    GameData.passives.addAll({
      'handSizeMax': {
        'id': 'handSizeMax',
        'description': 'passive_handSizeMax_description',
        'descriptionParams': ['statsBonus.handSizeMax'],
      },
      'scry_upgrade': {
        'id': 'scry_upgrade',
        'description': 'passive_scry_upgrade_description',
        'descriptionParams': ['battleStatus.upgradeChosen'],
      },
    });
    GameData.statusEffects['scry_upgrade'] = {'upgradeChosen': 1};
    try {
      final character = {
        'passives': {
          'handSizeMax': {
            'id': 'handSizeMax',
            'description': 'passive_handSizeMax_greater_description',
            'priority': 2,
            'value': null,
          },
          'scry_upgrade': {
            'id': 'scry_upgrade',
            'description': 'passive_scry_upgrade_greater_description',
            'priority': 1,
            'value': null,
          },
        },
        'passivesRaw': {
          'handSizeMax': {
            'equipment:normal:1': {
              'statsBonus': {'handSizeMax': 1}
            },
            'equipment:greater:1': {
              'statsBonus': {'handSizeMax': 2}
            },
          },
          'scry_upgrade': {
            'equipment:normal:1': {'battleStatus': 'scry_upgrade'},
            'equipment:greater:1': {'battleStatus': 'scry_upgrade'},
          },
        },
        'ephemeralPassives': <String, dynamic>{},
        'ephemeralPassivesRaw': <String, dynamic>{},
        'stats': {
          'battleStatusParams': {
            'scry_upgrade': {'upgradeChosen': 1}
          }
        },
      };
      final description = GameData.getPassivesDescription(character: character);
      expect(description, contains('手牌上限 +3'));
      expect(description, contains('选中的牌等级 +2'));
      expect(description, isNot(contains('greater_description')));

      final greaterAffix = {
        'id': 'handSizeMax',
        'description': 'passive_handSizeMax_description',
        'isGreater': true,
        'greater': true,
        'statsBonus': {'handSizeMax': 2},
      };
      expect(GameData.getPassiveAffixDescription(greaterAffix),
          contains('手牌上限 +2'));
    } finally {
      GameData.passives.remove('handSizeMax');
      GameData.passives.remove('scry_upgrade');
      GameData.statusEffects.remove('scry_upgrade');
    }
  });
}
