import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state/history.dart';

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

    return incidents.isNotEmpty
        ? GestureDetector(
            onTap: () {
              // TODO: open hitstory view.
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 328,
                height: 140,
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
