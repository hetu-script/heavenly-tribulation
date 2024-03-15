import 'package:flutter/material.dart';

import '../../config.dart';
import 'package:samsara/ui/responsive_window.dart';

class ZoneView extends StatelessWidget {
  final String? zoneId;
  final dynamic zoneData;

  const ZoneView({
    super.key,
    this.zoneId,
    this.zoneData,
  });

  @override
  Widget build(BuildContext context) {
    final data = zoneData;
    if (data == null && zoneId != null) {
      engine.hetu.invoke('getZoneById', positionalArgs: [zoneId!]);
    }

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      size: const Size(400.0, 400.0),
      child: data != null
          ? Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${engine.locale('name')}: ${zoneData['name']}'),
                  Text(
                      '${engine.locale('category')}: ${engine.locale(zoneData['category'])}'),
                ],
              ),
            )
          : null,
    );
  }
}
