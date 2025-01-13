import 'package:flutter/material.dart';

enum ViewPanels {
  characterProfile,
  characterMemory,
  characterQuest,
  characterDetails,
  itemSelect,
}

class ViewPanelState with ChangeNotifier {
  final Map<ViewPanels, Map<String, dynamic>> visiblePanels = {};

  void toogle(ViewPanels panel, {Map<String, dynamic> arguments = const {}}) {
    if (visiblePanels.containsKey(panel)) {
      visiblePanels.remove(panel);
    } else {
      visiblePanels[panel] = arguments;
    }
    notifyListeners();
  }

  void clearAll() {
    visiblePanels.clear();
    notifyListeners();
  }

  void setUpFront(ViewPanels panel) {
    assert(visiblePanels.containsKey(panel));
    final arguments = visiblePanels[panel]!;
    visiblePanels.remove(panel);
    visiblePanels[panel] = arguments;
    notifyListeners();
  }

  void hide(ViewPanels panel) {
    visiblePanels.remove(panel);
    notifyListeners();
  }
}

class PanelPositionState with ChangeNotifier {
  final Map<ViewPanels, Offset> panelPositions = {};

  Offset? get(ViewPanels panel) {
    return panelPositions[panel];
  }

  void update(ViewPanels panel, Offset offset) {
    assert(panelPositions.containsKey(panel));
    final current = panelPositions[panel]!;
    panelPositions[panel] = current + offset;
    notifyListeners();
  }
}
