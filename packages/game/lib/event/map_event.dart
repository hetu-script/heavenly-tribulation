import 'dart:ui';

import 'event.dart';
import '../engine/tilemap/tile.dart';
import '../engine/tilemap/actor.dart';

abstract class MapEvents {
  static const onMapLoaded = 'mapLoaded';
  static const onMapTapped = 'tileTapped';
}

class MapEvent extends GameEvent {
  final MapTile? terrain;
  final TileMapActor? actor;

  const MapEvent.mapLoaded(
      {required String eventName, this.terrain, this.actor})
      : super(MapEvents.onMapLoaded);
}

class MapInteractionEvent extends GameEvent {
  final Offset globalPosition;

  final MapTile? terrain;
  final TileMapActor? actor;

  const MapInteractionEvent.mapTapped(
      {required this.globalPosition, this.terrain, this.actor})
      : super(MapEvents.onMapTapped);
}
