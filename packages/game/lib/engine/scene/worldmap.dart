import 'package:flutter/material.dart';

import 'scene.dart';
import 'component/map.dart';
import '../game.dart';

class WorldMapScene extends Scene {
  var _loaded = false;
  bool get loaded => _loaded;

  MapComponent? map;

  var showTileInfo = false;

  @override
  late final Map<String, Widget Function(BuildContext, Scene)>
      overlayBuilderMap;

  WorldMapScene({
    required SamsaraGame game,
  }) : super(key: 'WorldMap', game: game) {
    overlayBuilderMap = {
      'overlayUI': (BuildContext context, Scene scene) {
        final widgets = <Widget>[
          Positioned(
            left: 5,
            top: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(
                  width: 2,
                  color: Colors.lightBlue.withOpacity(0.5),
                ),
              ),
              child: IconButton(
                onPressed: () {
                  game.leaveScene('WorldMap');
                },
                icon: const Icon(Icons.menu_open),
              ),
            ),
          ),
        ];
        if (showTileInfo) {
          final tileInfoContent = <Widget>[
            Text(
                'X: ${map!.selectedTerrain!.left}, Y: ${map!.selectedTerrain!.top}'),
            Text('地域: ${map!.zones[map!.selectedTerrain!.zoneIndex].name}'),
          ];
          if (map!.selectedEntity != null) {
            tileInfoContent.add(
              Row(
                children: <Widget>[
                  Text('据点: ${map!.selectedEntity!.name}'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('查看详情'),
                  )
                ],
              ),
            );
          }
          widgets.add(
            Positioned(
              left: 5,
              bottom: 5,
              child: Container(
                height: 200,
                width: 240,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(
                    width: 2,
                    color: Colors.lightBlue.withOpacity(0.5),
                  ),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: tileInfoContent,
                ),
              ),
            ),
          );
        }
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: widgets,
          ),
        );
      },
    };
    game.registerListener(MapEvents.tileTapped, (event) {
      showTileInfo = true;
      overlays.remove('overlayUI');
      overlays.add('overlayUI');
    });
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await game.hetu.invoke('createWorld', namedArgs: {
      'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
    });
    add(map!);
    _loaded = true;
  }
}
