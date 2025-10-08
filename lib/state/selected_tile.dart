import 'package:flutter/foundation.dart';
import 'package:samsara/tilemap.dart';

import '../engine.dart';

class SelectedPositionState with ChangeNotifier {
  dynamic currentZone, currentNation, currentLocation;
  TileMapTerrain? currentTerrain;

  void update({
    dynamic currentZoneData,
    dynamic currentNationData,
    dynamic currentLocationData,
    TileMapTerrain? currentTerrainObject,
  }) {
    currentZone = currentZoneData;
    currentNation = currentNationData;
    currentLocation = currentLocationData;
    currentTerrain = currentTerrainObject;
    notifyListeners();
  }

  void clear() {
    currentZone = null;
    currentNation = null;
    currentLocation = null;
    currentTerrain = null;
    notifyListeners();
  }
}

class HeroPositionState with ChangeNotifier {
  dynamic currentZone, currentNation, currentLocation, currentDungeon;
  TileMapTerrain? currentTerrain;

  void updateTerrain({
    dynamic currentZoneData,
    dynamic currentNationData,
    TileMapTerrain? currentTerrainData,
  }) {
    bool changed = false;
    if (currentZone != currentZoneData) {
      currentZone = currentZoneData;
      changed = true;
    }
    if (currentNation != currentNationData) {
      currentNation = currentNationData;
      changed = true;
    }
    if (currentTerrain != currentTerrainData) {
      currentTerrain = currentTerrainData;
      changed = true;
      if (currentTerrain != null) {
        engine.hetu.assign('terrain', currentTerrain!.data);
      }
    }
    if (changed) {
      notifyListeners();
    }
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

  void clear() {
    currentZone = null;
    currentNation = null;
    currentTerrain = null;
    currentLocation = null;
    currentDungeon = null;
    notifyListeners();
  }
}
