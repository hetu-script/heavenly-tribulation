import 'package:flutter/foundation.dart';
import 'package:samsara/extensions.dart';
import 'package:samsara/tilemap.dart';

import '../logic/logic.dart';
import '../data/game.dart';
import '../global.dart';

class GameState with ChangeNotifier {
  bool isInteractable = true;
  bool isStandby = false;

  bool isUIVisible = false;
  String datetimeString = '';
  int timestamp = 0;
  List<dynamic> activeJournals = [];
  List<dynamic> incidents = [];
  Iterable<dynamic> npcs = [];
  dynamic currentZone, currentNation, currentLocation, currentDungeon;
  TileMapTerrain? currentTerrain;

  void setUIVisible([bool value = true]) {
    if (isUIVisible == value) return;
    isUIVisible = value;
    notifyListeners();
  }

  void reset() {
    setUIVisible(true);
    clearTerrain();
    updateDatetime();
    updateHistory();
    updateActiveJournals();
    updateLocation();
    updateDungeon();
    updateNpcs();
  }

  void updateDatetime({int? timestamp, String? datetimeString}) {
    if (timestamp != null && datetimeString != null) {
      this.timestamp = timestamp;
      this.datetimeString = datetimeString;
    } else {
      (timestamp, datetimeString) = GameLogic.calculateTimestamp();
      this.timestamp = timestamp;
      this.datetimeString = datetimeString;
    }
    notifyListeners();
  }

  (int, String) getDatetime() {
    return (timestamp, datetimeString);
  }

  void updateActiveJournals([List? journals]) {
    if (journals == null && GameData.hero != null) {
      journals = engine.hetu.invoke('getActiveJournals', namespace: 'Player');
    }
    activeJournals = journals ?? const [];
    notifyListeners();
  }

  void updateHistory({int limit = 20}) {
    final String? heroId = GameData.hero?['id'];
    if (heroId == null) return;

    incidents.clear();
    if (GameData.history != null) {
      for (final incident in (GameData.history.values as Iterable).reversed) {
        if (incident['subjectId'] == heroId ||
            incident['objectId'] == heroId ||
            incident['isGlobal']) {
          incidents.add(incident);
          if (limit > 0 && incidents.length >= limit) {
            break;
          }
        }
      }
      incidents = incidents.reversed.toList();
    }
    notifyListeners();
  }

  void hideNpc(String id) {
    npcs = npcs.where((npc) => npc['id'] != id);
    notifyListeners();
  }

  void updateNpcs([Iterable characters = const []]) {
    npcs = characters;
    notifyListeners();
  }

  void updateTerrain({
    dynamic currentZoneData,
    dynamic currentNationData,
    TileMapTerrain? currentTerrainData,
    bool notify = true,
  }) {
    bool changed = false;
    if (currentZone != currentZoneData) {
      changed = true;
      currentZone = currentZoneData;
    }
    if (currentNation != currentNationData) {
      changed = true;
      currentNation = currentNationData;
    }
    if (currentTerrain != currentTerrainData) {
      changed = true;
      currentTerrain = currentTerrainData;
      if (currentTerrain != null) {
        engine.hetu.assign('terrain', currentTerrain!.data);
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void clearTerrain() {
    currentZone = null;
    currentNation = null;
    currentTerrain = null;
    notifyListeners();
  }

  void updateLocation([dynamic currentLocationData]) {
    if (currentLocationData != currentLocation) {
      currentLocation = currentLocationData;
      notifyListeners();
    }
  }

  void updateDungeon([dynamic currentDungeonData]) {
    if (currentDungeonData != currentDungeon) {
      currentDungeon = currentDungeonData;
      notifyListeners();
    }
  }
}
