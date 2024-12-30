import 'package:flutter/material.dart';

import '../../engine.dart';
import '../../ui.dart';
import '../../view/menu_item_builder.dart';

enum WorldMapDropMenuItems {
  save,
  saveAs,
  info,
  viewNone,
  viewZones,
  viewOrganizations,
  console,
  exit
}

List<PopupMenuEntry<WorldMapDropMenuItems>> buildWorldMapDropMenu() {
  return [
    buildMenuItem(
      item: WorldMapDropMenuItems.save,
      name: engine.locale('save'),
    ),
    buildMenuItem(
      item: WorldMapDropMenuItems.saveAs,
      name: engine.locale('saveAs'),
    ),
    const PopupMenuDivider(),
    buildSubMenuItem(
      items: {
        engine.locale('none'): WorldMapDropMenuItems.viewNone,
        engine.locale('zone'): WorldMapDropMenuItems.viewZones,
        engine.locale('organization'): WorldMapDropMenuItems.viewOrganizations,
      },
      name: engine.locale('view'),
      offset: const Offset(-160, 0),
    ),
    buildMenuItem(
      item: WorldMapDropMenuItems.info,
      name: engine.locale('info'),
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: WorldMapDropMenuItems.console,
      name: engine.locale('console'),
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: WorldMapDropMenuItems.exit,
      name: engine.locale('exit'),
    ),
  ];
}

class WorldMapDropMenu extends StatelessWidget {
  const WorldMapDropMenu({super.key, required this.onSelected});

  final void Function(WorldMapDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: kForegroundColor),
      ),
      child: PopupMenuButton<WorldMapDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => buildWorldMapDropMenu(),
      ),
    );
  }
}
