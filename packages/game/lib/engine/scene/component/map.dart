import 'package:flutter/material.dart';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:tian_dao_qi_jie/ui/pointer_detector.dart';

import '../../gestures/gesture_mixin.dart';
import '../../extensions.dart';
import 'tile.dart';
import '../../game.dart';
import '../../event/event.dart';
import 'zone.dart';

abstract class MapEvents {
  static const tileTapped = 'tile_tapped';
}

class MapEvent extends Event {
  final Terrain? terrain;
  final Entity? entity;

  const MapEvent({
    required String eventName,
    this.terrain,
    this.entity,
  }) : super(eventName);

  const MapEvent.tileTapped({required Terrain terrain, Entity? entity})
      : this(eventName: MapEvents.tileTapped, terrain: terrain, entity: entity);
}

enum WorldStyle {
  innerland,
  island,
  beach,
}

class MapComponent extends GameComponent with HandlesGesture {
  static final selectedPaint = Paint()
    ..strokeWidth = 1
    ..style = PaintingStyle.stroke
    ..color = Colors.yellow;

  @override
  Camera get camera => gameRef.camera;

  final TileShape tileShape;
  final int entryX, entryY;
  final Vector2 tileSize;

  List<List<Terrain>> terrains;
  Map<String, Entity> entities;
  List<Zone> zones;

  final int mapTileWidth;
  final int mapTileHeight;

  Vector2 mapScreenSize = Vector2.zero();
  Vector2 mapStartPosition = Vector2.zero();

  final bool tapSelect;
  Terrain? selectedTerrain;
  Entity? selectedEntity;

  // 从坐标得到索引
  int tilePos2Index(int left, int top) {
    return left - 1 + (top - 1) * mapTileWidth;
  }

  // 从索引得到坐标
  TilePosition index2TilePos(int index) {
    final left = index % mapTileWidth + 1;
    final top = index ~/ mapTileHeight + 1;
    return TilePosition(left, top);
  }

