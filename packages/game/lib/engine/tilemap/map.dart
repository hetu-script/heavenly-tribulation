import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../../ui/shared/pointer_detector.dart';
import '../gestures/gesture_mixin.dart';
import '../extensions.dart';
import 'tile.dart';
import '../engine.dart';
import '../../event/map_event.dart';
import 'zone.dart';
import 'actor.dart';
import 'cloud.dart';

enum WorldStyle {
  innerland,
  island,
  beach,
}

class TileMapRouteNode {
  final TilePosition tilePosition;
  final Vector2 worldPosition;

  TileMapRouteNode({required this.tilePosition, required this.worldPosition});
}

class MapComponent extends GameComponent with HandlesGesture {
  static const maxCloudsCout = 16;
  static const cloudsKindNum = 12;

  static final selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow;

  static final routePaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.white;

  @override
  Camera get camera => gameRef.camera;

  final TileShape tileShape;
  final int heroX, heroY;
  final double gridWidth, gridHeight;

  final int mapTileWidth, mapTileHeight;

  final bool tapSelect;

  Vector2 mapScreenSize = Vector2.zero();

  TileMapTerrain? selectedTerrain;
  TileMapInteractable? selectedInteractable;
  List<TileMapActor>? selectedActors;

  final List<List<TileMapTerrain>> terrains;
  final List<TileMapInteractable?> interactables;
  final List<TileMapActor> actors;
  final List<Zone> zones;
  // final List<TileMapRoute> routes;

  final List<TileMapCloud> clouds = [];

  bool isTimeFlowing = false;

  final TileMapActor? hero;
  List<TileMapRouteNode>? currentRoute;

  MapComponent({
    required this.tileShape,
    this.tapSelect = false,
    required this.heroX,
    required this.heroY,
    required this.gridWidth,
    required this.gridHeight,
    required this.mapTileWidth,
    required this.mapTileHeight,
    required this.terrains,
    this.interactables = const [],
    required this.hero,
    this.actors = const [],
    // this.routes = const [],
    this.zones = const [],
  }) {
    assert(terrains.isNotEmpty);
    scale = Vector2(MapTile.defaultScale, MapTile.defaultScale);
  }

  static int tilePosition2Index(int left, int top, int tileMapWidth) {
    return (left - 1) + (top - 1) * tileMapWidth;
  }

