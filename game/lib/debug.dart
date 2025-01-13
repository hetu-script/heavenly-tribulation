import 'engine.dart';

abstract class Debug {
  static dynamic generateEnemy() {
    final enemy = engine.hetu.invoke('Character', namedArgs: {
      // 'isFemale': false,
      'isMajorCharacter': false,
      'cultivationLevel': 10,
      'cultivationRank': 1,
      // 'baseStats': {
      //   'life': 80,
      //   'physiqueAttack': 5,
      // },
      // 'skin': 'boar',
    });
    final enemyLibrary = {};
    final List cards = [];
    cards.add(engine.hetu.invoke(
      'BattleCard',
      namedArgs: {
        'genre': "general",
        'category': "attack",
        'kind': "punch",
        'level': enemy['cultivationLevel'],
        'rank': enemy['cultivationRank'],
      },
    ));
    cards.add(engine.hetu.invoke(
      'BattleCard',
      namedArgs: {
        'genre': "general",
        'category': "attack",
        'kind': "sword",
        'level': enemy['cultivationLevel'],
        'rank': enemy['cultivationRank'],
      },
    ));
    cards.add(engine.hetu.invoke(
      'BattleCard',
      namedArgs: {
        'genre': "swordcraft",
        'category': "attack",
        'kind': "flying_sword",
        'level': enemy['cultivationLevel'],
        'rank': enemy['cultivationRank'],
      },
    ));
    for (final cardData in cards) {
      enemyLibrary[cardData['id']] = cardData;
    }
    enemy['cardLibrary'] = enemyLibrary;
    final enemyDeck = {
      'title': 'battleDeck',
      'isBattleDeck': true,
      'cards': enemyLibrary.keys.toList(),
    };
    enemy['battleDecks'] = [enemyDeck];
    enemy['battleDeckIndex'] = 0;

    return enemy;
  }
}
