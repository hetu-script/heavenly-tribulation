import 'package:samsara/extensions.dart';
// import 'package:samsara/cardgame.dart';

/// Unicode Character "⎯" (U+23AF)
const kSeparateLine = '⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯';

/// Unicode Character "∕" (U+2215)
const kSlash = '∕';

const kGameVersion = '0.0.1';

const kGameSaveFileExtension = '.tdqjgame';
const kUniverseSaveFilePostfix = '_universe';
const kWorldSaveFilePostfix = '_world';
const kHistorySaveFilePostfix = '_history';

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

const kZoneVoid = 'world';
const kZoneLand = 'land';
const kZoneWater = 'water';

const kTerrainKindToNaturalResources = {
  'void': null,
  'city': null,
  'road': null,
  'plain': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'mountain': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'forest': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'snow_plain': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'snow_mountain': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'snow_forest': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'shore': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'shelf': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'lake': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'sea': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
  'river': {
    'grain': 5,
    'meat': 1,
    'water': 0,
    'leather': 1,
    'herb': 1,
    'timber': 2,
    'stone': 1,
    'ore': 1,
    'spirit': 1,
  },
};

const kTileSpriteIndexToZoneCategory = {
  0: kZoneWater,
  1: kZoneLand,
  // 2: kZoneRiver,
};

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

