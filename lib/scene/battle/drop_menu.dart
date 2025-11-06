import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/menu_builder.dart';

import '../../global.dart';
import '../../ui.dart';

enum BattleDropMenuItems { console, exit }

List<PopupMenuEntry<BattleDropMenuItems>> buildBattleDropMenu() {
  return [
    buildMenuItem(
      item: BattleDropMenuItems.console,
      name: engine.locale('console'),
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: BattleDropMenuItems.exit,
      name: engine.locale('exit'),
    ),
  ];
}

class BattleDropMenu extends StatelessWidget {
  const BattleDropMenu({super.key, required this.onSelected});

  final void Function(BattleDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GameUI.boxDecoration,
      child: PopupMenuButton<BattleDropMenuItems>(
        padding: const EdgeInsets.all(0),
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => buildBattleDropMenu(),
      ),
    );
  }
}
