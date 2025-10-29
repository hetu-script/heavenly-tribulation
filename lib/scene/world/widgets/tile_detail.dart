import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../engine.dart';
import '../../../state/selected_tile.dart';
import '../../../widgets/ui/close_button2.dart';
import '../../../data/game.dart';
import '../../../widgets/ui/responsive_view.dart';

class TileDetailPanel extends StatefulWidget {
  const TileDetailPanel({super.key});

  @override
  State<TileDetailPanel> createState() => _TileDetailPanelState();
}

class _TileDetailPanelState extends State<TileDetailPanel> {
  @override
  Widget build(BuildContext context) {
    dynamic currentZone = context.watch<SelectedPositionState>().currentZone;
    dynamic currentNation =
        context.watch<SelectedPositionState>().currentNation;
    dynamic currentTerrain =
        context.watch<SelectedPositionState>().currentTerrain;
    dynamic currentLocation =
        context.watch<SelectedPositionState>().currentLocation;

    final positionDetails = StringBuffer();

    if (currentLocation != null) {
      dynamic manager;
      // dynamic sect;
      final managerId = currentLocation['managerId'];
      // 这里 manager 可能是 null
      manager = GameData.game['characters'][managerId];
      // final sectId = currentLocation['sectId'];
      // sect = GameData.gameData['sects'][sectId];

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
          .writeln('$title ${manager?['name'] ?? engine.locale('none')}');
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
        positionDetails
            .writeln('[${currentTerrain.left}, ${currentTerrain.top}]');
      }
    }

    String? coordinates;
    if (currentTerrain != null) {
      coordinates = '${currentTerrain.left}, ${currentTerrain.top}';
    }

    return ResponsiveView(
      barrierColor: null,
      width: 400,
      height: 400,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('terrain')),
          actions: const [CloseButton2()],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (currentTerrain != null) ...[
                Text('${engine.locale('coordinates')}: $coordinates'),
                Text(
                    '${engine.locale('kind')}: ${engine.locale(currentTerrain.kind!)}'),
              ],
              if (currentZone != null)
                Text('${engine.locale('zone')}: ${currentZone['name']}'),
              if (currentNation != null)
                Text('${engine.locale('sect')}: ${currentNation['name']}'),
              // if (currentLocation != null)
              //   Text(
              //       '${engine.locale('location')}: ${currentLocation['name']}'),
            ],
          ),
        ),
      ),
    );
  }
}
