import 'package:flutter/material.dart';
import 'package:samsara/event.dart';

import '../../../global.dart';

class HistoryPanel extends StatefulWidget {
  const HistoryPanel({required Key key}) : super(key: key);

  @override
  _HistoryPanelState createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  final List<String> messages = [];

  @override
  void initState() {
    super.initState();

    final List incidents = engine.invoke('getIncidents');
    for (final incident in incidents) {
      if (incident['isPublic']) {
        messages.add(incident['content']);
      }
    }

    engine.registerListener(
      Events.incidentOccurred,
      EventHandler(widget.key!, (event) {
        final historyEvent = event as HistoryEvent;
        setState(() {
          messages.add(historyEvent.data['content']);
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: messages.map((text) => Text(text)).toList(),
    );
  }
}
