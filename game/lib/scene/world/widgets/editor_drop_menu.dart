import 'package:flutter/material.dart';

// import 'package:samsara/ui/popup_submenu_item.dart';

import '../../../engine.dart';
import '../../../widgets/menu_item_builder.dart';
import '../../../game/ui.dart';

enum WorldEditorDropMenuItems {
  addWorld,
  switchWorld,
  deleteWorld,
  expandWorld,
  save,
  saveAs,
  viewNone,
  viewZones,
  viewOrganizations,
  reloadGameData,
  reloadModules,
  console,
  exit,
}

List<PopupMenuEntry<WorldEditorDropMenuItems>> buildWorldEditorDropMenuItems() {
  return [
    buildMenuItem(
      item: WorldEditorDropMenuItems.addWorld,
      name: engine.locale('addWorld'),
    ),
    buildMenuItem(
      item: WorldEditorDropMenuItems.switchWorld,
      name: engine.locale('switchWorld'),
    ),
    buildMenuItem(
      item: WorldEditorDropMenuItems.deleteWorld,
      name: engine.locale('deleteWorld'),
    ),
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
    buildSubMenuItem(
      items: {
        engine.locale('none'): WorldEditorDropMenuItems.viewNone,
        engine.locale('zone'): WorldEditorDropMenuItems.viewZones,
        engine.locale('organization'):
            WorldEditorDropMenuItems.viewOrganizations,
      },
      name: engine.locale('view'),
      offset: const Offset(-160, 0),
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: WorldEditorDropMenuItems.reloadGameData,
      name: engine.locale('reloadGameData'),
    ),
    buildMenuItem(
      item: WorldEditorDropMenuItems.reloadModules,
      name: engine.locale('reloadModules'),
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
  const WorldEditorDropMenu({
    super.key,
    required this.onSelected,
  });

  final void Function(WorldEditorDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: GameUI.foregroundColor),
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
