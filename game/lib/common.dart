import 'package:samsara/extensions.dart';
// import 'package:samsara/cardgame.dart';

const kGameVersion = '0.0.1';

const kGameSaveFileExtension = '.tdqjgame';
const kUniverseSaveFilePostfix = '_universe';
const kHistorySaveFilePostfix = '_history';

const kValueTypeInt = 'int';
const kValueTypeFloat = 'float';
const kValueTypePercentage = 'percentage';

enum SceneStates {
  mainmenu,
  world,
  locationSite,
  battle,
  cultivation,
  cardLibrary,
}

const kEquipmentMax = 6;
const kLevelPerRank = 10;
const kRankMax = 8;

const kCardKinds = [
  'punch',
  // 'kick',
  'wrestling',
  'dianxue',
  'sabre',
  // 'spear',
  'sword',
  'staff',
  // 'bow',
  'dart',
  'flying_sword',
  'qinggong',
  'xinfa',
  'windbend',
  'firebend',
  'lightning',
  // 'waterbend',
  // 'earthbend',
  // 'wood_control',
  // 'scripture',
  // 'poison',
  // 'curse',
  // 'music',
];

const kWeaponKinds = [
  // 'sabre',
  'sword',
  // 'spear',
  // 'staff',
  // 'dart',
];

const kWearingKinds = [
  'armor',
  'boots',
  'amulet',
  'vehicle',
];

const kOtherTalismanKinds = [
  'buff',
  'ongoing',
  'consume',
];

const kCityKinds = [
  'inland',
  'harbor',
  'island',
  'mountain',
];

const kCityKindInland = 'inland';
const kCityKindHarbor = 'harbor';
const kCityKindIsland = 'island';
const kCityKindMountain = 'mountain';

Color getColorFromRarity(String rarity) {
  return switch (rarity) {
    /// 基础
    'basic' => HexColor.fromString('#A3A3A3'),

    /// 凡品
    'common' => HexColor.fromString('#CCCCCC'),

    /// 良品
    'uncommon' => HexColor.fromString('#FFFFFF'),

    /// 上品
    'rare' => HexColor.fromString('#00A6A9'),

    /// 极品
    'epic' => HexColor.fromString('#804DC8'),

    /// 神品
    'legendary' => HexColor.fromString('#C5C660'),

    /// 秘宝
    'unique' => HexColor.fromString('#62CC39'),

    /// 古宝
    'mythic' => HexColor.fromString('#F28234'),

    /// 灵宝
    'arcane' => HexColor.fromString('#C65043'),

    /// 其他
    _ => HexColor.fromString('#A3A3A3'),
  };
}

Color getColorFromRank(int rank) {
  return switch (rank) {
    /// 未修炼 黑
    0 => HexColor.fromString('#A3A3A3'),

    /// 凝气 灰
    1 => HexColor.fromString('#CCCCCC'),

    /// 筑基 白
    2 => HexColor.fromString('#FFFFFF'),

    /// 结丹 蓝
    3 => HexColor.fromString('#00A6A9'),

    /// 还婴 紫
    4 => HexColor.fromString('#804DC8'),

    /// 化神 橙
    5 => HexColor.fromString('#C5C660'),

    /// 炼虚 金
    6 => HexColor.fromString('#62CC39'),

    /// 合体 暗金
    7 => HexColor.fromString('#F28234'),

    /// 大乘 红
    _ => HexColor.fromString('#C65043'),
  };
}

const kMajorAttributes = [
  'spirituality',
  'dexterity',
  'strength',
  'willpower',
  'perception',
];

const kOrganizationCategories = {
  'cultivation',
  'gang',
  'religion',
  'business',
  'nation',
};

const kMainCultivationGenres = [
  'swordcraft',
  'daoism',
  'bodyforge',
  'avatar',
  'vitality',
];

const kSupportCultivationGenres = [
  'array',
  'rune',
  'plant',
  'animal',
  'divination',
  'theurgy',
  'psychic',
  'illusion',
  'craft',
  'alchemy',
];

const kConstructableSiteCategories = {
  'library',
  'arena',
  'tradinghouse',
  'auctionhouse',
  'mine',
  'timberland',
  'farmland',
  'huntground',
  'canal',
  'fishmarket',
  'arraylab',
  'runehouse',
  'alchemylab',
  'workshop',
  'nursery',
  'zoo',
  'illusionhouse',
  'psychichouse',
  'divinationhouse',
  'theurgyhouse',
};

const kMaterialMoney = 'money';
const kMaterialJade = 'jade';
const kMaterialFood = 'food';
const kMaterialWater = 'water';
const kMaterialStone = 'stone';
const kMaterialOre = 'ore';
const kMaterialPlank = 'plank';
const kMaterialPaper = 'paper';
const kMaterialHerb = 'herb';
const kMaterialYinQi = 'yinqi';
const kMaterialShaQi = 'shaqi';
const kMaterialYuanQi = 'yuanqi';

const kGenres = {
  'daoism',
  'swordcraft',
  'bodyforge',
  'avatar',
  'vitality',
  'array',
  'rune',
  'alchemy',
  'craft',
  'animal',
  'plant',
  'psychic',
  'illusion',
  'theurgy',
  'divination',
};

const kAttributeToGenre = {
  'spirituality': 'daoism',
  'dexterity': 'swordcraft',
  'strength': 'bodyforge',
  'willpower': 'vitality',
  'perception': 'avatar',
};

const kGenreToAttribute = {
  'daoism': 'spirituality',
  'swordcraft': 'dexterity',
  'bodyforge': 'strength',
  'vitality': 'willpower',
  'avatar': 'perception',
};

abstract class AttackType {
  static const unarmed = 'unarmed';
  static const weapon = 'weapon';
  static const spell = 'spell';
  static const curse = 'curse';
  static const poison = 'poison';
}

const Set<String> kAttackTypes = {
  AttackType.unarmed,
  AttackType.weapon,
  AttackType.spell,
  AttackType.curse,
  AttackType.poison,
};

abstract class DamageType {
  static const physical = 'physical';
  static const chi = 'chi';
  static const elemental = 'elemental';
  static const spiritual = 'spiritual';
  static const pure = 'pure';
}

const Set<String> kDamageTypes = {
  DamageType.physical,
  DamageType.chi,
  DamageType.elemental,
  DamageType.spiritual,
  DamageType.pure,
};
