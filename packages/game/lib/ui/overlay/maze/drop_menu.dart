import 'package:flutter/material.dart';

// import '../../shared/popup_submenu_item.dart';
import '../../../global.dart';

enum MazeDropMenuItems { console, quit }

class MazeDropMenu extends StatelessWidget {
  const MazeDropMenu({super.key, required this.onSelected});

  final void Function(MazeDropMenuItems)? onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
        border: Border.all(color: kForegroundColor),
      ),
      child: PopupMenuButton<MazeDropMenuItems>(
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open),
        tooltip: engine.locale['menu'],
        onSelected: onSelected,
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<MazeDropMenuItems>>[
          PopupMenuItem<MazeDropMenuItems>(
            height: 24.0,
            value: MazeDropMenuItems.console,
            child: Container(
              alignment: Alignment.centerLeft,
              width: 100,
              child: Text(engine.locale['console']),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<MazeDropMenuItems>(
            height: 24.0,
            value: MazeDropMenuItems.quit,
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
