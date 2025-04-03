const kTopLayerAnimationPriority = 500;
const kStatusEffectIconPriority = 1000;

const kOppositeStatus = {
  'enhance_unarmed': 'weaken_unarmed',
  'enhance_weapon': 'weaken_weapon',
  'enhance_spell': 'weaken_spell',
  'enhance_curse': 'weaken_curse',
  'weaken_unarmed': 'enhance_unarmed',
  'weaken_weapon': 'enhance_weapon',
  'weaken_spell': 'enhance_spell',
  'weaken_curse': 'enhance_curse',
  'resistant_physical': 'weakness_physical',
  'resistant_chi': 'weakness_chi',
  'resistant_elemental': 'weakness_elemental',
  'resistant_psychic': 'weakness_psychic',
  'weakness_physical': 'resistant_physical',
  'weakness_chi': 'resistant_chi',
  'weakness_elemental': 'resistant_elemental',
  'weakness_psychic': 'resistant_psychic',
  'speed_quick': 'speed_slow',
  'speed_slow': 'speed_quick',
  'dodge_nimble': 'dodge_clumsy',
  'dodge_clumsy': 'dodge_nimble',
  'dodge_invincible': 'dodge_staggering',
  'dodge_staggering': 'dodge_invincible',
  'energy_positive_life': 'energy_negative_life',
  'energy_positive_leech': 'energy_negative_leech',
  'energy_positive_pure': 'energy_negative_pure',
  'energy_positive_spell': 'energy_negative_spell',
  'energy_positive_weapon': 'energy_negative_weapon',
  'energy_positive_unarmed': 'energy_negative_unarmed',
  'energy_positive_curse': 'energy_negative_curse',
  'energy_positive_ultimate': 'energy_negative_ultimate',
  'energy_negative_life': 'energy_positive_life',
  'energy_negative_leech': 'energy_positive_leech',
  'energy_negative_pure': 'energy_positive_pure',
  'energy_negative_spell': 'energy_positive_spell',
  'energy_negative_weapon': 'energy_positive_weapon',
  'energy_negative_unarmed': 'energy_positive_unarmed',
  'energy_negative_curse': 'energy_positive_curse',
  'energy_negative_ultimate': 'energy_positive_ultimate',
  'defense_physical': 'vulnerable_physical',
  'defense_chi': 'vulnerable_chi',
  'defense_elemental': 'vulnerable_elemental',
  'defense_psychic': 'vulnerable_psychic',
  'vulnerable_physical': 'defense_physical',
  'vulnerable_chi': 'defense_chi',
  'vulnerable_elemental': 'defense_elemental',
  'vulnerable_psychic': 'defense_psychic',
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
