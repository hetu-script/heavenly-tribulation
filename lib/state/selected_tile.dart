import 'package:flutter/foundation.dart';
import 'package:samsara/tilemap.dart';

class SelectedTileState with ChangeNotifier {
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
  dynamic currentZone, currentNation, currentLocation;
  TileMapTerrain? currentTerrain;

  void updateTerrain({
    dynamic currentZoneData,
    dynamic currentNationData,
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

  void updateLocation(dynamic currentLocationData) {
    if (currentLocationData != currentLocation) {
      currentLocation = currentLocationData;
      notifyListeners();
    }
  }

  void clear() {
    currentZone = null;
    currentNation = null;
    currentTerrain = null;
    currentLocation = null;
    notifyListeners();
  }
}
