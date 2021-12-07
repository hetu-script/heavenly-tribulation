import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';

import '../binding/external_game_functions.dart';
import '../binding/game/scene/rogue/component/rogue_map_binding.dart';
import 'scene/scene.dart';
import 'event/event.dart';
import '../shared/localizations.dart';

class SamsaraGame with SceneController, EventAggregator {
  static final texts = GameLocalizations();
  final hetu = Hetu();
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    await hetu.initFlutter(
      externalFunctions: externalGameFunctions,
      externalClasses: [RogueMapClassBinding()],
    );
    hetu.evalFile('main.ht', invokeFunc: 'init');
    final localizationData = hetu.invoke('getLocalizations');
    SamsaraGame.texts.loadFromJson(localizationData);

    hetu.invoke('createGame');
    _isLoaded = true;
  }

  @override
  Future<Scene> createScene(String name) async {
    final Scene scene = await super.createScene(name);
    broadcast(SceneEvent.started(sceneKey: scene.key));
    return scene;
  }
}