  static Future<MapComponent> fromJson(Map<String, dynamic> data) async {
    final tileShapeData = data['tileShape'];
    var tileShape = TileShape.orthogonal;
    if (tileShapeData == 'isometric') {
      tileShape = TileShape.isometric;
    } else if (tileShapeData == 'hexagonalHorizontal') {
      tileShape = TileShape.hexagonalHorizontal;
    } else if (tileShapeData == 'hexagonalVertical') {
      tileShape = TileShape.hexagonalVertical;
    }
    final tapSelect = data['tapSelect'] ?? false;

    final gridWidth = data['gridWidth'];
    final gridHeight = data['gridHeight'];
    final tileSpriteSrcWidth = data['tileSpriteSrcWidth'];
    final tileSpriteSrcHeight = data['tileSpriteSrcHeight'];
    final tileOffsetX = data['tileOffsetX'];
    final tileOffsetY = data['tileOffsetY'];

    final terrainSpritePath = data['terrainSpriteSheet'];
    final terrainSpriteSheet = SpriteSheet(
      image: await Flame.images.load(terrainSpritePath),
      srcSize: Vector2(tileSpriteSrcWidth, tileSpriteSrcHeight),
    );

    final int tileMapWidth = data['width'];
    final int tileMapHeight = data['height'];
    final int heroX = data['heroX'];
    final int heroY = data['heroY'];
    final terrainsData = data['terrains'];

    final zonesData = data['zones'];
    final zones = <Zone>[];
    for (final zoneData in zonesData) {
      final index = zoneData['index'];
      final name = zoneData['name'];
      zones.add(Zone(index: index, name: name));
    }

    // final routesData = data['routes'];
    // final routes = <TileMapRoute>[];
    // for (final routeData in routesData) {
    //   final tiles = <TilePosition>[];
    //   for (final index in routeData) {
    //     final left = index % mapTileWidth + 1;
    //     final top = index ~/ mapTileHeight + 1;
    //     tiles.add(TilePosition(left, top));
    //   }
    //   final route = TileMapRoute(tiles: tiles);
    //   routes.add(route);
    // }

    final List<List<TileMapTerrain>> terrains = [];
    for (var j = 0; j < tileMapHeight; ++j) {
      terrains.add([]);
      for (var i = 0; i < tileMapWidth; ++i) {
        final index = tilePosition2Index(i + 1, j + 1, tileMapWidth);
        final terrainData = terrainsData[index];
        final spritePath = terrainData['sprite'];
        final spriteIndex = terrainData['spriteIndex'];
        final animationPath = terrainData['animation'];
        int animationFrameCount = terrainData['animationFrameCount'] ?? 1;
        Sprite? sprite;
        if (spritePath != null) {
          sprite = await Sprite.load(
            spritePath,
            srcSize: Vector2(tileSpriteSrcWidth, tileSpriteSrcHeight),
          );
        } else if (spriteIndex != null) {
          sprite = terrainSpriteSheet.getSpriteById(spriteIndex - 1);
        }
        SpriteAnimation? animation;
        if (animationPath != null) {
          final sheet = SpriteSheet(
              image: await Flame.images.load(animationPath),
              srcSize: Vector2(
                tileSpriteSrcWidth,
                tileSpriteSrcHeight,
              ));
          animation = sheet.createAnimation(
              row: 0,
              stepTime: MapTile.defaultAnimationStepTime,
              from: 0,
              to: animationFrameCount);
        }
        final zoneIndex = terrainData['zoneIndex'];
        var isEntry = false;
        if (i + 1 == heroX && j + 1 == heroY) {
          isEntry = true;
        }
        final tile = TileMapTerrain(
          shape: tileShape,
          left: i + 1,
          top: j + 1,
          tileMapWidth: tileMapWidth,
          srcWidth: tileSpriteSrcWidth,
          srcHeight: tileSpriteSrcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          isVisible: true,
          zoneIndex: zoneIndex,
          sprite: sprite,
          animation: animation,
          offsetX: tileOffsetX,
          offsetY: tileOffsetY,
        );
        if (isEntry) {
          tile.isVisible = true;
        }
        terrains[j].add(tile);
      }
    }

    final interactablesData = data['interactables'];
    final List<TileMapInteractable> interactables = [];
    if (interactablesData != null) {
      for (final interactableData in interactablesData) {
        final int zoneIndex = interactableData['zoneIndex'];
        final String? locationId = interactableData['locationId'];
        final int left = interactableData['left'];
        final int top = interactableData['top'];
        final double srcWidth = interactableData['srcWidth'];
        final double srcHeight = interactableData['srcHeight'];
        final double offsetX = interactableData['offsetX'] ?? 0.0;
        final double offsetY = interactableData['offsetY'] ?? 0.0;
        final String? spritePath = interactableData['sprite'];
        final int? spriteIndex = interactableData['spriteIndex'];
        final String? animationPath = interactableData['animation'];
        final int? animationFrameCount =
            interactableData['animationFrameCount'] ?? 1;
        Sprite? sprite;
        if (spritePath != null) {
          sprite = await Sprite.load(
            spritePath,
            srcSize: Vector2(tileSpriteSrcWidth, tileSpriteSrcHeight),
          );
        } else if (spriteIndex != null) {
          sprite = terrainSpriteSheet.getSpriteById(spriteIndex - 1);
        }
        SpriteAnimation? animation;
        if (animationPath != null) {
          final sheet = SpriteSheet(
              image: await Flame.images.load(animationPath),
              srcSize: Vector2(
                srcWidth,
                srcHeight,
              ));
          animation = sheet.createAnimation(
              row: 0,
              stepTime: MapTile.defaultAnimationStepTime,
              from: 0,
              to: animationFrameCount);
        }
        final interactable = TileMapInteractable(
          shape: tileShape,
          left: left,
          top: top,
          tileMapWidth: tileMapWidth,
          srcWidth: srcWidth,
          srcHeight: srcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          isVisible: true,
          zoneIndex: zoneIndex,
          locationId: locationId,
          sprite: sprite,
          animation: animation,
          offsetX: offsetX,
          offsetY: offsetY,
        );
        interactables.add(interactable);
      }
    }

    final sheet = SpriteSheet.fromColumnsAndRows(
      image: await Flame.images.load('character/tile_character.png'),
      columns: 4,
      rows: 4,
    );
    final hero = TileMapActor(
        shape: tileShape,
        gridWidth: gridWidth,
        gridHeight: gridHeight,
        left: heroX,
        top: heroY,
        tileMapWidth: tileMapWidth,
        srcWidth: 32,
        srcHeight: 32,
        characterId: 'current',
        spriteSheet: sheet);

    return MapComponent(
      tileShape: tileShape,
      tapSelect: tapSelect,
      heroX: heroX,
      heroY: heroY,
      mapTileWidth: tileMapWidth,
      mapTileHeight: tileMapHeight,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      terrains: terrains,
      zones: zones,
      interactables: interactables,
      hero: hero,
      // routes: routes,
    );
  }

