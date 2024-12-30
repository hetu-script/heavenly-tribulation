import 'package:flutter/material.dart';

import '../../../engine.dart';

enum SiteViewDropMenuItems { console, quit }

class SiteViewDropMenu extends StatelessWidget {
  const SiteViewDropMenu({super.key, required this.onSelected});

  final void Function(SiteViewDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: PopupMenuButton<SiteViewDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale('menu'),
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<SiteViewDropMenuItems>>[
          PopupMenuItem<SiteViewDropMenuItems>(
            height: 24.0,
            value: SiteViewDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale('console')),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<SiteViewDropMenuItems>(
            height: 24.0,
            value: SiteViewDropMenuItems.quit,
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
