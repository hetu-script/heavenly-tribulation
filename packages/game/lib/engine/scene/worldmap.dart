import 'scene.dart';
import 'component/map.dart';
import '../game.dart';

class WorldMapScene extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  WorldMapScene({required SamsaraGame game})
      : super(key: 'WorldMap', game: game);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final MapComponent map = await game.hetu.invoke('createWorld');
    add(map);
    _loaded = true;
  }
}
