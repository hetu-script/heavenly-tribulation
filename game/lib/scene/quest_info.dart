import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/quest.dart';
import '../ui.dart';

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
class QuestInfoPanel extends StatefulWidget {
  const QuestInfoPanel({super.key});

  @override
  State<QuestInfoPanel> createState() => _QuestInfoPanelState();
}

class _QuestInfoPanelState extends State<QuestInfoPanel> {
  bool _showBorder = false;

  @override
  Widget build(BuildContext context) {
    final questsData = context.watch<QuestState>().questsData;

    return (questsData != null)
        ? Column(
            children: questsData
                .map(
                  (quest) => MouseRegion(
                    onEnter: (_) {
                      setState(() {
                        _showBorder = true;
                      });
                    },
                    onExit: (_) {
                      setState(() {
                        _showBorder = false;
                      });
                    },
                    child: Container(
                      width: 300,
                      height: 130,
                      margin: const EdgeInsets.all(8.0),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(50),
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                            color: _showBorder
                                ? GameUI.foregroundColor
                                : Colors.transparent),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            quest['name'],
                            style: const TextStyle(
                              fontSize: 20.0,
                              color: Colors.yellow,
                              shadows: kTextShadow,
                            ),
                          ),
                          const Divider(),
                          Text(
                            quest['stages'][quest['currentStageIndex']]
                                ['description'],
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.yellow,
                              shadows: kTextShadow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          )
        : Container();
  }
}
