import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/empty_placeholder.dart';
// import 'package:flutter/services.dart';

import '../engine.dart';
import '../ui.dart';
import 'common.dart';

enum QuestViewMode { all, ongoing, finished }

class QuestView extends StatefulWidget {
  const QuestView({
    super.key,
    this.characterId,
    this.characterData,
    this.mode = ViewPanelMode.view,
  }) : assert(characterId != null || characterData != null);

  final String? characterId;

  final dynamic characterData;

  final ViewPanelMode mode;

  @override
  State<QuestView> createState() => _QuestViewState();
}

class _QuestViewState extends State<QuestView> {
  bool get isEditorMode =>
      widget.mode == ViewPanelMode.edit || widget.mode == ViewPanelMode.create;

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
          '• ${questData['stages'][i]['description']}',
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
    return ResponsiveWindow(
      color: kBackgroundColor,
      alignment: AlignmentDirectional.center,
      size: const Size(
          680.0, //widget.mode != ViewPanelMode.view ? 450.0 :
          400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('quest'),
          ),
          actions: const [CloseButton2()],
        ),
        body: Column(
          children: [
            Container(
              width: 670.0,
              height: 350.0,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 290.0,
                    child: Column(
                      children: [
                        // Padding(
                        //   padding: const EdgeInsets.only(bottom: 5.0),
                        //   child:
                        SegmentedButton<QuestViewMode>(
                          segments: <ButtonSegment<QuestViewMode>>[
                            ButtonSegment<QuestViewMode>(
                                value: QuestViewMode.all,
                                label: Text(engine.locale('all')),
                                icon: const Icon(Icons.list)),
                            ButtonSegment<QuestViewMode>(
                                value: QuestViewMode.ongoing,
                                label: Text(engine.locale('ongoing')),
                                icon: const Icon(Icons.access_time)),
                            ButtonSegment<QuestViewMode>(
                                value: QuestViewMode.finished,
                                label: Text(engine.locale('finished')),
                                icon: const Icon(Icons.check_circle)),
                          ],
                          selected: {_selectedMode},
                          onSelectionChanged:
                              (Set<QuestViewMode> newSelection) {
                            setState(() {
                              _selectedMode = newSelection.first;
                            });
                          },
                          // ),
                        ),
                        Container(
                          width: 289.0,
                          height: 310.0,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: kForegroundColor,
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
                                        onPressed: () {},
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            quest['name'],
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
                      width: 350.0,
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
            Row(
              children: [
                const Spacer(),
                if (widget.mode != ViewPanelMode.view)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                          engine.locale(isEditorMode ? 'save' : 'confirm')),
                    ),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
