const kGameVersion = '0.0.1';

const kGameSaveFileExtension = '.tdqjgame';
const kUniverseSaveFilePostfix = '_universe';
const kHistorySaveFilePostfix = '_history';

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
  'element',
  'physique',
  'avatar',
  'vitality',
  'blade',
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
  'element',
  'blade',
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
  'spirituality': 'spirituality',
  'dexterity': 'blade',
  'strength': 'physique',
  'willpower': 'vitality',
  'perception': 'avatar',
};
