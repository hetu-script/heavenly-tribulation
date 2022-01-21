import 'package:flutter/material.dart';

import '../../../engine/engine.dart';
import '../../../engine/tilemap/tile.dart';

class LocationBrief extends StatelessWidget {
  static Future<void> show(
    BuildContext context, {
    TileMapTerrain? terrain,
    bool isHeroPosition = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.center,
            child: LocationBrief(
              terrain: terrain,
              isHeroPosition: isHeroPosition,
            ),
          ),
        );
      },
    );
  }

  final TileMapTerrain? terrain;
  final bool isHeroPosition;

  const LocationBrief({
    Key? key,
    this.terrain,
    this.isHeroPosition = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final informationWidgets = <Widget>[];
    if (terrain != null && terrain!.locationId != null) {
      final locationData = engine.hetu
          .invoke('getLocationById', positionalArgs: [terrain!.locationId]);
      informationWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Text(
            locationData['name'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      final String? organizationId = locationData['organizationId'];
      dynamic organizationData;
      if (organizationId != null) {
        organizationData = engine.hetu
            .invoke('getOrganizationById', positionalArgs: [organizationId]);
      }
      if (organizationData != null) {
        informationWidgets.add(
          Text('组织: ${organizationData['name']}'),
        );
      }
    }
    if (terrain != null) {
      final zoneData = engine.hetu
          .invoke('getZoneByIndex', positionalArgs: [terrain!.zoneIndex]);
      informationWidgets.addAll(
        [Text('地域: ${zoneData['name']} (${terrain!.left}, ${terrain!.top})')],
      );
    }
    if (isHeroPosition) {
      informationWidgets.addAll([
        const Spacer(),
        Align(
          alignment: Alignment.center,
          child: ElevatedButton(
            onPressed: () {},
            child: Text(engine.locale['check']),
          ),
        )
      ]);
    }

    return Container(
      constraints: BoxConstraints.tight(const Size(200, 240)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          width: 2,
          color: Colors.lightBlue.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: informationWidgets,
      ),
    );
  }
}
