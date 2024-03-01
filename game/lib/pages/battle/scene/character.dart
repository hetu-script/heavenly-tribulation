import 'dart:async';
import 'dart:math' show Random;

// import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/component/fading_text.dart';
// import 'package:flame/sprite.dart';

import 'status.dart';
// import '../common.dart';
import '../../../config.dart';
import 'common.dart';
import '../../../data.dart';

const kTopLayerPriority = 200;

const String kDefeatedState = 'defeated';
const String kStandState = 'stand';
const String kHitState = 'hit';
const String kHitRecoveryState = 'hit_recovery';
const String kNormalAttackState = 'attack_normal';
const String kNormalAttackRecoveryState = 'attack_normal_recovery';
const String kNormalDefendState = 'defend_normal';
const Set<String> kPreloadAnimationStates = {
  kDefeatedState,
  kStandState,
  kHitState,
  kHitRecoveryState,
  kNormalAttackState,
  kNormalAttackRecoveryState,
  kNormalDefendState,
};

class BattleCharacter extends GameComponent {
  final String skinId;

  final Map<String, SpriteAnimationWithTicker> _animations = {};
  late String _currentState;

  SpriteAnimationWithTicker get currentAnimation {
    assert(_animations.containsKey(_currentState),
        'Could not find animation state: [$_currentState]');
    return _animations[_currentState]!;
  }

  bool containsState(String stateId) {
    return _animations.containsKey('${stateId}_$skinId');
  }

  Future<void> setState(
    String stateId, {
    bool resetStateWhenComplete = false,
    void Function()? onComplete,
  }) {
    // engine.info('${isHero ? 'hero' : 'enemy'} new state: $stateId');
    final state = '${stateId}_$skinId';
    if (_currentState != state) {
      _currentState = state;
    }
    final anim = currentAnimation;
    anim.ticker.reset();
    anim.ticker.onComplete = () {
      onComplete?.call();
      if (resetStateWhenComplete) {
        setState(kStandState);
      }
    };
    return anim.ticker.completed;
  }

  final bool isHero;

  late final StatusBar status;

  int removeStatusEffect(String effect, {int count = 1}) =>
      status.removeEffect(effect, count: count);

  void addStatusEffect(String effect, {int count = 1}) =>
      status.addEffect(effect, count: count);

  final dynamic data;

  int get life => data['stats']['life'];
  set life(int value) {
    data['stats']['life'] = value;
    status.life = life.toDouble();
  }

  int get lifeMax => data['stats']['lifeMax'];
  set lifeMax(int value) {
    data['stats']['lifeMax'] = value;
    status.lifeMax = value.toDouble();
  }

  int get mana => data['stats']['mana'];
  set mana(int value) {
    data['stats']['mana'] = value;
    status.mana = value.toDouble();
  }

  int get manaMax => data['stats']['manaMax'];
  set manaMax(int value) {
    data['stats']['manaMax'] = value;
    status.manaMax = value.toDouble();
  }

  int get attack => data['stats']['attack'];

  BattleCharacter? opponent;

  BattleCharacter({
    super.position,
    super.size,
    this.isHero = false,
    required this.skinId,
    required Set<String> cardAnimations,
    required this.data,
  }) : super(anchor: Anchor.topCenter) {
    _currentState = '${kStandState}_$skinId';
    cardAnimations.addAll(kPreloadAnimationStates.map((e) => '${e}_$skinId'));
    for (final state in cardAnimations) {
      assert(GameData.animationData.containsKey(state));
      final data = GameData.animationData[state];
      _animations[state] = SpriteAnimationWithTicker(
        animationId: state,
        srcSize: Vector2(data['width'], data['height']),
        stepTime: data['stepTime'],
        loop: data['loop'],
        renderRect: Rect.fromLTWH(
          data['offsetX'].toDouble(),
          data['offsetY'].toDouble(),
          data['width'].toDouble() * 2,
          data['height'].toDouble() * 2,
        ),
      );
    }
  }

