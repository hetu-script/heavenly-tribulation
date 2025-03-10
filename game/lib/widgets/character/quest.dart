import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';
// import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../engine.dart';
import '../../ui.dart';
import '../common.dart';
import '../../state/view_panels.dart';
import '../draggable_panel.dart';

enum QuestViewMode { all, ongoing, finished }

class CharacterQuest extends StatefulWidget {
  const CharacterQuest({
    super.key,
    this.characterId,
    this.characterData,
    this.mode = InformationViewMode.view,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;

  final dynamic characterData;

  final InformationViewMode mode;

  @override
  State<CharacterQuest> createState() => _CharacterQuestState();
}

class _CharacterQuestState extends State<CharacterQuest> {
  bool get isEditorMode =>
      widget.mode == InformationViewMode.edit ||
      widget.mode == InformationViewMode.create;

  dynamic _characterData, _questsData;

  QuestViewMode _selectedMode = QuestViewMode.all;

  String? _selectedQuestId;
  dynamic _selectedQuest;

  @override
  void initState() {
    super.initState();

    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      _characterData = engine.hetu
          .invoke('getCharacterById', positionalArgs: [widget.characterId]);
    }
    _questsData = _characterData['quests'];

    if (_questsData.isNotEmpty) {
      _selectedQuest = _questsData.values.last;
      _selectedQuestId = _selectedQuest['id'];
    }
  }

  Widget _buildQuestDescription(dynamic questData) {
    final List<Widget> descriptions = [];

    final currentStageIndex = questData['currentStageIndex'];
    for (var i = 0; i < currentStageIndex + 1; ++i) {
      descriptions.add(
        Text(
          '${questData['stages'][i]['description']}',
          style: i < currentStageIndex
              ? const TextStyle(
                  decoration: TextDecoration.lineThrough,
                )
              : null,
        ),
      );
    }
    return SizedBox(
      width: 330.0,
      height: 310.0,
      child: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: descriptions,
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
      width: GameUI.profileWindowWidth,
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
          children: [
            SizedBox(
              width: 300.0,
              child: Column(
                children: [
                  SegmentedButton<QuestViewMode>(
                    segments: <ButtonSegment<QuestViewMode>>[
                      ButtonSegment<QuestViewMode>(
                          value: QuestViewMode.all,
                          label: Text(engine.locale('all')),
                          icon: const Icon(Icons.list)),
                      ButtonSegment<QuestViewMode>(
                          value: QuestViewMode.ongoing,
                          label: Text(engine.locale('current')),
                          icon: const Icon(Icons.access_time)),
                      ButtonSegment<QuestViewMode>(
                          value: QuestViewMode.finished,
                          label: Text(engine.locale('finished')),
                          icon: const Icon(Icons.check_circle)),
                    ],
                    selected: {_selectedMode},
                    onSelectionChanged: (Set<QuestViewMode> newSelection) {
                      setState(() {
                        _selectedMode = newSelection.first;
                      });
                    },
                  ),
                  Container(
                    width: 289.0,
                    height: 300.0,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: GameUI.foregroundColor,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(5.0),
                        bottomRight: Radius.circular(5.0),
                      ),
                    ),
                    child: _questsData.values.isNotEmpty
                        ? ListView(
                            children: List<Widget>.from(
                              _questsData.values.map(
                                (quest) => TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                        quest['id'] == _selectedQuestId
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
                ],
              ),
            ),
            if (_selectedQuest != null)
              Container(
                width: 320.0,
                padding: const EdgeInsets.only(left: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
