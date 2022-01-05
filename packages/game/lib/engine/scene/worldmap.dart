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
    required void Function() onQuit,
  }) : super(key: 'WorldMap', game: game) {
    overlayBuilderMap = {
      'overlayUI': (BuildContext context, Scene scene) {
        final widgets = <Widget>[
          Positioned(
            left: 5,
            top: 5,
            child: Container(
              color: Colors.white,
              child: IconButton(
                onPressed: onQuit,
                icon: const Icon(Icons.menu_open),
              ),
            ),
          ),
        ];
        if (showTileInfo) {
          widgets.add(
            Positioned(
              left: 5,
              bottom: 5,
              child: SizedBox(
                height: 200,
                width: 240,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                    border:
                        Border.all(color: Colors.lightBlue.withOpacity(0.5)),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                          'X: ${map!.selectedTerrain!.left}, Y: ${map!.selectedTerrain!.top}'),
                      Text('ZoneIndex: ${map!.selectedTerrain!.zoneIndex}'),
                      Text(
                          'ZoneName: ${map!.zones[map!.selectedTerrain!.zoneIndex].name}'),
                    ],
                  ),
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

    map = await game.hetu.invoke('createWorldMap', namedArgs: {
      'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
    });
    add(map!);
    _loaded = true;
  }
}
