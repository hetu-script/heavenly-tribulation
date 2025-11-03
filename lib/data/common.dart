import 'package:samsara/extensions.dart';
import 'package:fast_noise/fast_noise.dart';
import 'package:samsara/colors.dart';

/// Unicode Character "⎯" (U+23AF)
const kSeparateLine = '⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯';

const kSeparateDot = '・';

/// Unicode Character "∕" (U+2215)
const kSlash = '∕';

const kGameVersion = '0.0.1';

const kGameSaveFileExtension = '.tdqjgame';
const kUniverseSaveFilePostfix = '_universe';
const kWorldSaveFilePostfix = '_world';
const kHistorySaveFilePostfix = '_history';
const kScenesSaveFilePostfix = '_scenes';

const kSpriteScale = 2.0;

const kTimeFlowInterval = 500;

const kTicksPerTime = 24; // 每个时辰的 tick 数，tick 是游戏的最小时间单位
const kTimesPerDay = 4; // 每天的时辰数
const kTicksPerDay = kTimesPerDay * kTicksPerTime; // 每天的 tick 数 96
const kDaysPerMonth = 30; // 每月的天数
const kTicksPerMonth = kDaysPerMonth * kTicksPerDay; // 每月的 tick 数 2880
const kMonthsPerYear = 12; // 每年的月数
const kDaysPerYear = kDaysPerMonth * kMonthsPerYear; // 每年的天数
const kTicksPerYear = kDaysPerYear * kTicksPerDay; // 每年的 tick 数 34560

enum SceneStates {
  mainmenu,
  world,
  locationSite,
  battle,
  cultivation,
  cardLibrary,
}

const kTips = {
  'tips_rank',
  'tips_level',
  'tips_rarity',
  'tips_bounty_quest',
  'tips_sect_quest',
  'tips_sect_policy',
  'tips_master_apprentice',
  'tips_work_and_produce',
  'tips_identify_item',
  'tips_faction_facility',
  'tips_deckbuilding',
  'tips_heavenly_tribulation',
  'tips_hidden_location',
  'tips_sandbox_freedom',
  'tips_terrain_movement',
  'tips_reputation',
};

const kTerrainKindToNaturalResources = {
  'void': null,
  'city': null,
  'road': null,
  'plain': {
    'water': 0,
    'grain': 5,
    'meat': 1,
    'ore': 1,
    'leather': 1,
    'herb': 2,
    'timber': 2,
    'stone': 1,
    'spirit': 1,
  },
  'mountain': {
    'water': 0,
    'grain': 3,
    'meat': 3,
    'ore': 3,
    'leather': 3,
    'herb': 4,
    'timber': 4,
    'stone': 5,
    'spirit': 4,
  },
  'forest': {
    'water': 0,
    'grain': 2,
    'meat': 4,
    'ore': 1,
    'leather': 4,
    'herb': 5,
    'timber': 5,
    'stone': 1,
    'spirit': 3,
  },
  'snow_plain': {
    'water': 3,
    'grain': 1,
    'meat': 1,
    'ore': 1,
    'leather': 1,
    'herb': 1,
    'timber': 1,
    'stone': 1,
    'spirit': 2,
  },
  'snow_mountain': {
    'water': 0,
    'grain': 1,
    'meat': 1,
    'ore': 2,
    'leather': 1,
    'herb': 3,
    'timber': 2,
    'stone': 3,
    'spirit': 5,
  },
  'snow_forest': {
    'water': 0,
    'grain': 1,
    'meat': 2,
    'ore': 1,
    'leather': 2,
    'herb': 4,
    'timber': 3,
    'stone': 1,
    'spirit': 4,
  },
  'shore': {
    'water': 0,
    'grain': 0,
    'meat': 1,
    'ore': 1,
    'leather': 1,
    'herb': 2,
    'timber': 1,
    'stone': 1,
    'spirit': 1,
  },
  'shelf': {
    'water': 4,
    'grain': 0,
    'meat': 2,
    'ore': 0,
    'leather': 0,
    'herb': 0,
    'timber': 0,
    'stone': 0,
    'spirit': 1,
  },
  'lake': {
    'water': 5,
    'grain': 0,
    'meat': 3,
    'ore': 0,
    'leather': 0,
    'herb': 0,
    'timber': 0,
    'stone': 0,
    'spirit': 3,
  },
  'sea': {
    'water': 5,
    'grain': 0,
    'meat': 4,
    'ore': 0,
    'leather': 0,
    'herb': 0,
    'timber': 0,
    'stone': 0,
    'spirit': 1,
  },
  'river': {
    'water': 3,
    'grain': 0,
    'meat': 2,
    'ore': 0,
    'leather': 0,
    'herb': 0,
    'timber': 0,
    'stone': 0,
    'spirit': 2,
  },
};

