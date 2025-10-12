import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';
// import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:samsara/richtext.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import '../common.dart';
import '../../state/view_panels.dart';
import '../ui/draggable_panel.dart';

enum JournalViewMode { all, ongoing, finished }

class JournalView extends StatefulWidget {
  const JournalView({
    super.key,
    this.characterId,
    this.character,
    this.mode = InformationViewMode.view,
  }) : assert(characterId != null || character != null);

  final String? characterId;

  final dynamic character;

  final InformationViewMode mode;

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  dynamic _characterData, _journalsData;

  // QuestViewMode _selectedMode = QuestViewMode.all;

  dynamic _selectedJournal;

  @override
  void initState() {
    super.initState();

    assert(widget.characterId != null || widget.character != null);
    if (widget.character != null) {
      _characterData = widget.character!;
    } else {
      _characterData = GameData.getCharacter(widget.characterId!);
    }
    _journalsData = _characterData['journals'];

    if (_journalsData.isNotEmpty) {
      _selectedJournal = _journalsData.values.last;
    }
  }

  Widget _buildJournalDescription(dynamic journalData) {
    final List<Widget> descriptions = [];
    final List sequence = journalData['sequence'];

    final budget = _selectedJournal['quest']?['budget'];
    if (budget != null) {
      descriptions.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: RichText(
            text: TextSpan(
              children: buildFlutterRichText(
                  GameData.getQuestBudgetDescription(budget)),
              style: TextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }
    final reward = _selectedJournal['quest']?['reward'];
    if (reward != null) {
      descriptions.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: RichText(
            text: TextSpan(
              children: buildFlutterRichText(
                  GameData.getQuestRewardDescription(reward)),
              style: TextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }
    final timeLimit = _selectedJournal['quest']?['timeLimit'];
    if (timeLimit != null) {
      descriptions.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: RichText(
            text: TextSpan(
              children: buildFlutterRichText(
                  GameData.getQuestTimeLimitDescription(timeLimit,
                      isFinished: journalData['isFinished'] == true)),
              style: TextStyles.bodyMedium,
            ),
          ),
        ),
      );
    }

    for (var index = sequence.length - 1; index >= 0; --index) {
      final stageIndex = sequence[index];
      descriptions.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '· ',
                style: TextStyles.bodyMedium,
              ),
              SizedBox(
                width: 330.0,
                child: RichText(
                  text: TextSpan(
                    children: buildFlutterRichText(
                      _selectedJournal['stages'][stageIndex],
                      style: (index == sequence.length - 1 &&
                              journalData['isFinished'] != true)
                          ? TextStyles.bodyMedium
                          : TextStyles.bodyMedium.copyWith(
                              color: Colors.grey,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: MaterialScrollBehavior(),
      child: Container(
        width: 360.0,
        height: 360.0,
        padding: const EdgeInsets.only(top: 10.0),
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
    final position =
        context.watch<ViewPanelPositionState>().get(ViewPanels.journal) ??
            GameUI.detailsWindowPosition;

    return DraggablePanel(
      title: engine.locale('journal'),
      position: position,
      width: GameUI.profileWindowSize.x,
      height: GameUI.profileWindowSize.y,
      onTapDown: (offset) {
        context.read<ViewPanelState>().setUpFront(ViewPanels.journal);
        context
            .read<ViewPanelPositionState>()
            .set(ViewPanels.journal, position);
      },
      onDragUpdate: (details) {
        context.read<ViewPanelPositionState>().update(
              ViewPanels.journal,
              details.delta,
            );
      },
      onClose: () {
        context.read<ViewPanelState>().hide(ViewPanels.journal);
      },
      child: Container(
        width: 640.0,
        height: 400.0,
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              width: 240.0,
              height: 400.0,
              margin: const EdgeInsets.only(left: 10.0, right: 10.0),
              padding: const EdgeInsets.all(5.0),
              decoration: BoxDecoration(
                border: Border.all(
                  color: GameUI.foregroundColor,
                ),
              ),
              child: _journalsData.values.isNotEmpty
                  ? ListView(
                      children: List<Widget>.from(
                        _journalsData.values.map(
                          (journal) => fluent.Button(
                            onPressed: () {
                              setState(() {
                                _selectedJournal = journal;
                              });
                            },
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${journal['title']}${journal['isFinished'] == true ? ' (${engine.locale('finished')})' : ''}',
                                softWrap: false,
                                style: TextStyles.labelLarge.copyWith(
                                  color: _selectedJournal == journal
                                      ? Colors.yellow
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ).reversed.toList(),
                    )
                  : EmptyPlaceholder(engine.locale('empty')),
            ),
            if (_selectedJournal != null)
              Container(
                width: 360.0,
                height: 400.0,
                padding: const EdgeInsets.only(left: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _selectedJournal['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: _selectedJournal['isFinished'] == true
                              ? Text(
                                  engine.locale('finished'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey,
                                  ),
                                )
                              : Text(
                                  engine.locale('continued'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.lightGreen,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    _buildJournalDescription(_selectedJournal),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
