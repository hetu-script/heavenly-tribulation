import 'package:flutter/foundation.dart';

class CraftState with ChangeNotifier {
  dynamic equipment;
  dynamic card;

  void setCraftingEquipment(dynamic equipmentData) {
    if (equipment != equipmentData) {
      equipment = equipmentData;
      card = null;
      notifyListeners();
    }
  }

  void setCraftingCard(dynamic cardData) {
    if (card != cardData) {
      card = cardData;
      equipment = null;
      notifyListeners();
    }
  }

  void clear() {
    if (equipment == null && card == null) return;

    equipment = null;
    card = null;
    notifyListeners();
  }
}
