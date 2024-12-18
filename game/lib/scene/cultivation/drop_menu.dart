import 'package:flutter/material.dart';

import '../../config.dart';

enum CultivationDropMenuItems { console, quit }

class CultivationDropMenu extends StatelessWidget {
  const CultivationDropMenu({super.key, required this.onSelected});

  final void Function(CultivationDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: PopupMenuButton<CultivationDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<CultivationDropMenuItems>>[
          PopupMenuItem<CultivationDropMenuItems>(
            height: 24.0,
            value: CultivationDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale('console')),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<CultivationDropMenuItems>(
            height: 24.0,
            value: CultivationDropMenuItems.quit,
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
