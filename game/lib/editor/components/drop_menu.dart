import 'package:flutter/material.dart';

// import 'package:samsara/ui/popup_submenu_item.dart';

import '../../config.dart';
import '../../scene/menu_item_builder.dart';

enum WorldEditorDropMenuItems { expandWorld, save, saveAs, console, exit }

List<PopupMenuEntry<WorldEditorDropMenuItems>> buildWorldEditorDropMenuItems() {
  return [
    buildMenuItem(
      item: WorldEditorDropMenuItems.expandWorld,
      name: engine.locale('expandWorld'),
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: WorldEditorDropMenuItems.save,
      name: engine.locale('save'),
    ),
    buildMenuItem(
      item: WorldEditorDropMenuItems.saveAs,
      name: engine.locale('saveAs'),
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: WorldEditorDropMenuItems.console,
      name: engine.locale('console'),
    ),
    buildMenuItem(
      item: WorldEditorDropMenuItems.exit,
      name: engine.locale('exit'),
    ),
  ];
}

class WorldEditorDropMenu extends StatelessWidget {
  const WorldEditorDropMenu({super.key, required this.onSelected});

  final void Function(WorldEditorDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: kForegroundColor),
      ),
      child: PopupMenuButton<WorldEditorDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => buildWorldEditorDropMenuItems(),
      ),
    );
  }
}
