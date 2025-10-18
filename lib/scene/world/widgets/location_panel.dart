import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/mouse_region2.dart';

import '../../../game/game.dart';
import '../../../ui.dart';
import '../../../engine.dart';
import '../../../state/selected_tile.dart';
import '../../../state/hover_content.dart';

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
    dynamic currentZone,
        currentNation,
        currentTerrain,
        currentLocation,
        currentDungeon;
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
      currentDungeon = context.watch<HeroPositionState>().currentDungeon;
    }

    final positionDetails = StringBuffer();

    // if (isEditorMode) {
    //   positionDetails.writeln(engine.locale('terrainDetail'));
    // }

    if (currentDungeon != null) {
      final rank = currentDungeon?['rank'];
      if (rank != null) {
        positionDetails.writeln(engine.locale('cultivationRank_$rank') +
            engine.locale('rank2') +
            engine.locale('dungeon'));
      } else {
        positionDetails.writeln(currentDungeon['name']);
      }
      final level = currentDungeon['level'];
      if (level != null) {
        positionDetails.writeln(
            '${engine.locale('currentDungeonLevel')}: ${level + 1}/${currentDungeon['levelMax'] + 1}');
      }
      final room = currentDungeon['room'];
      if (room != null) {
        positionDetails.writeln(
            '${engine.locale('currentDungeonRoom')}: ${room + 1}/${currentDungeon['roomMax'] + 1}');
      }
    } else if (currentLocation != null) {
      dynamic owner;
      // dynamic organization;
      final ownerId = currentLocation['ownerId'];
      // 这里 owner 可能是 null
      owner = GameData.data['characters'][ownerId];
      // final organizationId = currentLocation['organizationId'];
      // organization = GameData.gameData['organizations'][organizationId];

      String title;
      if (currentLocation['category'] == 'city') {
        title = engine.locale('mayor');
      } else {
        final kind = currentLocation['kind'];
        if (kind == 'headquarters') {
          title = engine.locale('head');
        } else if (kind == 'cityhall') {
          title = engine.locale('mayor');
        } else if (kind == 'home') {
          title = engine.locale('homeOwner');
        } else {
          title = engine.locale('manager');
        }
      }

      positionDetails.writeln(currentLocation['name']);
      positionDetails
          .writeln('$title ${owner?['name'] ?? engine.locale('none')}');
      positionDetails.writeln(
          '${engine.locale('development')}: ${currentLocation['development']}');
    } else {
      if (currentZone != null) {
        positionDetails.writeln('${currentZone!['name']}');
      }
      if (currentNation != null) {
        positionDetails.writeln('${currentNation['name']}');
      }
      if (currentTerrain != null) {
        positionDetails
            .write('${engine.locale(currentTerrain.data?['kind'])} ');
        if (isEditorMode) {
          positionDetails.write(
              '${engine.locale('spriteIndex')}: ${engine.locale(kSpriteIndexCategory[currentTerrain.data?['spriteIndex']])} ');
        }
        positionDetails
            .writeln('[${currentTerrain.left}, ${currentTerrain.top}]');
      }
    }

    return (positionDetails.isEmpty && !isEditorMode)
        ? SizedBox.shrink()
        : MouseRegion2(
            onEnter: (rect) {
              context.read<HoverContentState>().hide();
            },
            child: Material(
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
            ),
          );
  }
}
