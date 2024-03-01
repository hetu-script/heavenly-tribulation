import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:heavenly_tribulation/pages/battle/scene/character.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/game/progress_indicator.dart';

import '../../../config.dart';
import '../../../data.dart';

enum StatusEffectType {
  none,
  buff,
  debuff,
}

StatusEffectType getStatusEffectType(String id) {
  return switch (id) {
    'buff' => StatusEffectType.buff,
    'debuff' => StatusEffectType.debuff,
    _ => StatusEffectType.none,
  };
}

const kStatusEffectIconSize = 24.0;

class StatusEffect extends GameComponent {
  static ScreenTextStyle defaultEffectCountStyle = ScreenTextStyle(
    anchor: Anchor.bottomRight,
    outlined: true,
    textPaint: TextPaint(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  final String id;

  late final Sprite sprite;

  int count;

  late final StatusEffectType type;

  final List<String> callbacks = [];

  String? soundId;

  late ScreenTextStyle screenTextStyle;

  StatusEffect({
    required this.id,
    required this.count,
    super.position,
  }) : super(size: Vector2(kStatusEffectIconSize, kStatusEffectIconSize)) {
    assert(GameData.statusEffectData.containsKey(id));
    final data = GameData.statusEffectData[id];
    type = getStatusEffectType(data['type']);
    for (final callbackId in data['callbacks']) {
      callbacks.add(callbackId);
    }
    soundId = data['sound'];

    screenTextStyle = defaultEffectCountStyle.copyWith(rect: border);
  }

  @override
  Future<void> onLoad() async {
    sprite = Sprite(await Flame.images.load('icon/status/$id.png'));
  }

  @override
  void render(Canvas canvas) {
    sprite.renderRect(canvas, border);
    drawScreenText(canvas, '$count', style: screenTextStyle);
  }

  void handleCallback({
    required String callbackId,
    required BattleCharacter self,
    required BattleCharacter opponent,
    required Map<String, dynamic> args,
  }) {
    final scriptCallBackId = '${id}_$callbackId';
    engine.hetu.invoke(
      scriptCallBackId,
      namespace: 'StatusEffect',
      positionalArgs: [self, opponent, args],
    );
  }
}

const kResourceBarHeight = 10.0;

class StatusBar extends GameComponent {
  late final DynamicColorProgressIndicator health, spirit;

  double _life, _lifeMax, _mana, _manaMax;

  set life(double newValue) {
    assert(newValue <= health.max);
    _life = newValue;
    health.value = _life;
  }

  set lifeMax(double newValue) {
    _lifeMax = newValue;
    health.max = _lifeMax;
  }

  set mana(double newValue) {
    assert(newValue <= spirit.max);
    _mana = newValue;
    spirit.value = _mana;
  }

  set manaMax(double newValue) {
    _manaMax = newValue;
    spirit.max = _manaMax;
  }

  final Map<String, StatusEffect> effects = {};

  StatusBar({
    super.position,
    double life = 100,
    double lifeMax = 100,
    double mana = 0,
    double manaMax = 5,
  })  : _life = life,
        _lifeMax = lifeMax,
        _mana = mana,
        _manaMax = manaMax,
        super(
          anchor: Anchor.center,
          size: Vector2(120, kStatusEffectIconSize + kResourceBarHeight * 2),
        );

  @override
  void onLoad() {
    health = DynamicColorProgressIndicator(
      position: Vector2(0, kStatusEffectIconSize + kResourceBarHeight),
      size: Vector2(width, kResourceBarHeight),
      value: _life,
      max: _lifeMax,
      colors: [Colors.red, Colors.green],
      showNumber: true,
    );
    add(health);

    spirit = DynamicColorProgressIndicator(
      position: Vector2(0, kStatusEffectIconSize),
      size: Vector2(width, kResourceBarHeight),
      value: _mana,
      max: _manaMax,
      colors: [Colors.lightBlue, Colors.blue],
      showNumber: true,
    );
    add(spirit);
  }

  void reArrangeEffects() {
    for (var i = 0; i < effects.length; ++i) {
      final effect = effects.values.elementAt(i);
      effect.position = Vector2(i * kStatusEffectIconSize, 0);
    }
  }

  /// 返回要移除的数量大于效果数量的差额
  /// 例如10攻打在5防上，差额5，意味着移除全部防之后，还有5点伤害需要处理
  int removeEffect(String id, {int count = 1}) {
    int diff = 0;
    if (effects.containsKey(id)) {
      final effect = effects[id]!;
      diff = count - effect.count;

      if (diff < 0) {
        effect.count = -diff;
      } else {
        effects.remove(id);
      }
    }
    return diff > 0 ? diff : 0;
  }

  void addEffect(String id, {int count = 1}) {
    StatusEffect effect;
    if (effects.containsKey(id)) {
      effect = effects[id]!;
      effect.count += count;
    } else {
      effect = StatusEffect(
        id: id,
        count: count,
      );
      add(effect);
      effects[id] = effect;
    }

    if (effect.soundId != null) {
      engine.playSound('sound_effect/${effect.soundId}',
          volume: GameConfig.soundEffectVolume);
    }

    reArrangeEffects();
  }

  void handleEffectCallback({
    required String callbackId,
    required BattleCharacter self,
    required BattleCharacter opponent,
    required Map<String, dynamic> args,
  }) {
    final effectList = effects.values.toList();
    for (final effect in effectList) {
      effect.handleCallback(
        callbackId: callbackId,
        self: self,
        opponent: opponent,
        args: args,
      );
    }
  }
}
