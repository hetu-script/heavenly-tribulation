import 'package:flutter/material.dart';

import '../../engine.dart';

enum BattleDropMenuItems { console, quit }

class BattleDropMenu extends StatelessWidget {
  const BattleDropMenu({super.key, required this.onSelected});

  final void Function(BattleDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: PopupMenuButton<BattleDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<BattleDropMenuItems>>[
          PopupMenuItem<BattleDropMenuItems>(
            height: 24.0,
            value: BattleDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale('console')),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<BattleDropMenuItems>(
            height: 24.0,
            value: BattleDropMenuItems.quit,
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
