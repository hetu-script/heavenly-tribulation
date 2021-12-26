import 'scene.dart';
import 'component/map.dart';
import '../game.dart';

class WorldMapScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  WorldMapScene({
    required SamsaraGame game,
    required void Function() onQuit,
  }) : super(key: 'WorldMap', game: game, onQuit: onQuit);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final MapComponent map =
        await game.hetu.invoke('createWorldMap', namedArgs: {
      'terrainSpriteSheet': 'fantasyhextiles_v3_borderless.png',
    });

    add(map);
    _loaded = true;
  }
}
