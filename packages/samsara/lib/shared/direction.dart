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

enum OrthogonalDirection {
  north,
  east,
  south,
  west,
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

OrthogonalDirection direction2Orthogonal(Direction direction) {
  switch (direction) {
    case Direction.north:
      return OrthogonalDirection.north;
    case Direction.south:
      return OrthogonalDirection.south;
    case Direction.east:
      return OrthogonalDirection.east;
    case Direction.west:
      return OrthogonalDirection.west;
    case Direction.northEast:
      return OrthogonalDirection.east;
    case Direction.southEast:
      return OrthogonalDirection.east;
    case Direction.northWest:
      return OrthogonalDirection.west;
    case Direction.southWest:
      return OrthogonalDirection.west;
  }
}
