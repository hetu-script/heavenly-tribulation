const kEquipmentMax = 7;
const kEquipmentSupportMax = 4;

// entityType决定了该对象的数据结构和保存位置
const kEntityTypeCharacter = 'character'; //game.characters
const kEntityTypeNpc = 'npc'; //game.npcs
const kEntityTypeItem = 'item'; //character.inventory
const kEntityTypeSkill = 'skill'; //character.skill
const kEntityTypeCompanion = 'companion';
const kEntityTypeOrganization = 'organization';

// category是界面上显示的对象类型文字
const kEntityCategoryCharacter = 'character';
const kEntityCategoryBeast = 'beast';
const kEntityCategoryMoney = 'money';
const kEntityCategoryWeapon = 'weapon';
const kEntityCategoryProtect = 'protect';
const kEntityCategoryTalisman = 'talisman';
const kEntityCategoryConsumable = 'consumable';
const kEntityCategoryKungfu = 'kungfu';
const kEntityCategoryWeaponArts = 'weaponArts';
const kEntityCategoryArcana = 'arcana';

const kEntityConsumableKindMedicine = 'medicine';
const kEntityConsumableKindBeverage = 'beverage';
const kEntityConsumableKindAlchemy = 'alchemy';
const kEntityConsumableKindFood = 'food';

const kEntityMaterialKindGrain = 'grain';
const kEntityMaterialKindFruit = 'fruit';
const kEntityMaterialKindFish = 'fish';
const kEntityMaterialKindVegetable = 'vegetable';
const kEntityMaterialKindHerb = 'herb';
const kEntityMaterialKindWood = 'wood';
const kEntityMaterialKindOre = 'ore';
const kEntityMaterialKindJade = 'jade';
const kEntityMaterialKindWater = 'water';
const kEntityMaterialKindEnergy = 'energy';
const kEntityMaterialKindSpectre = 'spectre';

// 实际上进攻类装备也可能具有防御效果，因此这里的类型仅用于显示而已
const kEquipTypeOffense = 'offense';
const kEquipTypeSupport = 'support';
const kEquipTypeDefense = 'defense';
const kEquipTypeArcana = 'arcana';
const kEquipTypeCompanion = 'companion';
