import 'package:flutter/material.dart';

import '../../shared/popup_submenu_item.dart';
import '../../../global.dart';

enum DropMenuItems { info, viewNone, viewZones, viewNations, exit }

class DropMenu extends StatelessWidget {
  const DropMenu({Key? key, required this.onSelected}) : super(key: key);

  final void Function(DropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: PopupMenuButton<DropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale['menu'],
        onSelected: onSelected,
        itemBuilder: (BuildContext context) => <PopupMenuEntry<DropMenuItems>>[
          PopupMenuItem<DropMenuItems>(
            value: DropMenuItems.info,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['info']),
            ),
          ),
          PopupSubMenuItem<DropMenuItems>(
            title: engine.locale['view'],
            offset: const Offset(-160, 0),
            items: {
              engine.locale['none']: DropMenuItems.viewNone,
              engine.locale['zone']: DropMenuItems.viewZones,
              engine.locale['nation']: DropMenuItems.viewNations,
            },
          ),
          const PopupMenuDivider(),
          PopupMenuItem<DropMenuItems>(
            value: DropMenuItems.exit,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['exitGame']),
            ),
          ),
        ],
      ),
    );
  }
}
