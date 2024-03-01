import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../config.dart';

class LocationInfoPanel extends StatelessWidget {
  const LocationInfoPanel({
    super.key,
    required this.locationData,
  });

  final HTStruct? locationData;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 120,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: kBackgroundColor,
        border: Border.all(color: kForegroundColor),
      ),
      child: locationData != null
          ? Column(
              children: [
                Text(locationData!['name']),
              ],
            )
          : null,
    );
  }
}
