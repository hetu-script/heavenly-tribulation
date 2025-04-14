import 'package:flutter/material.dart';
// import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';

import '../game/data.dart';
import '../game/ui.dart';
import '../engine.dart';
import '../state/selected_tile.dart';

class LocationPanel extends StatelessWidget {
  const LocationPanel({
    super.key,
    required this.width,
    required this.height,
  });

  final double width, height;

  @override
  Widget build(BuildContext context) {
    final currentZone = context.watch<HeroPositionState>().currentZone;
    final currentNation = context.watch<HeroPositionState>().currentNation;
    final currentTerrain = context.watch<HeroPositionState>().currentTerrain;
    final currentLocation = context.watch<HeroPositionState>().currentLocation;

    final positionDetails = StringBuffer();

    if (currentZone != null) {
      positionDetails.writeln('${currentZone!['name']}');
    }
    if (currentNation != null) {
      positionDetails.writeln('${currentNation['name']}');
    }

    if (currentTerrain != null) {
      positionDetails
          .writeln('[${currentTerrain.left}, ${currentTerrain.top}]');
      // positionDetails.writeln('${engine.locale(currentTerrain.kind)}');
    }

    if (currentLocation != null) {
      dynamic owner;
      // dynamic organization;
      final ownerId = currentLocation['ownerId'];
      owner = GameData.gameData['characters'][ownerId];
      // final organizationId = currentLocation['organizationId'];
      // organization = GameData.gameData['organizations'][organizationId];

      String title;
      if (currentLocation['category'] == 'city') {
        title = engine.locale('cityHead');
      } else {
        final kind = currentLocation['kind'];
        if (kind == 'headquarters') {
          title = engine.locale('organizationHead');
        } else if (kind == 'cityhall') {
          title = engine.locale('cityHead');
        } else if (kind == 'home') {
          title = engine.locale('homeOwner');
        } else {
          title = engine.locale('locationHead');
        }
      }

      positionDetails.writeln(currentLocation['name']);
      positionDetails
          .writeln('$title ${owner?['name'] ?? engine.locale('none')}');
      positionDetails.writeln(
          '${engine.locale('development')}: ${currentLocation['development']}');
    }

    return positionDetails.isEmpty
        ? SizedBox.shrink()
        : Container(
            color: GameUI.backgroundColor2,
            width: width,
            height: height,
            padding: const EdgeInsets.all(5.0),
            child: Text(positionDetails.toString()),
          );
  }
}
