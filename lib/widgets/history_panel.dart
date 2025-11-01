import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';

import '../state/view_panels.dart';
import '../ui.dart';
import '../global.dart';
import 'history_list.dart';
import '../state/hover_content.dart';
import '../data/game.dart';
import '../state/game_state.dart';

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
    final dateString = context.watch<GameState>().datetimeString;
    positionDetails.write(dateString);

    dynamic currentZone,
        currentNation,
        currentTerrain,
        currentLocation,
        currentDungeon;

    currentZone = context.watch<GameState>().currentZone;
    currentNation = context.watch<GameState>().currentNation;
    currentTerrain = context.watch<GameState>().currentTerrain;
    currentLocation = context.watch<GameState>().currentLocation;
    currentDungeon = context.watch<GameState>().currentDungeon;

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
      String? managerId = currentLocation['managerId'];
      dynamic manager = GameData.game['characters'][managerId];
      String title;
      int development = currentLocation['development'];
      if (currentLocation['category'] == 'site') {
        final kind = currentLocation['kind'];
        if (kind == 'headquarters') {
          title = engine.locale('head');
          final sectId = currentLocation['sectId'];
          final sect = GameData.getSect(sectId);
          managerId = sect['headId'];
          manager = GameData.game['characters'][managerId];
        } else if (kind == 'cityhall') {
          title = engine.locale('mayor');
          final atCityId = currentLocation['atCityId'];
          final atCity = GameData.getLocation(atCityId);
          managerId = atCity['managerId'];
          manager = GameData.game['characters'][managerId];
          development = atCity['development'];
        } else {
          if (kind == 'home') {
            title = engine.locale('homeOwner');
          } else {
            title = engine.locale('manager');
          }
        }
      } else {
        assert(currentLocation['category'] == 'city');
        title = engine.locale('mayor');
      }

      positionDetails.write(' ${currentLocation['name']}');
      positionDetails
          .write(' $title ${manager?['name'] ?? engine.locale('none')}');
      positionDetails.write(' ${engine.locale('development')}: $development');
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
        positionDetails
            .write(' [${currentTerrain.left},${currentTerrain.top}]');
      }
    }

    return Container(
      width: width,
      height: height,
      color: GameUI.backgroundColor,
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MouseRegion2(
            onEnter: (rect) {
              context.read<HoverContentState>().show(
                    engine.locale('hint_datetime'),
                    rect,
                    textAlign: TextAlign.left,
                    direction: HoverContentDirection.bottomLeft,
                  );
            },
            onExit: () {
              context.read<HoverContentState>().hide();
            },
            child: SizedBox(
              width: 480,
              child: Text(
                positionDetails.toString(),
                style: TextStyles.bodySmall,
              ),
            ),
          ),
          SizedBox(
            width: 480,
            child: HeroAndGlobalHistoryList(
              limit: 3,
              onTapUp: () {
                context.read<ViewPanelState>().toogle(ViewPanels.memoryAndBond);
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
