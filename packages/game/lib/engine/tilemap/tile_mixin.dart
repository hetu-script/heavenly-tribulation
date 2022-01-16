import 'package:flame/components.dart';

import 'tile.dart';
import '../shared/direction.dart';

mixin TileInfo on Component {
  late final TilePosition tilePosition;
  int get left => tilePosition.left;
  int get top => tilePosition.top;

  /// the tile index of the terrain array
  late final int index;

  late final double srcWidth, srcHeight;
  late final TileShape tileShape;
  late final double gridWidth, gridHeight;

  Vector2 tilePosition2World(int left, int top,
      {TileRenderDirection renderDirection = TileRenderDirection.rightBottom}) {
    late final double bl, bt, l, t;
    switch (tileShape) {
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

  // 计算 hexagonal tile 的方向
  Direction directionTo(TilePosition position) {
    assert(tilePosition != position);
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
