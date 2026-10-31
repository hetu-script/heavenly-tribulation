import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:heavenly_tribulation/logic/logic.dart';

import 'support/hetu_test_utils.dart';

void main() {
  Hetu createItemHetu() {
    final passives = loadJson5File('assets/data/passives.json5');
    final itemSource =
        File('scripts/main/data/item/item.ht').readAsStringSync();
    final helper = itemSource.substring(
      itemSource.indexOf('function _markPassiveAffixGreater'),
      itemSource.indexOf('function createItemById'),
    );
    final hetu = createTestHetu(relaxedConversions: true);
    bindGameLogicFunctions(hetu);
    hetu.eval('var game;');
    hetu.assign('game', {'passives': passives});
    hetu.eval('''
      $kGameLogicExternalDeclarations
      final kEntityTypeItem = 'item'
      final kCultivationRankMax = 5
      final kRarityCommon = 'common'
      final kItemCategoryPotion = 'potion'
      final kItemCategoryExtractedAffix = 'extracted_affix'
      final kItemTypeEquipment = 'equipment'
      final kItemTypeConsumable = 'consumable'
      final kRarity = {
        common: {rank: 0, color: 0},
        rare: {rank: 1, color: 1},
        epic: {rank: 2, color: 2},
        legendary: {rank: 3, color: 3},
        mythic: {rank: 4, color: 4},
        arcane: {rank: 5, color: 5},
      }
      final Constants = {
        rankToRarity: ['common', 'rare', 'epic', 'legendary', 'mythic', 'arcane'],
        equipmentCategoryKinds: {talisman: ['pearl'], jewelry: ['amulet']},
        equipmentKinds: ['pearl', 'amulet'],
        maxNormalExtraAffixCount: 3,
        greaterAffixGenerationChance: 0.05,
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
        randomUID: function({withTime}) { return 'test-item-uid' },
      }
      function getRandomLevel(min, max) { return min }
      function generateTalismanName({kind}) { return 'test-equipment' }
      function generateConsumableName({category, rarity}) { return 'test-potion' }
      function calculatePrice(item) { item.price = 1 }
      $helper
      ${File('scripts/main/data/item/equipment.ht').readAsStringSync()}
      ${File('scripts/main/data/item/usable.ht').readAsStringSync()}
      ${File('scripts/main/data/item/extracted_affix.ht').readAsStringSync()}
    ''');
    return hetu;
  }

  test('普通装备真实构造：最多三条额外词条，主词条不太古，额外词条满级强化', () {
    final hetu = createItemHetu();
    final item =
        hetu.invoke('Equipment', namedArgs: {'kind': 'pearl', 'rank': 3});
    expect(item['affixes'], hasLength(4));
    expect(item['affixes'][0]['isGreater'], isNot(true));
    final greater =
        item['affixes'].singleWhere((affix) => affix['isGreater'] == true);
    expect(greater['level'], GameLogic.maxLevelForRank(3));
    expect(greater['value'], 34);
    expect(item['affixes'].where((affix) => affix['isGreater'] == true),
        hasLength(1));
  });

  test('普通丹药真实构造保留太古额外词条且主效果不被强化', () {
    final hetu = createItemHetu();
    final item =
        hetu.invoke('Potion', namedArgs: {'mainAffixId': 'heal', 'rank': 3});
    expect(item['affixes'], hasLength(4));
    expect(item['affixes'][0]['isGreater'], isNot(true));
    expect(item['affixes'][0]['value'], 60);
    final greater =
        item['affixes'].singleWhere((affix) => affix['isGreater'] == true);
    expect(greater['level'], GameLogic.maxLevelForRank(3));
    expect(greater['value'], 34);
  });

  test('提取太古词条保留 sourceRank 与独立快照，填槽不重复判定', () {
    final hetu = createItemHetu();
    hetu.eval('''
      final affix = {
        id: 'dexterity',
        description: 'passive_dexterity_description',
        increment: 0.5,
        greater: true,
        isGreater: true,
        level: 45,
      }
      final extracted = ExtractedAffix(affix: affix, rank: 3)
      final item = Equipment(kind: 'pearl', rank: 3, affixes: [extracted.affixes[0]])
    ''');
    final extracted = hetu.fetch('extracted');
    final item = hetu.fetch('item');
    expect(extracted['sourceRank'], 3);
    expect(extracted['affixes'][0]['sourceRank'], 3);
    expect(identical(extracted['affixes'][0], hetu.fetch('affix')), isFalse);
    expect(item['affixes'].where((affix) => affix['isGreater'] == true),
        hasLength(1));
    expect(item['affixes'][1]['level'], GameLogic.maxLevelForRank(3));
    expect(item['affixes'][1]['value'], 34);
  });
}
