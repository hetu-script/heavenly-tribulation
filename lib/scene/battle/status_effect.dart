// import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/hovertip.dart';
import 'package:hetu_script/utils/collection.dart';

import '../../engine.dart';
import '../../game/data.dart';
import '../../game/ui.dart';
import 'common.dart';

class StatusEffect extends BorderComponent with HandlesGesture {
  static ScreenTextConfig defaultEffectCountStyle = const ScreenTextConfig(
    anchor: Anchor.bottomRight,
    outlined: true,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 10.0,
      fontWeight: FontWeight.bold,
    ),
  );

  dynamic data;

  late final Sprite sprite;

  late final String? spriteId;

  int _amount;

  int get amount => _amount;

  set amount(int value) {
    if (value < 0) {
      value = 0;
    }
    _amount = value;
    data['amount'] = value;
  }

  late final String id;

  String? get oppositeEffectId => data['opposite'];

  String? get attackType => data['attackType'];

  String? get damageType => data['damageType'];

  String? get script => data['script'];

  String? get soundId => data['sound'];

  bool get isHidden => data['isHidden'] ?? false;

  bool get isResource => data['isResource'] ?? false;

  bool get isPermenant => data['isPermenant'] ?? false;

  bool get isOngoing => data['isOngoing'] ?? false;

  bool get isUnique => data['isUnique'] ?? false;

  int get effectPriority => data['priority'] ?? 0;

  List get callbacks => data['callbacks'] ?? [];

  late ScreenTextConfig countTextConfig;

  late final String description;

  StatusEffect({
    required this.id,
    int amount = 1,
    super.position,
    super.anchor,
  })  : _amount = amount,
        super(
          priority: kStatusEffectIconPriority,
        ) {
    assert(amount >= 1);
    assert(GameData.statusEffects.containsKey(id));
    data = deepCopy(GameData.statusEffects[id]);
    assert(data != null);
    data['amount'] = amount;

    spriteId = data['icon'];

    size = isPermenant
        ? GameUI.permenantStatusEffectIconSize
        : GameUI.statusEffectIconSize;
    countTextConfig = defaultEffectCountStyle.copyWith(size: size);

    description =
        '${engine.locale(data['title'])}\n${engine.locale(data['description'])}';

    onMouseEnter = () {
      Hovertip.show(
        scene: game,
        target: this,
        direction: HovertipDirection.topLeft,
        content: description,
      );
    };
    onMouseExit = () {
      Hovertip.hide(this);
    };
  }

  @override
  Future<void> onLoad() async {
    if (spriteId != null) {
      sprite = Sprite(await Flame.images.load(spriteId!));
    }
    // else {
    //   sprite = Sprite(await Flame.images.load('icon/status/placeholder.png'));
    // }
  }

  @override
  void render(Canvas canvas) {
    sprite.render(canvas, size: size);
    drawScreenText(canvas, '$amount', config: countTextConfig);
  }
}
