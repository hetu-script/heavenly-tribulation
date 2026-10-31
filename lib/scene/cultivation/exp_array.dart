int getExpArrayMaxRounds(int development) {
  assert(development >= 0);
  return (development + 1).clamp(1, 3);
}
