// import 'dart:ui';
// import 'package:flame/components.dart';
import 'package:samsara/components.dart';
// import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

import '../../../ui.dart';

class VersusBanner extends GameComponent {
  // late final SpriteComponent2 versus;
  // late final Rect versusBannerRect;

  final String heroIconId, enemyIconId;
  // late final SpriteComponent2 heroIcon, enemyIcon;

  VersusBanner({
    super.priority,
    super.position,
    required this.heroIconId,
    required this.enemyIconId,
  }) : super(
          anchor: Anchor.center,
          size: GameUI.size,
        );

  @override
  void onLoad() async {
    add(SpriteComponent2(
      position: Vector2(center.x - 80.0, center.y - 90.0),
      image: await Flame.images.load('battle/versus.png'),
      size: Vector2(160.0, 180.0),
      paint: paint,
    ));

    add(SpriteComponent2(
      position: Vector2(center.x - 80.0 - 10.0 - 100.0, center.y - 50.0),
      image: await Flame.images.load('avatar/$heroIconId'),
      borderImage: await Flame.images.load('avatar/border.png'),
      size: Vector2(100.0, 100.0),
      borderRadius: 12.0,
      paint: paint,
    ));
    add(SpriteComponent2(
      position: Vector2(center.x + 80.0 + 10.0, center.y - 50.0),
      image: await Flame.images.load('avatar/$enemyIconId'),
      borderImage: await Flame.images.load('avatar/border.png'),
      size: Vector2(100.0, 100.0),
      borderRadius: 12.0,
      paint: paint,
    ));
  }

  // @override
  // void render(Canvas canvas) {
  // versus.renderRect(canvas, versusBannerRect, overridePaint: paint);

  // heroIcon.renderRect(canvas, heroIconRect, overridePaint: paint);
  // enemyIcon.renderRect(canvas, enemyIconRect, overridePaint: paint);
  // }
}
