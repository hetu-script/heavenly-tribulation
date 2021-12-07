import '../../scene/scene.dart';
import 'component/rogue_map.dart';
import '../../game.dart';

class RogueGame extends Scene {
  bool _loaded = false;
  bool get loaded => _loaded;

  RogueGame({required SamsaraGame game}) : super(key: 'RogueGame', game: game);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final RogueMap map = await game.hetu.invoke('createRogueGame');
    add(map);
    _loaded = true;
  }
}
