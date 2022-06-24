import 'package:flutter/material.dart';

import '../../shared/popup_submenu_item.dart';
import '../../../global.dart';

enum DropMenuItems { console, giveUp }

class DropMenu extends StatelessWidget {
  const DropMenu({super.key, required this.onSelected});

  final void Function(DropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: kForegroundColor),
      ),
      child: PopupMenuButton<DropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale['menu'],
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<DropMenuItems>>[
          PopupMenuItem<DropMenuItems>(
            height: 24.0,
            value: DropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['console']),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<DropMenuItems>(
            height: 24.0,
            value: DropMenuItems.giveUp,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['giveUp']),
            ),
          ),
        ],
      ),
    );
  }
}
