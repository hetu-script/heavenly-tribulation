import 'event.dart';
import '../engine/tilemap/tile.dart';
import '../engine/tilemap/actor.dart';

abstract class MapEvents {
  static const onMapLoaded = 'mapLoaded';
  static const onTileTapped = 'tileTapped';
}

class MapEvent extends GameEvent {
  final TileMapTerrain? terrain;
  final TileMapEntity? entity;
  final TileMapActor? actor;

  const MapEvent({
    required String eventName,
    this.terrain,
    this.entity,
    this.actor,
  }) : super(eventName);

  const MapEvent.mapLoaded() : this(eventName: MapEvents.onMapLoaded);

  const MapEvent.tileTapped(
      {required TileMapTerrain terrain,
      TileMapEntity? entity,
      TileMapActor? actor})
      : this(
            eventName: MapEvents.onTileTapped,
            terrain: terrain,
            entity: entity,
            actor: actor);
}
