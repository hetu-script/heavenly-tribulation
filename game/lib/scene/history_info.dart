import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/history.dart';
import '../ui.dart';

class HistoryInfoPanel extends StatefulWidget {
  const HistoryInfoPanel({super.key});

  @override
  State<HistoryInfoPanel> createState() => _HistoryInfoPanelState();
}

class _HistoryInfoPanelState extends State<HistoryInfoPanel> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final incidents = context.watch<HistoryState>().incidents;

    return incidents.isNotEmpty
        ? GestureDetector(
            onTap: () {
              // TODO: open hitstory view.
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: GameUI.historyPanelSize.x,
                height: GameUI.historyPanelSize.y,
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: kForegroundColor),
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
            ),
          )
        : Container();
  }
}
