import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../../ui/pointer_detector.dart';
import '../gestures/gesture_mixin.dart';
import '../extensions.dart';
import 'tile.dart';
import '../game.dart';
import '../../event/map_event.dart';
import 'zone.dart';
import 'actor.dart';
import 'cloud.dart';

enum WorldStyle {
  innerland,
  island,
  beach,
}

class TileMapRoute {
  // final int startLeft, startTop;
  final List<TilePosition> tiles;
  Path? path;

  TileMapRoute(
      {
      //required this.startLeft, required this.startTop,
      required this.tiles});
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
  TileMapEntity? selectedEntity;

  final List<List<TileMapTerrain>> terrains;
  final Map<String, TileMapEntity> entities;
  final List<TileMapActor> actors;
  final List<Zone> zones;
  // final List<TileMapRoute> routes;

  final List<TileMapCloud> clouds = [];

  bool isTimeFlowing = false;

  final TileMapActor hero;

  MapComponent({
    required SamsaraGame game,
    required this.tileShape,
    this.tapSelect = false,
    required this.heroX,
    required this.heroY,
    required this.gridWidth,
    required this.gridHeight,
    required this.mapTileWidth,
    required this.mapTileHeight,
    required this.terrains,
    this.entities = const {},
    required this.hero,
    this.actors = const [],
    // this.routes = const [],
    this.zones = const [],
  }) : super(game: game) {
    assert(terrains.isNotEmpty);
    scale = Vector2(MapTile.defaultScale, MapTile.defaultScale);

    //   for (final route in routes) {
    //     final path = Path();
    //     final start = route.tiles.first;
    //     var pos = tilePosition2TileCenterInWorld(start.left, start.top);
    //     path.moveTo(pos.x, pos.y);
    //     for (var i = 1; i < route.tiles.length; ++i) {
    //       final tile = route.tiles[i];
    //       pos = tilePosition2TileCenterInWorld(tile.left, tile.top);
    //       path.lineTo(pos.x, pos.y);
    //     }
    //     route.path = path;
    //   }
  }

  static int tilePos2Index(int left, int top, int mapTileWidth) {
    return (left - 1) + (top - 1) * mapTileWidth;
  }

  static Future<MapComponent> fromJson(
      SamsaraGame game, Map<String, dynamic> data) async {
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

    final int mapTileWidth = data['width'];
    final int mapTileHeight = data['height'];
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
    for (var j = 0; j < mapTileHeight; ++j) {
      terrains.add([]);
      for (var i = 0; i < mapTileWidth; ++i) {
        final index = tilePos2Index(i + 1, j + 1, mapTileWidth);
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
          game: game,
          shape: tileShape,
          left: i + 1,
          top: j + 1,
          index: index,
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

    final entitiyData = data['entities'];
    final Map<String, TileMapEntity> entities = {};
    if (entitiyData != null) {
      for (final key in entitiyData.keys) {
        final entityData = entitiyData[key];
        final int index = entityData['index'];
        final String id = entityData['id'];
        final int zoneIndex = entityData['zoneIndex'];
        final String name = entityData['name'];
        final int left = entityData['left'];
        final int top = entityData['top'];
        final double srcWidth = entityData['srcWidth'];
        final double srcHeight = entityData['srcHeight'];
        final double offsetX = entityData['offsetX'] ?? 0.0;
        final double offsetY = entityData['offsetY'] ?? 0.0;
        final String? spritePath = entityData['sprite'];
        final int? spriteIndex = entityData['spriteIndex'];
        final String? animationPath = entityData['animation'];
        final int? animationFrameCount = entityData['animationFrameCount'] ?? 1;
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
        final entity = TileMapEntity(
          id: id,
          name: name,
          game: game,
          shape: tileShape,
          left: left,
          top: top,
          index: index,
          srcWidth: srcWidth,
          srcHeight: srcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          isVisible: true,
          zoneIndex: zoneIndex,
          sprite: sprite,
          animation: animation,
          offsetX: offsetX,
          offsetY: offsetY,
        );
        entities[key] = entity;
      }
    }

    final sheet = SpriteSheet.fromColumnsAndRows(
      image: await Flame.images.load('character/tile_character.png'),
      columns: 4,
      rows: 4,
    );
    final hero = TileMapActor(
        game: game,
        tileShape: tileShape,
        gridWidth: gridWidth,
        gridHeight: gridHeight,
        left: heroX,
        top: heroY,
        srcWidth: 32,
        srcHeight: 32,
        characterId: 'current',
        spriteSheet: sheet);

    return MapComponent(
      game: game,
      tileShape: tileShape,
      tapSelect: tapSelect,
      heroX: heroX,
      heroY: heroY,
      mapTileWidth: mapTileWidth,
      mapTileHeight: mapTileHeight,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      terrains: terrains,
      zones: zones,
      entities: entities,
      hero: hero,
      // routes: routes,
    );
  }

  // 从索引得到坐标
  TilePosition index2TilePos(int index) {
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

  TileMapEntity? getEntity(int left, int top) {
    return entities['$left,$top'];
  }

  bool removeEntity(int left, int top) {
    final entity = entities['$left,$top'];
    if (entity != null) {
      remove(entity);
      entities.remove('$left,$top')!;
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

  void _moveToTerrain(TileMapTerrain tile) {
    final entity = getEntity(tile.left, tile.top);
    entity?.isVisible = true;
    _moveCameraToTilePosition(tile.left, tile.top, animated: true);
  }

  void moveToTerrain(int left, int top) {
    final tile = getTerrain(left, top);
    if (tile != null) {
      _moveToTerrain(tile);
    }
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
    return Vector2(rl * scale.x, rt * scale.x);
  }

  Vector2 tilePosition2TileCenterInScreen(int left, int top) =>
      tilePosition2TileCenterInWorld(left, top) - camera.position;

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
    final entity = entities['${tilePos.left},${tilePos.top}'];
    if (terrain != null) {
      // if (tile.isRoom && tile.isVisible) {
      //   gameRef.game.hetu.invoke('handleMazeTileInteraction',
      //       positionalArgs: [tile.left, tile.top]);
      // }
      if (tapSelect) {
        if (selectedTerrain != null) {
          selectedTerrain = null;
          selectedEntity = null;
        } else {
          selectedTerrain = terrain;
          selectedEntity = entity;
        }
      }
    } else {
      selectedTerrain = null;
      selectedEntity = null;
    }
    game.broadcast(MapInteractionEvent.mapTapped(
        globalPosition: details.globalPosition,
        terrain: terrain,
        entity: entity));
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
    for (final tile in entities.values) {
      add(tile);
    }
    add(hero);
    for (final actor in actors) {
      add(actor);
    }
    double mapScreenSizeX = (gridWidth * 3 / 4) * mapTileWidth;
    double mapScreenSizeY = (gridHeight * mapTileHeight + gridHeight / 2);
    mapScreenSize = Vector2(mapScreenSizeX, mapScreenSizeY);
    _moveCameraToTilePosition(heroX, heroY);

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
      if (r < 0.04) {
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

  void _moveCameraToTilePosition(int left, int top,
      {bool animated = false, double speed = 500.0}) {
    final dest = Vector2(left * gridWidth * scale.x + gridWidth / 2 * scale.x,
            top * gridHeight * scale.x + gridHeight / 2 * scale.y) -
        gameRef.size / 2;
    camera.speed = speed;
    camera.moveTo(dest);
    if (!animated) {
      camera.snap();
    }
  }
}
