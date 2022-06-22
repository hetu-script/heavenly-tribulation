import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../ui/pointer_detector.dart';
import '../component/game_component.dart';
import '../gestures/gesture_mixin.dart';
import '../extensions.dart';
import 'tile.dart';
import 'zone.dart';
import 'actor.dart';
import 'cloud.dart';
import '../../shared/color.dart';
import '../engine.dart';
import '../../event/events.dart';

class TileMapRouteNode {
  final TilePosition tilePosition;
  final Vector2 worldPosition;

  TileMapRouteNode({required this.tilePosition, required this.worldPosition});
}

enum GridMode {
  none,
  zone,
  nation,
}

enum DestinationAction {
  none,
  enter,
  check,
}

class TileMap extends GameComponent with HandlesGesture {
  static const maxCloudsCout = 16;
  static const cloudsKindNum = 12;

  static final selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow;

  @override
  Camera get camera => gameRef.camera;

  final SamsaraEngine engine;

  final TileShape tileShape;
  final int heroX, heroY;
  final double gridWidth, gridHeight;

  final int mapTileWidth, mapTileHeight;

  final bool tapSelect;

  Vector2 mapScreenSize = Vector2.zero();

  TileMapTerrain? selectedTerrain;
  List<TileMapActor>? selectedActors;

  final List<TileMapTerrain> terrains;
  final List<TileMapActor> actors;
  final List<TileMapZone> zones;
  // final List<TileMapRoute> routes;

  final List<TileMapCloud> clouds = [];

  bool isTimeFlowing = false;

  final TileMapActor? hero;
  List<TileMapRouteNode>? currentRoute;

  TileMapTerrain? currentMoveDestination;

  DestinationAction currentDestinationAction = DestinationAction.none;

  GridMode gridMode = GridMode.none;

  final VoidCallback? onMoved;

  TileMap({
    required this.engine,
    required this.tileShape,
    this.tapSelect = false,
    required this.heroX,
    required this.heroY,
    required this.gridWidth,
    required this.gridHeight,
    required this.mapTileWidth,
    required this.mapTileHeight,
    required this.terrains,
    required this.hero,
    this.actors = const [],
    // this.routes = const [],
    this.zones = const [],
    this.onMoved,
  }) {
    assert(terrains.isNotEmpty);
    scale = Vector2(TileMapTerrain.defaultScale, TileMapTerrain.defaultScale);
  }

  static int tilePosition2Index(int left, int top, int mapTileWidth) {
    return (left - 1) + (top - 1) * mapTileWidth;
  }

