enum Direction {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

enum HexagonalDirection {
  north,
  northEast,
  southEast,
  south,
  southWest,
  northWest,
}

HexagonalDirection direction2Hexagonal(Direction direction) {
  switch (direction) {
    case Direction.north:
      return HexagonalDirection.north;
    case Direction.south:
      return HexagonalDirection.south;
    case Direction.northEast:
      return HexagonalDirection.northEast;
    case Direction.southEast:
      return HexagonalDirection.southEast;
    case Direction.northWest:
      return HexagonalDirection.northWest;
    case Direction.southWest:
      return HexagonalDirection.southWest;
    default:
      throw 'Hexagonal map tile direction should never be $direction';
  }
}
