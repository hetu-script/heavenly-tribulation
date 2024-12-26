int expForLevel(level, [difficulty = 1]) {
  return (difficulty * (level) * (level)) * 10 + level * 100 + 40;
}
