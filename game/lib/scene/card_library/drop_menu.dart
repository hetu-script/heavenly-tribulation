import 'package:flutter/material.dart';

import '../../config.dart';

enum DeckbuildingDropMenuItems { console, quit }

class DeckbuildingDropMenu extends StatelessWidget {
  const DeckbuildingDropMenu({super.key, required this.onSelected});

  final void Function(DeckbuildingDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: PopupMenuButton<DeckbuildingDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<DeckbuildingDropMenuItems>>[
          PopupMenuItem<DeckbuildingDropMenuItems>(
            height: 24.0,
            value: DeckbuildingDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale('console')),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<DeckbuildingDropMenuItems>(
            height: 24.0,
            value: DeckbuildingDropMenuItems.quit,
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
