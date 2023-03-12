import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:samsara/tilemap.dart';
import 'package:hetu_script/values.dart';

import '../../global.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    this.title,
    this.heroId,
    this.retraceMessageCount = 50,
    this.showGlobalIncident = true,
    this.historyData,
    this.showTileInfo = true,
    this.heroPosition,
    this.currentTerrain,
    this.currentNationData,
    this.currentLocationData,
  });

  final String? title;
  final String? heroId;
  final int retraceMessageCount;
  final bool showGlobalIncident;
  final List? historyData;

  final bool showTileInfo;
  final HTStruct? heroPosition;
  final TileMapTerrain? currentTerrain;
  final HTStruct? currentNationData;
  final HTStruct? currentLocationData;

  @override
  Widget build(BuildContext context) {
    final Iterable history = historyData?.reversed ??
        engine.invoke('getCurrentWorldHistory').reversed;
    final List items = [];
    final iter = history.iterator;
    var i = 0;
    while (iter.moveNext() && i < retraceMessageCount) {
      final incident = iter.current;
      if (!showGlobalIncident && !incident['isGlobal']) continue;
      if ((heroId != null &&
          (incident['subjectIds'].contains(heroId) ||
              incident['objectIds'].contains(heroId)))) {
        items.add(incident);
        ++i;
      }
    }

    final dateString = engine.invoke('getCurrentDateTimeString');

    final sb = StringBuffer();

    if (currentTerrain != null) {
      final zoneIndex = currentTerrain!.data!['zoneIndex'];
      if (zoneIndex != null) {
        final zoneData =
            engine.invoke('getZoneByIndex', positionalArgs: [zoneIndex]);
        sb.write(zoneData['name']);
      }
    }

    if (currentNationData != null) {
      sb.write(', ');
      sb.write(currentNationData!['name']);
    }

    if (currentLocationData != null) {
      sb.write(', ');
      sb.write(currentLocationData!['name']);
    } else if (currentTerrain != null) {
      sb.write(', ');
      sb.write(engine.locale[currentTerrain!.kind!]);
    }

    if (heroPosition != null) {
      sb.write(' (${heroPosition!['left']}, ${heroPosition!['top']})');
    }

    return GestureDetector(
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
            // borderRadius:
            //     const BorderRadius.only(topRight: Radius.circular(5.0)),
            border: Border.all(color: kForegroundColor),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) Text(title!),
              if (title == null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateString),
                    Text(sb.toString()),
                  ],
                ),
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
