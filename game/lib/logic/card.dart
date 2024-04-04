/// 根据人物当前境界，获取不同境界卡牌的概率
const cardObtainProbabilityByRank = {
  '1': {1: 1},
  '2': {
    '1': 0.7,
    '2': 0.3,
  },
  '3': {
    '1': 0.6,
    '2': 0.25,
    '3': 0.15,
  },
  '4': {
    '1': 0.5,
    '2': 0.25,
    '3': 0.15,
    '4': 0.1,
  },
  '5': {
    '1': 0.45,
    '2': 0.25,
    '3': 0.15,
    '4': 0.1,
    '5': 0.05,
  }
};

/// 根据角色当前的流派等级和境界，获得三张卡牌
List<String> obtainCultivationCardsForHero(dynamic heroData) {
  final List<String> result = [];

  /// genreLevels 是一个数组，代表每个流派的等级
  /// 内容示例：
  /// [
  ///   { genreId: 'blade', probability: 0.7 },
  ///   { genreId: 'element', probability: 0.2 },
  ///   { genreId: 'avatar', probability: 0.1 },
  ///   ...
  /// ]

  // final probabilityTotal = genreLevels.reduce((a, b) => a.level + b.level);

  // genreLevels.sort((a, b) => b.level.compareTo(a.level));

  return result;
}
