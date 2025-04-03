import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';
// import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:samsara/richtext.dart';

import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import '../common.dart';
import '../../state/view_panels.dart';
import '../draggable_panel.dart';

enum QuestViewMode { all, ongoing, finished }

class QuestView extends StatefulWidget {
  const QuestView({
    super.key,
    this.characterId,
    this.characterData,
    this.mode = InformationViewMode.view,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;

  final dynamic characterData;

  final InformationViewMode mode;

  @override
  State<QuestView> createState() => _QuestViewState();
}

class _QuestViewState extends State<QuestView> {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  dynamic _characterData, _questsData;

  // QuestViewMode _selectedMode = QuestViewMode.all;

  String? _selectedQuestId;
  dynamic _selectedQuest;

  @override
  void initState() {
    super.initState();

    assert(widget.characterId != null || widget.characterData != null);
    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      _characterData = GameData.getCharacter(widget.characterId!);
    }
    _questsData = _characterData['quests'];

    if (_questsData.isNotEmpty) {
      _selectedQuest = _questsData.values.last;
      _selectedQuestId = _selectedQuest['id'];
    }
  }

  Widget _buildQuestDescription(dynamic questData) {
    final List<Widget> descriptions = [];
    final String questId = questData['id'];
    final List sequence = questData['sequence'];

    for (var index in sequence) {
      descriptions.add(
        RichText(
          text: TextSpan(
            children: buildFlutterRichText(
              engine.locale('${questId}_stage$index'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }
    return ScrollConfiguration(
      behavior: MaterialScrollBehavior(),
      child: SizedBox(
        width: 300.0,
        height: 290.0,
        child: SingleChildScrollView(
          child: ListView(
            shrinkWrap: true,
            children: descriptions,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final position = context
            .watch<ViewPanelPositionState>()
            .get(ViewPanels.characterQuest) ??
        GameUI.detailsWindowPosition;

    return DraggablePanel(
      title: engine.locale('quest'),
      position: position,
      width: GameUI.profileWindowSize.x,
      height: 400.0,
      onTapDown: (offset) {
        context.read<ViewPanelState>().setUpFront(ViewPanels.characterQuest);
        context
            .read<ViewPanelPositionState>()
            .set(ViewPanels.characterQuest, position);
      },
      onDragUpdate: (details) {
        context.read<ViewPanelPositionState>().update(
              ViewPanels.characterQuest,
              details.delta,
            );
      },
      onClose: () {
        context.read<ViewPanelState>().hide(ViewPanels.characterQuest);
      },
      child: Container(
        width: 630.0,
        height: 350.0,
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SizedBox(
            //   width: 300.0,
            //   child: Column(
            //     children: [
            // SegmentedButton<QuestViewMode>(
            //   segments: <ButtonSegment<QuestViewMode>>[
            //     ButtonSegment<QuestViewMode>(
            //         value: QuestViewMode.all,
            //         label: Text(engine.locale('all')),
            //         icon: const Icon(Icons.list)),
            //     ButtonSegment<QuestViewMode>(
            //         value: QuestViewMode.ongoing,
            //         label: Text(engine.locale('current')),
            //         icon: const Icon(Icons.access_time)),
            //     ButtonSegment<QuestViewMode>(
            //         value: QuestViewMode.finished,
            //         label: Text(engine.locale('finished')),
            //         icon: const Icon(Icons.check_circle)),
            //   ],
            //   selected: {_selectedMode},
            //   onSelectionChanged: (Set<QuestViewMode> newSelection) {
            //     setState(() {
            //       _selectedMode = newSelection.first;
            //     });
            //   },
            // ),
            Container(
              width: 300.0,
              height: 320.0,
              margin: const EdgeInsets.only(left: 10.0, right: 10.0),
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: GameUI.foregroundColor,
                ),
                // borderRadius: const BorderRadius.only(
                //   bottomLeft: Radius.circular(5.0),
                //   bottomRight: Radius.circular(5.0),
                // ),
              ),
              child: _questsData.values.isNotEmpty
                  ? ListView(
                      children: List<Widget>.from(
                        _questsData.values.map(
                          (quest) => TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: quest['id'] == _selectedQuestId
                                  ? Colors.white24
                                  : Colors.transparent,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedQuestId = quest['id'];
                                _selectedQuest = quest;
                              });
                            },
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${quest['name']}${quest['isFinished'] ? ' (${engine.locale('finished')})' : ''}',
                              ),
                            ),
                          ),
                        ),
                      ).reversed.toList(),
                    )
                  : EmptyPlaceholder(engine.locale('empty')),
            ),
            // ],
            // ),
            // ),
            if (_selectedQuest != null)
              Container(
                width: 300.0,
                height: 320.0,
                padding: const EdgeInsets.only(left: 5.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedQuest['name'],
                          style: const TextStyle(fontSize: 20),
                        ),
                        const Spacer(),
                        if (_selectedQuest['isFinished'])
                          Text(
                            engine.locale('finished'),
                            style: const TextStyle(fontSize: 20),
                          )
                        else
                          Text(
                            engine.locale('continued'),
                            style: const TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                    _buildQuestDescription(_selectedQuest),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
