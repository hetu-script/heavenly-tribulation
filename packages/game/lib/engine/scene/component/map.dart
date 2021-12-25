import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../../gestures/gesture_mixin.dart';
import '../../extensions.dart';
import 'tile.dart';

class MapComponent extends GameComponent with HandlesGesture {
  @override
  Camera get camera => gameRef.camera;

  int entryX, entryY;
  final Vector2 tileSize;

  List<List<Terrain>> terrains;
  Map<String, Entity> entities;

  final int mapTileWidth;
  final int mapTileHeight;

  Vector2 mapScreenSize = Vector2.zero();
  Vector2 mapStartPosition = Vector2.zero();

  final TileShape tileShape;

  MapComponent({
    required this.tileShape,
    required this.entryX,
    required this.entryY,
    required double screenTileWidth,
    required double screenTileHeight,
    required this.terrains,
    this.entities = const {},
  })  : mapTileHeight = terrains.length,
        mapTileWidth = terrains.first.length,
        tileSize = Vector2(screenTileWidth, screenTileHeight) {
    assert(terrains.isNotEmpty);
    scale = Vector2(MapTile.defaultScale, MapTile.defaultScale);
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
    final terrainData = data['terrains'];
    final roomData = data['rooms'];
    final entitiyData = data['entities'];

    final List<List<Terrain>> terrains = [];
    for (var j = 0; j < mapTileHeight; ++j) {
      terrains.add([]);
      for (var i = 0; i < mapTileWidth; ++i) {
        final blockId = j * mapTileWidth + i;
        final spriteId = terrainData[blockId];
        Sprite? sprite;
        if (spriteId > 0) {
          sprite = terrainSpriteSheet.getSpriteById(spriteId - 1);
        }
        var isRoom = false;
        if (roomData != null && roomData[blockId] > 0) {
          isRoom = true;
        }
        var isEntry = false;
        if (i + 1 == entryX && j + 1 == entryY) {
          isEntry = true;
        }
        final tile = Terrain(
          shape: tileShape,
          left: i + 1,
          top: j + 1,
          srcWidth: tileSpriteSrcWidth,
          srcHeight: tileSpriteSrcHeight,
          gridWidth: gridWidth,
          gridHeight: gridHeight,
          isVisible: true,
          isRoom: isRoom,
          isVisited: isEntry,
          sprite: sprite,
          offsetX: tileOffsetX,
          offsetY: tileOffsetY,
        );
        if (isEntry) {
          tile.isVisible = true;
        }
        terrains[j].add(tile);
      }
    }

    final Map<String, Entity> entities = {};
    if (entitiyData != null) {
      for (final key in entitiyData.keys) {
        final entityData = entitiyData[key];
        final entity = await Entity.fromJson(
            type: tileShape,
            gridWidth: gridWidth,
            gridHeight: gridHeight,
            spriteSrcWidth: tileSpriteSrcWidth,
            spriteSrcHeight: tileSpriteSrcHeight,
            isVisible: true,
            jsonData: entityData);
        entities[key] = entity;
      }
    }

    return MapComponent(
      tileShape: tileShape,
      entryX: entryX,
      entryY: entryY,
      screenTileWidth: gridWidth,
      screenTileHeight: gridHeight,
      terrains: terrains,
      entities: entities,
    );
  }

  Terrain? getTerrain(int left, int top) {
    if (left > 0 && top > 0 && left <= mapTileWidth && top <= mapTileHeight) {
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
    final around = <Terrain?>[];
    around.add(getTerrain(tile.left - 1, tile.top)); // the tile on the left
    around.add(getTerrain(tile.left + 1, tile.top)); // the tile on the right
    around.add(getTerrain(tile.left, tile.top - 1)); // the tile on the top
    around.add(getTerrain(tile.left, tile.top + 1)); // the tile on the bottom
    for (final neighbour in around) {
      if (neighbour != null && !neighbour.isVoid) {
        if (neighbour.isVisible) {
          continue;
        } else {
          neighbour.isVisible = true;
          final entity = getEntity(neighbour.left, neighbour.top);
          entity?.isVisible = true;
          if (!neighbour.isRoom) {
            _lightUpAroundTerrain(neighbour);
          }
        }
      }
    }
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
    if (tile == null) {
      return;
    }

    _moveToTerrain(tile);
  }

  Vector2 worldPositionToScreen(Vector2 position) {
    return position - camera.position;
  }

  Vector2 screenPositionToWorld(Vector2 position) {
    return position + camera.position;
  }

  TilePosition screenPositionToTile(Vector2 position) {
    final worldPos = screenPositionToWorld(position);
    final left = (worldPos.x / tileSize.x / scale.x).truncate();
    final top = (worldPos.y / tileSize.y / scale.x).truncate();

    return TilePosition(left, top);
  }

  @override
  void onDragUpdate(int pointer, DragUpdateDetails details) {
    camera.snapTo(camera.position - details.delta.toVector2());
  }

  @override
  void onTapUp(int pointer, TapUpDetails details) {
    final screenPosition = details.globalPosition.toVector2();

    // print('clicked!');
    // print('world position: $position');
    // print('camera position: ${camera.position}');
    // print('screen position: $screenPosition');
    // print('tile position: $tilePosition');

    final tilePos = screenPositionToTile(screenPosition);
    final tile = getTerrain(tilePos.left, tilePos.top);
    if (tile != null && tile.isRoom && tile.isVisible) {
      gameRef.game.hetu.invoke('handleTileInteraction',
          positionalArgs: [tile.left, tile.top]);
    }
  }

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