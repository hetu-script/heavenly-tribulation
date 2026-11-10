import 'package:hetu_script/utils/collection.dart' as utils;
import 'package:hetu_script/utils/uid.dart';

import '../../data/game.dart';
import '../../global.dart';
import '../../logic/logic.dart';

final class DungeonController {
  static const defaultRouteId = 'spellcraft_intro';
  static const battleKinds = {'battle', 'elite', 'boss'};

  static dynamic get run => GameData.game['flags']['dungeon'];

  static dynamic get currentRoute => GameData.dungeonRoutes[run['routeId']];

  static dynamic get currentScene {
    final currentRun = run;
    final route = currentRoute;
    if (currentRun == null || route == null) return null;
    final sceneIds = route['sceneIds'] as List;
    final index = currentRun['currentSceneIndex'] as int;
    if (index < 0 || index >= sceneIds.length) return null;
    return GameData.dungeonScenes[sceneIds[index]];
  }

  static dynamic get currentRoom {
    final scene = currentScene;
    if (scene == null) return null;
    final rooms = run['rooms'];
    final key = '${run['currentSceneIndex']}';
    return rooms[key] ??= engine.hetu.invoke(
      'createSceneDungeonRoom',
      positionalArgs: [scene, run],
    );
  }

  static bool isBattleKind(String kind) => battleKinds.contains(kind);

  static bool isDeckUsable(dynamic deck) {
    final cards = deck?['cards'];
    if (cards is! List || cards.isEmpty) return false;
    final library = GameData.hero['cardLibrary'];
    for (final cardId in cards) {
      final card = library[cardId];
      if (card != null && GameLogic.checkCardRequirements(card) == null) {
        return true;
      }
    }
    return false;
  }

  static int prepareBattleDeck() {
    final decks = GameData.hero['battleDecks'] as List;
    final currentIndex = GameData.hero['battleDeckIndex'] as int? ?? -1;
    if (currentIndex >= 0 &&
        currentIndex < decks.length &&
        isDeckUsable(decks[currentIndex])) {
      return currentIndex;
    }
    for (var i = 0; i < decks.length; ++i) {
      if (isDeckUsable(decks[i])) {
        GameData.hero['battleDeckIndex'] = i;
        return i;
      }
    }
    GameData.hero['battleDeckIndex'] = -1;
    return -1;
  }

  static dynamic startRun() {
    final created = engine.hetu.invoke(
      'createSceneDungeonRun',
      namedArgs: {'routeId': defaultRouteId},
    );
    GameData.flags = GameData.game['flags'];
    return created;
  }

  static void goToRoom(int index) {
    final sceneIds = currentRoute['sceneIds'] as List;
    if (index < 0 || index >= sceneIds.length) return;
    run['currentSceneIndex'] = index;
  }

  static bool canGoNext() {
    final scene = currentScene;
    final room = currentRoom;
    if (scene == null || room == null) return false;
    final kind = scene['kind'];
    if (kind == 'merchant' || kind == 'rest') return true;
    return isBattleKind(kind) && room['battleWon'] == true;
  }

  static bool canReturnCamp() {
    return currentScene?['kind'] == 'boss' && currentRoom['battleWon'] == true;
  }

  static void recordBattleResult(bool result) {
    run['battleResult'] = result;
    run['battleRoomIndex'] = run['currentSceneIndex'];
    if (result) {
      currentRoom['battleWon'] = true;
    }
  }

  static Future<List> grantCurrentRoomRewards() async {
    final room = currentRoom;
    if (room['rewardGranted'] == true) return const [];
    final rewards = engine.hetu.invoke(
      'createSceneDungeonRewards',
      positionalArgs: [room, currentScene],
    ) as List;
    for (final item in rewards) {
      await engine.hetu.invoke(
        'acquire',
        namespace: 'Player',
        positionalArgs: [item],
      );
    }
    room['rewardGranted'] = true;
    engine.hetu.invoke('clearSceneDungeonBattleResult');
    return rewards;
  }

  static List createScavengeCandidates() {
    final room = currentRoom;
    final existing = room['scavengeCandidates'];
    if (existing is List) return existing;

    final enemy = room['enemy'];
    final candidates = <dynamic>[];
    final deckIndex = enemy['battleDeckIndex'] as int? ?? -1;
    final decks = enemy['battleDecks'] as List;
    if (deckIndex >= 0 && deckIndex < decks.length) {
      final library = enemy['cardLibrary'];
      for (final cardId in decks[deckIndex]['cards']) {
        final card = library[cardId];
        if (card != null &&
            GameLogic.checkCardRequirements(card, character: enemy) == null) {
          candidates.add(card);
        }
      }
    }
    candidates.shuffle(GameData.random);
    room['scavengeCandidates'] = candidates.take(3).toList();
    return room['scavengeCandidates'];
  }

  static dynamic createDungeonCardCopy(dynamic selectedCard) {
    final card = utils.deepCopy(selectedCard);
    card['id'] = randomUID();
    card['isDungeonCard'] = true;
    return card;
  }

  static void resolveScavenge({dynamic selectedCard}) {
    final room = currentRoom;
    if (room['scavengeResolved'] == true) return;
    if (selectedCard != null) {
      final card = createDungeonCardCopy(selectedCard);
      engine.hetu.invoke(
        'acquireCard',
        namespace: 'Player',
        positionalArgs: [card],
      );
      final deckIndex = GameData.hero['battleDeckIndex'] as int;
      GameData.hero['battleDecks'][deckIndex]['cards'].add(card['id']);
    }
    room['scavengeResolved'] = true;
  }

  static bool useRestAction(dynamic action) {
    return engine.hetu.invoke(
      'useSceneDungeonRest',
      positionalArgs: [currentRoom, action],
    ) as bool;
  }

  static void leaveAfterFailure() {
    engine.hetu.invoke('leaveSceneDungeonAfterFailure');
    gameState.isInteractable = true;
  }
}
