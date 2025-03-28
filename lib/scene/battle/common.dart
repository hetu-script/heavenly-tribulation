const kTurnLimit = 80;

const kTopLayerAnimationPriority = 500;
const kStatusEffectIconPriority = 1000;

const kOppositeEffect = {
  'enhance_unarmed': 'weaken_unarmed',
  'enhance_weapon': 'weaken_weapon',
  'enhance_spell': 'weaken_spell',
  'enhance_curse': 'weaken_curse',
  'enhance_chaos': 'weaken_chaos',
  'weaken_unarmed': 'enhance_unarmed',
  'weaken_weapon': 'enhance_weapon',
  'weaken_spell': 'enhance_spell',
  'weaken_curse': 'enhance_curse',
  'weaken_chaos': 'enhance_chaos',
  'speed_quick': 'speed_slow',
  'speed_slow': 'speed_quick',
  'dodge_nimble': 'dodge_clumsy',
  'dodge_clumsy': 'dodge_nimble',
  'dodge_invincible': 'dodge_staggering',
  'dodge_staggering': 'dodge_invincible',
  'positive_energy_life': 'negative_energy_life',
  'positive_energy_leech': 'negative_energy_leech',
  'positive_energy_pure': 'negative_energy_pure',
  'negative_energy_spell': 'negative_energy_spell',
  'positive_energy_weapon': 'negative_energy_weapon',
  'positive_energy_unarmed': 'negative_energy_unarmed',
  'positive_energy_curse': 'negative_energy_curse',
  'positive_energy_chaos': 'negative_energy_chaos',
  'positive_energy_ultimate': 'negative_energy_ultimate',
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
