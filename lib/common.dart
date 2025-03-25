import 'package:samsara/extensions.dart';
// import 'package:samsara/cardgame.dart';

const kGameVersion = '0.0.1';

const kGameSaveFileExtension = '.tdqjgame';
const kUniverseSaveFilePostfix = '_universe';
const kHistorySaveFilePostfix = '_history';

const kValueTypeInt = 'int';
const kValueTypeFloat = 'float';
const kValueTypePercentage = 'percentage';

const kAutoTimeFlowInterval = 500;

enum SceneStates {
  mainmenu,
  world,
  locationSite,
  battle,
  cultivation,
  cardLibrary,
}

const kPersonalities = [
  'idealistic',
  'orderly',
  'goodwill',
  'extrovert',
  'frank',
  'merciful',
  'helping',
  'empathetic',
  'competitive',
  'reasoning',
  'initiative',
  'optimistic',
  'curious',
  'prudent',
  'deepthinking',
  'organizing',
  'confident',
  'humorous',
  'frugal',
  'generous',
  'satisfied',
];

const kOppositePersonalities = {
  'idealistic': 'realistic',
  'orderly': 'chaotic',
  'goodwill': 'evilminded',
  'extrovert': 'introvert',
  'frank': 'tactful',
  'merciful': 'merciless',
  'helping': 'selfish',
  'empathetic': 'jealous',
  'competitive': 'easygoing',
  'reasoning': 'feeling',
  'initiative': 'reactive',
  'optimistic': 'cynical',
  'curious': 'indifferent',
  'prudent': 'adventurous',
  'deepthinking': 'superficial',
  'organizing': 'relaxing',
  'confident': 'modest',
  'humorous': 'solemn',
  'frugal': 'lavish',
  'generous': 'stingy',
  'satisfied': 'greedy',
};

const kAttributes = [
  'charisma',
  'wisdom',
  'luck',
  'spirituality',
  'dexterity',
  'strength',
  'willpower',
  'perception',
];

const kNonBattleAttributes = [
  'charisma',
  'wisdom',
  'luck',
];

const kBattleAttributes = [
  'spirituality',
  'dexterity',
  'strength',
  'willpower',
  'perception',
];

const kEquipmentMax = 6;
const kLevelPerRank = 10;
const kCultivationRankMax = 8;

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
  'lightning_control',
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

const kRestrictedEquipmentTypes = {
  'weapon',
  'armor',
  'helmet',
  'boots',
  'vehicle',
};

const kCityKinds = [
  'inland',
  'harbor',
  'island',
  'mountain',
];

const kLocationKindInlandCity = 'inland';
const kLocationKindHarborCity = 'harbor';
const kLocationKindIslandCity = 'island';
const kLocationKindMountainCity = 'mountain';

Color getColorFromRarity(String rarity) {
  return switch (rarity) {
    /// 基础
    'basic' => HexColor.fromString('#A3A3A3'),

    /// 凡品
    'common' => HexColor.fromString('#CCCCCC'),

    /// 良品
    'uncommon' => HexColor.fromString('#FFFFFF'),

    /// 上品
    'rare' => HexColor.fromString('#9D9DFF'),

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
    3 => HexColor.fromString('#9D9DFF'),

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

const kOrganizationCategories = {
  'cultivation', // 悟道：修真，功法，战斗
  'immortality', // 长生：宗教，等级，境界
  'chivalry', // 任侠：江湖豪杰
  'entrepreneur', // 权霸：扩张国家领地，发展下属和附庸
  'wealth', // 财富：经营商号，积累钱币和灵石
  'pleasure', // 欢愉：享乐，赌博，情色
};

const kMainCultivationGenres = [
  'swordcraft',
  'spellcraft',
  'bodyforge',
  'avatar',
  'vitality',
];

const kSupportCultivationGenres = [
  'array',
  'scroll',
  'plant',
  'animal',
  'divination',
  'theurgy',
  'psychic',
  'illusion',
  'craft',
  'alchemy',
];

const kLocationCityKinds = [
  'inland',
  'harbor',
  'island',
  'mountain',
];

const kLocationSiteKinds = [
  'cityhall',
  'arena',
  'library',
  'tradinghouse',
  'auctionhouse',
  'mine',
  'timberland',
  'farmland',
  'huntingground',
  'fishery',
  'nursery',
  'zoo',
  'workshop',
  'arraylab',
  'scrolllab',
  'alchemylab',
  'illusionaltar',
  'psychicaltar',
  'divinationaltar',
  'theurgyaltar',
];

const kMaterialMoney = 'money';
const kMaterialShard = 'shard';
const kMaterialFood = 'food';
const kMaterialWater = 'water';
const kMaterialStone = 'stone';
const kMaterialOre = 'ore';
const kMaterialTimber = 'timber';
const kMaterialPaper = 'paper';
const kMaterialHerb = 'herb';
const kMaterialYinQi = 'yinqi';
const kMaterialShaQi = 'shaqi';
const kMaterialYuanQi = 'yuanqi';

const kGenres = {
  'spellcraft',
  'swordcraft',
  'bodyforge',
  'avatar',
  'vitality',
  'array',
  'scroll',
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
  'spirituality': 'spellcraft',
  'dexterity': 'swordcraft',
  'strength': 'bodyforge',
  'willpower': 'vitality',
  'perception': 'avatar',
};

const kGenreToAttribute = {
  'spellcraft': 'spirituality',
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

const kTicksPerDay = 4; //每天的回合数 morning, afternoon, evening, night
const kDaysPerMonth = 30; //每月的天数
const kTicksPerMonth = kDaysPerMonth * kTicksPerDay; //每月的回合数 120
const kDaysPerYear = 360; //每年的月数
const kMonthsPerYear = 12; //每年的月数
const kTicksPerYear = kDaysPerYear * kTicksPerDay; //每年的回合数 1440

const kMoneyToShardRate = 10000;
const kBaseBuyRate = 1.5;
const kBaseSellRate = 0.5;

const kUntradableItemKinds = {
  'money',
  'worker',
};