const kZoneLand = 'land';
const kZoneWater = 'water';

const kTileSpriteIndexToZoneCategory = {
  0: kZoneWater,
  1: kZoneLand,
  // 2: kZoneRiver,
};

const kWorldStyles = {'coast', 'islands', 'inland'};

const kWorldWidthByScale = {
  1: 40, // 40 × 20 = 800
  2: 64, // 64 × 32 = 2048
  3: 96, // 96 × 48 = 4608
  4: 128, // 128 × 64 = 8192
};

const kWorldLabelToScale = {
  'tiny': 1, // 40 × 20     1:
  'medium': 2, // 64 × 322:
  'huge': 3, // 90 × 453:
  'gigantic': 4, // 128 × 644:
};

const kNoiseConfigByWorldStyle = {
  'islands': (0.45, 0.3, 6, NoiseType.perlinFractal, 3),
  'coast': (0.55, 0.33, 3.5, NoiseType.valueFractal, 10),
  'inland': (0.65, 0.42, 10, NoiseType.cubicFractal, 3),
};

/// 城市数量，门派数量和人物数量
const kEntityNumberPerWorldScale = {
  1: (24, 6, 60),
  2: (48, 12, 120),
  3: (96, 24, 240),
  4: (192, 48, 480),
};

const kDifficultyLabels = {
  0: 'easy',
  1: 'normal',
  2: 'challenging',
  3: 'hard',
  4: 'tough',
  5: 'brutal',
};

const kRankToRarity = {
  0: 'common',
  1: 'rare',
  2: 'epic',
  3: 'legendary',
  4: 'mythic',
  5: 'arcane',
};

const kRaces = {
  'fanzu',
  'yaozu',
  'xianzu',
};

const kWorldViews = {
  // 三观
  'idealistic', // 理想, 现实
  'orderly', // 守序, 混乱
  'goodwill', // 善良, 邪恶
};

const kPersonalitiesWithoutWorldViews = {
  // 对他人
  'empathetic', // 仁慈, 冷酷
  'generous', // 慷慨, 自私
  'competitive', // 好胜, 随和
  'frank', // 直率, 圆滑
  // 对自己
  'extrovert', // 外向, 内省
  'organizing', // 自律, 不羁
  'confident', // 自负, 谦逊
  'frugal', // 节俭, 奢靡
  // 对事物
  'reasoning', // 理智, 感性
  'optimistic', // 乐观, 愤世
  'curious', // 好奇, 冷漠
  'satisfied', // 知足, 贪婪
};

const kPersonalities = {
  ...kWorldViews,
  ...kPersonalitiesWithoutWorldViews,
};

const kOppositePersonalities = {
  // 三观
  'idealistic': 'realistic',
  'orderly': 'chaotic',
  'goodwill': 'evilminded',
  // 对他人
  'empathetic': 'merciless',
  'generous': 'stingy',
  'competitive': 'easygoing',
  'frank': 'tactful',
  // 对自己
  'extrovert': 'introvert',
  'organizing': 'relaxing',
  'confident': 'modest',
  'frugal': 'lavish',
  // 对事物
  'reasoning': 'impulsive',
  'optimistic': 'cynical',
  'curious': 'indifferent',
  'satisfied': 'greedy',
};