  // 从索引得到坐标
  TilePosition index2TilePosition(int index) {
    final left = index % mapTileWidth + 1;
    final top = index ~/ mapTileHeight + 1;
    return TilePosition(left, top);
  }

  bool isPositionWithinMap(int left, int top) {
    return (left > 0 &&
        top > 0 &&
        left <= mapTileWidth &&
        top <= mapTileHeight);
  }

  List<TilePosition> getNeighborTilePositions(int left, int top) {
    final positions = <TilePosition>[];
    switch (tileShape) {
      case TileShape.orthogonal:
        positions.add(TilePosition(left - 1, top));
        positions.add(TilePosition(left, top - 1));
        positions.add(TilePosition(left + 1, top));
        positions.add(TilePosition(left, top + 1));
        break;
      case TileShape.hexagonalVertical:
        positions.add(TilePosition(left - 1, top));
        positions.add(TilePosition(left, top - 1));
        positions.add(TilePosition(left + 1, top));
        positions.add(TilePosition(left, top + 1));
        if (left.isOdd) {
          positions.add(TilePosition(left - 1, top - 1));
          positions.add(TilePosition(left + 1, top - 1));
        } else {
          positions.add(TilePosition(left + 1, top + 1));
          positions.add(TilePosition(left - 1, top + 1));
        }
        break;
      case TileShape.isometric:
        throw 'Get neighbors of Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Get neighbors of Vertical hexagonal map tile is not supported yet!';
    }
    return positions;
  }

  TileMapTerrain? getTerrainByPosition(TilePosition position) {
    return getTerrain(position.left, position.top);
  }

  TileMapTerrain? getTerrain(int left, int top) {
    if (isPositionWithinMap(left, top)) {
      return terrains[top - 1][left - 1];
    } else {
      return null;
    }
  }

