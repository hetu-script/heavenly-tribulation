import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../global.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    required super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List history = engine.invoke('getHistory');

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
                    children: [
                      for (final incident in history)
                        if (incident['isGlobal'] ?? false)
                          Text(incident['content'])
                    ],
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