const kPersonalityThreshold1 = 10;
const kPersonalityThreshold2 = 20;
const kPersonalityThreshold3 = 30;
const kPersonalityThreshold4 = 40;

const kAttributes = {
  'charisma',
  'wisdom',
  'luck',
  'spirituality',
  'dexterity',
  'strength',
  'willpower',
  'perception',
};

const kVisibleAttributes = {
  'charisma',
  'spirituality',
  'dexterity',
  'strength',
  'willpower',
  'perception',
};

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

const kCultivationRankMax = 5;
const kEquipmentMax = 5;
const kFameRankMax = 5;
const kJobRankMax = 5;

const kRestrictedEquipmentCategories = {
  'weapon',
  'shield',
  'armor',
  'gloves',
  'helmet',
  'boots',
  'vehicle',
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

const kRarityMax = 5;

final kRarityDistribution = [0.01, 0.04, 0.09, 0.22, 0.45, 1.0];

Color getColorFromRarity(String rarity) {
  return switch (rarity) {
    /// 凡品
    'common' => RankedColors.common,

    /// 良品
    'rare' => RankedColors.rare,

    /// 上品
    'epic' => RankedColors.epic,

    /// 极品
    'legendary' => RankedColors.legendary,

    /// 绝品
    'mythic' => RankedColors.mythic,

    /// 神品
    'arcane' => RankedColors.arcane,

    /// 其他
    _ => RankedColors.common,
  };
}

Color getColorFromRank(int rank) {
  return switch (rank) {
    /// 无境界 根据背景，一般是黑或白
    0 => RankedColors.common,

    /// 凝气 灰
    1 => RankedColors.rare,

    /// 筑基 蓝
    2 => RankedColors.epic,

    /// 结丹 紫
    3 => RankedColors.legendary,

    /// 还婴 金
    4 => RankedColors.mythic,

    /// 化神 红
    5 => RankedColors.arcane,

    /// 其他
    _ => RankedColors.common,
  };
}

/// 组织的类型即动机，代表了不同的发展方向
const kSectCategories = {
  'wuwei', // 无为：清净，隐居，不问世事
  'cultivation', // 修真：功法，战斗
  'immortality', // 长生：宗教，等级，境界
  'chivalry', // 任侠：江湖义气，路见不平拔刀相助
  'entrepreneur', // 权霸：扩张国家领地，发展下属和附庸
  'wealth', // 财富：经营商号，积累钱币和灵石
  'pleasure', // 欢愉：享乐，赌博，情色
};

const kCultivationGenres = {
  'swordcraft',
  'spellcraft',
  'bodyforge',
  'avatar',
  'vitality',
};

const kCardpackGenres = {
  'none',
  'swordcraft',
  'spellcraft',
  'bodyforge',
  'avatar',
  'vitality',
};

const kLocationCityKinds = {
  'inland',
  'harbor',
  'island',
  'mountain',
};

// 门派总堂，每个门派在总部的默认建筑，用来管理门派
const kLocationKindHeadquarters = 'headquarters';
// 城市总堂，每个城市默认建筑，用来管理城市
const kLocationKindCityhall = 'cityhall';

const kLocationSiteKinds = {
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
  'enchantshop',
  'alchemylab',
  'tattooshop',
  'runelab',
  'arraylab',
  'illusionaltar',
  'psychictemple',
  'divinationaltar',
  'theurgytemple',
  'farmland',
  'timberland',
  'fishery',
  'huntingground',
  'mine',
  'dungeon',
};

const kSiteKindToNpcId = {
  'headquarters': 'executiveAssistant',
  'cityhall': 'assistant',
  'tradinghouse': 'trader',
  'daostele': 'steleKeeper',
  'exparray': 'expCollector',
  'library': 'librarian',
  'arena': 'martialArtist',
  'militarypost': 'militaryAdvisor',
  'auctionhouse': 'auctionist',
  'hotel': 'hotelManager',
  'workshop': 'smith',
  'enchantshop': 'enchanter',
  'alchemylab': 'alchemist',
  'tattooshop': 'tattooArtist',
  'runelab': 'runeMaster',
  'arraylab': 'arrayMaster',
  'illusionaltar': 'illusionist',
  'psychictemple': 'psychist',
  'divinationaltar': 'diviner',
  'theurgytemple': 'theurgist',
  'farmland': 'farmer',
  'fishery': 'fisher',
  'timberland': 'lumberjack',
  'huntingground': 'hunter',
  'mine': 'miner',
  'dungeon': 'dungeonKeeper',
};

const kSiteKindsWorkable = {
  'farmland', // 神识
  'fishery', // 念力
  'timberland', // 灵力
  'huntingground', // 身法
  'mine', // 体魄
};

const kSiteKindToAttribute = {
  'farmland': 'perception',
  'timberland': 'spirituality',
  'fishery': 'willpower',
  'huntingground': 'dexterity',
  'mine': 'strength',
};

const kSiteDevelopmentDaysBase = 5;
const kCityDevelopmentDaysBase = 10;
const kSectDevelopmentDaysBase = 20;

/// 所有的城市和建筑升级，每天所要消耗的基础资源
/// 实际消耗主要取决于开发所需要的总时间

const kSiteKindsManagable = {
  'home': {
    'developmentCost': {
      'money': 50,
      'worker': 2,
      'water': 1,
      'timber': 2,
      'stone': 1,
    },
  },
  'headquarters': {
    'developmentCost': {
      'money': 1000,
      'worker': 25,
      'timber': 8,
      'stone': 8,
    },
  },
  'cityhall': {
    'developmentCost': {
      'money': 500,
      'worker': 10,
      'water': 1,
      'ore': 1,
      'leather': 1,
      'herb': 1,
      'timber': 3,
      'stone': 1,
    },
  },
  'tradinghouse': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'timber': 2,
      'stone': 2,
    },
    'maintainanceCost': {
      'money': 100,
      'worker': 2,
    },
  },
  'daostele': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'timber': 1,
      'stone': 4,
      'ore': 2,
      'herb': 1,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 5,
    },
  },
  'exparray': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 2,
      'ore': 1,
      'herb': 1,
      'timber': 2,
      'stone': 2,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 5,
    },
  },
  'library': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'leather': 1,
      'herb': 1,
      'timber': 5,
      'stone': 1,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 5,
    },
  },
  'arena': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'ore': 1,
      'herb': 1,
      'timber': 2,
      'stone': 4,
    },
    'maintainanceCost': {
      'money': 200,
      'worker': 2,
    },
  },
  'militarypost': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'ore': 2,
      'leather': 2,
      'timber': 2,
      'stone': 2,
    },
    'maintainanceCost': {
      'money': 500,
      'worker': 2,
    },
  },
  'auctionhouse': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'leather': 3,
      'herb': 1,
      'timber': 3,
      'stone': 1,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 5,
    },
  },
  'hotel': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 1,
      'ore': 1,
      'leather': 1,
      'herb': 1,
      'timber': 3,
      'stone': 1,
    },
    'maintainanceCost': {
      'money': 500,
      'worker': 3,
    },
  },
  'workshop': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'timber': 3,
      'stone': 5,
    },
    'maintainanceCost': {
      'money': 500,
      'worker': 3,
    },
  },
  'enchantshop': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'timber': 5,
      'stone': 3,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'alchemylab': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 1,
      'ore': 1,
      'leather': 1,
      'herb': 1,
      'timber': 3,
      'stone': 1,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'tattooshop': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 1,
      'ore': 1,
      'leather': 1,
      'herb': 1,
      'timber': 3,
      'stone': 1,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'runelab': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 1,
      'ore': 1,
      'leather': 1,
      'herb': 1,
      'timber': 3,
      'stone': 1,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'arraylab': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 1,
      'ore': 2,
      'timber': 3,
      'stone': 2,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'illusionaltar': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 1,
      'ore': 2,
      'herb': 1,
      'timber': 3,
      'stone': 1,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'psychictemple': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 1,
      'ore': 2,
      'herb': 2,
      'timber': 2,
      'stone': 1,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'divinationaltar': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'ore': 2,
      'herb': 1,
      'timber': 2,
      'stone': 3,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'theurgytemple': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'ore': 2,
      'herb': 2,
      'timber': 2,
      'stone': 2,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 3,
    },
  },
  'farmland': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 2,
      'herb': 1,
      'stone': 1,
    },
    'maintainanceCost': {
      'money': 50,
      'worker': 1,
    },
  },
  'timberland': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 2,
      'timber': 1,
      'stone': 1,
    },
    'maintainanceCost': {
      'money': 50,
      'worker': 1,
    },
  },
  'fishery': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'water': 2,
      'timber': 2,
    },
    'maintainanceCost': {
      'money': 50,
      'worker': 1,
    },
  },
  'huntingground': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'herb': 1,
      'timber': 2,
      'stone': 1,
    },
    'maintainanceCost': {
      'money': 50,
      'worker': 1,
    },
  },
  'mine': {
    'developmentCost': {
      'money': 200,
      'worker': 5,
      'timber': 1,
      'stone': 3,
    },
    'maintainanceCost': {
      'money': 50,
      'worker': 1,
    },
  },
  'dungeon': {
    'developmentCost': {
      'money': 500,
      'worker': 10,
      'ore': 6,
      'timber': 4,
      'stone': 6,
    },
    'maintainanceCost': {
      'shard': 1,
      'worker': 5,
    },
  },
};

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
  // 'tattooshop',
  'runelab',
  // 'arraylab',
  'illusionaltar',
  // 'psychictemple',
  'divinationaltar',
  // 'theurgytemple',
};