const kPersonalitiesWithoutWorldViews = [
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

const kPersonalities = {
  ...kWorldViews,
  ...kPersonalitiesWithoutWorldViews,
};

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

/// 战斗属性决定了角色战斗流派
const kBattleAttributes = [
  'spirituality',
  'dexterity',
  'strength',
  'willpower',
  'perception',
];

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

const kEquipmentMax = 6;
const kCultivationRankMax = 5;

const kBattleCardKinds = [
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

const kRarities = {
  'common',
  'rare',
  'epic',
  'legendary',
  'mythic',
  'arcane',
};

const kRaritiesToRank = {
  'common': 0,
  'rare': 1,
  'epic': 2,
  'legendary': 3,
  'mythic': 4,
  'arcane': 5,
};

Color getColorFromRarity(String rarity) {
  return switch (rarity) {
    /// 凡品
    'common' => HexColor.fromString('#B4B4B4'),

    /// 良品
    'rare' => HexColor.fromString('#D4FFFF'),

    /// 上品
    'epic' => HexColor.fromString('#9D9DFF'),

    /// 极品
    'legendary' => HexColor.fromString('#693DA8'),

    /// 绝品
    'mythic' => HexColor.fromString('#E7E7AC'),

    /// 神品
    'arcane' => HexColor.fromString('#C65043'),

    /// 其他
    _ => HexColor.fromString('#B4B4B4'),
  };
}

Color getColorFromRank(int rank) {
  return switch (rank) {
    /// 无境界 根据背景，一般是黑或白
    0 => HexColor.fromString('#B4B4B4'),

    /// 凝气 灰
    1 => HexColor.fromString('#D4FFFF'),

    /// 筑基 蓝
    2 => HexColor.fromString('#9D9DFF'),

    /// 结丹 紫
    3 => HexColor.fromString('#693DA8'),

    /// 还婴 金
    4 => HexColor.fromString('#E7E7AC'),

    /// 化神 红
    5 => HexColor.fromString('#C65043'),

    /// 其他
    _ => HexColor.fromString('#B4B4B4'),
  };
}

/// 组织的类型即动机，代表了不同的发展方向
const kOrganizationCategories = [
  'wuwei', // 无为：清净，隐居，不问世事
  'cultivation', // 修真：功法，战斗
  'immortality', // 长生：宗教，等级，境界
  'chivalry', // 任侠：江湖义气，路见不平拔刀相助
  'entrepreneur', // 权霸：扩张国家领地，发展下属和附庸
  'wealth', // 财富：经营商号，积累钱币和灵石
  'pleasure', // 欢愉：享乐，赌博，情色
];

const kCultivationGenres = [
  'swordcraft',
  'spellcraft',
  'bodyforge',
  'avatar',
  'vitality',
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
  'tradinghouse',
  'daostele',
  'exparray',
  'library',
  'arena',
  'militarypost',
  'auctionhouse',
  'hotel',
  'workshop',
  // 'enchantshop',
  'alchemylab',
  // 'tatooshop',
  'runelab',
  // 'arraylab',
  'illusionaltar',
  // 'psychictemple',
  'divinationaltar',
  // 'theurgytemple',
  'farmland',
  'fishery',
  'timberland',
  'huntingground',
  'mine',
  'dungeon',
];

const kSiteKindsWorkable = [
  'tradinghouse',
  'daostele',
  'exparray',
  'library',
  'arena',
  'militarypost',
  'auctionhouse',
  'hotel',
  'workshop',
  // 'enchantshop',
  'alchemylab',
  // 'tatooshop',
  'runelab',
  // 'arraylab',
  'illusionaltar',
  // 'psychictemple',
  'divinationaltar',
  // 'theurgytemple',
  'farmland',
  'fishery',
  'timberland',
  'huntingground',
  'mine',
];

const kSiteKindsBuildable = {
  'daostele',
  'exparray',
  'library',
  'arena',
  'militarypost',
  'auctionhouse',
  'hotel',
  'workshop',
  // 'enchantshop',
  'alchemylab',
  // 'tatooshop',
  'runelab',
  // 'arraylab',
  'illusionaltar',
  // 'psychictemple',
  'divinationaltar',
  // 'theurgytemple',
};

const kSiteKindsBuildableOnWorldMap = {
  'farmland', // 只会在平原地形且在城市周围出现
  'fishery', // 只会在大陆架、湖泊或者据点周围一格的水域地形出现
  'timberland', // 只会在森林地形出现
  'huntingground', // 只会在山地或森林地形出现
  'mine', // 只会在山地地形出现
};

const kOrganizationCategoryToSiteKind = {
  'wuwei': 'daostele',
  'cultivation': 'library',
  'immortality': 'exparray',
  'chivalry': 'arena',
  'entrepreneur': 'militarypost',
  'wealth': 'auctionhouse',
  'pleasure': 'hotel',
};

const kOrganizationGenreToSiteKinds = {
  'swordcraft': [
    'workshop',
    // 'enchantshop',
  ],
  'bodyforge': [
    'alchemylab',
    // 'tatooshop',
  ],
  'spellcraft': [
    'runelab',
    // 'arraylab',
  ],
  'avatar': [
    'divinationaltar',
    // 'theurgytemple',
  ],
  'vitality': [
    'illusionaltar',
    // 'psychictemple',
  ],
};

/// 非门派成员打工时的可用月份
final kSiteWorkableMounths = {
  'tradinghouse': [10, 11, 12, 1, 2, 3],
  'daostele': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  'exparray': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  'library': [3, 4, 5, 6, 7, 8, 9, 10, 11],
  'arena': [1, 2, 3, 4, 5, 6, 7, 8, 9],
  'militarypost': [3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 1],
  'auctionhouse': [9, 10, 11, 12, 1, 2, 3, 4],
  'hotel': [3, 4, 5, 6, 7, 8, 9, 10, 11],
  'farmland': [3, 4, 5, 6, 7, 8, 9, 10, 11],
  'fishery': [3, 4, 5, 6, 7, 8, 9, 10, 11],
  'timberland': [3, 4, 5, 6, 7, 8, 9, 10, 11],
  'huntingground': [9, 10, 11, 12, 1, 2, 3, 4],
  'mine': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  'workshop': [10, 11, 12, 1, 2, 3, 4, 5, 6],
  'enchantshop': [3, 4, 5, 6, 7, 8, 9, 10, 11],
  'alchemylab': [10, 11, 12, 1, 2, 3, 4, 5, 6],
  'tatooshop': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  'runelab': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  'arraylab': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  'illusionaltar': [10, 11, 12, 1, 2, 3, 4, 5, 6],
  'psychictemple': [10, 11, 12, 1, 2, 3, 4, 5, 6],
  'divinationaltar': [8, 9, 10, 11, 12, 1],
  'theurgytemple': [9, 10, 11, 12, 1, 2],
};

/// 工作时的基础工资
final kSiteWorkableBaseSalaries = {
  'tradinghouse': 7,
  'daostele': 8,
  'exparray': 12,
  'library': 21,
  'arena': 24,
  'militarypost': 50,
  'auctionhouse': 28,
  'hotel': 56,
  'farmland': 14,
  'fishery': 44,
  'timberland': 23,
  'huntingground': 32,
  'mine': 64,
  'workshop': 46,
  'enchantshop': 22,
  'alchemylab': 20,
  'tatooshop': 25,
  'runelab': 27,
  'arraylab': 48,
  'illusionaltar': 26,
  'psychictemple': 27,
  'divinationaltar': 29,
  'theurgytemple': 60,
};

/// 工作时消耗的体力值
final kSiteWorkableBaseStaminaCost = {
  'tradinghouse': 1,
  'daostele': 1,
  'exparray': 1,
  'library': 2,
  'arena': 2,
  'militarypost': 4,
  'auctionhouse': 2,
  'hotel': 4,
  'farmland': 2,
  'fishery': 5,
  'timberland': 3,
  'huntingground': 4,
  'mine': 7,
  'workshop': 4,
  'enchantshop': 2,
  'alchemylab': 2,
  'tatooshop': 2,
  'runelab': 2,
  'arraylab': 4,
  'illusionaltar': 2,
  'psychictemple': 2,
  'divinationaltar': 2,
  'theurgytemple': 4,
};

/// 非门派成员使用设施的日租金
/// 以 money 为单位，但可能会被转化为灵石
final kSiteRentMoneyCostByDay = {
  'tradinghouse': null,
  'daostele': 1000,
  'exparray': 1000,
  'library': 1500,
  'arena': null,
  'militarypost': null,
  'auctionhouse': null,
  'hotel': 1000,
  'farmland': 100,
  'fishery': 150,
  'timberland': 50,
  'huntingground': 100,
  'mine': 250,
  'workshop': 1200,
  'enchantshop': 1350,
  'alchemylab': 1000,
  'tatooshop': 1350,
  'runelab': 1800,
  'arraylab': 1800,
  'illusionaltar': 1800,
  'psychictemple': 1200,
  'divinationaltar': 2200,
  'theurgytemple': 2800,
  'dungeon': 5000,
};

const kMaterialMoney = 'money';
const kMaterialShard = 'shard';
const kMaterialWorker = 'worker';

const kMaterialMeat = 'meat';
const kMaterialGrain = 'grain';
const kMaterialWater = 'water';
const kMaterialLeather = 'leather';

const kMaterialHerb = 'herb';
const kMaterialTimber = 'timber';
const kMaterialStone = 'stone';
const kMaterialOre = 'ore';

abstract class AttackType {
  static const unarmed = 'unarmed';
  static const weapon = 'weapon';
  static const spell = 'spell';
  static const curse = 'curse';
}

const List<String> kAttackTypes = [
  AttackType.unarmed,
  AttackType.weapon,
  AttackType.spell,
  AttackType.curse,
];

abstract class DamageType {
  static const physical = 'physical';
  static const chi = 'chi';
  static const elemental = 'elemental';
  static const psychic = 'psychic';
  static const pure = 'pure';
}

const List<String> kDamageTypes = [
  DamageType.physical,
  DamageType.chi,
  DamageType.elemental,
  DamageType.psychic,
  DamageType.pure,
];

const kTicksPerDay = 4; //每天的回合数 morning, afternoon, evening, night
const kDaysPerMonth = 30; //每月的天数
const kTicksPerMonth = kDaysPerMonth * kTicksPerDay; //每月的回合数 120
const kDaysPerYear = 360; //每年的月数
const kMonthsPerYear = 12; //每年的月数
const kTicksPerYear = kDaysPerYear * kTicksPerDay; //每年的回合数 1440

enum ItemType {
  none,
  player,
  npc,
  customer,
  merchant,
}

const kBaseBuyRate = 1.0;
const kBaseSellRate = 0.75;

const kMinSellRate = 0.1;
const kMinBuyRate = 0.1;

const kPriceFavorRate = 0.1;
const kPriceFavorIncrement = 0.05;

const kMaterialKinds = [
  'money',
  'shard',
  'worker',
  'grain',
  'meat',
  'water',
  'leather',
  'herb',
  'timber',
  'stone',
  'ore',
];

const kNonCurrencyMaterialKinds = [
  'worker',
  'grain',
  'meat',
  'water',
  'leather',
  'herb',
  'timber',
  'stone',
  'ore',
];

const kNaturalResourceKinds = [
  'grain',
  'meat',
  'water',
  'leather',
  'herb',
  'timber',
  'stone',
  'ore',
  'spirit',
];

final kMaterialBasePriceByKind = {
  'shard': 1000,
  'worker': 20,
  'grain': 20,
  'meat': 40,
  'water': 10,
  'herb': 40,
  'leather': 80,
  'timber': 80,
  'stone': 160,
  'ore': 320,
};

/// 物品的基础价格
final kItemBasePriceByCategory = {
  'cardpack': 1000,
  'craftmaterial': 2000,
  'dungeon_ticket': 4000,
  'scroll_paper': 150,
  'identify_scroll': 500,
  'weapon': 100,
  'shield': 50,
  'armor': 50,
  'gloves': 50,
  'helmet': 50,
  'boots': 50,
  'ship': 500,
  'aircraft': 500,
  'jewelry': 100,
  'talisman': 250,
  'potion': 50,
};

const kUntradableItemKinds = {
  'money',
  'worker',
};

const kMaxAffixCount = 4;

const kAttributeAnyLevel = 10;
const kBaseResistMax = 75;

const kBaseMoveCostOnHill = 1.0;
const kBaseMoveCostOnWater = 2.0;

const kTerrainKindsLand = ['plain', 'shore', 'forest', 'city'];
const kTerrainKindsWater = ['sea', 'river', 'lake', 'shelf'];
const kTerrainKindsMountain = ['mountain'];

/// 战斗结束后生命恢复比例计算时，
/// 战斗中使用的卡牌使用过的数量的阈值
const kBaseAfterBattleHPRestoreRate = 0.25;
const kBattleCardsCount = 16;

const kCharacterYearlyUpdateMonth = 3;
const kLocationYearlyUpdateMonth = 6;
const kOrganizationYearlyUpdateMonth = 9;

const kBattleCardPriceRate = 0.135;
const kCraftScrollCostRate = 0.06;

const kCardCraftOperations = [
  'addAffix',
  'replaceAffix',
  'rerollAffix',
  'upgradeRank',
  'dismantle',
];

const kCardOperations = [
  'addAffix',
  'rerollAffix',
  'replaceAffix',
  'upgradeRank',
  'dismantle',
  'craftScroll',
];

const kTimeOfDay = {
  1: 'morning',
  2: 'afternoon',
  3: 'evening',
  4: 'midnight',
};

/// 预定义的天赋树节点路线，用于NPC提升等级时自动分配
const kCultivationStyles = {
  'dexterity': {'standard'},
  'spirituality': {'standard'},
  'willpower': {'standard'},
  'perception': {'standard'},
  'strength': {'standard'},
};

/// 不同流派的境界节点路径
const kCultivationRankPaths = {
  'swordcraft': [
    'track_5_0',
    'track_6_0',
    'track_7_0',
    'track_8_0',
    'track_9_0',
    'track_10_0',
    'track_11_0',
    'track_12_0',
  ],
  'spellcraft': [
    'track_5_4',
    'track_6_8',
    'track_7_4',
    'track_8_8',
    'track_9_4',
    'track_10_8',
    'track_11_4',
    'track_12_8',
  ],
  'vitality': [
    'track_5_8',
    'track_6_16',
    'track_7_8',
    'track_8_16',
    'track_9_8',
    'track_10_16',
    'track_11_8',
    'track_12_16',
  ],
  'avatar': [
    'track_5_12',
    'track_6_24',
    'track_7_12',
    'track_8_24',
    'track_9_12',
    'track_10_24',
    'track_11_12',
    'track_12_24',
  ],
  'bodyforge': [
    'track_5_16',
    'track_6_32',
    'track_7_16',
    'track_8_32',
    'track_9_16',
    'track_10_32',
    'track_11_16',
    'track_12_32',
  ],
};

const kCultivationStylePaths = {
  'swordcraft': {
    'standard': [
      'track_0_0',
      'track_1_0',
      'track_2_0',
      'track_3_0',
      'track_4_0', // 以上5个节点是境界前置必须
      'track_2_9',
      'track_3_9',
      'track_4_18', // 身法+20
      'track_2_1',
      'track_3_1',
      'track_4_2', // 灵力+20
      'track_4_19',
      'track_5_19',
      'track_6_38',
      'track_6_37', // 武器攻
      'track_4_3',
      'track_5_3',
      'track_6_6',
      'track_6_5', // 法攻
      'track_4_1',
      'track_5_1',
      'track_6_2',
      'track_6_3', // 速度
      'track_4_17',
      'track_5_17',
      'track_6_34',
      'track_6_35', // 物抗
      'track_5_18',
      'track_6_36',
      'track_7_18',
      'track_8_36', // 身法+20
      'track_9_18', // 战斗开始时剑气
      'track_5_2',
      'track_6_4',
      'track_7_2',
      'track_8_4', // 灵力+20
      'track_9_2', // 战斗开始时灵气
      'track_8_5',
      'track_8_6',
      'track_8_7',
      'track_6_7', // 灵气不足时自动恢复
      'track_8_3',
      'track_8_2',
      'track_8_1',
      'track_6_1', // 灵气视作剑气
      'track_8_37',
      'track_8_38',
      'track_8_39',
      'track_6_39', // 无需装备剑
      'track_8_35',
      'track_8_34',
      'track_8_33',
      'track_6_33', // 剑气溢出的debuff变双方
    ],
  },
  'spellcraft': {
    'standard': [
      'track_0_1',
      'track_1_1',
      'track_2_2',
      'track_3_2',
      'track_4_4', // 以上5个节点是境界前置必须
      'track_2_1',
      'track_3_1',
      'track_4_2', // 灵力+20
      'track_2_3',
      'track_3_3',
      'track_4_6', // 神识+20
      'track_4_3',
      'track_5_3',
      'track_6_6',
      'track_6_5', // 法攻
      'track_4_1',
      'track_5_1',
      'track_6_2',
      'track_6_3', // 速度
      'track_4_5',
      'track_5_5',
      'track_6_10',
      'track_6_11', // 元素抗
      'track_4_7',
      'track_5_7',
      'track_6_14',
      'track_6_13', // 真气抗
      'track_5_2',
      'track_6_4',
      'track_7_2',
      'track_8_4', // 灵力+20
      'track_9_2', // 战斗开始时灵气
      'track_5_6',
      'track_6_12',
      'track_7_6',
      'track_8_12', // 神识+20
      'track_9_6', // 战斗开始时元气
      'track_8_5',
      'track_8_6',
      'track_8_7',
      'track_6_7', // 灵气不足时自动恢复
      'track_8_11',
      'track_8_10',
      'track_8_9',
      'track_6_9', // 灵气溢出转化为元气
      'track_8_13',
      'track_8_14',
      'track_8_15',
      'track_6_15', // ---
      'track_8_3',
      'track_8_2',
      'track_8_1',
      'track_6_1', // 灵气视作剑气
    ],
  },
  'vitality': {
    'standard': [
      'track_0_2',
      'track_1_2',
      'track_2_4',
      'track_3_4',
      'track_4_8', // 以上5个节点是境界前置必须
      'track_2_5',
      'track_3_5',
      'track_4_10', // 念力+20
      'track_2_3',
      'track_3_3',
      'track_4_6', // 神识+20
      'track_4_11',
      'track_5_11',
      'track_6_22',
      'track_6_21', // 咒攻
      'track_4_5',
      'track_5_5',
      'track_6_10',
      'track_6_11', // 元素抗
      'track_4_7',
      'track_5_7',
      'track_6_14',
      'track_6_13', // 真气抗
      'track_4_9',
      'track_5_9',
      'track_6_18',
      'track_6_19', // 精神抗
      'track_5_10',
      'track_6_20',
      'track_7_10',
      'track_8_20', // 念力+20
      'track_9_10', // 战斗开始时辟邪
      'track_5_6',
      'track_6_12',
      'track_7_6',
      'track_8_12', // 神识+20
      'track_9_6', // 战斗开始时元气
      'track_8_19',
      'track_8_18',
      'track_8_17',
      'track_6_17', // 咒术造成纯粹伤害
      'track_8_11',
      'track_8_10',
      'track_8_9',
      'track_6_9', // 灵气溢出转化为元气
      'track_8_13',
      'track_8_14',
      'track_8_15',
      'track_6_15', // ---
      'track_8_21',
      'track_8_22',
      'track_8_23',
      'track_6_23', // ---
    ],
  },
  'avatar': {
    'standard': [
      'track_0_3',
      'track_1_3',
      'track_2_6',
      'track_3_6',
      'track_4_12', // 以上5个节点是境界前置必须
      'track_2_5',
      'track_3_5',
      'track_4_10', // 念力+20
      'track_2_7',
      'track_3_7',
      'track_4_14', // 体魄+20
      'track_4_15',
      'track_5_15',
      'track_6_30',
      'track_6_29', // 徒手攻
      'track_4_11',
      'track_5_11',
      'track_6_22',
      'track_6_21', // 咒攻
      'track_4_13',
      'track_5_13',
      'track_6_26',
      'track_6_27', // 闪避
      'track_4_9',
      'track_5_9',
      'track_6_18',
      'track_6_19', // 精神抗
      'track_5_10',
      'track_6_20',
      'track_7_10',
      'track_8_20', // 念力+20
      'track_9_10', // 战斗开始时辟邪
      'track_5_14',
      'track_6_28',
      'track_7_14',
      'track_8_28', // 体魄+20
      'track_9_14', // 战斗开始时怒气
      'track_8_19',
      'track_8_18',
      'track_8_17',
      'track_6_17', // 咒术造成纯粹伤害
      'track_8_29',
      'track_8_30',
      'track_8_31',
      'track_6_31', // 怒气不足时消耗生命
      'track_8_21',
      'track_8_22',
      'track_8_23',
      'track_6_23', // ---
      'track_8_27',
      'track_8_26',
      'track_8_25',
      'track_6_25', // ---
    ],
  },
  'bodyforge': {
    'standard': [
      'track_0_4',
      'track_1_4',
      'track_2_8',
      'track_3_8',
      'track_4_16', // 以上5个节点是境界前置必须
      'track_2_7',
      'track_3_7',
      'track_4_14', // 体魄+20
      'track_2_9',
      'track_3_9',
      'track_4_18', // 身法+20
      'track_4_15',
      'track_5_15',
      'track_6_30',
      'track_6_29', // 徒手攻
      'track_4_19',
      'track_5_19',
      'track_6_38',
      'track_6_37', // 武器攻
      'track_4_13',
      'track_5_13',
      'track_6_26',
      'track_6_27', // 闪避
      'track_4_17',
      'track_5_17',
      'track_6_34',
      'track_6_35', // 物抗
      'track_5_14',
      'track_6_28',
      'track_7_14',
      'track_8_28', // 体魄+20
      'track_9_14', // 战斗开始时怒气
      'track_5_18',
      'track_6_36',
      'track_7_18',
      'track_8_36', // 身法+20
      'track_9_18', // 战斗开始时剑气
      'track_8_29',
      'track_8_30',
      'track_8_31',
      'track_6_31', // 怒气不足时消耗生命
      'track_8_35',
      'track_8_34',
      'track_8_33',
      'track_6_33', // 剑气溢出的debuff变双方
      'track_8_37',
      'track_8_38',
      'track_8_39',
      'track_6_39', // 无需装备剑
      'track_8_27',
      'track_8_26',
      'track_8_25',
      'track_6_25', // ---
    ],
  },
};

const kItemEquipmentCategories = {
  'weapon',
  'shield',
  'armor',
  'gloves',
  'helmet',
  'boots',
  'ship',
  // 'aircraft',
  'jewelry',
  'talisman',
};

const kItemEquipmentKinds = {
  // 武器
  'sword',
  'sabre',
  'spear',
  'staff',
  'bow',
  'dart',
  // 防具
  'shield',
  'armor',
  'gloves',
  'helmet',
  // 载具
  'boots',
  'ship',
  //   'aircraft',
  // 首饰
  'ring',
  'amulet',
  // 'belt',
  // 法宝
  'pearl',
};

const kItemModificationOperations = {
  'rerollAffix',
  'extract',
};

const kItemCategoryCardpack = 'cardpack';
const kItemCategoryIdentifyScroll = 'identify_scroll';
const kItemCategoryScroll = 'scroll';
const kItemCategoryScrollPaper = 'scroll_paper';
const kItemCategoryDungeonTicket = 'dungeon_ticket';
const kItemCategoryExppack = 'exp_pack';
const kItemCategoryMaterialPack = 'material_pack';
const kItemCategoryStatusSpirit = 'status_spirit';
const kItemCategoryEquipmentAffix = 'equipment_affix';
const kItemCategoryPotion = 'potion';
const kItemCategoryCraftMaterial = 'craftmaterial';

/// 职位等级
/// 职位等级对应于境界，角色境界若小于职位等级，则无法任命该职位
const kTitleToOrganizationRank = {
  'taskman': 0,
  'executor': 1,
  'manager': 2,
  'mayor': 3,
  'governor': 4,
  'head': 5,
  'guard': 2,
  'minister': 3,
  'chancellor': 4,
  "guestChancellor": 4,
};

/// 职位对应的贡献度需求
const kTitleToContribution = {
  'taskman': 0,
  'executor': 90,
  'manager': 300,
  'mayor': 800,
  'governor': 1200,
  'head': 5000,
  'guard': 300,
  'minister': 800,
  'chancellor': 1200,
  "guestChancellor": 1200,
};

const kDiplomacyScoreAllyThreshold = 50;
const kDiplomacyScoreEnemyThreshold = -50;

const kDiplomacyDefaultScore = 0;

const kConsumableCategoryKinds = [
  kItemCategoryCardpack,
  kItemCategoryPotion,
];

const kEquipmentCategoryKinds = {
  // 所有武器的category都是weapon
  'weapon': [
    'sword',
    'sabre',
    'spear',
    'staff',
    'bow',
    'dart',
  ],
  'shield': [
    'shield',
  ],
  'armor': [
    'armor',
  ],
  'gloves': [
    'gloves',
  ],
  'helmet': [
    'helmet',
  ],
  'boots': [
    'boots',
  ],
  'ship': [
    'ship',
  ],
  // aircraft: [
  //   'aircraft',
  // ],
  // 所有首饰的 category 都是 jewelry
  'jewelry': [
    'ring',
    'amulet',
    // 'belt',
  ],
  'talisman': [
    'pearl',
  ],
};

final kEquipmentKinds = [
  ...kEquipmentCategoryKinds['weapon']!,
  ...kEquipmentCategoryKinds['shield']!,
  ...kEquipmentCategoryKinds['armor']!,
  ...kEquipmentCategoryKinds['gloves']!,
  ...kEquipmentCategoryKinds['helmet']!,
  ...kEquipmentCategoryKinds['boots']!,
  ...kEquipmentCategoryKinds['ship']!,
  // ...kEquipmentCategoryKinds['aircraft']!,
  ...kEquipmentCategoryKinds['jewelry']!,
  ...kEquipmentCategoryKinds['talisman']!, // 非以上四种的物品都算作法器 talisman
];
