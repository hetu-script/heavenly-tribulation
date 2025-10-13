import 'package:flutter/material.dart';

import '../../engine.dart';
import 'package:samsara/ui/responsive_view.dart';

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
    dynamic data = zoneData;
    if (data == null && zoneId != null) {
      data = engine.hetu.invoke('getZoneById', positionalArgs: [zoneId!]);
    }

    return ResponsiveView(
      alignment: AlignmentDirectional.center,
      width: 400.0,
      height: 400.0,
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
