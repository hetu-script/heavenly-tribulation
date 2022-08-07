import 'dart:ui';

import 'event.dart';
import '../tilemap/tile.dart';

abstract class Events {
  static const createdScene = 'created_scene';
  static const loadingScene = 'loading_scene';
  static const endedScene = 'ended_scene';
  static const loadedMap = 'loaded_map';
  static const loadedMaze = 'loaded_maze';
  static const mapTapped = 'map_tapped';
  static const mapDoubleTapped = 'map_double_tapped';
  static const mapLongPressed = 'map_long_pressed';
  static const heroMoved = 'hero_moved_on_worldmap';
}

class MapLoadedEvent extends GameEvent {
  final bool isFirstLoad;

  const MapLoadedEvent({this.isFirstLoad = false})
      : super(name: Events.loadedMap);
}

class MapInteractionEvent extends GameEvent {
  final Offset globalPosition;

  final int buttons;

  final TilePosition tilePosition;

  const MapInteractionEvent.mapTapped({
    required this.globalPosition,
    required this.buttons,
    required this.tilePosition,
  }) : super(name: Events.mapTapped);

  const MapInteractionEvent.mapDoubleTapped({
    required this.globalPosition,
    required this.buttons,
    required this.tilePosition,
  }) : super(name: Events.mapDoubleTapped);

  const MapInteractionEvent.mapLongPressed({
    required this.globalPosition,
    required this.buttons,
    required this.tilePosition,
  }) : super(name: Events.mapLongPressed);
}

class HeroEvent extends GameEvent {
  final TilePosition tilePosition;

  const HeroEvent.heroMoved({
    required String scene,
    required this.tilePosition,
  }) : super(name: Events.heroMoved, scene: scene);
}

class MazeLoadedEvent extends GameEvent {
  const MazeLoadedEvent() : super(name: Events.loadedMaze);
}
