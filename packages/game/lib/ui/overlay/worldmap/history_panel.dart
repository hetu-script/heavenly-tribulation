import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:samsara/event.dart';

import '../../../global.dart';

class HistoryPanel extends StatefulWidget {
  const HistoryPanel({required Key key}) : super(key: key);

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  late final ScrollController _scrollController = ScrollController();
  final List<String> messages = [];

  @override
  void initState() {
    super.initState();

    final List history = engine.invoke('getHistory');
    for (final incident in history) {
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
    return GestureDetector(
      onTap: () {
        // TODO: open hitstory view.
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor.withOpacity(0.5),
            borderRadius:
                const BorderRadius.only(topRight: Radius.circular(5.0)),
            border: Border.all(color: kForegroundColor),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Text(engine.invoke('getDateTimeString')),
              const Divider(
                color: kForegroundColor,
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: ListView(
                    controller: _scrollController,
                    reverse: true,
                    children: messages
                        .map((text) => Text(text))
                        .toList()
                        .reversed
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
