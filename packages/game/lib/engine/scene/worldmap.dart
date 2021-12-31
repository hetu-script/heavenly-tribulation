import 'package:flutter/material.dart';

import 'scene.dart';
import 'component/map.dart';
import '../game.dart';

class WorldMapScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  MapComponent? map;

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
  }

  // @override
  // void render(Canvas canvas) {
  //   super.render(canvas);

  //   if (map.selectedTerrain != null) {
  //     camera.apply(canvas);
  //     canvas.drawPath(map.selectedTerrain!.path, MapComponent.selectedPaint);
  //   }
  // }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    map = await game.hetu.invoke('createWorldMap', namedArgs: {
      'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
    });
    add(map!);
    _loaded = true;
  }

  @override
  late final Map<String, Widget Function(BuildContext, Scene)>
      overlayBuilderMap;

  Widget tileInfoBuilder(BuildContext ctx, Scene scene) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        SizedBox(
          width: 200,
          child: Column(
            children: <Widget>[
              Text(
                  'X: ${map?.selectedTerrain?.left}, Y: ${map?.selectedTerrain?.top}'),
              Text('ZondeIndex: ${map?.selectedTerrain?.zoneIndex}'),
            ],
          ),
        ),
      ],
    );
  }
}