  TileMapInteractable? getInteractable(int left, int top) {
    try {
      return interactables.singleWhere(
          (element) => element!.left == left && element.top == top);
    } catch (e) {
      if (e is StateError) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  bool removeInteractable(int left, int top) {
    final interactable = getInteractable(left, top);
    if (interactable != null) {
      remove(interactable);
      interactables.removeWhere(
          (element) => element!.left == left && element.top == top);
      return true;
    } else {
      return false;
    }
  }

  void _lightUpAroundTerrain(TileMapTerrain tile) {
    // final neighbors = getNeighborTilePositions(tile.left, tile.top);
    // for (final pos in neighbors) {
    //   final neighbor = getTerrainByPosition(pos);
    //   if (neighbor != null && !neighbor.isVoid) {
    //     if (neighbor.isVisible) {
    //       continue;
    //     } else {
    //       neighbor.isVisible = true;
    //       final entity = getEntity(neighbor.left, neighbor.top);
    //       entity?.isVisible = true;
    //       if (!neighbor.isRoom) {
    //         _lightUpAroundTerrain(neighbor);
    //       }
    //     }
    //   }
    // }
  }

  void lightUpAroundTerrain(int left, int top) {
    final tile = getTerrain(left, top);
    if (tile == null) {
      return;
    }

    _lightUpAroundTerrain(tile);
  }

  Vector2 worldPosition2Screen(Vector2 position) {
    return position - camera.position;
  }

  Vector2 screenPosition2World(Vector2 position) {
    return position + camera.position;
  }

  Vector2 tilePosition2TileCenterInWorld(int left, int top) {
    late final double rl, rt;
    switch (tileShape) {
      case TileShape.orthogonal:
        rl = ((left - 1) * gridWidth);
        rt = ((top - 1) * gridHeight);
        break;
      case TileShape.hexagonalVertical:
        rl = (left - 1) * gridWidth * (3 / 4) + gridWidth / 2;
        rt = left.isOdd
            ? (top - 1) * gridHeight + gridHeight / 2
            : (top - 1) * gridHeight + gridHeight;
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    return Vector2(rl, rt);
  }

  Vector2 tilePosition2TileCenterInScreen(int left, int top) {
    final worldPos = tilePosition2TileCenterInWorld(left, top);
    final scaled = Vector2(worldPos.x * scale.x, worldPos.y * scale.y);
    return scaled - camera.position;
  }

  TilePosition screenPosition2Tile(Vector2 position) {
    final worldPos = screenPosition2World(position);
    late final int left, top;
    switch (tileShape) {
      case TileShape.orthogonal:
        left = (worldPos.x / scale.x / gridWidth).floor();
        top = (worldPos.y / scale.x / gridHeight).floor();
        break;
      case TileShape.hexagonalVertical:
        int l = (worldPos.x / (gridWidth * 3 / 4) / scale.x).floor() + 1;
        final inTilePosX = worldPos.x / scale.x - (l - 1) * (gridWidth * 3 / 4);
        late final double inTilePosY;
        int t;
        if (l.isOdd) {
          t = (worldPos.y / scale.y / gridHeight).floor() + 1;
          inTilePosY = gridHeight / 2 - (worldPos.y / scale.y) % gridHeight;
        } else {
          t = ((worldPos.y / scale.y - gridHeight / 2) / gridHeight).floor() +
              1;
          inTilePosY = gridHeight / 2 -
              (worldPos.y / scale.y - gridHeight / 2) % gridHeight;
        }
        if (inTilePosX < gridWidth / 4) {
          if (l.isOdd) {
            if (inTilePosY >= 0) {
              if (inTilePosY / inTilePosX > gridHeight / gridWidth * 2) {
                left = l - 1;
                top = t - 1;
              } else {
                left = l;
                top = t;
              }
            } else {
              if (-inTilePosY / inTilePosX > gridHeight / gridWidth * 2) {
                left = l - 1;
                top = t;
              } else {
                left = l;
                top = t;
              }
            }
          } else {
            if (inTilePosY >= 0) {
              if (inTilePosY / inTilePosX > gridHeight / gridWidth * 2) {
                left = l - 1;
                top = t;
              } else {
                left = l;
                top = t;
              }
            } else {
              if (-inTilePosY / inTilePosX > gridHeight / gridWidth * 2) {
                left = l - 1;
                top = t + 1;
              } else {
                left = l;
                top = t;
              }
            }
          }
        } else {
          left = l;
          top = t;
        }
        break;
      case TileShape.isometric:
        throw 'Get Isometric map tile position from screen position is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Get Horizontal hexagonal map tile position from screen position is not supported yet!';
    }
    return TilePosition(left, top);
  }

  void moveCameraToTilePosition(int left, int top,
      {bool animated = true, double speed = 500.0}) {
    final dest = Vector2(left * gridWidth * scale.x + gridWidth / 2 * scale.x,
            top * gridHeight * scale.x + gridHeight / 2 * scale.y) -
        gameRef.size / 2;
    camera.speed = speed;
    camera.moveTo(dest);
    if (!animated) {
      camera.snap();
    }
  }

  void moveHeroToTilePositionByRoute(List<int> route) {
    if (hero!.isMoving) {
      return;
    }
    assert(hero!.index == route.first);
    currentRoute = route
        .map((index) {
          final tilePos = index2TilePosition(index);
          final worldPos =
              tilePosition2TileCenterInWorld(tilePos.left, tilePos.top);
          return TileMapRouteNode(
              tilePosition: tilePos, worldPosition: worldPos);
        })
        .toList()
        .reversed
        .toList();
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.snapTo(camera.position - details.delta.toVector2());
  }

  @override
  void onTapUp(int pointer, int buttons, TapUpDetails details) {
    final screenPosition = details.globalPosition.toVector2();

    // print('clicked!');
    // print('world position: ${screenPosition2World(screenPosition)}');
    // print('camera position: ${camera.position}');
    // print('screen position: $screenPosition');
    // print('tile position: ${screenPosition2Tile(screenPosition)}');

    final tilePos = screenPosition2Tile(screenPosition);
    final terrain = getTerrain(tilePos.left, tilePos.top);
    final interactable = getInteractable(tilePos.left, tilePos.top);
    if (terrain != null) {
      // if (tile.isRoom && tile.isVisible) {
      //   gameRef.game.hetu.invoke('handleMazeTileInteraction',
      //       positionalArgs: [tile.left, tile.top]);
      // }
      if (tapSelect) {
        if (selectedTerrain != null) {
          selectedTerrain = null;
          selectedInteractable = null;
        } else {
          if (hero == null || !hero!.isMoving) {
            selectedTerrain = terrain;
            selectedInteractable = interactable;
          }
        }
      }
    } else {
      selectedTerrain = null;
      selectedInteractable = null;
    }
    engine.broadcast(MapInteractionEvent.mapTapped(
        globalPosition: details.globalPosition,
        terrain: terrain,
        interactable: interactable));
  }

  @override
  void onMouseMove(MouseMoveUpdateDetails details) {}

  @override
  Future<void> onLoad() async {
    super.onLoad();
    for (final row in terrains) {
      if (tileShape == TileShape.hexagonalVertical) {
        for (var i = 0; i < row.length; i = i + 2) {
          final tile = row[i];
          add(tile);
        }
        for (var i = 1; i < row.length; i = i + 2) {
          final tile = row[i];
          add(tile);
        }
      } else {
        for (final tile in row) {
          add(tile);
        }
      }
    }
    for (final tile in interactables) {
      add(tile!);
    }
    if (hero != null) {
      add(hero!);
    }
    for (final actor in actors) {
      add(actor);
    }
    double mapScreenSizeX = (gridWidth * 3 / 4) * mapTileWidth;
    double mapScreenSizeY = (gridHeight * mapTileHeight + gridHeight / 2);
    mapScreenSize = Vector2(mapScreenSizeX, mapScreenSizeY);
    moveCameraToTilePosition(heroX, heroY);

    final r = math.Random().nextInt(6);
    for (var i = 0; i < r; ++i) {
      final cloud = TileMapCloud(screenSize: mapScreenSize);
      clouds.add(cloud);
      add(cloud);
    }
  }

  @override
  void updateTree(double dt, {bool callOwnUpdate = true}) {
    super.updateTree(dt);

    if (clouds.length < maxCloudsCout) {
      final r = math.Random().nextDouble();
      if (r < 0.03) {
        final cloud = TileMapCloud(screenSize: mapScreenSize);
        clouds.add(cloud);
        add(cloud);
      }
    }

    clouds.removeWhere((cloud) {
      if (!cloud.visible) {
        remove(cloud);
        return true;
      }
      return false;
    });

    if (currentRoute != null && currentRoute!.isNotEmpty) {
      final char = hero!;
      if (!char.isMoving) {
        currentRoute!.removeLast();
        if (currentRoute!.isNotEmpty) {
          final nextTile = currentRoute!.last;
          char.moveTo(nextTile.tilePosition);
        }
      }
    }
  }

  @override
  void renderTree(Canvas canvas) {
    super.renderTree(canvas);
    canvas.save();
    canvas.transform(transformMatrix.storage);
    if (selectedTerrain != null) {
      canvas.drawPath(selectedTerrain!.path, selectedPaint);
    }
    canvas.restore();
  }

  @override
  bool containsPoint(Vector2 point) {
    return true;
  }
}
