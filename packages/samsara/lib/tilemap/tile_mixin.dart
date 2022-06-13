import 'package:flame/components.dart';

import 'tile.dart';
import '../shared/direction.dart';

mixin TileInfo on Component {
  late TilePosition _tilePosition;
  TilePosition get tilePosition => _tilePosition;
  set tilePosition(TilePosition position) {
    _tilePosition = position;
    _index =
        tilePosition2Index(_tilePosition.left, _tilePosition.top, tileMapWidth);
    _renderPosition = tilePosition2RenderPosition(left, top);
    _worldPosition = tilePosition2TileCenterInWorld(left, top);
  }

  late Vector2 _renderPosition;
  Vector2 get renderPosition => _renderPosition;

  late Vector2 _worldPosition;
  Vector2 get worldPosition => _worldPosition;

  int get left => _tilePosition.left;
  int get top => _tilePosition.top;

  /// the tile index of the terrain array
  late int _index;
  int get index => _index;

  late final double srcWidth, srcHeight;
  late final TileShape shape;
  late final double gridWidth, gridHeight;
  late final int tileMapWidth;

  int tilePosition2Index(int left, int top, int tileMapWidth) {
    return (left - 1) + (top - 1) * tileMapWidth;
  }

  Vector2 tilePosition2RenderPosition(int left, int top,
      {TileRenderDirection renderDirection = TileRenderDirection.rightBottom}) {
    late final double bl, bt, l, t;
    switch (shape) {
      case TileShape.orthogonal:
        bl = ((left - 1) * gridWidth);
        bt = ((top - 1) * gridHeight);
        break;
      case TileShape.hexagonalVertical:
        bl = (left - 1) * gridWidth * (3 / 4);
        bt = left.isOdd
            ? (top - 1) * gridHeight
            : (top - 1) * gridHeight + gridHeight / 2;
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    switch (renderDirection) {
      case TileRenderDirection.rightBottom:
        l = bl - (srcWidth - gridWidth);
        t = bt - (srcHeight - gridHeight);
        break;
      case TileRenderDirection.leftBottom:
        l = bl;
        t = bt - (srcWidth - gridHeight);
        break;
      case TileRenderDirection.rightTop:
        l = bl - (srcHeight - gridWidth);
        t = bt;
        break;
      case TileRenderDirection.leftTop:
        l = bl;
        t = bt;
        break;
    }
    return Vector2(l, t);
  }

  Vector2 tilePosition2TileCenterInWorld(int left, int top) {
    late final double rl, rt;
    switch (shape) {
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

  // 计算 hexagonal tile 的方向
  Direction directionTo(TilePosition position) {
    assert(_tilePosition != position);
    if (left % 2 != 0) {
      if (position.left == left) {
        if (position.top < top) {
          return Direction.north;
        } else {
          return Direction.south;
        }
      } else if (position.left > left) {
        if (position.top == top) {
          if (position.left % 2 != 0) {
            return Direction.east;
          } else {
            return Direction.southEast;
          }
        } else if (position.top < top) {
          return Direction.northEast;
        } else {
          return Direction.southEast;
        }
      } else {
        if (position.top == top) {
          if (position.left % 2 != 0) {
            return Direction.west;
          } else {
            return Direction.southWest;
          }
        } else if (position.top < top) {
          return Direction.northWest;
        } else {
          return Direction.southWest;
        }
      }
    } else {
      if (position.left == left) {
        if (position.top < top) {
          return Direction.north;
        } else {
          return Direction.south;
        }
      } else if (position.left > left) {
        if (position.top == top) {
          if (position.left.isEven) {
            return Direction.east;
          } else {
            return Direction.northEast;
          }
        } else if (position.top < top) {
          return Direction.northEast;
        } else {
          return Direction.southEast;
        }
      } else {
        if (position.top == top) {
          if (position.left.isEven) {
            return Direction.west;
          } else {
            return Direction.northWest;
          }
        } else if (position.top < top) {
          return Direction.northWest;
        } else {
          return Direction.southWest;
        }
      }
    }
  }
}
