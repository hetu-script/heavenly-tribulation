import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/quest.dart';
import '../game/ui.dart';

const double _kTextShadowOffset = 0.5;

const List<Shadow> kTextShadow = [
  Shadow(
    // bottomLeft
    offset: Offset(-_kTextShadowOffset, -_kTextShadowOffset),
    color: Colors.black,
    blurRadius: 2.5,
  ),
  Shadow(
    // bottomRight
    offset: Offset(_kTextShadowOffset, -_kTextShadowOffset),
    color: Colors.black,
    blurRadius: 2.5,
  ),
  Shadow(
    // topRight
    offset: Offset(_kTextShadowOffset, _kTextShadowOffset),
    color: Colors.black,
    blurRadius: 2.5,
  ),
  Shadow(
    // topLeft
    offset: Offset(-_kTextShadowOffset, _kTextShadowOffset),
    color: Colors.black,
    blurRadius: 2.5,
  ),
];

/// 右上角悬浮文字面板
class QuestPanel extends StatefulWidget {
  const QuestPanel({super.key});

  @override
  State<QuestPanel> createState() => _QuestPanelState();
}

class _QuestPanelState extends State<QuestPanel> {
  String? selectedId;

  @override
  Widget build(BuildContext context) {
    final questsData = context.watch<QuestState>().questsData;

    return (questsData == null)
        ? Container()
        : MouseRegion(
            onEnter: (_) {
              setState(() {
                selectedId = questsData['id'];
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
                color: Colors.black.withAlpha(50),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                    color: selectedId == questsData['id']
                        ? GameUI.foregroundColor
                        : Colors.transparent),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questsData['name'],
                    style: const TextStyle(
                      fontSize: 20.0,
                      color: Colors.lightGreen,
                      shadows: kTextShadow,
                    ),
                  ),
                  const Divider(),
                  Text(
                    questsData['stages'][questsData['currentStageIndex']]
                        ['description'],
                    style: const TextStyle(
                      fontSize: 16.0,
                      // color: Colors.yellow,
                      shadows: kTextShadow,
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
