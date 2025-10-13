import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import '../state/view_panels.dart';
import '../state/game_update.dart';
import '../game/ui.dart';
import '../engine.dart';
import 'history_list.dart';
import '../state/hover_content.dart';
import '../game/game.dart';
import '../state/selected_tile.dart';

class HistoryPanel extends StatelessWidget {
  const HistoryPanel({
    super.key,
    required this.width,
    required this.height,
  });

  final double height, width;

  @override
  Widget build(BuildContext context) {
    final positionDetails = StringBuffer();
    final dateString = context.watch<GameTimestampState>().datetimeString;
    positionDetails.write(dateString);

    dynamic currentZone,
        currentNation,
        currentTerrain,
        currentLocation,
        currentDungeon;

    currentZone = context.watch<HeroPositionState>().currentZone;
    currentNation = context.watch<HeroPositionState>().currentNation;
    currentTerrain = context.watch<HeroPositionState>().currentTerrain;
    currentLocation = context.watch<HeroPositionState>().currentLocation;
    currentDungeon = context.watch<HeroPositionState>().currentDungeon;

    // if (isEditorMode) {
    //   positionDetails.write(engine.locale('terrainDetail'));
    // }

    if (currentDungeon != null) {
      final rank = currentDungeon?['rank'];
      if (rank != null) {
        positionDetails.write(
            ' ${engine.locale('cultivationRank_$rank') + engine.locale('rank2') + engine.locale('dungeon')}');
      } else {
        positionDetails.write(' ${currentDungeon['name']}');
      }
      final level = currentDungeon['level'];
      if (level != null) {
        positionDetails.write(
            ' ${engine.locale('currentDungeonLevel')}: ${level + 1}/${currentDungeon['levelMax'] + 1}');
      }
      final room = currentDungeon['room'];
      if (room != null) {
        positionDetails.write(
            ' ${engine.locale('currentDungeonRoom')}: ${room + 1}/${currentDungeon['roomMax'] + 1}');
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

      positionDetails.write(currentLocation['name']);
      positionDetails
          .write(' $title ${owner?['name'] ?? engine.locale('none')}');
      positionDetails.write(
          ' ${engine.locale('development')}: ${currentLocation['development']}');
    } else {
      if (currentZone != null) {
        positionDetails.write(' ${currentZone!['name']}');
      }
      if (currentNation != null) {
        positionDetails.write(' ${currentNation['name']}');
      }
      if (currentTerrain != null) {
        positionDetails
            .write(' ${engine.locale(currentTerrain.data?['kind'])}');
        // if (isEditorMode) {
        //   positionDetails.write(
        //       '${engine.locale('spriteIndex')}: ${engine.locale(kSpriteIndexCategory[currentTerrain.data?['spriteIndex']])} ');
        // }
        positionDetails
            .write(' [${currentTerrain.left}, ${currentTerrain.top}]');
      }
    }

    return Container(
      width: width,
      height: height,
      color: GameUI.backgroundColor2,
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(positionDetails.toString(), style: TextStyles.bodySmall),
          SizedBox(
            width: 480,
            child: HeroAndGlobalHistoryList(
              limit: 3,
              cursor: FlutterCustomMemoryImageCursor(key: 'click'),
              onTapUp: () {
                context.read<ViewPanelState>().toogle(ViewPanels.memory);
              },
              onMouseEnter: (rect) {
                context
                    .read<HoverContentState>()
                    .show(engine.locale('history'), rect);
              },
              onMouseExit: () {
                context.read<HoverContentState>().hide();
              },
            ),
          ),
        ],
      ),
    );
  }
}
