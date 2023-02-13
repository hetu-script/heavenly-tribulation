import 'package:flutter/material.dart';

import 'package:samsara/ui/shared/popup_submenu_item.dart';
import '../../../global.dart';

enum WorldMapDropMenuItems {
  info,
  viewNone,
  viewZones,
  viewNations,
  console,
  exit
}

class WorldMapDropMenu extends StatelessWidget {
  const WorldMapDropMenu({super.key, required this.onSelected});

  final void Function(WorldMapDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: kForegroundColor),
      ),
      child: PopupMenuButton<WorldMapDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale['menu'],
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<WorldMapDropMenuItems>>[
          PopupMenuItem<WorldMapDropMenuItems>(
            height: 24.0,
            value: WorldMapDropMenuItems.info,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['info']),
            ),
          ),
          PopupSubMenuItem<WorldMapDropMenuItems>(
            title: engine.locale['view'],
            offset: const Offset(-160, 0),
            items: {
              engine.locale['none']: WorldMapDropMenuItems.viewNone,
              engine.locale['zone']: WorldMapDropMenuItems.viewZones,
              engine.locale['nation']: WorldMapDropMenuItems.viewNations,
            },
          ),
          PopupMenuItem<WorldMapDropMenuItems>(
            height: 24.0,
            value: WorldMapDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['console']),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<WorldMapDropMenuItems>(
            height: 24.0,
            value: WorldMapDropMenuItems.exit,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['saveAndExitGame']),
            ),
          ),
        ],
      ),
    );
  }
}
