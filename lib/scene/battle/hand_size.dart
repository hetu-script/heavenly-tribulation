import 'dart:math' as math;

int getDrawableCardCount({
  required int requestedCount,
  required int currentHandSize,
  required int handSizeMax,
}) {
  if (requestedCount <= 0) return 0;
  return math.min(requestedCount, math.max(0, handSizeMax - currentHandSize));
}
