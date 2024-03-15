import 'package:flutter/foundation.dart';
import 'package:samsara/tilemap.dart';

class SelectedTileState with ChangeNotifier {
  dynamic hero, currentZone, currentLocation, currentNation;
  TileMapTerrain? currentTerrain;

  void updateHero(dynamic heroData) {
    assert(heroData != null);
    hero = heroData;
    notifyListeners();
  }

  void updateTerrain({
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

  void clearTerrain() {
    currentZone = null;
    currentNation = null;
    currentLocation = null;
    currentTerrain = null;
    notifyListeners();
  }
}
