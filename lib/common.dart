import 'package:samsara/extensions.dart';
// import 'package:samsara/cardgame.dart';

const kGameVersion = '0.0.1';

const kGameSaveFileExtension = '.tdqjgame';
const kUniverseSaveFilePostfix = '_universe';
const kHistorySaveFilePostfix = '_history';

abstract class Cursors {
  static const normal = 'normal';
  static const click = 'click';
  static const drag = 'drag';
  static const press = 'press';
}

const kValueTypeInt = 'int';
const kValueTypeFloat = 'float';
const kValueTypePercentage = 'percentage';

const kAutoTimeFlowInterval = 500;

const kSpriteScale = 2.0;

enum SceneStates {
  mainmenu,
  world,
  locationSite,
  battle,
  cultivation,
  cardLibrary,
}

/// 当前版本等级限制为50
const kCurrentVersionCultivationLevelMax = 50;
const kCurrentVersionCultivationRankMax = 3;

const kRaces = [
  'fanzu',
  'yaozu',
  'xianzu',
];

const kWorldViews = [
  // 三观
  'idealistic', // 理想, 现实
  'orderly', // 守序, 混乱
  'goodwill', // 善良, 邪恶
];

const kPersonalities = [
  // 对他人
  'extrovert', // 外向, 内省
  'frank', // 直率, 圆滑
  'merciful', // 仁慈, 冷酷
  'helping', // 助人, 自私
  'empathetic', // 同情, 嫉妒
  'competitive', // 好胜, 嫉妒
  // 对自己
  'organizing', // 自律, 不羁
  'confident', // 自负, 谦逊
  'humorous', // 幽默, 庄重
  'frugal', // 节俭, 奢靡
  'generous', // 慷慨, 小气
  'satisfied', // 知足, 贪婪
  // 对事物
  'reasoning', // 理智, 感性
  'initiative', // 主动, 被动
  'optimistic', // 乐观, 愤世
  'curious', // 好奇, 冷漠
  'prudent', // 谨慎, 冲动
  'deepthinking', // 深沉, 轻浮
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
  'organizing': 'relaxing',
  'confident': 'modest',
  'humorous': 'solemn',
  'frugal': 'lavish',
  'generous': 'stingy',
  'satisfied': 'greedy',
  'reasoning': 'feeling',
  'initiative': 'reactive',
  'optimistic': 'cynical',
  'curious': 'indifferent',
  'prudent': 'adventurous',
  'deepthinking': 'superficial',
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
  'qinna',
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
  'airbend',
  'firebend',
  'lightning_control',
  // 'waterbend',
  // 'earthbend',
  // 'plant_control',
  // 'scripture',
  // 'sigil',
  // 'curse',
  // 'music',
];

const kRestrictedEquipmentTypes = {
  'weapon',
  'shield',
  'armor',
  'gloves',
  'helmet',
  'boots',
  'ship',
  'aircraft',
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
    'basic' => HexColor.fromString('#CCCCCC'),

    /// 凡品
    'common' => HexColor.fromString('#D4FFFF'),

    /// 良品
    'uncommon' => HexColor.fromString('#9D9DFF'),

    /// 上品
    'rare' => HexColor.fromString('#693DA8'),

    /// 极品
    'epic' => HexColor.fromString('#E7E7AC'),

    /// 神品
    'legendary' => HexColor.fromString('#DBDB72'),

    /// 秘宝
    'unique' => HexColor.fromString('#62CC39'),

    /// 古宝
    'mythic' => HexColor.fromString('#C65043'),

    /// 灵宝
    'arcane' => HexColor.fromString('#C65043'),

    /// 其他
    _ => HexColor.fromString('#CCCCCC'),
  };
}

Color getColorFromRank(int rank) {
  return switch (rank) {
    /// 未修炼 黑
    0 => HexColor.fromString('#CCCCCC'),

    /// 凝气 灰
    1 => HexColor.fromString('#D4FFFF'),

    /// 筑基 蓝灰
    2 => HexColor.fromString('#9D9DFF'),

    /// 结丹 蓝
    3 => HexColor.fromString('#693DA8'),

    /// 还婴 紫
    4 => HexColor.fromString('#E7E7AC'),

    /// 化神 金
    5 => HexColor.fromString('#DBDB72'),

    /// 洞虚 橙
    6 => HexColor.fromString('#62CC39'),

    /// 合体 红
    7 => HexColor.fromString('#C65043'),

    /// 大乘 暗红
    8 => HexColor.fromString('#983030'),

    /// 其他
    _ => HexColor.fromString('#CCCCCC'),
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
  'home',
  'headquarters',
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

const kLocationKindManagableSites = [
  'headquarters',
  'cityhall',
  'library',
  'arena',
  'tradinghouse',
  'auctionhouse',
  'workshop',
  'alchemylab',
  'scrolllab',
  'arraylab',
  'illusionaltar',
  'divinationaltar',
  'psychicaltar',
  'theurgyaltar',
  'mine',
  'timberland',
  'farmland',
  'huntingground',
  'fishery',
  'nursery',
  'zoo',
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
}

const Set<String> kAttackTypes = {
  AttackType.unarmed,
  AttackType.weapon,
  AttackType.spell,
  AttackType.curse,
};

abstract class DamageType {
  static const physical = 'physical';
  static const chi = 'chi';
  static const elemental = 'elemental';
  static const psychic = 'psychic';
  static const pure = 'pure';
}

const Set<String> kDamageTypes = {
  DamageType.physical,
  DamageType.chi,
  DamageType.elemental,
  DamageType.psychic,
  DamageType.pure,
};

const kTicksPerDay = 4; //每天的回合数 morning, afternoon, evening, night
const kDaysPerMonth = 30; //每月的天数
const kTicksPerMonth = kDaysPerMonth * kTicksPerDay; //每月的回合数 120
const kDaysPerYear = 360; //每年的月数
const kMonthsPerYear = 12; //每年的月数
const kTicksPerYear = kDaysPerYear * kTicksPerDay; //每年的回合数 1440

const kMoneyToShardRate = 10000;
const kExpToShardRate = 100;

const kBaseBuyRate = 1.5;
const kBaseSellRate = 0.5;

const kUntradableItemKinds = {
  'money',
  'worker',
};

const kAttributeAnyLevel = 6;
const kBaseResistMax = 75;

const kCardCraftOperations = [
  'addAffix',
  'rerollAffix',
  'replaceAffix',
  'upgradeCard',
  'upgradeRank',
  'dismantle',
];

const kBaseMoveCostOnHill = 1.0;
const kBaseMoveCostOnWater = 2.0;

const kPlainTerrains = ['plain', 'forest', 'snow_plain'];
const kWaterTerrains = ['sea', 'river', 'lake', 'seashelf'];
const kMountainTerrains = ['mountain'];
