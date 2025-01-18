import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../engine.dart';
import '../state/history.dart';
import '../ui.dart';

class HistoryPanel extends StatefulWidget {
  const HistoryPanel({super.key});

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<HistoryState>().incidents;

    return incidents.isEmpty
        ? Container()
        : GestureDetector(
            onTap: () {
              // TODO: open hitstory view.
            },
            child: Container(
              width: GameUI.historyPanelSize.x,
              height: GameUI.historyPanelSize.y,
              decoration: BoxDecoration(
                color: GameUI.backgroundColor,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: GameUI.foregroundColor),
              ),
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView(
                      // controller: _scrollController,
                      reverse: true,
                      children: incidents
                          .map((incident) => Text(incident['message']))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
