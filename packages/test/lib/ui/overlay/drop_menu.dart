import 'package:flutter/material.dart';

import '../../global.dart';

enum CardGameDropMenuItems { console, quit }

class CardGameDropMenu extends StatelessWidget {
  const CardGameDropMenu({super.key, required this.onSelected});

  final void Function(CardGameDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: Colors.white),
      ),
      child: PopupMenuButton<CardGameDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale['menu'],
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<CardGameDropMenuItems>>[
          PopupMenuItem<CardGameDropMenuItems>(
            height: 24.0,
            value: CardGameDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['console']),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<CardGameDropMenuItems>(
            height: 24.0,
            value: CardGameDropMenuItems.quit,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['quit']),
            ),
          ),
        ],
      ),
    );
  }
}
