import 'package:flutter/material.dart';
import 'package:samsara/ui/popup_submenu_item.dart';

PopupMenuItem<T> buildMenuItem<T>({
  required T item,
  required String name,
  void Function(T item)? onSelectedItem,
  double height = 24.0,
  double width = 140.0,
  bool enabled = true,
}) {
  return PopupMenuItem<T>(
    enabled: enabled,
    height: height,
    value: item,
    child: Container(
      alignment: Alignment.centerLeft,
      width: width,
      child: Text(name),
    ),
    onTap: () => onSelectedItem?.call(item),
  );
}

PopupSubMenuItem<T> buildSubMenuItem<T>({
  required Map<String, T> items,
  required String name,
  required Offset offset,
  void Function(T item)? onSelectedItem,
  double height = 24.0,
  double width = 120.0,
  Map<String, bool> enabled = const {},
}) {
  return PopupSubMenuItem<T>(
    title: name,
    height: height,
    width: width,
    offset: offset,
    items: items,
    enabled: enabled,
    onSelected: onSelectedItem,
  );
}
