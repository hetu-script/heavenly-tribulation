import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
// import 'package:hetu_script/values.dart';

import '../ui/pointer_detector.dart';
import '../component/game_component.dart';
import '../gestures/gesture_mixin.dart';
import '../extensions.dart';
import 'tile.dart';
import 'zone.dart';
import 'entity.dart';
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

// enum DestinationAction {
//   none,
//   enter,
//   check,
// }

class TileMap extends GameComponent with HandlesGesture {
  static const maxCloudsCout = 16;
  static const cloudsKindNum = 12;

  static final selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow;

  static final fogPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black;

  static final fogNeighborPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.black.withOpacity(0.5);

  static Future<TileMap> fromData(
      {required SamsaraEngine engine, required dynamic data}) async {
    final sceneKey = data['scene'];
    final tileShapeData = data['tileShape'];
    var tileShape = TileShape.orthogonal;
    if (tileShapeData == 'isometric') {
      tileShape = TileShape.isometric;
    } else if (tileShapeData == 'hexagonalHorizontal') {
      tileShape = TileShape.hexagonalHorizontal;
    } else if (tileShapeData == 'hexagonalVertical') {
      tileShape = TileShape.hexagonalVertical;
    }
    // final tapSelect = data['tapSelect'] ?? false;

    final gridWidth = data['gridWidth'].toDouble();
    final gridHeight = data['gridHeight'].toDouble();
    final tileSpriteSrcWidth = data['tileSpriteSrcWidth'].toDouble();
    final tileSpriteSrcHeight = data['tileSpriteSrcHeight'].toDouble();
    final tileOffsetX = data['tileOffsetX'];
    final tileOffsetY = data['tileOffsetY'];

    final terrainSpritePath = data['terrainSpriteSheet'];
    final terrainSpriteSheet = SpriteSheet(
      image: await Flame.images.load(terrainSpritePath),
      srcSize: Vector2(tileSpriteSrcWidth, tileSpriteSrcHeight),
    );

    final int tileMapWidth = data['width'];
    final int tileMapHeight = data['height'];
    final terrainsData = data['terrains'];

    final zonesData = data['zones'];
    final zones = <TileMapZone>[];
    if (zonesData != null) {
      for (final zoneData in zonesData) {
        final int index = zoneData['index'];
        final String colorHex = zoneData['color'];
        final color = HexColor.fromHex(colorHex);
        zones.add(TileMapZone(
          index: index,
          color: color,
        ));
      }
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
        final bool isVisible = terrainData['isVisible'] ?? true;
        final bool isSelectable = terrainData['isSelectable'] ?? false;
        final bool showGrid = terrainData['showGrid'] ?? false;
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
          tileShape: tileShape,
          left: i + 1,
          top: j + 1,
          isVisible: isVisible,
          isSelectable: isSelectable,
          showGrid: showGrid,
          tileMapWidth: tileMapWidth,
          srcWidth: tileSpriteSrcWidth,
          srcHeight: tileSpriteSrcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
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

    final entityData = data['entities'];
    final entities = <TileMapEntity>[];
    if (entityData != null) {
      for (final data in entityData) {
        final spriteSrc = data['spriteSrc'];
        final entitySpriteSrcWidth = data['srcWidth'].toDouble();
        final entitySpriteSrcHeight = data['srcHeight'].toDouble();
        final Sprite sprite = Sprite(await Flame.images.load(spriteSrc));
        final entity = TileMapEntity(
          engine: engine,
          sceneKey: sceneKey,
          left: data['left'],
          top: data['top'],
          sprite: sprite,
          tileShape: tileShape,
          tileMapWidth: tileMapWidth,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          srcWidth: entitySpriteSrcWidth,
          srcHeight: entitySpriteSrcHeight,
        );

        final tile = terrains[entity.index];
        tile.entity = entity;
        entities.add(entity);
      }
    }

    return TileMap(
      engine: engine,
      sceneKey: sceneKey,
      tileShape: tileShape,
      tileMapWidth: tileMapWidth,
      tileMapHeight: tileMapHeight,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      terrains: terrains,
      zones: zones,
      entities: entities,
    );
  }

  @override
  Camera get camera => gameRef.camera;

  final SamsaraEngine engine;
  final String sceneKey;

  final TileShape tileShape;
  final double gridWidth, gridHeight;

  final int tileMapWidth, tileMapHeight;

  // final bool tapSelect;

  Vector2 mapScreenSize = Vector2.zero();

  TileMapTerrain? selectedTerrain;
  List<TileMapEntity>? selectedActors;

  final List<TileMapTerrain> terrains;
  final List<TileMapZone> zones;
  final List<TileMapEntity> entities;
  TileMapEntity? _hero;
  TileMapEntity? get hero => _hero;
  set hero(TileMapEntity? entity) {
    _hero = entity;
    if (_hero != null) {
      lightUpAroundTile(_hero!.tilePosition, size: 1);
      moveCameraToTilePosition(_hero!.left, _hero!.top);
    }
  }

  final List<AnimatedCloud> _clouds = [];

  bool isTimeFlowing = false;

  List<TileMapRouteNode>? _currentRoute;

  // TileMapTerrain? _currentMoveDestination;

  // DestinationAction currentDestinationAction = DestinationAction.none;

  VoidCallback? _currentDestinationCallback;

  GridMode gridMode = GridMode.none;

  bool showClouds = true;
  bool showSelected = true;
  bool showFogOfWar = false;
  bool isFogOfWarForever = false;

  final Set<TilePosition> _visiblePerimeter = {};

  TileMap({
    required this.engine,
    required this.sceneKey,
    required this.tileShape,
    // this.tapSelect = false,
    required this.gridWidth,
    required this.gridHeight,
    required this.tileMapWidth,
    required this.tileMapHeight,
    required this.terrains,
    this.zones = const [],
    this.entities = const [],
    // this.routes = const [],
    // required this._hero,
  }) {
    assert(terrains.isNotEmpty);
    scale = Vector2(TileMapTerrain.defaultScale, TileMapTerrain.defaultScale);
  }

  // 从索引得到坐标
  TilePosition index2TilePosition(int index) {
    final left = index % tileMapWidth + 1;
    final top = index ~/ tileMapWidth + 1;
    return TilePosition(left, top);
  }

  bool isPositionWithinMap(int left, int top) {
    return (left > 0 &&
        top > 0 &&
        left <= tileMapWidth &&
        top <= tileMapHeight);
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
      return terrains[tilePosition2Index(left, top, tileMapWidth)];
    } else {
      return null;
    }
  }

