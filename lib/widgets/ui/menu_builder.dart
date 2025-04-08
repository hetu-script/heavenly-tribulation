import 'package:flutter/material.dart';
import 'package:samsara/ui/popup_submenu_item.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../game/ui.dart';

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
  offset = const Offset(120, 0),
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

fluent.MenuFlyoutItem buildFluentMenuItem<T>({
  required BuildContext context,
  required String name,
  required T item,
  void Function(T)? onSelectedItem,
  Widget? leading,
  Widget? trailing,
  bool enabled = true,
}) {
  return fluent.MenuFlyoutItem(
    text: Text(
      name,
      style: !enabled ? TextStyle(color: GameUI.foregroundDiabled) : null,
    ),
    leading: leading,
    trailing: trailing,
    onPressed: enabled
        ? () {
            fluent.Flyout.of(context).close();
            onSelectedItem?.call(item);
          }
        : null,
  );
}

fluent.MenuFlyoutSubItem buildFluentSubMenuItem<T>({
  required String text,
  required Map<String, T> items,
  void Function(T value)? onSelected,
  Widget? leading,
}) {
  return fluent.MenuFlyoutSubItem(
    text: Text(text),
    leading: leading,
    items: (context) {
      return items.entries
          .map((e) => fluent.MenuFlyoutItem(
                text: Text(e.key),
                onPressed: () {
                  onSelected?.call(e.value);
                },
              ))
          .toList();
    },
  );
}

final fluent.FlyoutController flyoutController = fluent.FlyoutController();

void showFluentMenu<T>({
  fluent.FlyoutController? controller,
  Offset? position,
  fluent.FlyoutPlacementMode placementMode =
      fluent.FlyoutPlacementMode.bottomLeft,
  required Widget Function(BuildContext) builder,
}) {
  final ctrl = controller ?? flyoutController;
  ctrl.showFlyout(
    autoModeConfiguration: fluent.FlyoutAutoConfiguration(
      preferredMode: placementMode,
    ),
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    position: position,
    builder: builder,
  );
}
