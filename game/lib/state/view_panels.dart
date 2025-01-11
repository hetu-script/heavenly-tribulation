import 'package:flutter/material.dart';

enum ViewPanels {
  characterProfile,
  characterMemory,
  characterQuest,
  characterDetails,
  itemSelect,
}

class ViewPanelState with ChangeNotifier {
  final Map<ViewPanels, dynamic> visiblePanels = {};

  void toogle(ViewPanels panel, [dynamic args]) {
    if (visiblePanels.containsKey(panel)) {
      visiblePanels.remove(panel);
    } else {
      visiblePanels[panel] = args ?? true;
    }
    notifyListeners();
  }

  void clearAll() {
    visiblePanels.clear();
    notifyListeners();
  }

  void setUpFront(ViewPanels panel) {
    assert(visiblePanels.containsKey(panel));
    final args = visiblePanels[panel];
    visiblePanels.remove(panel);
    visiblePanels[panel] = args;
    notifyListeners();
  }

  void hide(ViewPanels panel) {
    visiblePanels.remove(panel);
    notifyListeners();
  }
}

class PanelPositionState with ChangeNotifier {
  final Map<ViewPanels, Offset> panelPositions = {};

  void updatePosition(ViewPanels panel, Offset offset) {
    assert(panelPositions.containsKey(panel));
    final current = panelPositions[panel]!;
    panelPositions[panel] = current + offset;
    notifyListeners();
  }
}