const kSiteKindsTradable = {
  'tradinghouse',
  'library',
  'auctionhouse',
  'alchemylab',
  'runelab',
};

/// farmland 只会在平原地形且在城市周围出现
/// timberland 只会在森林地形出现
/// fishery 只会在大陆架、湖泊或者城市周围一格的水域地形出现
/// huntingground 只会在山地或森林地形出现
/// mine 只会在山地地形出现
const kProductionSiteKinds = {
  'farmland',
  'timberland',
  'fishery',
  'huntingground',
  'mine',
};

const kProductionSiteDevelopmentMax = 2;

const kSiteProductionMainMaterialProduceProbability = {
  'farmland': 0.8,
  'fishery': 0.6,
  'huntingground': 0.65,
  'timberland': 0.7,
  'mine': 0.75,
};

const kSectCategoryToSiteKind = {
  'wuwei': 'daostele',
  'cultivation': 'library',
  'immortality': 'exparray',
  'chivalry': 'arena',
  'entrepreneur': 'militarypost',
  'wealth': 'auctionhouse',
  'pleasure': 'hotel',
};

const kSectCategoryExpansionRate = {
  'wuwei': 0.2,
  'cultivation': 0.5,
  'immortality': 0.3,
  'chivalry': 0.6,
  'entrepreneur': 0.8,
  'wealth': 0.7,
  'pleasure': 0.4,
};