  void lightUpAroundTile(TilePosition tilePosition, {int size = 0}) {
    final start = getTerrain(tilePosition.left, tilePosition.top)!;
    start.isVisible = true;
    _visiblePerimeter.remove(tilePosition);
    final neighbors =
        getNeighborTilePositions(tilePosition.left, tilePosition.top);
    for (final pos in neighbors) {
      final tile = getTerrain(pos.left, pos.top);
      if (tile != null) {
        if (!tile.isVisible) {
          _visiblePerimeter.add(tile.tilePosition);
        }
        if (size > 0) {
          lightUpAroundTile(pos, size: size - 1);
        }
      }
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
      [VoidCallback? onDestinationCallback]) {
    assert(_hero != null);
    if (_hero!.isMoving) return;
    _currentDestinationCallback = onDestinationCallback;
    assert(tilePosition2Index(_hero!.left, _hero!.top, tileMapWidth) ==
        route.first);
    _currentRoute = route
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

  void selectTile(int left, int top) {
    final terrain = getTerrain(left, top);
    if (terrain != null) {
      if (terrain.isSelectable) selectedTerrain = terrain;
    } else {
      selectedTerrain = null;
    }
  }

  @override
  void onTap(int pointer, int buttons, TapUpDetails details) {
    final screenPosition = details.globalPosition.toVector2();
    final tilePosition = screenPosition2Tile(screenPosition);
    selectTile(tilePosition.left, tilePosition.top);

    // if (kDebugMode) {
    //   print('tilemap tapped at: $tilePosition');
    // }
    engine.broadcast(MapInteractionEvent.mapTapped(
        globalPosition: details.globalPosition,
        buttons: buttons,
        tilePosition: tilePosition));
  }

  @override
  void onDoubleTap(int pointer, int buttons, TapUpDetails details) {
    final screenPosition = details.globalPosition.toVector2();
    final tilePosition = screenPosition2Tile(screenPosition);
    selectTile(tilePosition.left, tilePosition.top);

    // if (kDebugMode) {
    // print('tilemap double tapped at: $tilePosition');
    // }
    engine.broadcast(MapInteractionEvent.mapDoubleTapped(
        globalPosition: details.globalPosition,
        buttons: buttons,
        tilePosition: tilePosition));
  }

  @override
  void onMouseMove(MouseMoveUpdateDetails details) {}

  @override
  Future<void> onLoad() async {
    super.onLoad();
    double mapScreenSizeX = (gridWidth * 3 / 4) * tileMapWidth;
    double mapScreenSizeY = (gridHeight * tileMapHeight + gridHeight / 2);
    mapScreenSize = Vector2(mapScreenSizeX, mapScreenSizeY);

    if (showClouds) {
      final r = math.Random().nextInt(6);
      for (var i = 0; i < r; ++i) {
        final cloud = AnimatedCloud(screenSize: mapScreenSize);
        _clouds.add(cloud);
        add(cloud);
      }
    }
  }

  @override
  void updateTree(double dt, {bool callOwnUpdate = true}) {
    super.updateTree(dt);

    if (showClouds) {
      if (_clouds.length < maxCloudsCout) {
        final r = math.Random().nextDouble();
        if (r < 0.03) {
          final cloud = AnimatedCloud(screenSize: mapScreenSize);
          _clouds.add(cloud);
          add(cloud);
        }
      }
      _clouds.removeWhere((cloud) {
        if (!cloud.visible) {
          remove(cloud);
          return true;
        }
        return false;
      });
    }

    if (_hero != null) {
      if (_currentRoute != null && _currentRoute!.isNotEmpty) {
        if (!_hero!.isMoving) {
          final current = getTerrain(_hero!.left, _hero!.top)!;
          lightUpAroundTile(current.tilePosition, size: 1);
          _currentRoute!.removeLast();
          if (_currentRoute!.isNotEmpty) {
            final nextTile = _currentRoute!.last;
            _hero!.moveTo(nextTile.tilePosition);
            final pos = nextTile.tilePosition;
            final terrain = getTerrain(pos.left, pos.top);
            if (terrain!.isWater) {
              _hero!.isOnWater = true;
            } else {
              _hero!.isOnWater = false;
            }
          } else {
            if (_currentDestinationCallback != null) {
              _currentDestinationCallback!();
            }
          }
        }
      }
    }

    _hero?.update(dt);
  }

  @override
  void renderTree(Canvas canvas) {
    super.renderTree(canvas);
    canvas.save();
    canvas.transform(transformMatrix.storage);

    // to avoid overlapping, render the tiles in a specific order:
    for (var j = 0; j < tileMapHeight; ++j) {
      if (tileShape == TileShape.hexagonalVertical) {
        for (var i = 0; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          tile.render(canvas);
        }
        for (var i = 1; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          tile.render(canvas);
        }
      } else {
        for (var i = 0; i < tileMapWidth; ++i) {
          final tile = terrains[i + j * tileMapWidth];
          tile.render(canvas);
        }
      }
    }

    // after all terrains, render the entities, in the same way:
    for (var j = 0; j < tileMapHeight; ++j) {
      if (tileShape == TileShape.hexagonalVertical) {
        for (var i = 0; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          tile.entity?.render(canvas);
        }
        for (var i = 1; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          tile.entity?.render(canvas);
        }
      } else {
        for (var i = 0; i < tileMapWidth; ++i) {
          final tile = terrains[i + j * tileMapWidth];
          tile.entity?.render(canvas);
        }
      }
    }

    if (gridMode == GridMode.zone) {
      for (final tile in terrains) {
        final color = engine.zoneColors[tile.zoneIndex]!;
        final paint = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withOpacity(0.6);
        canvas.drawPath(tile.borderPath, paint);
      }
    } else if (gridMode == GridMode.nation) {
      for (final tile in terrains) {
        if (tile.nationId != null) {
          final color = engine.nationColors[tile.nationId]!;
          final paint = Paint()
            ..style = PaintingStyle.fill
            ..color = color.withOpacity(0.6);
          canvas.drawPath(tile.borderPath, paint);
        }
      }
    }

    if (showFogOfWar) {
      for (final tile in terrains) {
        if (tile.isVisible) {
          continue;
        } else if (_visiblePerimeter.contains(tile.tilePosition)) {
          canvas.drawShadow(tile.borderPath, Colors.black, 0, true);
        } else {
          final Paint paint = Paint()
            ..color = Colors.black
            ..maskFilter =
                MaskFilter.blur(BlurStyle.normal, convertRadiusToSigma(0.5));
          canvas.drawPath(tile.shadowPath, paint);
        }
      }
    }
    if (showSelected && selectedTerrain != null) {
      canvas.drawPath(selectedTerrain!.borderPath, selectedPaint);
    }
    _hero?.render(canvas);
    canvas.restore();
  }

  @override
  bool containsPoint(Vector2 point) {
    return true;
  }
}
