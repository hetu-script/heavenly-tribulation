import 'package:flutter/material.dart';

enum ViewPanels {
  profile,
  memoryAndBond,
  journal,
  statsAndItem,
  workbench,
  alchemy,
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

class ViewPanelPositionState with ChangeNotifier {
  final Map<ViewPanels, Offset> panelPositions = {};

  Offset? get(ViewPanels panel) {
    return panelPositions[panel];
  }

  void set(ViewPanels panel, Offset offset) {
    panelPositions[panel] = offset;
  }

  void update(ViewPanels panel, Offset offset) {
    if (!panelPositions.containsKey(panel)) return;
    final current = panelPositions[panel]!;
    panelPositions[panel] = current + offset;
    notifyListeners();
  }
}
