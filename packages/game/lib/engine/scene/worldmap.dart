// import 'dart:ui';

import 'scene.dart';
import 'component/map.dart';
import '../game.dart';

class WorldMapScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  late MapComponent map;

  WorldMapScene({
    required SamsaraGame game,
    required void Function() onQuit,
  }) : super(key: 'WorldMap', game: game, onQuit: onQuit);

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

    add(map);
    _loaded = true;
  }
}
