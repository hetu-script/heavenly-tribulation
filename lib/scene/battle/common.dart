const kTurnLimit = 80;

const kTopLayerAnimationPriority = 500;
const kStatusEffectIconPriority = 1000;

const kOppositeEffect = {
  'enhance_unarmed': 'weaken_unarmed',
  'enhance_weapon': 'weaken_weapon',
  'enhance_spell': 'weaken_spell',
  'enhance_curse': 'weaken_curse',
  'enhance_poison': 'weaken_poison',
  'weaken_unarmed': 'enhance_unarmed',
  'weaken_weapon': 'enhance_weapon',
  'weaken_spell': 'enhance_spell',
  'weaken_curse': 'enhance_curse',
  'weaken_poison': 'enhance_poison',
  'speed_quick': 'speed_slow',
  'speed_slow': 'speed_quick',
  'dodge_nimble': 'dodge_clumsy',
  'dodge_clumsy': 'dodge_nimble',
  'dodge_invincible': 'dodge_staggering',
  'dodge_staggering': 'dodge_invincible',
  'energy_positive_life': 'energy_negative_life',
  'energy_positive_leech': 'energy_negative_leech',
  'energy_positive_pure': 'energy_negative_pure',
  'energy_negative_spell': 'energy_negative_spell',
  'energy_positive_weapon': 'energy_negative_weapon',
  'energy_positive_unarmed': 'energy_negative_unarmed',
  'energy_positive_curse': 'energy_negative_curse',
  'energy_positive_poison': 'energy_negative_poison',
  'energy_positive_chaotic': 'energy_negative_chaotic',
  'defense_physical': 'vulnerable_physical',
  'defense_chi': 'vulnerable_chi',
  'defense_elemental': 'vulnerable_elemental',
  'defense_spiritual': 'vulnerable_spiritual',
  'vulnerable_physical': 'defense_physical',
  'vulnerable_chi': 'defense_chi',
  'vulnerable_elemental': 'defense_elemental',
  'vulnerable_spiritual': 'defense_spiritual',
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
