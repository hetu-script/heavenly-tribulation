const kTopLayerAnimationPriority = 500;

/// 6 种资源阴气的状态 id（净值 UI：图标运行时反色显示，见计划 §5）
const kNegativeResourceQi = {
  'energy_negative_life',
  'energy_negative_spell',
  'energy_negative_weapon',
  'energy_negative_unarmed',
  'energy_negative_curse',
  'energy_negative_ultimate',
};

/// 是否为资源阴气（阴阳对冲保证同对阴阳不会同时持有，阴气显示为对应阳气的反色图标）
bool isNegativeResourceQi(String statusId) =>
    kNegativeResourceQi.contains(statusId);

const kOppositeStatus = {
  'enhance_unarmed': 'weaken_unarmed',
  'enhance_weapon': 'weaken_weapon',
  'enhance_spell': 'weaken_spell',
  'enhance_curse': 'weaken_curse',
  'weaken_unarmed': 'enhance_unarmed',
  'weaken_weapon': 'enhance_weapon',
  'weaken_spell': 'enhance_spell',
  'weaken_curse': 'enhance_curse',
  'resistant_fire': 'weakness_fire',
  'resistant_ice': 'weakness_ice',
  'resistant_lightning': 'weakness_lightning',
  'resistant_poison': 'weakness_poison',
  'resistant_elemental': 'weakness_elemental',
  'weakness_fire': 'resistant_fire',
  'weakness_ice': 'resistant_ice',
  'weakness_lightning': 'resistant_lightning',
  'weakness_poison': 'resistant_poison',
  'weakness_elemental': 'resistant_elemental',
  'speed_quick': 'speed_slow',
  'speed_slow': 'speed_quick',
  'dodge_nimble': 'dodge_clumsy',
  'dodge_clumsy': 'dodge_nimble',
  'dodge_invincible': 'dodge_staggering',
  'dodge_staggering': 'dodge_invincible',
  'buff_crit': 'debuff_crit',
  'buff_ward': 'debuff_ward',
  'buff_shield': 'debuff_shield',
  'debuff_crit': 'buff_crit',
  'debuff_ward': 'buff_ward',
  'debuff_shield': 'buff_shield',
  'energy_positive_life': 'energy_negative_life',
  'energy_positive_spell': 'energy_negative_spell',
  'energy_positive_weapon': 'energy_negative_weapon',
  'energy_positive_unarmed': 'energy_negative_unarmed',
  'energy_positive_curse': 'energy_negative_curse',
  'energy_positive_ultimate': 'energy_negative_ultimate',
  'energy_negative_life': 'energy_positive_life',
  'energy_negative_spell': 'energy_positive_spell',
  'energy_negative_weapon': 'energy_positive_weapon',
  'energy_negative_unarmed': 'energy_positive_unarmed',
  'energy_negative_curse': 'energy_positive_curse',
  'energy_negative_ultimate': 'energy_positive_ultimate',
};

const Set<String> kCardCategories = {
  'attack',
  'buff',
};

const String kDefeatState = 'defeat';
const String kDodgeState = 'dodge';
const String kHitState = 'hit';
const String kStandState = 'stand';
const Set<String> kPreloadAnimationStates = {
  kDefeatState,
  kDodgeState,
  kHitState,
  kStandState,
};
