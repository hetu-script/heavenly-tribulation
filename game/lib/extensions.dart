import 'package:samsara/tilemap.dart';

extension TileMapEx on TileMap {
  void saveMovingObjectsFrameData() {
    for (final object in movingObjects.values) {
      assert(object.data != null);
      assert(object.data['worldPosition'] != null);
      object.data['worldPosition'] = {
        'left': object.left,
        'top': object.top,
        'animation': {
          'direction': object.direction.name,
          'currentIndex': object.currentAnimation.ticker.currentIndex,
          'clock': object.currentAnimation.ticker.clock,
          'elapsed': object.currentAnimation.ticker.elapsed,
        }
      };
    }
  }
}
