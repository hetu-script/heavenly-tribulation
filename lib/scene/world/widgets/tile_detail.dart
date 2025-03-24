import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../../engine.dart';
import '../../../game/ui.dart';
import '../../../state/selected_tile.dart';

class TileDetailPanel extends StatefulWidget {
  const TileDetailPanel({super.key});

  @override
  State<TileDetailPanel> createState() => _TileDetailPanelState();
}

class _TileDetailPanelState extends State<TileDetailPanel> {
  @override
  Widget build(BuildContext context) {
    final currentZone = context.watch<SelectedTileState>().currentZone;
    final currentNation = context.watch<SelectedTileState>().currentNation;
    final currentLocation = context.watch<SelectedTileState>().currentLocation;
    final currentTerrain = context.watch<SelectedTileState>().currentTerrain;

    String? coordinates;
    if (currentTerrain != null) {
      coordinates = '${currentTerrain.left}, ${currentTerrain.top}';
    }

    return ResponsiveView(
      alignment: Alignment.center,
      backgroundColor: GameUI.backgroundColor,
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
                Text(
                    '${engine.locale('organization')}: ${currentNation['name']}'),
              if (currentLocation != null)
                Text(
                    '${engine.locale('location')}: ${currentLocation['name']}'),
            ],
          ),
        ),
      ),
    );
  }
}