const kSectGenreToSiteKinds = {
  'swordcraft': [
    'workshop',
    // 'enchantshop',
  ],
  'bodyforge': [
    'alchemylab',
    // 'tattooshop',
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

const kSitePriority = {
  'home': 99,
  'headquarters': 55,
  'cityhall': 54,
  'tradinghouse': 53,
  'daostele': 47,
  'exparray': 46,
  'library': 45,
  'arena': 44,
  'militarypost': 43,
  'auctionhouse': 42,
  'hotel': 41,
  'workshop': 39,
  'enchantshop': 38,
  'alchemylab': 37,
  'tattooshop': 36,
  'runelab': 35,
  'arraylab': 34,
  'illusionaltar': 33,
  'psychictemple': 32,
  'divinationaltar': 31,
  'theurgytemple': 30,
  'dungeon': 25,
  'farmland': 9,
  'fishery': 8,
  'timberland': 7,
  'huntingground': 6,
  'mine': 5,
};

/// 非门派成员打工时的可用月份
final kSiteWorkableMounths = {
  'farmland': [1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  'fishery': [2, 3, 4, 5, 6, 7, 8, 9, 10],
  'huntingground': [1, 2, 3, 9, 10, 11, 12],
  'timberland': [4, 5, 6, 7, 8],
  'mine': [11, 12, 1],
};

/// 工作时消耗的体力值
final kSiteWorkableStaminaCost = {
  'farmland': 1,
  'fishery': 2,
  'huntingground': 3,
  'timberland': 4,
  'mine': 5,
};

/// 非门派成员使用设施的日租金
/// 以 money 为单位，但可能会被转化为灵石
final kSiteRentMoneyCostByDay = {
  'tradinghouse': null,
  'daostele': 2000,
  'exparray': 2000,
  'library': 2500,
  'arena': null,
  'militarypost': null,
  'auctionhouse': null,
  'hotel': 1000,
  'farmland': 150,
  'timberland': 350,
  'fishery': 200,
  'huntingground': 550,
  'mine': 850,
  'workshop': 2500,
  'enchantshop': 2500,
  'alchemylab': 1500,
  'tattooshop': 1500,
  'runelab': 1250,
  'arraylab': 2500,
  'illusionaltar': 2500,
  'psychictemple': 1000,
  'divinationaltar': 1500,
  'theurgytemple': 1500,
  'dungeon': 5000,
};

final class AttackType {
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

final class DamageType {
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

const kBuyRateBase = 1.0;
const kSellRateBase = 0.75;

const kMinSellRate = 0.1;
const kMinBuyRate = 0.1;

const kPriceFavorRate = 0.1;
const kPriceFavorIncrement = 0.05;

/// money 和 shard 是在任何地方随时可以交换的货币
/// worker 是建造和维护必须的一种特殊资源，可以理解为劳动合同
/// water grain meat ore leather 是消耗性资源，建筑每天会固定消耗
/// timber 和 stone 主要用于建造和升级建筑
const kMaterialKinds = [
  'money',
  'shard',
  'worker',
  'water',
  'grain',
  'meat',
  'ore',
  'leather',
  'herb',
  'timber',
  'stone',
];

const kNonCurrencyMaterialKinds = [
  'worker',
  'water',
  'grain',
  'meat',
  'ore',
  'leather',
  'herb',
  'timber',
  'stone',
];

const kNaturalResourceKinds = [
  'water',
  'grain',
  'meat',
  'ore',
  'leather',
  'herb',
  'timber',
  'stone',
  'spirit',
];

final kMaterialPrice = {
  'shard': 1000,
  'worker': 2,
  'water': 5,
  'grain': 2,
  'meat': 5,
  'ore': 16,
  'herb': 6,
  'leather': 8,
  'timber': 10,
  'stone': 6,
};

const kUnknownItemPrice = 10;

/// 物品的基础价格
final kItemPriceByCategory = {
  'craftmaterial_addAffix': 350,
  'craftmaterial_replaceAffix': 750,
  'craftmaterial_rerollAffix': 1000,
  'craftmaterial_upgrade': 3500,
  'dungeon_ticket': 2000,
  'cardpack': 700,
  'scroll_paper': 350,
  'identify_scroll': 75,
  'weapon': 20,
  'shield': 10,
  'armor': 10,
  'gloves': 10,
  'helmet': 10,
  'boots': 20,
  'vehicle': 75,
  'jewelry': 35,
  'talisman': 50,
  'potion': 10,
};

const kItemWithAffixCategories = [
  'weapon',
  'shield',
  'armor',
  'gloves',
  'helmet',
  'boots',
  'vehicle',
  'jewelry',
  'talisman',
  'potion',
];

const kUntradableItemKinds = {
  'money',
  'worker',
};

const kMaxAffixCount = 6;

const kPassiveTreeAttributeAnyLevel = 10;

/// 不同种族的属性偏向
const kRaceMainAttributes = {
  'fanzu': {
    'wisdom',
    'dexterity',
  },
  'yaozu': {
    'strength',
    'luck',
  },
  'xianzu': {
    'spirituality',
    'charisma',
  },
};

const kBaseExpGainPerLight = 40;
const kBaseExpCollectSpeed = 1.0;
const kNPCMoveSpeed = 0.5;
const kNPCMoveSpeedMultiplier = 2;
const kBaseMoveSpeedOnPlain = 2.0;
const kBaseMoveSpeedOnMountain = 1.0;
const kBaseMoveSpeedOnWater = 4.0;

const kBaseStaminaCostOnMountain = 2.0;
const kBaseStaminaCostOnWater = 4.0;
const kBaseCraftSkillLevel = 0;

const kBaseLife = 10;
const kBaseLifePerLevel = 5;
const kBaseLightRadius = 2;

const kBaseMonthlyIdentifyCardsMax = 12;
const kBaseResistMax = 75;
const kBaseTurnActionThreshold = 10;
const kMaxTurnActionThreshold = 15;
const kMinTurnActionThreshold = 5;

const kLocationKindHome = 'home';

const kTerrainKindsLand = ['plain', 'shore', 'forest', 'city'];
const kTerrainKindsWater = ['sea', 'river', 'lake', 'shelf'];
const kTerrainKindsMountain = ['mountain'];
const kTerrainKindsAll = [
  ...kTerrainKindsLand,
  ...kTerrainKindsWater,
  ...kTerrainKindsMountain,
];

/// 战斗结束后生命恢复比例计算时，
const kLifeRestoreRateAfterBattle = 0.25;

/// 战斗中使用的卡牌使用过的数量的阈值
const kBattleCardsCount = 16;

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

const kTimeStrings = {
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

const kBattleCardGenreAttacks = {
  // 怒气
  'bodyforge': {
    'punch',
    'kick',
    'qinna',
  },
  // 灵气、剑气
  'swordcraft': {
    'punch',
    'flying_sword',
    'dianxue',
  },
  // 灵气
  'spellcraft': {
    'punch',
    'airbend',
    'firebend',
    'lightning_control',
    // 'waterbend',
  },
  // 煞气
  'vitality': {
    'punch',
    'power_word',
  },
  // 煞气、怒气
  'avatar': {
    'kick',
    'sigil',
  },
};

const kBattleCardGenreBuffs = {
  // 怒气
  'bodyforge': {
    'xinfa',
    'punch',
    'kick',
    'shenfa',
    'qinggong',
  },
  // 灵气、剑气
  'swordcraft': {
    'xinfa',
    'kick',
    'flying_sword',
    'shenfa',
    'qinggong',
  },
  // 灵气
  'spellcraft': {
    'xinfa',
    'punch',
    'airbend',
    'plant_control',
    // 'waterbend',
  },
  // 煞气
  'vitality': {
    'xinfa',
    'punch',
    'power_word',
    // 'music',
  },
  // 煞气、怒气
  'avatar': {
    'xinfa',
    'kick',
    'scripture',
  },
};

const kBattleCardKinds = {
  'punch',
  'kick',
  'qinna',
  'dianxue',
  'sabre',
  'spear',
  'sword',
  'staff',
  'bow',
  'dart',
  'flying_sword',
  'shenfa',
  'qinggong',
  'xinfa',
  'airbend',
  'firebend',
  // 'waterbend',
  'lightning_control',
  'earthbend',
  'plant_control',
  'sigil',
  'power_word',
  'scripture',
  // 'music',
  // 'array',
  // 'illusion',
};

const kItemEquipmentCategories = {
  'weapon',
  'shield',
  'armor',
  'gloves',
  'helmet',
  'boots',
  'vehicle',
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
const kItemCategoryScrollPaper = 'scroll_paper';
const kItemCategoryDungeonTicket = 'dungeon_ticket';
const kItemCategoryExppack = 'exp_pack';
const kItemCategoryMaterialPack = 'material_pack';
const kItemCategoryContributionPack = 'contribution_pack';
const kItemCategoryEquipmentAffix = 'equipment_affix';
const kItemCategoryPotion = 'potion';

/// 职位等级
/// 职位等级对应于境界，角色境界若小于职位等级，则无法任命该职位
const kTitleToJobRank = {
  'taskman': 0,
  'executor': 1,
  'manager': 2,
  'mayor': 3,
  'governor': 4,
  'head': 5,
  'guard': 2,
  'envoy': 3,
  'chancellor': 4,
  "guestChancellor": 4,
};

const kCultivationRankToTitle = {
  0: 'taskman',
  1: 'executor',
  2: 'manager',
  3: 'mayor',
  4: 'governor',
};

const kTitleToAlternativeTitle = {
  'manager': 'guard',
  'mayor': 'envoy',
  'governor': 'chancellor',
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
    //'robe',
  ],
  'gloves': [
    'gloves',
  ],
  'helmet': [
    'helmet',
    // 'coronet',
  ],
  'boots': [
    'boots',
  ],
  'vehicle': [
    'ship',
    // 'aircraft',
  ],
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
  ...kEquipmentCategoryKinds['vehicle']!,
  // ...kEquipmentCategoryKinds['aircraft']!,
  ...kEquipmentCategoryKinds['jewelry']!,
  ...kEquipmentCategoryKinds['talisman']!, // 非以上四种的物品都算作法器 talisman
];

const kEnemyEncounterQuests = {
  'deliver_material',
  'deliver_item',
  'escort',
  'purchase_material',
  'purchase_item',
};

const kTerrainKindToEnemyEncounterRate = {
  'plain': 0.05,
  'mountain': 0.12,
  'forest': 0.1,
  'snow_plain': 0.075,
  'snow_mountain': 0.18,
  'snow_forest': 0.15,
  'shore': 0.05,
  'shelf': 0.05,
  'sea': 0.1,
  'lake': 0.06,
  'river': 0.04,
};

final kNpcIds = [
  ...kSiteKindToNpcId.values,
];

const kLocationManualReplenishCostBase = 50;

const kEstimatePriceFactor = 0.8;
const kEstimatePriceRange = {
  'cheap',
  'normal',
  'expensive',
};

const kWuweiTrialQuestionCount = 8;
const kWuweiTrialOptionsCount = 3;
const kWuweiTrialAnswers = {
  1: 2,
  2: 1,
  3: 3,
  4: 2,
  5: 3,
  6: 1,
  7: 3,
  8: 1,
};

// 修真试炼最少需要的战斗回合数
const kCultivationTrialMinBattleRound = 4;

// 财富试炼需要支付的灵石数量
const kWealthTrialCost = 5;

const kPleasureTrialMinCharisma = 70;

const kRecruitCityRequirementContribution = 50;
const kRecruitCityRequirementMoney = 50_000;
const kRecruitCityRequirementShard = 50;

const kCreateSectRequirementRank = 2;
const kCreateSectRequirementMoney = 500_000;
const kCreateSectRequirementShard = 500;

const kHomeRelocationCost = 200;

const kHomeLifeRestorePerTime = 2;

const kHotelStableCostPerTime = 50;
const kHotelNormalCostPerTime = 150;
const kHotelVipCostPerTime = 500;

const kHotelNormalLifeRestorePerTime = 5;
const kHotelVipLifeRestorePerTime = 15;

const kItemPriceToContributionRate = 0.001;