  MapComponent({
    required SamsaraGame game,
    required this.tileShape,
    required this.entryX,
    required this.entryY,
    required double gridWidth,
    required double gridHeight,
    required this.terrains,
    this.entities = const {},
    this.zones = const [],
    this.tapSelect = false,
  })  : mapTileHeight = terrains.length,
        mapTileWidth = terrains.first.length,
        tileSize = Vector2(gridWidth, gridHeight),
        super(game: game) {
    assert(terrains.isNotEmpty);
    scale = Vector2(MapTile.defaultScale, MapTile.defaultScale);
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

    final mapTileWidth = data['width'] as int;
    final mapTileHeight = data['height'] as int;
    final entryX = data['entry']['x'] as int;
    final entryY = data['entry']['y'] as int;
    final terrainsData = data['terrains'];

    final zonesData = data['zones'];
    final zones = <Zone>[];
    for (final zoneData in zonesData) {
      final index = zoneData['index'];
      final name = zoneData['name'];
      zones.add(Zone(index: index, name: name));
    }

    final tapSelect = data['tapSelect'] ?? false;

    final List<List<Terrain>> terrains = [];
    for (var j = 0; j < mapTileHeight; ++j) {
      terrains.add([]);
      for (var i = 0; i < mapTileWidth; ++i) {
        final terrain = terrainsData[i + j * mapTileWidth];
        final spritePath = terrain['sprite'];
        final spriteIndex = terrain['spriteIndex'];
        final animationPath = terrain['animation'];
        int animationFrameCount = terrain['animationFrameCount'] ?? 1;
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
        final zoneIndex = terrain['zoneIndex'];
        var isEntry = false;
        if (i + 1 == entryX && j + 1 == entryY) {
          isEntry = true;
        }
        final tile = Terrain(
          game: game,
          shape: tileShape,
          left: i + 1,
          top: j + 1,
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
    final Map<String, Entity> entities = {};
    if (entitiyData != null) {
      for (final key in entitiyData.keys) {
        final entityData = entitiyData[key];
        final String id = entityData['id'];
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
        final entity = Entity(
          id: id,
          name: name,
          game: game,
          shape: tileShape,
          left: left,
          top: top,
          srcWidth: srcWidth,
          srcHeight: srcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          isVisible: true,
          sprite: sprite,
          animation: animation,
          offsetX: offsetX,
          offsetY: offsetY,
        );
        entities[key] = entity;
      }
    }

    return MapComponent(
      game: game,
      tileShape: tileShape,
      entryX: entryX,
      entryY: entryY,
      gridWidth: gridWidth,
      gridHeight: gridHeight,
      terrains: terrains,
      zones: zones,
      entities: entities,
      tapSelect: tapSelect,
    );
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

  Terrain? getTerrainByPosition(TilePosition position) {
    return getTerrain(position.left, position.top);
  }

  Terrain? getTerrain(int left, int top) {
    if (isPositionWithinMap(left, top)) {
      return terrains[top - 1][left - 1];
    } else {
      return null;
    }
  }

  Entity? getEntity(int left, int top) {
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

  void _lightUpAroundTerrain(Terrain tile) {
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

  void _moveToTerrain(Terrain tile) {
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

  TilePosition screenPosition2Tile(Vector2 position) {
    final worldPos = screenPosition2World(position);
    late final int left, top;

    switch (tileShape) {
      case TileShape.orthogonal:
        left = (worldPos.x / scale.x / tileSize.x).floor();
        top = (worldPos.y / scale.x / tileSize.y).floor();
        break;
      case TileShape.hexagonalVertical:
        int l = (worldPos.x / (tileSize.x * 3 / 4) / scale.x).floor() + 1;
        final inTilePosX =
            worldPos.x / scale.x - (l - 1) * (tileSize.x * 3 / 4);
        late final double inTilePosY;
        int t;
        if (l.isOdd) {
          t = (worldPos.y / scale.y / tileSize.y).floor() + 1;
          inTilePosY = tileSize.y / 2 - (worldPos.y / scale.y) % tileSize.y;
        } else {
          t = ((worldPos.y / scale.y - tileSize.y / 2) / tileSize.y).floor() +
              1;
          inTilePosY = tileSize.y / 2 -
              (worldPos.y / scale.y - tileSize.y / 2) % tileSize.y;
        }
        if (inTilePosX < tileSize.x / 4) {
          if (l.isOdd) {
            if (inTilePosY >= 0) {
              if (inTilePosY / inTilePosX > tileSize.y / tileSize.x * 2) {
                left = l - 1;
                top = t - 1;
              } else {
                left = l;
                top = t;
              }
            } else {
              if (-inTilePosY / inTilePosX > tileSize.y / tileSize.x * 2) {
                left = l - 1;
                top = t;
              } else {
                left = l;
                top = t;
              }
            }
          } else {
            if (inTilePosY >= 0) {
              if (inTilePosY / inTilePosX > tileSize.y / tileSize.x * 2) {
                left = l - 1;
                top = t;
              } else {
                left = l;
                top = t;
              }
            } else {
              if (-inTilePosY / inTilePosX > tileSize.y / tileSize.x * 2) {
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
        selectedTerrain = terrain;
        selectedEntity = entity;
      }
      game.broadcast(MapEvent.tileTapped(terrain: terrain, entity: entity));
    }
  }

  @override
  void onMouseMove(MouseMoveUpdateDetails details) {}

  @override
  void update(double dt) {
    super.update(dt);
    for (final column in terrains) {
      for (final tile in column) {
        tile.update(dt);
      }
    }
    for (final entity in entities.values) {
      entity.update(dt);
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
    updateData();
  }

  @override
  bool containsPoint(Vector2 point) {
    return true;
  }

  void updateData(
      {List<List<Terrain>>? terrainData, Map<String, Entity>? entityData}) {
    if (terrainData != null) {
      for (final row in terrains) {
        for (final tile in row) {
          remove(tile);
        }
      }
      terrains = terrainData;
      for (final row in terrains) {
        for (final tile in row) {
          add(tile);
        }
      }
    }
    if (entityData != null) {
      for (final tile in entities.values) {
        remove(tile);
      }
      entities = entityData;
      for (final tile in entities.values) {
        add(tile);
      }
    }
    _verifyMaxTopAndLeft(gameRef.size);
    _moveCameraToTilePosition(entryX, entryY);
  }

  void _verifyMaxTopAndLeft(Vector2 size) {
    double height = 0;
    double width = 0;
    for (final column in terrains) {
      for (final tile in column) {
        if (tile.rect.right > width) {
          width = tile.rect.right;
        }
        if (tile.rect.bottom > height) {
          height = tile.rect.bottom;
        }
      }
    }

    mapScreenSize = Vector2(width, height);
    mapStartPosition = terrains.first.first.position;
    for (final column in terrains) {
      for (final tile in column) {
        if (tile.position.x < x) {
          mapStartPosition.x = tile.position.x;
        }
        if (tile.position.y < y) {
          mapStartPosition.y = tile.position.y;
        }
      }
    }
  }

  void _moveCameraToTilePosition(int left, int top,
      {bool animated = false, double speed = 500.0}) {
    final dest = Vector2(left * tileSize.x * scale.x + tileSize.x / 2 * scale.x,
            top * tileSize.y * scale.x + tileSize.y / 2 * scale.y) -
        gameRef.size / 2;
    camera.speed = speed;
    camera.moveTo(dest);
    if (!animated) {
      camera.snap();
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    _verifyMaxTopAndLeft(gameSize);
  }
}
