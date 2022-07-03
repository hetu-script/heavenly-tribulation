import 'dart:ui';

import 'package:flutter/material.dart';

import '../../global.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    this.heroId,
    this.retraceMessageCount = 50,
    this.showGlobalIncident = true,
  });

  final String? heroId;

  final int retraceMessageCount;

  final bool showGlobalIncident;

  @override
  Widget build(BuildContext context) {
    final Iterable history = engine.invoke('getHistory').reversed;
    final List items = [];
    final iter = history.iterator;
    var i = 0;
    while (iter.moveNext() && i < retraceMessageCount) {
      ++i;
      final current = iter.current;
      if (!showGlobalIncident) continue;
      if ((heroId != null &&
          (current['subjectIds'].contains(heroId) ||
              current['objectIds'].contains(heroId)))) {
        items.add(current);
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
