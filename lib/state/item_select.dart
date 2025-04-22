import 'package:flutter/foundation.dart';

class ItemSelectState with ChangeNotifier {
  bool showItemSelect = false;
  dynamic character;
  String? title;
  dynamic filter;
  bool multiSelect = false;
  void Function(Iterable)? onSelect;
  Iterable? selectedItems;

  void show(
    dynamic character, {
    String? title,
    dynamic filter,
    bool multiSelect = false,
    void Function(Iterable)? onSelect,
    Iterable? selectedItems,
  }) {
    this.character = character;
    this.title = title;
    this.filter = filter;
    this.multiSelect = multiSelect;
    this.onSelect = onSelect;
    this.selectedItems = selectedItems;
    showItemSelect = true;
    notifyListeners();
  }

  void close() {
    character = null;
    title = null;
    filter = null;
    multiSelect = false;
    onSelect = null;
    selectedItems = null;
    showItemSelect = false;
    notifyListeners();
  }
}
