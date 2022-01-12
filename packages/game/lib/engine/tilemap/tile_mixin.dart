import 'package:flame/components.dart';

import 'tile.dart';

mixin TileInfo on Component {
  late final int left, top;
  late final int srcWidth, srcHeight;

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
}
