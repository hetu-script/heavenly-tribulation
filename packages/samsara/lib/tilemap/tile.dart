import 'package:quiver/core.dart';
import 'package:flame/components.dart';
import '../shared/direction.dart';

class TilePosition {
  final int left, top;

  const TilePosition(this.left, this.top);
  const TilePosition.leftTop() : this(1, 1);

  @override
  String toString() => '[$left,$top]';

  @override
  int get hashCode {
    return hashObjects([left, top]);
  }

  @override
  bool operator ==(Object other) {
    if (other is TilePosition) {
      return hashCode == other.hashCode;
    }
    return false;
  }
}

enum TileShape {
  orthogonal,
  isometric,
  hexagonalVertical,
  hexagonalHorizontal,
}

enum TileRenderDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  bottomCenter,
}

int tilePosition2Index(int left, int top, int tileMapWidth) {
  return (left - 1) + (top - 1) * tileMapWidth;
}

mixin TileInfo on Component {
  late final int tileMapWidth;
  late final TileShape tileShape;
  late final double gridWidth, gridHeight;
  late final double srcWidth, srcHeight;
  double? srcOffsetY;
  late TilePosition _tilePosition;

  TilePosition get tilePosition => _tilePosition;
  set tilePosition(TilePosition position) {
    _tilePosition = position;
    _index =
        tilePosition2Index(_tilePosition.left, _tilePosition.top, tileMapWidth);
    final p = tilePosition2RenderPosition(left, top);
    p.y += srcOffsetY ?? 0;
    _renderPosition = p;
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

  Vector2 tilePosition2RenderPosition(int left, int top) {
    late final double l, t; //, l, t;
    switch (tileShape) {
      case TileShape.orthogonal:
        l = ((left - 1) * gridWidth);
        t = ((top - 1) * gridHeight);
        break;
      case TileShape.hexagonalVertical:
        l = (left - 1) * gridWidth * (3 / 4);
        t = left.isOdd
            ? (top - 1) * gridHeight
            : (top - 1) * gridHeight + gridHeight / 2;
        break;
      case TileShape.isometric:
        throw 'Isometric map tile is not supported yet!';
      case TileShape.hexagonalHorizontal:
        throw 'Vertical hexagonal map tile is not supported yet!';
    }
    // switch (renderDirection) {
    //   case TileRenderDirection.bottomRight:
    //     l = bl - (srcWidth - gridWidth);
    //     t = bt - (srcHeight - gridHeight);
    //     break;
    //   case TileRenderDirection.bottomLeft:
    //     l = bl;
    //     t = bt - (srcWidth - gridHeight);
    //     break;
    //   case TileRenderDirection.topRight:
    //     l = bl - (srcHeight - gridWidth);
    //     t = bt;
    //     break;
    //   case TileRenderDirection.topLeft:
    //     l = bl;
    //     t = bt;
    //     break;
    //   case TileRenderDirection.bottomCenter:
    //     break;
    // }
    return Vector2(
        l - (srcWidth - gridWidth) / 2, t - (srcHeight - gridHeight));
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

  /// 计算 hexagonal tile 的方向，如果是 backward 则是反方向
  Direction directionTo(TilePosition position, {bool backward = false}) {
    assert(tilePosition != position);
    if (left % 2 != 0) {
      if (position.left == left) {
        if (position.top < top) {
          return backward ? Direction.south : Direction.north;
        } else {
          return backward ? Direction.north : Direction.south;
        }
      } else if (position.left > left) {
        if (position.top == top) {
          if (position.left % 2 != 0) {
            return backward ? Direction.west : Direction.east;
          } else {
            return backward ? Direction.northWest : Direction.southEast;
          }
        } else if (position.top < top) {
          return backward ? Direction.southWest : Direction.northEast;
        } else {
          return backward ? Direction.northWest : Direction.southEast;
        }
      } else {
        if (position.top == top) {
          if (position.left % 2 != 0) {
            return backward ? Direction.east : Direction.west;
          } else {
            return backward ? Direction.northEast : Direction.southWest;
          }
        } else if (position.top < top) {
          return backward ? Direction.southEast : Direction.northWest;
        } else {
          return backward ? Direction.northEast : Direction.southWest;
        }
      }
    } else {
      if (position.left == left) {
        if (position.top < top) {
          return backward ? Direction.south : Direction.north;
        } else {
          return backward ? Direction.north : Direction.south;
        }
      } else if (position.left > left) {
        if (position.top == top) {
          if (position.left.isEven) {
            return backward ? Direction.west : Direction.east;
          } else {
            return backward ? Direction.southWest : Direction.northEast;
          }
        } else if (position.top < top) {
          return backward ? Direction.southWest : Direction.northEast;
        } else {
          return backward ? Direction.northWest : Direction.southEast;
        }
      } else {
        if (position.top == top) {
          if (position.left.isEven) {
            return backward ? Direction.east : Direction.west;
          } else {
            return backward ? Direction.southEast : Direction.northWest;
          }
        } else if (position.top < top) {
          return backward ? Direction.southEast : Direction.northWest;
        } else {
          return backward ? Direction.northEast : Direction.southWest;
        }
      }
    }
  }
}
