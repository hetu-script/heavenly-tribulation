import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:samsara/hover_info.dart';

import '../ui.dart';
import '../data/game.dart';
import '../global.dart';
import '../state/states.dart';

/// 右上角悬浮文字面板
class JournalPanel extends StatefulWidget {
  const JournalPanel({super.key});

  @override
  State<JournalPanel> createState() => _JournalPanelState();
}

class _JournalPanelState extends State<JournalPanel> {
  String? hoveringId;

  @override
  Widget build(BuildContext context) {
    final activeJournals = context.watch<GameState>().activeJournals;

    return (activeJournals.isEmpty)
        ? SizedBox.shrink()
        : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...activeJournals.map(
                (journal) => GestureDetector(
                  onTap: () {
                    context.read<ViewPanelState>().toogle(ViewPanels.journal,
                        arguments: {'selectedId': journal['id']});
                  },
                  child: MouseRegion2(
                    cursor: GameUI.cursor.resolve({WidgetState.hovered}),
                    hitTestBehavior: HitTestBehavior.opaque,
                    onEnter: (rect) {
                      context.read<HoverContentState>().hide();
                      setState(() {
                        hoveringId = journal['id'];
                      });
                    },
                    onExit: () {
                      setState(() {
                        hoveringId = null;
                      });
                    },
                    child: Container(
                      width: 300,
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: hoveringId == journal['id']
                            ? Colors.black.withAlpha(50)
                            : Colors.transparent,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            journal['title'],
                            style: const TextStyle(
                              fontSize: 20.0,
                              color: Colors.yellow,
                              shadows: kTextShadow,
                            ),
                          ),
                          const Divider(),
                          Label(
                            journal['stages'][journal['stage']],
                            textAlign: TextAlign.left,
                            textStyle: const TextStyle(
                              fontSize: 16.0,
                              shadows: kTextShadow,
                            ),
                          ),
                          if (journal['quest']?['timeLimit'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    '${engine.locale('deadline')}: ',
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      shadows: kTextShadow,
                                    ),
                                  ),
                                  Text(
                                    GameData.getQuestTimeLimitDescription(
                                        journal),
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      shadows: kTextShadow,
                                      color: GameData.game['timestamp'] >
                                              (journal['timestamp'] +
                                                  journal['quest']['timeLimit'])
                                          ? Colors.red
                                          : Colors.yellow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }
}
