import 'dart:math' as math;

import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:samsara/gestures.dart';

import 'package:samsara/samsara.dart';

const _kLightRadius = 25.0;

class LightPoint extends BorderComponent with HandlesGesture {
  static final random = math.Random();

  double _flickerTimer = 0.0;

  late Sprite sprite;

  /// 每秒钟光晕闪烁的频率
  late double _flickerDt;
  double get flickerDt => _flickerDt;
  set flickerRate(int value) => _flickerDt = 1.0 / value;

  double preferredRadius;

  Vector2 preferredSize;

  double _distance2CondensePoint = 0;
  double get distance2CondensePoint => _distance2CondensePoint;

  LightPoint({
    super.isVisible,
    super.position,
    super.opacity,
    int flickerRate = 0,
    Vector2? preferredSize,
    this.preferredRadius = _kLightRadius,
    Vector2? condensedPosition,
  })  : preferredSize = preferredSize ?? Vector2.zero(),
        super(
          anchor: Anchor.center,
          lightConfig: LightConfig(
            radius: preferredRadius,
            blurBorder: _kLightRadius,
            shape: LightShape.circle,
          ),
        ) {
    if (preferredSize != null && !preferredSize.isZero()) {
      size = preferredSize;
    }

    this.flickerRate = flickerRate;

    if (condensedPosition != null) {
      final dx = (position.x - condensedPosition.x).abs();
      final dy = (position.y - condensedPosition.y).abs();
      _distance2CondensePoint = math.sqrt(dx * dx + dy * dy);
    }
  }

  @override
  void onLoad() async {
    sprite = Sprite(await Flame.images.load('light_point.png'));
    if (preferredSize.isZero()) {
      size = preferredSize = sprite.srcSize;
    }
  }

  @override
  void update(double dt) {
    _flickerTimer += dt;

    if (_flickerTimer >= _flickerDt) {
      _flickerTimer = 0;

      size = Vector2(
          preferredSize.x + random.nextDouble() * preferredSize.x * 0.1,
          preferredSize.y + random.nextDouble() * preferredSize.y * 0.1);

      lightConfig!.radius = preferredRadius + random.nextDouble() * 5;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    sprite.renderRect(canvas, border, overridePaint: paint);
  }
}
