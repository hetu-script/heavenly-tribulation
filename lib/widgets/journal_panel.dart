import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
// import 'package:samsara/richtext.dart';

import '../ui.dart';
import '../../state/game_update.dart';
import '../../state/view_panels.dart';
import '../../game/game.dart';
import '../../engine.dart';

/// 右上角悬浮文字面板
class JournalPanel extends StatefulWidget {
  const JournalPanel({super.key});

  @override
  State<JournalPanel> createState() => _JournalPanelState();
}

class _JournalPanelState extends State<JournalPanel> {
  String? selectedId;

  @override
  Widget build(BuildContext context) {
    final activeJournals = context.watch<HeroJournalUpdate>().activeJournals;

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
                  child: MouseRegion(
                    cursor: FlutterCustomMemoryImageCursor(key: 'click'),
                    onEnter: (_) {
                      setState(() {
                        selectedId = journal['id'];
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        selectedId = null;
                      });
                    },
                    child: Container(
                      width: 300,
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: selectedId == journal['id']
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
                          Text(
                            journal['stages'][journal['stage']],
                            style: const TextStyle(
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
                                        journal['quest']?['timeLimit']),
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
