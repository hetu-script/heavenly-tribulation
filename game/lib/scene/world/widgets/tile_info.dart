import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../../engine.dart';
import '../../../game/ui.dart';
import '../../../state/selected_tile.dart';
// import 'tile_detail.dart';

class TileInfoPanel extends StatefulWidget {
  const TileInfoPanel({
    super.key,
  });

  @override
  State<TileInfoPanel> createState() => _TileInfoPanelState();
}

class _TileInfoPanelState extends State<TileInfoPanel> {
  @override
  Widget build(BuildContext context) {
    final currentZone = context.watch<SelectedTileState>().currentZone;
    final currentNation = context.watch<SelectedTileState>().currentNation;
    final currentLocation = context.watch<SelectedTileState>().currentLocation;
    final currentTerrain = context.watch<SelectedTileState>().currentTerrain;

    String? coordinates;
    if (currentTerrain != null) {
      coordinates =
          '${currentTerrain.data['left']}, ${currentTerrain.data['top']}';
    }

    return ResponsiveView(
      color: GameUI.backgroundColor,
      width: 220,
      height: 160,
      margin: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child:
                // ElevatedButton(
                //   onPressed: () {
                //     showDialog(
                //       context: context,
                //       builder: (context) => const TileDetailPanel(),
                //     );
                //   },
                //   child: Text(engine.locale('terrainDetail')),
                // ),
                Text(engine.locale('terrainDetail')),
          ),
          if (currentTerrain != null) ...[
            Text('${engine.locale('coordinates')}: $coordinates'),
            Text(
                '${engine.locale('kind')}: ${engine.locale(currentTerrain.kind)}'),
          ],
          if (currentZone != null)
            Text('${engine.locale('zone')}: ${currentZone['name']}'),
          if (currentNation != null)
            Text('${engine.locale('organization')}: ${currentNation['name']}'),
          if (currentLocation != null)
            Text('${engine.locale('location')}: ${currentLocation['name']}'),
          if (currentTerrain?.isNonEnterable == true)
            Text(engine.locale('nonInteractable')),
          if (currentTerrain?.objectId != null)
            Text('${engine.locale('mapObject')}: ${currentTerrain!.objectId!}'),
        ],
      ),
    );
  }
}
