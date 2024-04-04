int expForLevel(level, [difficulty = 1]) {
  return (difficulty * (level) * (level)) * 5 + level * 100 + 25;
}
