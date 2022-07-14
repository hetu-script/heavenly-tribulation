import 'dart:ui';

import 'package:flutter/material.dart';

import '../../global.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    this.title,
    this.heroId,
    this.retraceMessageCount = 50,
    this.showGlobalIncident = true,
    this.historyData,
  });

  final String? title;

  final String? heroId;

  final int retraceMessageCount;

  final bool showGlobalIncident;

  final List? historyData;

  @override
  Widget build(BuildContext context) {
    final Iterable history =
        historyData?.reversed ?? engine.invoke('getHistory').reversed;
    final List items = [];
    final iter = history.iterator;
    var i = 0;
    while (iter.moveNext() && i < retraceMessageCount) {
      ++i;
      final incident = iter.current;
      if (!showGlobalIncident && !incident['isGlobal']) continue;
      if ((heroId != null &&
          (incident['subjectIds'].contains(heroId) ||
              incident['objectIds'].contains(heroId)))) {
        items.add(incident);
      }
    }

    return GestureDetector(
      onTap: () {
        // TODO: open hitstory view.
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 300,
          height: 160,
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius:
                const BorderRadius.only(topRight: Radius.circular(5.0)),
            border: Border.all(color: kForegroundColor),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) Text(title!),
              if (title == null)
                Text(engine.invoke('getCurrentDateTimeString')),
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
                    // controller: _scrollController,
                    reverse: true,
                    children: items
                        .map((incident) => Text(incident['content']))
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
