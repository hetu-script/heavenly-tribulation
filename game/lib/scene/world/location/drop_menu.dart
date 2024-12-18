import 'package:flutter/material.dart';

import '../../../config.dart';

enum LocationSceneDropMenuItems { console, quit }

class LocationSceneDropMenu extends StatelessWidget {
  const LocationSceneDropMenu({super.key, required this.onSelected});

  final void Function(LocationSceneDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: PopupMenuButton<LocationSceneDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<LocationSceneDropMenuItems>>[
          PopupMenuItem<LocationSceneDropMenuItems>(
            height: 24.0,
            value: LocationSceneDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale('console')),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<LocationSceneDropMenuItems>(
            height: 24.0,
            value: LocationSceneDropMenuItems.quit,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale('quit')),
            ),
          ),
        ],
      ),
    );
  }
}
