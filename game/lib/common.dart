import 'package:samsara/extensions.dart';

const kGameVersion = '0.0.1';

const kGameSaveFileExtension = '.tdqjgame';
const kUniverseSaveFilePostfix = '_universe';
const kHistorySaveFilePostfix = '_history';

const kValueTypeInt = 'int';
const kValueTypeFloat = 'float';
const kValueTypePercentage = 'percentage';

const kEquipmentMax = 7;
const kEquipmentSupportMax = 4;

// entityType决定了该对象的数据结构和保存位置
const kEntityTypeCharacter = 'character'; //game.characters
const kEntityTypeBaby = 'baby'; // game.babies
const kEntityTypeItem = 'item'; //character.inventory
const kEntityTypeOrganization = 'organization'; //game.organizations
const kEntityTypeLocation = 'location'; // game.locations
const kEntityTypeSite = 'site'; // location.sites

// category是物品栏界面上显示的对象类型文字
const kEntityCategoryMaterial = 'material';

// 实际上进攻类装备也可能具有防御效果，因此这里的类型仅用于显示而已
const kEquipTypeOffense = 'offense';
const kEquipTypeSupport = 'support';
const kEquipTypeDefense = 'defense';
const kEquipTypeArcana = 'arcana';
const kEquipTypeCompanion = 'companion';

const kLevelPerRank = 10;

Color getColorFromRarity(String rarity) {
  return switch (rarity) {
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

int getDeckCardLimitFromRank(int rank) {
  assert(rank >= 0);
  return rank == 0 ? 3 : rank + 2;
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

    /// 元婴 紫
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
  'physique',
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
  'physique',
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

const kAttributesToGenre = {
  'spirituality': 'daoism',
  'dexterity': 'swordcraft',
  'strength': 'physique',
  'willpower': 'vitality',
  'perception': 'avatar',
};

const kRequirementKeys = [
  'equipment',
  'dexterity',
  'strength',
  'spirituality',
  'willpower',
  'perception',
];

abstract class DamageType {
  static const physical = 'physical';
  static const chi = 'chi';
  static const elemental = 'elemental';
  static const psychic = 'psychic';
}

const Set<String> kDamageTypes = {
  DamageType.physical,
  DamageType.chi,
  DamageType.elemental,
  DamageType.psychic,
};
