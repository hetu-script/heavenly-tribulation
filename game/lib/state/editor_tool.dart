import 'package:flutter/foundation.dart';

enum EditorToolItems {
  none,
  delete,
  nonInteractable,
  sea,
  plain,
  forest,
  mountain,
  farmfield,

  // shelf,

  fishTile,
  stormTile,
  spiritTile,

  city,
  portalArray,
  dungeon,

  dungeonStoneGate,
  dungeonStonePavedTile,

  portal,
  glowingTile,
  pressureTile,

  treasureBox,
}

EditorToolItems getEditorToolItem(String? id) {
  return EditorToolItems.values.firstWhere((element) => element.name == id,
      orElse: () => EditorToolItems.none);
}

class EditorToolState with ChangeNotifier {
  EditorToolItems item = EditorToolItems.none;

  void reset() {
    item = EditorToolItems.none;
    notifyListeners();
  }

  void selectItem(EditorToolItems item) {
    this.item = item;
    notifyListeners();
  }
}
