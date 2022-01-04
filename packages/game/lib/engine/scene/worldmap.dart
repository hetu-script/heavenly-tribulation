import 'package:flutter/material.dart';

import 'scene.dart';
import 'component/map.dart';
import '../game.dart';

class WorldMapScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  MapComponent? map;

  @override
  late final Map<String, Widget Function(BuildContext, Scene)>
      overlayBuilderMap;

  WorldMapScene({
    required SamsaraGame game,
    required void Function() onQuit,
  }) : super(key: 'WorldMap', game: game) {
    overlayBuilderMap = {
      'menu': (BuildContext ctx, Scene scene) {
        return Material(
          child: Stack(
            children: <Widget>[
              Positioned(
                child: IconButton(
                  onPressed: onQuit,
                  icon: const Icon(Icons.menu_open),
                ),
              ),
            ],
          ),
        );
      },
      'tileInfo': tileInfoBuilder,
    };

    game.registerListener(MapEvents.tileTapped, (event) {
      overlays.remove('tileInfo');
      overlays.add('tileInfo');
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

  Widget tileInfoBuilder(BuildContext context, Scene scene) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            const Spacer(),
            SizedBox(
              height: 200,
              width: 240,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.lightBlue.withOpacity(0.5)),
                ),
                child: Column(
                  children: <Widget>[
                    Text(
                        'X: ${map?.selectedTerrain?.left}, Y: ${map?.selectedTerrain?.top}'),
                    Text('ZondeIndex: ${map?.selectedTerrain?.zoneIndex}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
