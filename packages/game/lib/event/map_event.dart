import 'dart:ui';

import 'event.dart';
import '../engine/tilemap/tile.dart';
import '../engine/tilemap/actor.dart';

abstract class MapEvents {
  static const onMapLoaded = 'mapLoaded';
  static const onMapTapped = 'tileTapped';
}

class MapEvent extends GameEvent {
  const MapEvent.mapLoaded() : super(MapEvents.onMapLoaded);
}

class MapInteractionEvent extends GameEvent {
  final Offset globalPosition;

  final TileMapTerrain? terrain;
  final TileMapActor? actor;

  const MapInteractionEvent.mapTapped(
      {required this.globalPosition, this.terrain, this.actor})
      : super(MapEvents.onMapTapped);
}
