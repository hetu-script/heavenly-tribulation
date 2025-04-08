import 'package:flutter/material.dart';

import '../../../engine.dart';
import '../../game/ui.dart';
import '../../widgets/ui/menu_builder.dart';

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
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: GameUI.foregroundColor),
      ),
      child: PopupMenuButton<BattleDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => buildBattleDropMenu(),
      ),
    );
  }
}
