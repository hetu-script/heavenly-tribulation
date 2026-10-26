import 'dart:math' as math;

import '../../data/common.dart';

int getScryCardCount({
  required int count,
  required int deckSize,
}) {
  return math.min(math.min(count, kScryCardCountMax), deckSize);
}
