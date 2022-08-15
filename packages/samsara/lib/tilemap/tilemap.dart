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
import 'object.dart';
import 'cloud.dart';
import '../../shared/color.dart';
import '../engine.dart';
import '../../event/events.dart';
import 'terrain.dart';

class TileMapRouteNode {
  final int index;
  final TilePosition tilePosition;
  final Vector2 worldPosition;

  TileMapRouteNode({
    required this.index,
    required this.tilePosition,
    required this.worldPosition,
  });
}

// enum DestinationAction {
//   none,
//   enter,
//   check,
// }

const kColorModeNone = -1;
const _kCaptionOffset = 14.0;

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

  TileMap({
    required this.engine,
    this.tileShape = TileShape.hexagonalVertical,
    this.gridWidth = 32.0,
    this.gridHeight = 28.0,
    this.tileSpriteSrcWidth = 32.0,
    this.tileSpriteSrcHeight = 64.0,
    this.tileOffsetX = 0.0,
    this.tileOffsetY = 16.0,
    double scaleFactor = 2.0,
    this.showGrids = false,
    this.showClouds = false,
    this.showSelected = false,
    this.showFogOfWar = false,
    required this.captionStyle,
  }) {
    scale = Vector2(scaleFactor, scaleFactor);
  }

  Future<void> updateData(dynamic mapData) async {
    sceneKey = mapData['id'];
    TileShape dataTileShape = TileShape.orthogonal;
    final tileShapeData = mapData['tileShape'];
    if (tileShapeData == 'isometric') {
      dataTileShape = TileShape.isometric;
    } else if (tileShapeData == 'hexagonalHorizontal') {
      dataTileShape = TileShape.hexagonalHorizontal;
    } else if (tileShapeData == 'hexagonalVertical') {
      dataTileShape = TileShape.hexagonalVertical;
    }
    if (tileShape != dataTileShape) {
      throw 'tile shape in loaded map data [$dataTileShape] is not the same to the tile map component [$tileShape]';
    }
    // final tapSelect = data['tapSelect'] ?? false;

    final dataGridWidth = mapData['gridWidth'].toDouble();
    if (gridWidth != dataGridWidth) {
      throw 'gridWidth in loaded map data [$dataGridWidth] is not the same to the tile map component [$gridWidth]';
    }

    final dataGridHeight = mapData['gridHeight'].toDouble();
    if (gridHeight != dataGridHeight) {
      throw 'gridWidth in loaded map data [$dataGridHeight] is not the same to the tile map component [$gridHeight]';
    }

    final dataTileSpriteSrcWidth = mapData['tileSpriteSrcWidth'].toDouble();
    if (tileSpriteSrcWidth != dataTileSpriteSrcWidth) {
      throw 'gridWidth in loaded map data [$dataTileSpriteSrcWidth] is not the same to the tile map component [$tileSpriteSrcWidth]';
    }

    final dataTileSpriteSrcHeight = mapData['tileSpriteSrcHeight'].toDouble();
    if (tileSpriteSrcHeight != dataTileSpriteSrcHeight) {
      throw 'gridWidth in loaded map data [$dataTileSpriteSrcHeight] is not the same to the tile map component [$tileSpriteSrcHeight]';
    }

    final dataTileOffsetX = mapData['tileOffsetX'];
    if (tileOffsetX != dataTileOffsetX) {
      throw 'gridWidth in loaded map data [$dataTileOffsetX] is not the same to the tile map component [$tileOffsetX]';
    }

    final dataTileOffsetY = mapData['tileOffsetY'];
    if (tileOffsetY != dataTileOffsetY) {
      throw 'gridWidth in loaded map data [$dataTileOffsetY] is not the same to the tile map component [$tileOffsetY]';
    }

    final terrainSpritePath = mapData['terrainSpriteSheet'];
    terrainSpriteSheet = SpriteSheet(
      image: await Flame.images.load(terrainSpritePath),
      srcSize: Vector2(tileSpriteSrcWidth, tileSpriteSrcHeight),
    );

    tileMapWidth = mapData['width'];
    tileMapHeight = mapData['height'];
    final terrainsData = mapData['terrains'];

    terrains = <TileMapTerrain>[];
    for (var j = 0; j < tileMapHeight; ++j) {
      for (var i = 0; i < tileMapWidth; ++i) {
        final index = tilePosition2Index(i + 1, j + 1, tileMapWidth);
        final terrainData = terrainsData[index];
        final bool isVisible = terrainData['isVisible'] ?? false;
        final bool isSelectable = terrainData['isSelectable'] ?? false;
        final bool isVoid = terrainData['isVoid'] ?? false;
        final bool isWater = terrainData['isWater'] ?? false;
        final String? kind = terrainData['kind'];
        final String? nationId = terrainData['nationId'];
        final String? locationId = terrainData['locationId'];
        final String? caption = terrainData['caption'];
        final String? objectId = terrainData['objectId'];
        final tile = TileMapTerrain(
          tileShape: tileShape,
          data: terrainData,
          left: i + 1,
          top: j + 1,
          isVisible: isVisible,
          isSelectable: isSelectable,
          isVoid: isVoid,
          tileMapWidth: tileMapWidth,
          srcWidth: tileSpriteSrcWidth,
          srcHeight: tileSpriteSrcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          isWater: isWater,
          kind: kind,
          nationId: nationId,
          locationId: locationId,
          caption: caption,
          captionStyle: captionStyle,
          offsetX: tileOffsetX,
          offsetY: tileOffsetY,
          objectId: objectId,
        );

        tile.loadSprite(terrainData, terrainSpriteSheet);

        final overlaySpriteData = terrainData['overlaySprite'];
        if (overlaySpriteData != null) {
          tile.loadOverlaySprite(overlaySpriteData, terrainSpriteSheet);
        }

        terrains.add(tile);
      }
    }

    final objectData = mapData['objects'];
    objects = <String, TileMapObject>{};
    if (objectData != null) {
      for (final data in objectData) {
        addObject(data);
      }
    }
  }

  @override
  Camera get camera => gameRef.camera;

  final TextStyle captionStyle;

  final SamsaraEngine engine;
  late String sceneKey;
  TileShape tileShape;

  final double gridWidth,
      gridHeight,
      tileSpriteSrcWidth,
      tileSpriteSrcHeight,
      tileOffsetX,
      tileOffsetY;

  late final SpriteSheet terrainSpriteSheet;

  late int tileMapWidth, tileMapHeight;

  // final bool tapSelect;

  Vector2 mapScreenSize = Vector2.zero();

  TileMapTerrain? selectedTerrain;
  List<TileMapObject>? selectedActors;

  List<TileMapTerrain> terrains = [];
  // List<TileMapZone> zones = [];

  /// 按id保存的object
  /// 这些object不一定都可以互动
  /// 而且也不一定都会在一开始就显示出来
  Map<String, TileMapObject> objects = {};

  void setTerrainCaption(int left, int top, String? caption) {
    final tile = getTerrain(left, top);
    assert(tile != null);
    tile!.caption = caption;
  }

  void addObject(dynamic data) async {
    final spriteSrc = data['spriteSrc'];
    final int? left = data['left'];
    final int? top = data['top'];
    final Sprite sprite = Sprite(await Flame.images.load(spriteSrc));
    final objectId = data['id'];
    final object = TileMapObject(
      engine: engine,
      sceneKey: sceneKey,
      left: left,
      top: top,
      sprite: sprite,
      tileShape: tileShape,
      tileMapWidth: tileMapWidth,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      srcWidth: data['srcWidth'].toDouble(),
      srcHeight: data['srcHeight'].toDouble(),
      entityId: objectId,
      srcOffsetY: data['srcOffsetY'] ?? 0.0,
    );

    if (left != null && top != null) {
      final tile = terrains[object.index];
      tile.objectId = objectId;
    }
    objects[objectId] = object;
  }

  void setTerrainObject(int left, int top, String? objectId) {
    if (objectId != null) assert(objects.containsKey(objectId));
    final tile = getTerrain(left, top);
    assert(tile != null);
    tile!.objectId = objectId;
  }

  void setTerrainSprite(int left, int top, dynamic data) {
    final tile = getTerrain(left, top);
    assert(tile != null);
    tile!.loadSprite(data, terrainSpriteSheet);
  }

  void setTerrainOverlaySprite(int left, int top, dynamic data) {
    final tile = getTerrain(left, top);
    assert(tile != null);
    tile!.loadOverlaySprite(data, terrainSpriteSheet);
  }

  TileMapObject? _hero;
  TileMapObject? get hero => _hero;
  set hero(TileMapObject? entity) {
    _hero = entity;
    if (_hero != null) {
      lightUpAroundTile(_hero!.tilePosition, size: 1);
      moveCameraToTilePosition(_hero!.left, _hero!.top);
    }
  }

  final List<AnimatedCloud> _clouds = [];

  bool isTimeFlowing = false;

  List<TileMapRouteNode>? _currentRoute;

  bool _backwardMoving = false;

  TileMapRouteNode? _lastRouteNode;

  // TileMapTerrain? _currentMoveDestination;

  // DestinationAction currentDestinationAction = DestinationAction.none;

  VoidCallback? _currentDestinationCallback;

  int colorMode = kColorModeNone;

  bool showGrids;
  bool showClouds;
  bool showSelected;
  bool showFogOfWar;

  final Set<TilePosition> _visiblePerimeter = {};

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

  TileMapTerrain? getTerrainAtHero() {
    if (_hero != null) {
      return terrains[
          tilePosition2Index(_hero!.left, _hero!.top, tileMapWidth)];
    }
    return null;
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
      {VoidCallback? onDestinationCallback, bool backwardMoving = false}) {
    assert(_hero != null);
    if (_hero!.isMoving) return;
    _backwardMoving = backwardMoving;
    _currentDestinationCallback = onDestinationCallback;
    assert(tilePosition2Index(_hero!.left, _hero!.top, tileMapWidth) ==
        route.first);
    _currentRoute = route
        .map((index) {
          final tilePos = index2TilePosition(index);
          final worldPos =
              tilePosition2TileCenterInWorld(tilePos.left, tilePos.top);
          return TileMapRouteNode(
            index: index,
            tilePosition: tilePos,
            worldPosition: worldPos,
          );
        })
        .toList()
        .reversed
        .toList();
  }

  void moveHeroToLastRouteNode() {
    assert(_hero != null);
    assert(_lastRouteNode != null);
    _currentRoute = null;
    moveHeroToTilePositionByRoute([_hero!.index, _lastRouteNode!.index],
        backwardMoving: true);
    _lastRouteNode = null;
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    camera.snapTo(camera.position - details.delta.toVector2());
  }

  void _selectTile(int left, int top) {
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
    _selectTile(tilePosition.left, tilePosition.top);

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
    _selectTile(tilePosition.left, tilePosition.top);

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
    double mapScreenSizeX = (gridWidth * 3 / 4) * tileMapWidth * scale.x;
    double mapScreenSizeY =
        (gridHeight * tileMapHeight + gridHeight / 2) * scale.y;
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

    for (final tile in terrains) {
      tile.update(dt);
    }

    if (showClouds) {
      for (final cloud in _clouds) {
        cloud.update(dt);
      }

      if (_clouds.length < maxCloudsCout) {
        final r = math.Random().nextDouble();
        if (r < 0.03) {
          final cloud = AnimatedCloud(screenSize: mapScreenSize);
          _clouds.add(cloud);
        }
      }
      _clouds.removeWhere((cloud) {
        if (!cloud.visible) {
          return true;
        }
        return false;
      });
    }

    if (_hero != null) {
      if (_currentRoute != null && _currentRoute!.isNotEmpty) {
        if (hero!.isMovingCanceled) {
          _currentRoute = null;
          hero!.isMovingCanceled = false;
        } else if (!_hero!.isMoving) {
          final currentTile = getTerrain(_hero!.left, _hero!.top)!;
          lightUpAroundTile(currentTile.tilePosition, size: 1);
          _lastRouteNode = _currentRoute!.last;
          _currentRoute!.removeLast();
          if (_currentRoute!.isNotEmpty) {
            final nextTile = _currentRoute!.last;
            _hero!.moveTo(nextTile.tilePosition, backward: _backwardMoving);
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
      } else {
        if (_lastRouteNode != null) _lastRouteNode = null;
        _hero!.stopAnimation();
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
          tile.render(canvas, showGrids);
        }
        for (var i = 1; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          tile.render(canvas, showGrids);
        }
      } else {
        for (var i = 0; i < tileMapWidth; ++i) {
          final tile = terrains[i + j * tileMapWidth];
          tile.render(canvas, showGrids);
        }
      }
    }

    if (showSelected && selectedTerrain != null) {
      canvas.drawPath(selectedTerrain!.borderPath, selectedPaint);
    }

    // after all terrains, render the objects, in the same way:
    for (var j = 0; j < tileMapHeight; ++j) {
      if (tileShape == TileShape.hexagonalVertical) {
        for (var i = 0; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          if (tile.objectId != null) {
            final object = objects[tile.objectId]!;
            object.render(canvas);
          }
          if (tile.tilePosition == hero?.tilePosition) {
            hero?.render(canvas);
          }
        }
        for (var i = 1; i < tileMapWidth; i = i + 2) {
          final tile = terrains[i + j * tileMapWidth];
          if (tile.objectId != null) {
            final object = objects[tile.objectId]!;
            object.render(canvas);
          }
          if (tile.tilePosition == hero?.tilePosition) {
            hero?.render(canvas);
          }
        }
      } else {
        for (var i = 0; i < tileMapWidth; ++i) {
          final tile = terrains[i + j * tileMapWidth];
          if (tile.objectId != null) {
            final object = objects[tile.objectId]!;
            object.render(canvas);
          }
          if (tile.tilePosition == hero?.tilePosition) {
            hero?.render(canvas);
          }
        }
      }
    }

    for (final tile in terrains) {
      tile.renderCaption(canvas, offset: _kCaptionOffset);
    }

    if (colorMode >= 0) {
      for (final tile in terrains) {
        final color = engine.colors[colorMode][tile.index];
        if (color != null) {
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

    if (showClouds) {
      for (final cloud in _clouds) {
        cloud.render(canvas);
      }
    }

    canvas.restore();
  }

  @override
  bool containsPoint(Vector2 point) {
    return true;
  }
}
