import 'package:flutter/material.dart' hide Viewport;
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/components/ui/hovertip.dart';
import 'package:hetu_script/utils/collection.dart' as utils;

import '../../global.dart';
import '../../data/game.dart';
import '../../ui.dart';
import 'common.dart';

/// 资源阴气图标的反色矩阵（净值 UI：同一图标的反色版本，不出新图）
const List<double> kNegativeQiInvertMatrix = [
  -1, 0, 0, 0, 255, //
  0, -1, 0, 0, 255,
  0, 0, -1, 0, 255,
  0, 0, 0, 1, 0,
];

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

  String? get opposite => data['opposite'];
  String? get category => data['category'];
  String? get genre => data['genre'];
  String? get kind => data['kind'];
  String? get cardType => data['cardType'];
  String? get damageType => data['damageType'];
  String? get script => data['script'];
  String? get soundId => data['sound'];
  bool get isHidden => data['isHidden'] ?? false;
  bool get isDebuff => data['isDebuff'] ?? false;
  bool get isResource => data['isResource'] ?? false;
  bool get isPermanent => data['isPermanent'] ?? false;
  bool get isOngoing => data['isOngoing'] ?? false;
  bool get isUnique => data['isUnique'] ?? false;
  int get effectPriority => data['priority'] ?? 0;
  List get callbacks => data['callbacks'] ?? [];

  late ScreenTextConfig countTextConfig;

  late final String description;

  /// 资源阴气反色渲染的缓存画笔（惰性创建，组件生命周期内复用）
  Paint? _invertPaint;

  StatusEffect({
    required this.id,
    int amount = 1,
    super.position,
    super.anchor,
  }) : _amount = amount {
    assert(amount >= 1);
    assert(GameData.statusEffects.containsKey(id));
    data = utils.deepCopy(GameData.statusEffects[id]);
    assert(data != null);
    data['amount'] = amount;

    spriteId = data['icon'];

    size = isPermanent
        ? GameUI.permanentStatusEffectIconSize
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
        width: 200.0,
      );
    };
    onMouseExit = () {
      Hovertip.hide(this);
    };
  }

  @override
  Future<void> onLoad() async {
    if (spriteId != null) {
      sprite = await Sprite.load(spriteId!);
    }
    // else {
    //   sprite = await Sprite.load('icon/status/placeholder.png'));
    // }
  }

  @override
  void render(Canvas canvas) {
    if (isNegativeResourceQi(id)) {
      // 资源阴气：以对应阳气的反色版本显示（阴阳净值 UI）
      _invertPaint ??= Paint()
        ..colorFilter = const ColorFilter.matrix(kNegativeQiInvertMatrix);
      sprite.render(canvas, size: size, overridePaint: _invertPaint);
    } else {
      sprite.render(canvas, size: size);
    }
    drawScreenText(canvas, '$amount', config: countTextConfig);
  }
}
