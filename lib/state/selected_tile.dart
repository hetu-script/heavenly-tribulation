import 'package:flutter/foundation.dart';
import 'package:samsara/tilemap.dart';

class SelectedTileState with ChangeNotifier {
  dynamic currentZone, currentNation;
  TileMapTerrain? currentTerrain;

  void update({
    dynamic currentZoneData,
    dynamic currentNationData,
    dynamic currentLocationData,
    TileMapTerrain? currentTerrainObject,
  }) {
    currentZone = currentZoneData;
    currentNation = currentNationData;
    currentTerrain = currentTerrainObject;
    notifyListeners();
  }

  void clear() {
    currentZone = null;
    currentNation = null;
    currentTerrain = null;
    notifyListeners();
  }
}

class HeroTileState with ChangeNotifier {
  dynamic currentZone, currentNation;
  TileMapTerrain? currentTerrain;
  String? currentScene;

  void update({
    dynamic currentZoneData,
    dynamic currentNationData,
    dynamic currentLocationData,
    TileMapTerrain? currentTerrainData,
  }) {
    bool changed = false;
    if (currentZoneData != currentZone) {
      currentZone = currentZoneData;
      changed = true;
    }
    if (currentNationData != currentNation) {
      currentNation = currentNationData;
      changed = true;
    }
    if (currentTerrainData != currentTerrain) {
      currentTerrain = currentTerrainData;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void updateScene(sceneId) {
    if (currentScene != sceneId) {
      currentScene = sceneId;
      notifyListeners();
    }
  }

  void clear() {
    currentZone = null;
    currentNation = null;
    currentTerrain = null;
    // currentLocation = null;
    currentScene = null;
    notifyListeners();
  }
}
