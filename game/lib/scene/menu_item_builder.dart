import 'package:flutter/material.dart';
import 'package:samsara/ui/popup_submenu_item.dart';

PopupMenuItem<T> buildMenuItem<T>({
  required T item,
  required String name,
  void Function(T item)? onItemPressed,
  double height = 24.0,
  double width = 140.0,
}) {
  return PopupMenuItem<T>(
    height: height,
    value: item,
    child: Container(
      alignment: Alignment.centerLeft,
      width: width,
      child: Text(name),
    ),
    onTap: () => onItemPressed?.call(item),
  );
}

PopupSubMenuItem<T> buildSubMenuItem<T>({
  required Map<String, T> items,
  required String name,
  required Offset offset,
  void Function(T item)? onItemPressed,
  double height = 24.0,
  double width = 120.0,
}) {
  return PopupSubMenuItem<T>(
    height: height,
    width: width,
    title: name,
    offset: offset,
    items: items,
  );
}
