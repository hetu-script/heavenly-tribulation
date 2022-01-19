import 'event.dart';

abstract class SceneEvents {
  static const loading = 'loading_scene';
  static const started = 'started_scene';
  static const ended = 'ended_scene';
}

class SceneEvent extends GameEvent {
  final String sceneKey;

  const SceneEvent({
    required String eventName,
    required this.sceneKey,
  }) : super(eventName);

  const SceneEvent.loading({required String sceneKey})
      : this(eventName: SceneEvents.loading, sceneKey: sceneKey);

  const SceneEvent.started({required String sceneKey})
      : this(eventName: SceneEvents.started, sceneKey: sceneKey);

  const SceneEvent.ended({required String sceneKey})
      : this(eventName: SceneEvents.ended, sceneKey: sceneKey);
}
