import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/view_panels.dart';
import '../state/game_update.dart';
import '../game/ui.dart';
import '../engine.dart';
import 'history_list.dart';
import '../state/hover_content.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    required this.width,
    required this.height,
  });

  final double height, width;

  @override
  Widget build(BuildContext context) {
    final dateString = context.watch<GameTimestampState>().gameDateTimeString;

    return Container(
      width: width,
      height: height,
      color: GameUI.backgroundColor2,
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3.0),
                child: Text(dateString),
              ),
            ],
          ),
          SizedBox(
            width: 480,
            height: 46,
            child: HeroAndGlobalHistoryList(
              onTapUp: () {
                context
                    .read<ViewPanelState>()
                    .toogle(ViewPanels.characterMemory);
              },
              onMouseEnter: (rect) {
                context
                    .read<HoverContentState>()
                    .show(engine.locale('history'), rect);
              },
              onMouseExit: () {
                context.read<HoverContentState>().hide();
              },
            ),
          ),
        ],
      ),
    );
  }
}
