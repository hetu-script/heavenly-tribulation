import 'package:flutter/material.dart';

import '../../global.dart';
import '../ui/responsive_view.dart';

class ZoneView extends StatelessWidget {
  final dynamic zoneData;

  const ZoneView({
    super.key,
    required this.zoneData,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 400.0,
      height: 400.0,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${engine.locale('name')}: ${zoneData['name']}'),
            Text(
                '${engine.locale('category')}: ${engine.locale(zoneData['category'])}'),
          ],
        ),
      ),
    );
  }
}