  static Future<TileMap> fromJson(
      {required SamsaraEngine engine,
      required Map<String, dynamic> data}) async {
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
    final zones = <TileMapZone>[];
    for (final zoneData in zonesData) {
      final int index = zoneData['index'];
      final String name = zoneData['name'];
      final String colorHex = zoneData['color'];
      final color = HexColor.fromHex(colorHex);
      zones.add(TileMapZone(
        index: index,
        name: name,
        color: color,
      ));
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

    final List<TileMapTerrain> terrains = [];
    for (var j = 0; j < tileMapHeight; ++j) {
      for (var i = 0; i < tileMapWidth; ++i) {
        final index = tilePosition2Index(i + 1, j + 1, tileMapWidth);
        final terrainData = terrainsData[index];
        final int zoneIndex = terrainData['zoneIndex'];
        final String zoneCategoryString = terrainData['zoneCategory'];
        ZoneCategory zoneCategory;
        switch (zoneCategoryString) {
          case 'empty':
            zoneCategory = ZoneCategory.empty;
            break;
          case 'water':
            zoneCategory = ZoneCategory.water;
            break;
          case 'continent':
            zoneCategory = ZoneCategory.continent;
            break;
          case 'island':
            zoneCategory = ZoneCategory.island;
            break;
          case 'lake':
            zoneCategory = ZoneCategory.lake;
            break;
          case 'plain':
            zoneCategory = ZoneCategory.plain;
            break;
          case 'moutain':
            zoneCategory = ZoneCategory.moutain;
            break;
          case 'forest':
            zoneCategory = ZoneCategory.forest;
            break;
          default:
            zoneCategory = ZoneCategory.continent;
        }
        final String? locationId = terrainData['locationId'];
        final String? nationId = terrainData['nationId'];
        Sprite? baseSprite;
        SpriteAnimation? baseAnimation;
        final String? baseSpritePath = terrainData['sprite'];
        final int? baseSpriteIndex = terrainData['spriteIndex'];
        final String? baseAnimationPath = terrainData['animation'];
        final int baseAnimationFrameCount =
            terrainData['animationFrameCount'] ?? 1;
        if (baseSpritePath != null) {
          baseSprite = await Sprite.load(
            baseSpritePath,
            srcSize: Vector2(tileSpriteSrcWidth, tileSpriteSrcHeight),
          );
        } else if (baseSpriteIndex != null) {
          baseSprite = terrainSpriteSheet.getSpriteById(baseSpriteIndex - 1);
        }
        if (baseAnimationPath != null) {
          final sheet = SpriteSheet(
              image: await Flame.images.load(baseAnimationPath),
              srcSize: Vector2(
                tileSpriteSrcWidth,
                tileSpriteSrcHeight,
              ));
          baseAnimation = sheet.createAnimation(
              row: 0,
              stepTime: TileMapTerrain.defaultAnimationStepTime,
              from: 0,
              to: baseAnimationFrameCount);
        }
        Sprite? overlaySprite;
        SpriteAnimation? overlayAnimation;
        final overlaySpriteData = terrainData['overlaySprite'];
        if (overlaySpriteData != null) {
          final String? overlaySpritePath = overlaySpriteData['path'];
          final int? overlaySpriteIndex = overlaySpriteData['index'];
          final String? overlayAnimationPath = overlaySpriteData['animation'];
          final int overlayAnimationFrameCount =
              overlaySpriteData['animationFrameCount'] ?? 1;
          if (overlaySpritePath != null) {
            overlaySprite = await Sprite.load(
              overlaySpritePath,
              srcSize: Vector2(tileSpriteSrcWidth, tileSpriteSrcHeight),
            );
          } else if (overlaySpriteIndex != null) {
            overlaySprite =
                terrainSpriteSheet.getSpriteById(overlaySpriteIndex - 1);
          }
          if (overlayAnimationPath != null) {
            final sheet = SpriteSheet(
                image: await Flame.images.load(overlayAnimationPath),
                srcSize: Vector2(
                  tileSpriteSrcWidth,
                  tileSpriteSrcHeight,
                ));
            overlayAnimation = sheet.createAnimation(
                row: 0,
                stepTime: TileMapTerrain.defaultAnimationStepTime,
                from: 0,
                to: overlayAnimationFrameCount);
          }
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
          zoneCategory: zoneCategory,
          locationId: locationId,
          nationId: nationId,
          baseSprite: baseSprite,
          baseAnimation: baseAnimation,
          overlaySprite: overlaySprite,
          overlayAnimation: overlayAnimation,
          offsetX: tileOffsetX,
          offsetY: tileOffsetY,
        );
        terrains.add(tile);
      }
    }

    final charSheet = SpriteSheet.fromColumnsAndRows(
      image: await Flame.images.load('character/tile_character.png'),
      columns: 4,
      rows: 6,
    );

    final shipSheet = SpriteSheet.fromColumnsAndRows(
      image: await Flame.images.load('character/tile_ship.png'),
      columns: 4,
      rows: 6,
    );

    final hero = TileMapActor(
      engine: engine,
      shape: tileShape,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      left: heroX,
      top: heroY,
      tileMapWidth: tileMapWidth,
      srcWidth: 32,
      srcHeight: 32,
      characterId: 'current',
      characterAnimationSpriteSheet: charSheet,
      shipAnimationSpriteSheet: shipSheet,
    );

    return TileMap(
      engine: engine,
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
      return terrains[tilePosition2Index(left, top, mapTileWidth)];
    } else {
      return null;
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
    final worldPos = tilePosition2TileCenterInWorld(left, top);
    final dest =
        Vector2(worldPos.x * scale.x, worldPos.y * scale.y) - gameRef.size / 2;
    camera.speed = speed;
    camera.moveTo(dest);
    if (!animated) {
      camera.snap();
    }
  }

  void moveHeroToTilePositionByRoute(List<int> route,
      {DestinationAction action = DestinationAction.none}) {
    if (hero!.isMoving) return;
    currentDestinationAction = action;
    final dest = index2TilePosition(route.last);
    currentMoveDestination = getTerrain(dest.left, dest.top);
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
    if (terrain != null) {
      // if (tile.isRoom && tile.isVisible) {
      //   gameRef.game.hetu.invoke('handleMazeTileInteraction',
      //       positionalArgs: [tile.left, tile.top]);
      // }
      if (tapSelect) {
        if (selectedTerrain != null) {
          selectedTerrain = null;
        } else {
          if (hero == null || !hero!.isMoving) {
            selectedTerrain = terrain;
          }
        }
      }
    } else {
      selectedTerrain = null;
    }

    engine.broadcast(MapInteractionEvent.mapTapped(
        globalPosition: details.globalPosition, terrain: terrain));
  }

  @override
  void onMouseMove(MouseMoveUpdateDetails details) {}

  @override
  Future<void> onLoad() async {
    super.onLoad();
    for (var j = 0; j < mapTileHeight; ++j) {
      if (tileShape == TileShape.hexagonalVertical) {
        for (var i = 0; i < mapTileWidth; i = i + 2) {
          final tile = terrains[i + j * mapTileWidth];
          add(tile);
        }
        for (var i = 1; i < mapTileWidth; i = i + 2) {
          final tile = terrains[i + j * mapTileWidth];
          add(tile);
        }
      } else {
        for (var i = 0; i < mapTileWidth; ++i) {
          final tile = terrains[i + j * mapTileWidth];
          add(tile);
        }
      }
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
        final pos = currentRoute!.last.tilePosition;
        final terrain = getTerrain(pos.left, pos.top);
        if (terrain!.isWater) {
          hero!.isOnShip = true;
        } else {
          hero!.isOnShip = false;
        }

        currentRoute!.removeLast();
        if (currentRoute!.isNotEmpty) {
          final nextTile = currentRoute!.last;
          char.moveTo(nextTile.tilePosition);
        } else {
          if (currentDestinationAction == DestinationAction.enter) {
            engine.broadcast(LocationEvent.entered(
                locationId: currentMoveDestination!.locationId!));
            currentMoveDestination = null;
          } else if (currentDestinationAction == DestinationAction.check) {
            engine.broadcast(MapInteractionEvent.checkTerrain(
                terrain: currentMoveDestination));
            currentMoveDestination = null;
          }
        }
      }
    }

    hero!.update(dt);
  }

  @override
  void renderTree(Canvas canvas) {
    super.renderTree(canvas);
    canvas.save();
    canvas.transform(transformMatrix.storage);
    if (gridMode == GridMode.zone) {
      for (final tile in terrains) {
        final color = engine.zoneColors[tile.zoneIndex]!;
        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withOpacity(0.6);
        canvas.drawPath(tile.path, paint);
      }
    } else if (gridMode == GridMode.nation) {
      for (final tile in terrains) {
        if (tile.nationId != null) {
          final color = engine.nationColors[tile.nationId]!;
          final paint = Paint()
            ..style = PaintingStyle.fill
            ..color = color.withOpacity(0.6);
          canvas.drawPath(tile.path, paint);
        }
      }
    }
    if (selectedTerrain != null) {
      canvas.drawPath(selectedTerrain!.path, selectedPaint);
    }
    hero!.render(canvas);
    canvas.restore();
  }

  @override
  bool containsPoint(Vector2 point) {
    return true;
  }
}
