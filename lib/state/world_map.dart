import 'package:flutter/foundation.dart';
import 'package:samsara/tilemap.dart';

class WorldMapState with ChangeNotifier {
  dynamic selectedZone, selectedNation, selectedLocation;
  TileMapTerrain? selectedTerrain;
  String? selectedToolId;

  void updateSelectedTerrain({
    dynamic currentZoneData,
    dynamic currentNationData,
    TileMapTerrain? currentTerrainObject,
    dynamic currentLocationData,
  }) {
    selectedZone = currentZoneData;
    selectedNation = currentNationData;
    selectedTerrain = currentTerrainObject;
    selectedLocation = currentLocationData;
    notifyListeners();
  }

  void clearTerrain() {
    selectedZone = null;
    selectedNation = null;
    selectedTerrain = null;
    selectedLocation = null;
    notifyListeners();
  }

  void clearTool() {
    selectedToolId = null;
    notifyListeners();
  }

  void selectTool(String item) {
    selectedToolId = item;
    notifyListeners();
  }
}
