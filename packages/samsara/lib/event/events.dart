import 'dart:ui';

import 'package:hetu_script/values.dart';

import 'event.dart';
import '../tilemap/tile.dart';
import '../tilemap/actor.dart';

abstract class Events {
  static const createdScene = 'created_scene';
  static const loadingScene = 'loading_scene';
  static const endedScene = 'ended_scene';
  static const loadedMap = 'loaded_map';
  static const loadedMaze = 'loaded_maze';
  static const tappedMap = 'tapped_tile';
  static const checkTerrain = 'checkTerrain';
  static const enteredLocation = 'entered_location';
  static const leftLocation = 'left_location';
  static const incidentOccurred = 'incident_occurred';
  static const heroMoved = 'hero_moved_on_worldmap';
}

// class SceneEvent extends GameEvent {
//   const SceneEvent({
//     required super.name,
//     required super.scene,
//   });

//   const SceneEvent.created({required String sceneKey})
//       : this(name: Events.createdScene, scene: sceneKey);

//   const SceneEvent.loading({required String sceneKey})
//       : this(name: Events.loadingScene, scene: sceneKey);

//   const SceneEvent.ended({required String sceneKey})
//       : this(name: Events.endedScene, scene: sceneKey);
// }

class MapLoadedEvent extends GameEvent {
  final bool isNewGame;

  const MapLoadedEvent({this.isNewGame = false})
      : super(name: Events.loadedMap);
}

class MapInteractionEvent extends GameEvent {
  final Offset? globalPosition;

  final TileMapTerrain? terrain;
  final TileMapActor? actor;

  const MapInteractionEvent.mapTapped(
      {required this.globalPosition, this.terrain, this.actor})
      : super(name: Events.tappedMap);

  const MapInteractionEvent.checkTerrain({required this.terrain, this.actor})
      : globalPosition = null,
        super(name: Events.checkTerrain);

  const MapInteractionEvent.heroMoved({required super.scene})
      : terrain = null,
        actor = null,
        globalPosition = null,
        super(name: Events.heroMoved);
}

class MazeLoadedEvent extends GameEvent {
  const MazeLoadedEvent() : super(name: Events.loadedMaze);
}

class LocationEvent extends GameEvent {
  final String locationId;

  const LocationEvent({
    required super.name,
    required this.locationId,
  });

  const LocationEvent.entered({required String locationId})
      : this(name: Events.enteredLocation, locationId: locationId);

  const LocationEvent.left({required String locationId})
      : this(name: Events.leftLocation, locationId: locationId);
}

class HistoryEvent extends GameEvent {
  final HTStruct data;

  const HistoryEvent({
    required super.name,
    required this.data,
  });

  const HistoryEvent.occurred({required HTStruct data})
      : this(name: Events.incidentOccurred, data: data);
}
