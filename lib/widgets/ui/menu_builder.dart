import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/popup_submenu_item.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../ui.dart';

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

/// create a list of MenuFlyoutItemBase
/// use `---` for separator
List<fluent.MenuFlyoutItemBase> buildFluentMenuItems<T>({
  required Map<dynamic, dynamic> items,
  void Function(T)? onSelectedItem,
}) {
  return items.keys.map((key) {
    final text = key.toString();
    final value = items[key];
    if (text.startsWith('___')) {
      return fluent.MenuFlyoutSeparator();
    } else if (value is Map<String, T>) {
      return fluent.MenuFlyoutSubItem(
        text: Text(text),
        items: (context) {
          return value.entries
              .map((entry) => fluent.MenuFlyoutItem(
                    text: Text(entry.key),
                    onPressed: () {
                      onSelectedItem?.call(entry.value);
                    },
                  ))
              .toList();
        },
      );
    } else if (value is T) {
      return fluent.MenuFlyoutItem(
        text: Text(text),
        onPressed: () {
          onSelectedItem?.call(items[text] as T);
        },
      );
    } else {
      return fluent.MenuFlyoutItem(
        text: Text('invalid menu item: {$text : $value}'),
        onPressed: () {},
      );
    }
  }).toList();
}

fluent.MenuFlyoutItem buildFluentMenuItem<T>({
  required String text,
  required T value,
  void Function(T)? onSelectedItem,
  Widget? leading,
  Widget? trailing,
  bool enabled = true,
}) {
  return fluent.MenuFlyoutItem(
    text: Text(
      text,
      style: !enabled ? TextStyle(color: GameUI.foregroundDiabled) : null,
    ),
    leading: leading,
    trailing: trailing,
    onPressed: enabled ? () => onSelectedItem?.call(value) : null,
    closeAfterClick: true,
  );
}

fluent.MenuFlyoutSubItem buildFluentSubMenuItem<T>({
  required String text,
  required Map<String, T> items,
  void Function(T value)? onSelectedItem,
  Widget? leading,
}) {
  return fluent.MenuFlyoutSubItem(
    text: Text(text),
    leading: leading,
    items: (context) {
      return items.entries
          .map((e) => fluent.MenuFlyoutItem(
                text: Text(e.key),
                onPressed: () => onSelectedItem?.call(e.value),
              ))
          .toList();
    },
  );
}

final fluent.FlyoutController globalFlyoutController =
    fluent.FlyoutController();

void showFluentMenu<T>({
  fluent.FlyoutController? controller,
  Offset? position,
  fluent.FlyoutPlacementMode placementMode =
      fluent.FlyoutPlacementMode.bottomLeft,
  required Map<dynamic, dynamic> items,
  required FutureOr<void> Function(T) onSelectedItem,
  NavigatorState? navigatorKey,
}) {
  final ctrl = controller ?? globalFlyoutController;
  ctrl.showFlyout(
    autoModeConfiguration: fluent.FlyoutAutoConfiguration(
      preferredMode: placementMode,
    ),
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    navigatorKey: navigatorKey,
    position: position,
    builder: (context) {
      return fluent.MenuFlyout(
        items: buildFluentMenuItems<T>(
          items: items,
          onSelectedItem: (item) {
            fluent.Flyout.of(context).close();
            if (item == null) return;
            onSelectedItem.call(item);
          },
        ),
      );
    },
  );
}
