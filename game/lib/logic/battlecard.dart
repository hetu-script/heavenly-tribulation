// import 'package:samsara/cardgame.dart';

import 'algorithm.dart';

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
  ///   { genreId: 'flying_sword', probability: 0.7 },
  ///   { genreId: 'dao', probability: 0.2 },
  ///   { genreId: 'avatar', probability: 0.1 },
  ///   ...
  /// ]

  // final probabilityTotal = genreLevels.reduce((a, b) => a.level + b.level);

  // genreLevels.sort((a, b) => b.level.compareTo(a.level));

  return result;
}

bool checkCardRequirement(dynamic characterData, dynamic cardData) {
  if (cardData['isIdentified'] != true) return false;

  final mainAffix = cardData['affixes'][0];
  assert(mainAffix != null);
  final String? equipment = mainAffix['equipment'];
  if (equipment != null) {
    if (characterData['passives']['equipment_$equipment'] == null) {
      return false;
    }
  }
  return true;
}

// 返回值依次是：卡组下限，卡组上限，消耗牌上限，持续牌上限
(int, int, int, int) getDeckLimitFromRank(int rank) {
  assert(rank >= 0);
  final min = 3;
  final max = rank == 0 ? 3 : rank + 2;
  final ephemeralMax = rank < 5 ? 1 : 2;
  final ongoingMax = rank < 2 ? 0 : 1;
  return (min, max, ephemeralMax, ongoingMax);
}

String? checkDeckRequirement(dynamic characterData, List<dynamic> cards) {
  final deckLimit = getDeckLimitFromRank(characterData['cultivationRank']);

  if (cards.length < deckLimit.$1) {
    return 'deckbuilding_cards_not_enough';
  }

  for (final card in cards) {
    final valid = checkCardRequirement(characterData, card);
    if (!valid) {
      return 'deckbuilding_card_invalid';
    }
  }

  return null;
}

double getHPRestoreRateAfterBattle(int usedCardCount) {
  assert(usedCardCount > 0);
  return 50 - gradualValue(usedCardCount - 1, 50, rate: 0.1);
}
