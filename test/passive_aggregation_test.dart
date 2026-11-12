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
    hetu.eval('var game; var Constants; var hero;');
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
        'weaponAttack': {
          'id': 'weaponAttack',
          'description': 'passive_weapon_attack_description',
          'increment': 0.5,
        },
      },
    });
    hetu.assign('Constants', <String, dynamic>{
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
      final kEntityTypeBattleEntity = 'battle_entity'
      final kEntityTypeCharacter = 'character'
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
      function equipmentSlotCount(rank) { return 8 }
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
        inventory: {},
        equipments: {},
      }
      hero = character
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

  test('武器攻击力不同来源按同一 weaponAttack ID 聚合', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    hetu.eval('''
      characterAddPassiveSource(character, _createPassiveSource(game.passives.weaponAttack,
        level: 20, sourceKey: 'equipment:sword:0', sourceType: 'equipment',
        sourceId: 'sword', affixIndex: 0))
      characterAddPassiveSource(character, _createPassiveSource(game.passives.weaponAttack,
        level: 4, sourceKey: 'equipment:other:1', sourceType: 'equipment',
        sourceId: 'other', affixIndex: 1))
      characterCalculateStats(character)
    ''');
    final character = hetu.fetch('character');
    expect(character['passives']['weaponAttack']['value'], 12);
    expect(character['passives']['weaponAttack']['sourceCount'], 2);
    expect(character['stats']['weaponAttack'], 12);
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

  test('首张减费规则按来源聚合且重复重算幂等', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      final affix = {
        id: 'key_branch_spellcraft_discount',
        description: 'passive_key_branch_spellcraft_discount_description',
        firstCardCostReduction: {
          color: 'spell', amount: 1, genres: ['spellcraft'],
        },
      }
      for (final sourceId in ['tree-a', 'tree-b']) {
        characterAddPassiveSource(character, _createPassiveSource(affix,
          sourceKey: 'passive_tree:' + sourceId,
          sourceType: 'passive_tree', sourceId: sourceId))
      }
      characterCalculateStats(character)
      characterCalculateStats(character)
    ''');
    final character = hetu.fetch('character');
    final rules = character['stats']['firstCardCostReduction'];
    expect(rules.length, 2);
    expect(rules[0]['amount'], 1);
    expect(rules[1]['genres'], ['spellcraft']);
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

  test('真实 scry_upgrade 太古配置在普通来源基础上升级 2 级', () {
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
      final effect = {upgradeChosen: params.upgradeChosen}
      final self = {turnCount: 1}
      final chosen = {level: 0}
      StatusScript.scry_upgrade_self_scry(self, null, effect, {chosen: chosen})
      [params.upgradeChosen, chosen]
    ''');
    expect(chosen[0], 2);
    expect(chosen[1]['level'], 2);
    expect(affix['greater']['data']['statusParams']['upgradeChosen'], 1);
    expect(affix['greater']['data']['upgradeChosen'], isNull);
  });

  test('多个同名 scry_upgrade 来源忽略等级并简单相加', () {
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final hetu = createHetu();
    hetu.eval('var scryUpgrade;');
    hetu.assign('scryUpgrade', passives['scry_upgrade']);
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    final chosen = hetu.eval('''
      ${File('scripts/main/cardgame/status_script.ht').readAsStringSync()}
      function upgradeCard(card, {inBattle = false}) { card.level += 1 }
      characterAddPassiveSource(character, _createPassiveSource(scryUpgrade,
        level: 1, sourceKey: 'equipment:mirror:2',
        sourceType: 'equipment', sourceId: 'mirror'))
      characterAddPassiveSource(character, _createPassiveSource(scryUpgrade,
        level: 50, sourceKey: 'passive_tree:side:scry_upgrade',
        sourceType: 'passive_tree', sourceId: 'side'))
      characterCalculateStats(character)
      final effect = {
        upgradeChosen: character.stats.battleStatusParams.scry_upgrade.upgradeChosen,
      }
      final self = {turnCount: 1}
      final chosen = {level: 0}
      StatusScript.scry_upgrade_self_scry(self, null, effect, {chosen: chosen})
      chosen
    ''');
    expect(chosen['level'], 2);
  });

  test('观星无极按普通、太古与混合来源结算，每回合只触发一次', () {
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final statuses = Map<String, dynamic>.from(
        loadJson5File('assets/data/status_effect.json5'));

    dynamic run(String mode) {
      final hetu = createHetu();
      hetu.eval(
          'var scryAllDamage; var scryAllDamageGreater; var statusPrototype; var mode;');
      hetu.assign('scryAllDamage', passives['scry_all_damage']);
      final greater =
          Map<String, dynamic>.from(passives['scry_all_damage'] as Map);
      greater['isGreater'] = true;
      hetu.assign('scryAllDamageGreater', greater);
      hetu.assign('statusPrototype', statuses['scry_all_damage']);
      hetu.assign('mode', mode);
      initializeCharacter(hetu);
      addNeutralStats(hetu);
      return hetu.eval('''
        ${File('scripts/main/cardgame/status_script.ht').readAsStringSync()}
        if (mode == 'normal' || mode == 'mixed') {
          characterAddPassiveSource(character, _createPassiveSource(scryAllDamage,
            sourceKey: 'equipment:normal:1', sourceType: 'equipment', sourceId: 'normal'))
        }
        if (mode == 'greater' || mode == 'mixed') {
          characterAddPassiveSource(character, _createPassiveSource(scryAllDamageGreater,
            sourceKey: 'equipment:greater:1', sourceType: 'equipment', sourceId: 'greater'))
        }
        characterCalculateStats(character)
        final modifier = character.stats.battleStatusParams?['scry_all_damage']?['statusAmount'] ?? 0
        final effect = {
          buffId: statusPrototype.buffId,
          statusAmount: statusPrototype.statusAmount + modifier,
        }
        final self = {
          turnCount: 1,
          gains: [],
          addStatusEffect: function(id, {amount}) {
            this.gains.add([id, amount])
          },
        }
        StatusScript.scry_all_damage_self_scry(self, null, effect, {})
        StatusScript.scry_all_damage_self_scry(self, null, effect, {})
        self.turnCount = 2
        StatusScript.scry_all_damage_self_scry(self, null, effect, {})
        {
          modifier: modifier,
          gains: self.gains,
          statusCount: character.stats.battleStatus.scry_all_damage,
        }
      ''', namedArgs: {'mode': mode});
    }

    final normal = run('normal');
    expect(normal['modifier'], 1);
    expect(normal['gains'], [
      ['buff_all_damage', 1],
      ['buff_all_damage', 1],
    ]);
    expect(normal['statusCount'], 1);

    final greater = run('greater');
    expect(greater['modifier'], 2);
    expect(greater['gains'], [
      ['buff_all_damage', 2],
      ['buff_all_damage', 2],
    ]);

    final mixed = run('mixed');
    expect(mixed['modifier'], 3);
    expect(mixed['gains'], [
      ['buff_all_damage', 3],
      ['buff_all_damage', 3],
    ]);
    expect(mixed['statusCount'], 1);
  });

  test('观星无极使用聚合后的状态参数生成描述', () {
    engine.loadLocaleDataFromJSON({
      'zh': {
        'languageId': 'zh',
        'passive_scry_all_damage_description': '每回合第一次观星后，获得 {0} 层无极之气',
      }
    });
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final statuses = Map<String, dynamic>.from(
        loadJson5File('assets/data/status_effect.json5'));
    GameData.passives['scry_all_damage'] = passives['scry_all_damage'];
    GameData.statusEffects['scry_all_damage'] = statuses['scry_all_damage'];
    try {
      final description = GameData.getPassivesDescription(character: {
        'passives': {
          'scry_all_damage': {
            'id': 'scry_all_damage',
            'description': 'passive_scry_all_damage_description',
            'priority': 1,
            'value': null,
          },
        },
        'passivesRaw': {
          'scry_all_damage': {
            'equipment:normal:1': {'battleStatus': 'scry_all_damage'},
            'equipment:greater:1': {'battleStatus': 'scry_all_damage'},
          },
        },
        'ephemeralPassives': <String, dynamic>{},
        'ephemeralPassivesRaw': <String, dynamic>{},
        'stats': {
          'battleStatusParams': {
            'scry_all_damage': {'statusAmount': 2}
          }
        },
      });
      expect(description, contains('获得 2 层无极之气'));
    } finally {
      GameData.passives.remove('scry_all_damage');
      GameData.statusEffects.remove('scry_all_damage');
    }
  });

  test('驭灵分别施加异常，天人合一只在跨回合达标后产灵一次', () {
    final statuses = Map<String, dynamic>.from(
        loadJson5File('assets/data/status_effect.json5'));
    final hetu = createHetu();
    hetu.eval('var channelingEffect; var unityEffect;');
    hetu.assign('channelingEffect', {
      ...?statuses['spellcraft_side_5'],
      'statusAmount': 1,
    });
    hetu.assign('unityEffect', {
      ...?statuses['spellcraft_side_6'],
      'resourceAmount': 2,
    });
    final result = hetu.eval('''
      ${File('scripts/main/cardgame/status_script.ht').readAsStringSync()}
      final random = {
        nextIterable: function(values) { return values.first },
      }
      Constants.elementAilments = {element_fire: 'ailment_fire'}
      final self = {
        turnFlags: {},
        gains: [],
        addStatusEffect: function(id, {amount, source}) {
          this.gains.add([id, amount])
        },
      }
      final opponent = {
        gains: [],
        addStatusEffect: function(id, {amount, source}) {
          this.gains.add([id, amount])
        },
      }
      StatusScript.elemental_channeling_self_turn_start(
        self, opponent, channelingEffect, {})

      self.turnFlags.usedElements = {element_fire: 1, element_water: 1}
      StatusScript.unity_with_heaven_self_turn_end(self, opponent, unityEffect, {})
      StatusScript.unity_with_heaven_self_produce_resources(
        self, opponent, unityEffect, {})
      final belowThreshold = self.gains.length

      self.turnFlags.usedElements = {
        element_fire: 1, element_water: 1, element_wind: 1,
      }
      StatusScript.unity_with_heaven_self_turn_end(self, opponent, unityEffect, {})
      StatusScript.unity_with_heaven_self_produce_resources(
        self, opponent, unityEffect, {})
      StatusScript.unity_with_heaven_self_produce_resources(
        self, opponent, unityEffect, {})
      [self.gains, opponent.gains, belowThreshold, unityEffect.lastTurnElementCount]
    ''');
    expect(result[0][0], ['ailment_fire', 1]);
    expect(result[1][0], ['ailment_fire', 1]);
    expect(result[2], 1);
    expect(result[0][1], ['energy_positive_spell', 2]);
    expect(result[0].length, 2);
    expect(result[3], 0);
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
    GameData.statusEffects['scry_upgrade'] = {'upgradeChosen': 0};
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
            'scry_upgrade': {'upgradeChosen': 2}
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

  test('回合开始观星是布尔开关，多来源不累加观星数量', () {
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final affix = passives['key_branch_scry'];
    expect(affix['turnStartScry'], true);

    final hetu = createHetu();
    hetu.eval('var scrySwitch;');
    hetu.assign('scrySwitch', affix);
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    hetu.eval('''
      characterAddPassiveSource(character, _createPassiveSource(scrySwitch,
        sourceKey: 'passive_tree:test-a:key_branch_scry',
        sourceType: 'passive_tree', sourceId: 'test-a'))
      characterAddPassiveSource(character, _createPassiveSource(scrySwitch,
        sourceKey: 'passive_tree:test-b:key_branch_scry',
        sourceType: 'passive_tree', sourceId: 'test-b'))
      characterCalculateStats(character)
    ''');
    expect(hetu.fetch('character')['stats']['turnStartScry'], true);

    hetu.eval('''
      characterRemovePassiveSource(character, 'key_branch_scry',
        'passive_tree:test-a:key_branch_scry')
      characterCalculateStats(character)
    ''');
    expect(hetu.fetch('character')['stats']['turnStartScry'], true);

    hetu.eval('''
      characterRemovePassiveSource(character, 'key_branch_scry',
        'passive_tree:test-b:key_branch_scry')
      characterCalculateStats(character)
    ''');
    expect(hetu.fetch('character')['stats']['turnStartScry'], false);
  });

  test('装备随常驻属性失效和恢复，NPC 始终有效且来源不重复', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    final result = hetu.eval('''
      final item = {
        id: 'item-a',
        kind: 'sword',
        equippedPosition: 0,
        attributes: {dexterity: 10},
        affixes: [
          {
            id: 'dexterity',
            description: 'passive_dexterity_description',
            increment: 0.5,
            level: 10,
          },
          {
            id: 'turnStartExtraDraw',
            description: 'passive_turnStartExtraDraw_description',
            turnStartExtraDraw: {count: 1},
          },
        ],
      }
      character.inventory[item.id] = item
      character.equipments = {'0': item.id}
      _addEquipmentPassiveSources(character, item)
      characterCalculateStats(character)
      final invalid = {
        isInvalid: item.isInvalid,
        attribute: character.stats.dexterity,
        passive: character.passives.dexterity?.value,
        rawCount: character.passivesRaw.dexterity.length,
        extraDraw: character.stats.turnStartExtraDraw,
      }

      character.dexterity = 10
      characterCalculateStats(character)
      final restored = {
        isInvalid: item.isInvalid,
        attribute: character.stats.dexterity,
        passive: character.passives.dexterity.value,
        rawCount: character.passivesRaw.dexterity.length,
        extraDraw: character.stats.turnStartExtraDraw.count,
      }

      hero = {}
      character.dexterity = 0
      characterCalculateStats(character)
      final npc = {
        isInvalid: item.isInvalid,
        attribute: character.stats.dexterity,
        passive: character.passives.dexterity.value,
        rawCount: character.passivesRaw.dexterity.length,
        extraDraw: character.stats.turnStartExtraDraw.count,
      }
      [invalid, restored, npc]
    ''');
    final expected = [
      {
        'isInvalid': true,
        'attribute': 0,
        'passive': null,
        'rawCount': 1,
        'extraDraw': null,
      },
      {
        'isInvalid': false,
        'attribute': 15,
        'passive': 5,
        'rawCount': 1,
        'extraDraw': 1,
      },
      {
        'isInvalid': false,
        'attribute': 5,
        'passive': 5,
        'rawCount': 1,
        'extraDraw': 1,
      },
    ];
    for (var i = 0; i < expected.length; ++i) {
      for (final entry in expected[i].entries) {
        expect(result[i][entry.key], entry.value, reason: '$i.${entry.key}');
      }
    }
  });

  test('玩家装备入口拒绝属性不达标物品，NPC 直接装备', () {
    final hetu = createHetu();
    initializeCharacter(hetu);
    final result = hetu.eval('''
      character.entityType = 'character'
      character.name = '测试角色'
      final item = {
        id: 'requirement-item',
        entityType: 'item',
        name: '测试装备',
        isEquippable: true,
        attributes: {dexterity: 10},
        affixes: [],
      }
      final playerResult = characterEquip(character, item)
      final playerSlot = character.equipments['0']
      hero = {}
      character.inventory[item.id] = item
      final npcResult = characterEquip(character, item)
      [playerResult, playerSlot, npcResult, character.equipments['0'], item.isInvalid]
    ''');
    expect(result, [false, null, true, 'requirement-item', false]);
  });

  test('固定资源被动按来源叠加且聚灵旗使用独立数值参数', () {
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final hetu = createHetu();
    hetu.eval('var manaAffix; var bannerAffix;');
    hetu.assign('manaAffix', passives['turn_start_gain_mana']);
    hetu.assign('bannerAffix', passives['spirit_gathering_banner']);
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    final result = hetu.eval('''
      characterAddPassiveSource(character, _createPassiveSource(manaAffix,
        sourceKey: 'passive_tree:entry:mana', sourceType: 'passive_tree', sourceId: 'entry'))
      characterAddPassiveSource(character, _createPassiveSource(manaAffix,
        sourceKey: 'equipment:amulet:3', sourceType: 'equipment', sourceId: 'amulet', affixIndex: 3))
      characterAddPassiveSource(character, _createPassiveSource(bannerAffix,
        sourceKey: 'equipment:banner:0', sourceType: 'equipment', sourceId: 'banner', affixIndex: 0))
      characterCalculateStats(character)
      character.stats.battleStatusParams.turn_start_gain_mana.resourceAmount
    ''');
    expect(result, 5);
  });

  test('等级缩放资源与固定参数聚合到同一状态', () {
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final hetu = createHetu();
    hetu.eval(
        'var manaAffix; var spellAffix; var karmaAffix; var ultimateAffix; var bannerAffix;');
    hetu.assign('manaAffix', passives['turn_start_gain_mana']);
    hetu.assign('spellAffix', passives['turn_start_gain_mana_affix']);
    hetu.assign('karmaAffix', passives['turn_start_gain_karma_affix']);
    hetu.assign('ultimateAffix', passives['turn_start_gain_ultimate_affix']);
    hetu.assign('bannerAffix', passives['spirit_gathering_banner']);
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    final result = hetu.eval('''
      characterAddPassiveSource(character, _createPassiveSource(manaAffix,
        sourceKey: 'passive_tree:entry:mana', sourceType: 'passive_tree', sourceId: 'entry'))
      characterAddPassiveSource(character, _createPassiveSource(spellAffix,
        level: 20, sourceKey: 'passive_tree:scaling:spell', sourceType: 'passive_tree', sourceId: 'scaling'))
      characterAddPassiveSource(character, _createPassiveSource(bannerAffix,
        sourceKey: 'equipment:banner:0', sourceType: 'equipment', sourceId: 'banner', affixIndex: 0))
      characterAddPassiveSource(character, _createPassiveSource(karmaAffix,
        level: 20, sourceKey: 'passive_tree:scaling:karma', sourceType: 'passive_tree', sourceId: 'scaling'))
      characterAddPassiveSource(character, _createPassiveSource(ultimateAffix,
        level: 50, sourceKey: 'passive_tree:scaling:ultimate', sourceType: 'passive_tree', sourceId: 'scaling'))
      characterCalculateStats(character)
      character.stats.battleStatusParams
    ''');
    expect(result['turn_start_gain_mana']['resourceAmount'], 5);
    expect(result['turn_start_gain_karma']['resourceAmount'], 1);
    expect(result['turn_start_gain_ultimate']['resourceAmount'], 1);
  });

  test('可叠加被动均按普通来源累计数值且排除项不叠加', () {
    final passives =
        Map<String, dynamic>.from(loadJson5File('assets/data/passives.json5'));
    final hetu = createHetu();
    hetu.eval('var passiveData;');
    hetu.assign('passiveData', passives);
    initializeCharacter(hetu);
    addNeutralStats(hetu);
    final result = hetu.eval(r'''
      game = {passives: passiveData}
      final cases = [
        ['scry_shield', 'scry_shield', 'shieldAmount'],
        ['scry_mana', 'scry_mana', 'manaBonus'],
        ['scry_all_damage', 'scry_all_damage', 'statusAmount'],
        ['key_branch_element_1', 'key_branch_element_1', 'upgradeCount'],
        ['key_branch_element_2', 'key_branch_element_2', 'resourceAmount'],
        ['spellcraft_side_5', 'spellcraft_side_5', 'statusAmount'],
        ['spellcraft_side_6', 'spellcraft_side_6', 'resourceAmount'],
        ['key_branch_spellcraft_overflow', 'key_branch_spellcraft_overflow', 'damagePerStack'],
        ['key_branch_spellcraft_rotation', 'key_branch_spellcraft_rotation', 'rotationMultiplier'],
        ['limitless_amulet', 'neutral_card_limitless', 'statusAmount'],
        ['spirit_gathering_banner', 'turn_start_gain_mana', 'resourceAmount'],
      ]
      for (final entry in cases) {
        final passive = passiveData[entry[0]]
        characterAddPassiveSource(character, _createPassiveSource(passive,
          sourceKey: 'passive_tree:${entry[0]}:a', sourceType: 'passive_tree', sourceId: 'a'))
        characterAddPassiveSource(character, _createPassiveSource(passive,
          sourceKey: 'passive_tree:${entry[0]}:b', sourceType: 'passive_tree', sourceId: 'b'))
      }
      characterCalculateStats(character)
      character.stats.battleStatusParams
    ''');
    expect(result['scry_shield']['shieldAmount'], 2);
    expect(result['scry_mana']['manaBonus'], 2);
    expect(result['scry_all_damage']['statusAmount'], 2);
    expect(result['key_branch_element_1']['upgradeCount'], 2);
    expect(result['key_branch_element_2']['resourceAmount'], 2);
    expect(result['spellcraft_side_5']['statusAmount'], 2);
    expect(result['spellcraft_side_6']['resourceAmount'], 4);
    expect(result['key_branch_spellcraft_overflow']['damagePerStack'], 20);
    expect(result['key_branch_spellcraft_rotation']['rotationMultiplier'], 2);
    expect(result['neutral_card_limitless']['statusAmount'], 2);
    expect(result['turn_start_gain_mana']['resourceAmount'], 6);
    expect(result['mana_threshold_guard'], isNull);
    expect(result['scry_self_ailments'], isNull);
  });
}
