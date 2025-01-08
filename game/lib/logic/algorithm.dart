import 'dart:math' as math;

int expForLevel(level, [difficulty = 1]) {
  return (difficulty * (level) * (level)) * 10 + level * 100 + 40;
}

double gradualValue(num input, num target, {double rate = 0.1}) {
  return target * (1 - math.exp(-rate * input));
}
