import 'dart:ui';

import 'event.dart';
import '../engine/tilemap/tile.dart';
import '../engine/tilemap/actor.dart';

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

abstract class MapEvents {
  static const onMapLoaded = 'mapLoaded';
  static const onMapTapped = 'tileTapped';
  static const onCheckTerrain = 'checkTerrain';
}

class MapEvent extends GameEvent {
  const MapEvent.mapLoaded() : super(MapEvents.onMapLoaded);
}

class MapInteractionEvent extends GameEvent {
  final Offset? globalPosition;

  final TileMapTerrain? terrain;
  final TileMapActor? actor;

  const MapInteractionEvent.mapTapped(
      {required this.globalPosition, this.terrain, this.actor})
      : super(MapEvents.onMapTapped);

  const MapInteractionEvent.checkTerrain({required this.terrain, this.actor})
      : globalPosition = Offset.zero,
        super(MapEvents.onCheckTerrain);
}

abstract class LocationEvents {
  static const entered = 'entered_location';
  static const left = 'left_location';
}

class LocationEvent extends GameEvent {
  final String locationId;

  const LocationEvent({
    required String eventName,
    required this.locationId,
  }) : super(eventName);

  const LocationEvent.entered({required String locationId})
      : this(eventName: LocationEvents.entered, locationId: locationId);

  const LocationEvent.left({required String locationId})
      : this(eventName: LocationEvents.left, locationId: locationId);
}
