import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../engine/engine.dart';
import '../../../event/event.dart';
import '../../../event/events.dart';

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

    final List incidents = engine.hetu.invoke('getIncidents');
    messages.addAll(incidents.map((data) => data['content']));

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
    return Container(
      constraints: BoxConstraints.tight(const Size(200, 240)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          width: 2,
          color: Colors.lightBlue,
        ),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: messages.map((text) => Text(text)).toList(),
      ),
    );
  }
}
