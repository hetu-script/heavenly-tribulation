import 'package:flutter/material.dart';
// import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';

import '../game/data.dart';
import '../game/ui.dart';
import '../engine.dart';
import '../state/selected_tile.dart';

const kSpriteIndexCategory = {
  0: 'waterZone',
  1: 'landZone',
  2: 'river',
};

class LocationPanel extends StatelessWidget {
  const LocationPanel({
    super.key,
    required this.width,
    required this.height,
    this.isEditorMode = false,
  });

  final double width, height;
  final bool isEditorMode;

  @override
  Widget build(BuildContext context) {
    dynamic currentZone, currentNation, currentTerrain, currentLocation;
    if (isEditorMode) {
      currentZone = context.watch<SelectedPositionState>().currentZone;
      currentNation = context.watch<SelectedPositionState>().currentNation;
      currentTerrain = context.watch<SelectedPositionState>().currentTerrain;
      currentLocation = context.watch<SelectedPositionState>().currentLocation;
    } else {
      currentZone = context.watch<HeroPositionState>().currentZone;
      currentNation = context.watch<HeroPositionState>().currentNation;
      currentTerrain = context.watch<HeroPositionState>().currentTerrain;
      currentLocation = context.watch<HeroPositionState>().currentLocation;
    }

    final positionDetails = StringBuffer();

    // if (isEditorMode) {
    //   positionDetails.writeln(engine.locale('terrainDetail'));
    // }

    if (currentZone != null) {
      positionDetails.writeln('${currentZone!['name']}');
    }
    if (currentNation != null) {
      positionDetails.writeln('${currentNation['name']}');
    }

    if (currentTerrain != null) {
      if (isEditorMode) {
        positionDetails.write(
            '${engine.locale('spriteIndex')}: ${engine.locale(kSpriteIndexCategory[currentTerrain.data?['spriteIndex']])} ');
        positionDetails.write('[${currentTerrain.data?['kind']}] ');
      }
      positionDetails
          .writeln('[${currentTerrain.left}, ${currentTerrain.top}]');
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

    return (positionDetails.isEmpty && !isEditorMode)
        ? SizedBox.shrink()
        : Material(
            type: MaterialType.transparency,
            child: Container(
              color: GameUI.backgroundColor2,
              width: width,
              height: height,
              padding: const EdgeInsets.only(left: 5.0, top: 5.0),
              child: Text(
                positionDetails.toString(),
              ),
            ),
          );
  }
}