  @override
  Future<void> onLoad() async {
    for (final anim in _animations.values) {
      await anim.load();
    }

    status = StatusBar(
      position: absoluteTopCenter,
      life: life.toDouble(),
      lifeMax: data['stats']['lifeMax'].toDouble(),
    );
    gameRef.world.add(status);

    if (!isHero) {
      flipHorizontally();
    }
  }

  @override
  void render(Canvas canvas) {
    currentAnimation.render(canvas);
  }

  @override
  void update(double dt) {
    currentAnimation.update(dt);
  }

  void _addHintText(String text, {double duration = 1.0, Color? textColor}) {
    final c2 = FadingText(
      text,
      position: Vector2(center.x + Random().nextDouble() * 20 - 10, center.y),
      movingUpOffset: 50,
      duration: duration,
      textPaint: TextPaint(
        style: TextStyle(
          color: textColor ?? Colors.white70,
          fontSize: 24,
        ),
      ),
    );
    gameRef.world.add(c2);
  }

  Future<void> restoreLife(int value) async {
    final v = value.toInt();
    int hp = life;
    int hpMax = data['stats']['lifeMax'];

    engine.playSound('sound_effect/spell-of-healing-876.mp3',
        volume: GameConfig.soundEffectVolume);
    await setState('heal');
    _addHintText(
      '${engine.locale['life']}+$v',
      textColor: Colors.lightGreen,
    );
    if (hp >= hpMax) return;
    hp += v;
    if (hp > hpMax) {
      hp = hpMax;
    }
    life = hp;
  }

  Future<void> restoreMana(int value) async {
    final v = value.toInt();
    int mp = mana;
    int mpMax = manaMax;

    engine.playSound('sound_effect/spell-of-healing-876.mp3',
        volume: GameConfig.soundEffectVolume);
    await setState('condense_spirit');
    _addHintText(
      '${engine.locale['mana']}+$v',
      textColor: Colors.lightBlue,
    );
    if (mp >= mpMax) return;
    mp += v;
    if (mp > mpMax) {
      mp = mpMax;
    }
    mana = mp;
  }

  Future<void> setDefendState({String? state}) async {
    state ??= 'normal';
    await setState('defend_$state', resetStateWhenComplete: true);
  }

  Future<void> setAttackState({String? state}) async {
    state ??= 'normal';
    final savedPriority = priority;
    priority = kTopLayerPriority;
    final recoveryAnimationId = 'attack_${state}_recovery';

    void onAttackComplete() {
      if (containsState(recoveryAnimationId)) {
        setState(recoveryAnimationId, resetStateWhenComplete: true);
      } else {
        setState(kStandState);
      }
    }

    await setState(
      'attack_$state',
      onComplete: onAttackComplete,
    );
    priority = savedPriority;
  }

  Future<void> takeDamage(num damage, String damageType) async {
    assert(isLoaded);
    assert(damage >= 0);

    // TODO:如果有防，则播放格挡动画
    await setState(
      kHitState,
      onComplete: () =>
          setState(kHitRecoveryState, resetStateWhenComplete: true),
    );

    Map<String, dynamic> args = {'damage': damage.toInt()};
    switch (damageType) {
      case DamageType.weapon:
        args['damage'] += attack;
        status.handleEffectCallback(
          callbackId: 'self_attacked',
          self: this,
          opponent: opponent!,
          args: args,
        );
      default:
    }

    int d = args['damage'];

    final damageString = d > 0 ? '-$d' : '$d';
    _addHintText(damageString);

    if (d <= 0) {
      engine.playSound('sound_effect/shield-block-shortsword-143940.mp3',
          volume: GameConfig.soundEffectVolume);
    } else {
      engine.playSound('sound_effect/sword-sound-2-36274.mp3',
          volume: GameConfig.soundEffectVolume);
      int life = data['stats']['life'];
      life -= d;
      if (life < 0) {
        life = 0;
      }
      data['stats']['life'] = life;
      status.life = life.toDouble();
    }
  }
}
