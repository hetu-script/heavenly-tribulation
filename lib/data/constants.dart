// 卡牌类型
const kCardTypes = {
  'unarmed',
  'weapon',
  'spell',
  'curse',
  'shenfa',
  'xinfa',
  'divinity',
};

// 临时状态类型（聚灵阵）
const kEphemeralTypes = {'attack', 'defense', 'attribute', 'energy'};

/// items.json5 的合法物品类型（见文件头注释）
const kItemTypes = {
  'consumable',
  'equipment',
  'craftmaterial',
  'miscellaneous'
};

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

/// 流派 → 费用色映射（战斗费用系统，见 plan/battle_resource_rework.md 单资源模型）
/// 仅用于缺省兜底推导（数据层约定所有卡显式写 coloredCost）；
/// 法身（avatar）无有色气产出、基础卡组花元气，故不在表中
const kGenreColoredCost = {
  'spellcraft': 'spell',
  'swordcraft': 'weapon',
  'bodyforge': 'unarmed',
  'vitality': 'curse',
};

/// 费用色 → 阳气状态 id 映射（基础卡的有色费用仅限这 4 色）
const kCostColorStatusIds = {
  'spell': 'energy_positive_spell',
  'weapon': 'energy_positive_weapon',
  'unarmed': 'energy_positive_unarmed',
  'curse': 'energy_positive_curse',
};

/// 万能费用色（太极之气）的状态 id，可支付任意有色费用
const kWildcardStatusId = 'energy_positive_ultimate';

/// 无色费用（元气）在 coloredCost 映射中的颜色 id
/// 元气也作为费用图标之一渲染，但支付规则与有色费用不同：
/// 不能用太极之气补齐
const kColorlessCostColorId = 'life';

/// 战斗负面效果池：邪祟（debuff_ward）回合开始随机施加、治疗时随机驱散的抽取池
/// 通过 Constants.debuffs 导出到脚本侧
const kDebuffs = [
  'speed_slow',
  'dodge_clumsy',
  'vulnerable',
  'debuff_crit',
  'debuff_ward',
  'debuff_shield',
  'ailment_bleeding',
  'ailment_internal_injury',
  'ailment_hallucination',
  'ailment_fire',
  'ailment_lightning',
  'ailment_ice',
  'ailment_poison',
];

/// 元素 → 元素异常的映射（对应关系以本地化 status_element_ailment_description 为准）：
/// 金:流血、木:中毒、水:冰缓（ailment_ice）、火:点燃（ailment_fire）、土:内伤、
/// 风:幻觉、雷:感电。
/// 供 ailment_spread / attack_multiple_ailment 等词条脚本直接施加元素异常查表
/// （不经 takeDamage 的异常计数器，必然施加）。
/// 通过 Constants.elementAilments 导出到脚本侧
const kElementAilmentIds = {
  'element_metal': 'ailment_bleeding',
  'element_wood': 'ailment_poison',
  'element_water': 'ailment_ice',
  'element_fire': 'ailment_fire',
  'element_earth': 'ailment_internal_injury',
  'element_wind': 'ailment_hallucination',
  'element_lightning': 'ailment_lightning',
};

/// 元素类型集合
final kElementTypes = kElementAilmentIds.keys.toSet();

/// 爆发元素 → 转化态伤害类型的映射（plan/damage_type_rework.md 2.4）：
/// 火→fire、水→ice、雷→lightning、木→poison。
/// 卡牌印刷伤害类型统一为无属性（ordinary）；潜伏元素在本表中的攻击卡，
/// 当对方持有对应元素异常（查 kElementAilmentIds）时，转化为对应元素伤害结算并消耗 1 层。
/// 本表只决定伤害类型转化；异常充能/幸运必异常的口径是 kElementAilmentIds（七元素）——
/// 金/土/风为控制元素，不在本表（永不转化，但其异常照常经计数器施加，异常是收益本体）。
/// 通过 Constants.elementDamageTypes 导出到脚本侧
const kElementDamageTypes = {
  'element_fire': 'fire',
  'element_water': 'ice',
  'element_lightning': 'lightning',
  'element_wood': 'poison',
};

const kRarityNames = {
  'common',
  'rare',
  'epic',
  'legendary',
  'mythic',
  'arcane',
};

const kCultivationGenres = {
  'swordcraft',
  'spellcraft',
  'bodyforge',
  'avatar',
  'vitality',
};

const kBattleCardCategories = {
  'attack',
  'buff',
};

const kBattleCardGenres = {
  'neutral',
  'swordcraft',
  'spellcraft',
  'bodyforge',
  'avatar',
  'vitality',
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
  // 物理：拳脚兵刃等无元素武技（elementType 为空的攻击卡），
  // 与护甲全额交互，唯一可暴击的伤害类型
  static const physical = 'physical';
  // 无属性：元素卡的未转化形态（含金/土/风控制元素卡的常驻形态），
  // 与护甲全额交互，不参与暴击
  static const ordinary = 'ordinary';
  static const chi = 'chi';
  static const psychic = 'psychic';
  // 四种元素伤害只作为战斗内转化态存在（见 kElementDamageTypes），
  // 数据层卡牌不再直接印刷这些伤害类型
  static const fire = 'fire';
  static const ice = 'ice';
  static const lightning = 'lightning';
  static const poison = 'poison';
  static const pure = 'pure';
}

const List<String> kDamageTypes = [
  DamageType.physical,
  DamageType.ordinary,
  DamageType.chi,
  DamageType.psychic,
  DamageType.fire,
  DamageType.ice,
  DamageType.lightning,
  DamageType.poison,
  DamageType.pure,
];

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
  'waterbend',
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
