import 'dart:math' show Random;

import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/progress_indicator.dart';
import 'package:samsara/components/fading_text.dart';
import 'package:samsara/cardgame/card.dart';
import 'package:samsara/components/tooltip.dart';
import 'package:samsara/animation/animation_state_controller.dart';

import '../../../config.dart';
import '../../../data.dart';
import 'common.dart';
import 'deck_zone.dart';
import '../../../ui.dart';
import '../../common.dart';

const kTopLayerAnimationPriority = 200;

const String kDefeatState = 'defeat';
const String kStandState = 'stand';
const String kHitState = 'hit';
const String kHitRecoveryState = 'hit_recovery';
const String kDodgeState = 'dodge';
const String kDodgeRecoveryState = 'dodge_recovery';
const String kAttackSwordState = 'attack_sword';
const String kAttackSwordRecoveryState = 'attack_sword_recovery';
const String kDefendSwordState = 'defend_sword';
const String kAttackFistState = 'attack_fist';
const String kAttackFistRecoveryState = 'attack_fist_recovery';
const String kDefendFistState = 'defend_fist';
const Set<String> kPreloadAnimationStates = {
  kDefeatState,
  kStandState,
  kHitState,
  kHitRecoveryState,
  kAttackFistState,
  kAttackFistRecoveryState,
  kDefendFistState,
};

enum StatusEffectType {
  permenant,
  block,
  buff,
  debuff,
  none,
}

StatusEffectType getStatusEffectType(String? id) {
  return StatusEffectType.values.firstWhere((element) => element.name == id,
      orElse: () => StatusEffectType.none);
}

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

  final String id;

  late final Sprite sprite;

  int amount;

  late bool allowNegative;

  late final int effectPriority;

  late final StatusEffectType type;

  bool get isPermenant => type == StatusEffectType.permenant;

  late final bool isUnique;

  final List<String> callbacks = [];

  String? soundId;

  late ScreenTextConfig countTextConfig;

  late final String title, description;

  StatusEffect({
    required this.id,
    required this.amount,
    super.position,
    super.anchor,
    super.priority,
  }) {
    assert(amount >= 1);
    assert(GameData.statusEffectsData.containsKey(id));
    final data = GameData.statusEffectsData[id];
    type = getStatusEffectType(data['type']);
    isUnique = data['unique'] ?? false;
    allowNegative = data['allowNegative'] ?? false;
    effectPriority = data['priority'] ?? 0;
    size = isPermenant
        ? GameUI.permenantStatusEffectIconSize
        : GameUI.statusEffectIconSize;
    for (final callbackId in data['callbacks']) {
      callbacks.add(callbackId);
    }
    soundId = data['sound'];
    countTextConfig = defaultEffectCountStyle.copyWith(size: size);

    description =
        '${engine.locale('$id.title')}\n${engine.locale('$id.description')}';

    onMouseEnter = () {
      Tooltip.show(
        scene: gameRef,
        target: this,
        direction: anchor.x == 0
            ? TooltipDirection.topLeft
            : TooltipDirection.topRight,
        content: description,
      );
    };
    onMouseExit = () {
      Tooltip.hide();
    };
  }

  @override
  Future<void> onLoad() async {
    sprite = Sprite(await Flame.images.load('icon/status/$id.png'));
  }

  @override
  void render(Canvas canvas) {
    sprite.render(canvas, size: size);
    drawScreenText(canvas, '$amount', config: countTextConfig);
  }
}

class BattleCharacter extends GameComponent with AnimationStateController {
  final String skinId;

  final bool isHero;

  final dynamic data;

  late final DynamicColorProgressIndicator _hpBar, _mpBar;

  int get life => data['stats']['life'];
  set life(int value) {
    assert(value <= _hpBar.max);
    data['stats']['life'] = value;
    _hpBar.value = value;
  }

  int get lifeMax => data['stats']['lifeMax'];
  set lifeMax(int value) {
    data['stats']['lifeMax'] = value;
    _hpBar.max = value;
  }

  int get mana => data['stats']['mana'];
  set mana(int value) {
    assert(value <= _mpBar.max);
    data['stats']['mana'] = value;
    _mpBar.value = value;
  }

  int get manaMax => data['stats']['manaMax'];
  set manaMax(int value) {
    data['stats']['manaMax'] = value;
    _mpBar.max = value;
  }

  int get weaponAttack => data['stats']['weaponAttack'];

  BattleCharacter? opponent;

  final Map<String, StatusEffect> _statusEffects = {};

  List<StatusEffect> get nonPermenantEffects {
    final els =
        _statusEffects.values.where((element) => !element.isPermenant).toList();
    els.sort((e1, e2) => -e1.effectPriority.compareTo(e2.effectPriority));
    return els;
  }

  List<StatusEffect> get permenantEffects {
    final els =
        _statusEffects.values.where((element) => element.isPermenant).toList();
    els.sort((e1, e2) => -e1.effectPriority.compareTo(e2.effectPriority));
    return els;
  }

  final BattleDeckZone deckZone;

  final Set<String> _turnFlags = {};
  setTurnFlag(String id) => _turnFlags.add(id);
  hasTurnFlag(String id) => _turnFlags.contains(id);
  removeTurnFlag(String id) => _turnFlags.remove(id);
  clearAllTurnFlags() => _turnFlags.clear();

  final Set<String> _gameFlags = {};
  setGameFlag(String id) => _gameFlags.add(id);
  hasGameFlag(String id) => _gameFlags.contains(id);
  removeGameFlag(String id) => _gameFlags.remove(id);
  clearAllGameFlags() => _gameFlags.clear();

  BattleCharacter({
    super.position,
    super.size,
    this.isHero = false,
    required this.skinId,
    required Set<String> animationStates,
    required this.data,
    required this.deckZone,
  }) : super(anchor: Anchor.topCenter) {
    if (!isHero) {
      flipHorizontally();
    }

    // _currentState = '${kStandState}_$skinId';
    currentState = kStandState;
    // cardAnimations.addAll(kPreloadAnimationStates.map((e) => '${e}_$skinId'));
    animationStates.addAll(kPreloadAnimationStates);
    for (final state in animationStates) {
      assert(GameData.animationsData.containsKey(skinId));
      final data = GameData.animationsData[skinId][state];
      assert(data != null);
      final anim = SpriteAnimationWithTicker(
        animationId: '$skinId/$state.png',
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
      addState(state, anim);
    }
  }

  @override
  Future<void> onLoad() async {
    await loadStates();

    _hpBar = DynamicColorProgressIndicator(
      anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      position: Vector2(0, -GameUI.resourceBarHeight),
      size: Vector2(width, GameUI.resourceBarHeight),
      value: life,
      max: lifeMax,
      colors: [Colors.red, Colors.green],
      showNumber: true,
    );
    if (!isHero) {
      _hpBar.flipHorizontally();
    }
    add(_hpBar);

    _mpBar = DynamicColorProgressIndicator(
      anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      position: Vector2(0, -GameUI.resourceBarHeight * 2),
      size: Vector2(width, GameUI.resourceBarHeight),
      value: mana,
      max: manaMax,
      colors: [Colors.lightBlue, Colors.blue],
      showNumber: true,
    );
    if (!isHero) {
      _mpBar.flipHorizontally();
    }
    add(_mpBar);
  }

  @override
  void render(Canvas canvas) {
    currentAnimation.render(canvas);
  }

  @override
  void update(double dt) {
    currentAnimation.update(dt);
  }

  int hasStatusEffect(String id) {
    if (_statusEffects.containsKey(id)) {
      return _statusEffects[id]!.amount;
    } else {
      return 0;
    }
  }

  /// 永久效果位置在卡组上方
  void reArrangePermenantEffects() {
    for (var i = 0; i < permenantEffects.length; ++i) {
      final effect = permenantEffects.elementAt(i);
      if (isHero) {
        effect.position = Vector2(
            GameUI.indent + i * (GameUI.permenantStatusEffectIconSize.x + 5),
            GameUI.p1BattleDeckZonePosition.y -
                GameUI.indent -
                GameUI.permenantStatusEffectIconSize.y);
      } else {
        effect.position = Vector2(
            GameUI.size.x -
                GameUI.indent -
                i * (GameUI.permenantStatusEffectIconSize.x + 5),
            GameUI.p2BattleDeckZonePosition.y -
                GameUI.indent -
                GameUI.permenantStatusEffectIconSize.y);
      }
    }
  }

  /// 非永久效果位置在血条上方
  void reArrangeNonPermenantEffects() {
    for (var i = 0; i < nonPermenantEffects.length; ++i) {
      final effect = nonPermenantEffects.elementAt(i);
      if (isHero) {
        effect.position = Vector2(
            GameUI.p1HeroSpritePosition.x -
                GameUI.heroSpriteSize.x / 2 +
                i * GameUI.statusEffectIconSize.x,
            GameUI.p1HeroSpritePosition.y -
                (GameUI.statusEffectIconSize.y + GameUI.resourceBarHeight * 2));
      } else {
        effect.position = Vector2(
            GameUI.p2HeroSpritePosition.x -
                GameUI.heroSpriteSize.x / 2 +
                (i + 1) * GameUI.statusEffectIconSize.x,
            GameUI.p2HeroSpritePosition.y -
                (GameUI.statusEffectIconSize.y + GameUI.resourceBarHeight * 2));
      }
    }
  }

  void clearAllStatusEffects() {
    for (final effect in _statusEffects.values) {
      effect.removeFromParent();
    }

    _statusEffects.clear();
  }

  void removeEffect(StatusEffect effect) {
    effect.removeFromParent();
    _statusEffects.remove(effect.id);

    if (effect.isPermenant) {
      reArrangePermenantEffects();
    } else {
      reArrangeNonPermenantEffects();
    }
  }

  /// 返回要移除的数量大于效果数量的差额
  /// 例如10攻打在5防上，差额5，意味着移除全部防之后，还有5点伤害需要处理
  int removeStatusEffect(String id, {int? amount, double? percentage}) {
    int diff = 0;

    if (_statusEffects.containsKey(id)) {
      final effect = _statusEffects[id]!;

      if (amount != null) {
        assert(amount > 0);
        diff = amount - effect.amount;
        if (diff < 0) {
          effect.amount = -diff;
        } else if (diff == 0) {
          removeEffect(effect);
        } else {
          if (effect.allowNegative) {
            // 某些效果允许负值存在
            effect.amount = -diff;
          } else {
            removeEffect(effect);
          }
        }
      } else if (percentage != null) {
        assert(!effect.isPermenant);
        assert(percentage > 0 && percentage < 1);
        effect.amount -= (effect.amount * percentage).truncate();
        if (effect.amount == 0) {
          removeEffect(effect);
        }
      } else {
        removeEffect(effect);
      }
    }
    return diff;
  }

  void addStatusEffect(String id, {int count = 1, bool playSound = true}) {
    // 数量可以是大于0或者小于0
    assert(count != 0);
    StatusEffect effect;
    if (_statusEffects.containsKey(id)) {
      int newVal = 0;

      effect = _statusEffects[id]!;
      if (effect.isUnique) return;

      newVal = effect.amount + count;

      if (newVal > 0) {
        effect.amount = newVal;
      } else if (newVal == 0) {
        removeEffect(effect);
      } else {
        if (effect.allowNegative) {
          // 某些效果允许负值存在
          effect.amount = newVal;
        } else {
          removeEffect(effect);
        }
      }

      if (playSound && effect.soundId != null) {
        engine.play('${effect.soundId}', volume: GameConfig.soundEffectVolume);
      }
    } else {
      effect = StatusEffect(
        priority: 4000,
        id: id,
        amount: count,
        anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      );
      gameRef.world.add(effect);
      _statusEffects[id] = effect;

      if (playSound && effect.soundId != null) {
        engine.play('${effect.soundId}', volume: GameConfig.soundEffectVolume);
      }
    }

    if (effect.isPermenant) {
      reArrangePermenantEffects();
    } else {
      reArrangeNonPermenantEffects();
    }
  }

  void handleEffectCallback(String callbackId, [Map<String, dynamic>? args]) {
    args ??= {};
    void invokeScript(StatusEffect effect) {
      args!['amount'] = effect.amount;
      engine.hetu.invoke(
        'status_script_${effect.id}_$callbackId',
        positionalArgs: [this, opponent, args],
        ignoreUndefined: true, // 如果不存在对应callback就跳过
      );
    }

    for (final effect in permenantEffects) {
      invokeScript(effect);
    }

    for (final effect in nonPermenantEffects) {
      invokeScript(effect);
    }
  }

  void addHintText(String text, {double duration = 2, Color? textColor}) {
    final c2 = FadingText(
      text,
      position: Vector2(center.x + Random().nextDouble() * 40 - 20, center.y),
      movingUpOffset: 100,
      duration: duration,
      config: ScreenTextConfig(
        textStyle: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'RuiZiYunZiKuLiBianTiGBK',
        ),
      ),
      priority: kHintTextPriority,
    );
    gameRef.world.add(c2);
  }

  void reset() {
    life = lifeMax;
    mana = 0;
    setState('stand');
    clearAllStatusEffects();
    _turnFlags.clear();
  }

  bool consumeLife(int value) {
    assert(value > 0);

    if (value < life) {
      addHintText(
        '${engine.locale('life')}-$value',
        textColor: Colors.red,
      );
      life -= value;
      return true;
    } else {
      return false;
    }
  }

  Future<void> restoreLife(int value) async {
    assert(value >= 0);

    await setState('restore_life', resetOnComplete: kStandState);

    int hp = life;
    int hpMax = lifeMax;
    hp += value;
    if (hp > hpMax) {
      hp = hpMax;
    }

    final diff = hp - life;
    addHintText(
      '${engine.locale('life')}+$diff',
      textColor: Colors.lightGreen,
    );

    if (diff > 0) {
      engine.play('spell-of-healing-876.mp3',
          volume: GameConfig.soundEffectVolume);
      life = hp;
    }
  }

  bool consumeMana(int value) {
    assert(value > 0);

    if (value <= mana) {
      addHintText(
        '${engine.locale('mana')}-$value',
        textColor: Colors.red,
      );
      mana -= value;
      return true;
    } else {
      addHintText(
        engine.locale('notEnoughMana'),
        textColor: Colors.deepPurple,
      );
      return false;
    }
  }

  Future<void> restoreMana(int value) async {
    assert(value >= 0);

    await setState('restore_mana', resetOnComplete: kStandState);

    int mp = mana;
    int mpMax = manaMax;
    mp += value;
    if (mp > mpMax) {
      mp = mpMax;
    }

    final diff = mp - mana;
    addHintText(
      '${engine.locale('mana')}+$diff',
      textColor: Colors.lightGreen,
    );

    if (diff > 0) {
      engine.play('spell-of-healing-876.mp3',
          volume: GameConfig.soundEffectVolume);
      mana = mp;
    }
  }

  Future<void> setSpellState([String? state]) async {
    state ??= 'default';
    await setState('spell_$state', resetOnComplete: kStandState);
  }

  Future<void> setDefendState(String state) async {
    await setState('defend_$state', resetOnComplete: kStandState);
  }

  Future<void> setAttackState(String state) async {
    final savedPriority = priority;
    priority = kTopLayerAnimationPriority;
    final recoveryAnimationId = 'attack_${state}_recovery';

    await setState(
      'attack_$state',
      onComplete: () {
        if (containsState(recoveryAnimationId)) {
          setState(recoveryAnimationId, resetOnComplete: kStandState);
        } else {
          setState(kStandState);
        }
      },
    );
    priority = savedPriority;
  }

  int _handleDamage(String damageType, int damage, Map<String, dynamic> args) {
    assert(damage > 0);
    switch (damageType) {
      case DamageType.blade:
        args['damage'] += opponent!.weaponAttack;
      default:
    }

    // 触发自己受到伤害时的效果
    handleEffectCallback('self_taking_damage', args);
    // 触发对方造成伤害时的效果
    opponent!.handleEffectCallback('self_damaging', args);

    if (args['blocked'] ?? false) {
      engine.play('shield-block-shortsword-143940.mp3',
          volume: GameConfig.soundEffectVolume);
    } else {
      switch (damageType) {
        case 'blade':
          engine.play('sword-sound-2-36274.mp3',
              volume: GameConfig.soundEffectVolume);
        case 'punchkick':
          engine.play('punch-or-kick-sound-effect-1-239696.mp3',
              volume: GameConfig.soundEffectVolume);
      }
    }

    int d = args['damage'];
    String damageString = d > 0 ? '-$d' : '$d';
    if (opponent!.hasTurnFlag('ignoreBlock')) {
      damageString = '${engine.locale('ignoreBlock')}: $damageString';
    }
    addHintText(damageString);

    if (d > 0) {
      int hp = life;
      hp -= d;
      if (hp < 0) {
        hp = 0;
      }
      life = hp;
    }

    return d;
  }

  /// 人物受到伤害，返回实际伤害值（有可能是0）
  int takeDamage(String damageType, {int? damage, List<int>? multipleDamages}) {
    assert(damage != null ||
        (multipleDamages != null && multipleDamages.isNotEmpty));

    int finalDamage = 0;
    Map<String, dynamic> args = {};
    if (damage != null) {
      args['damage'] = damage;
      finalDamage = _handleDamage(damageType, damage, args);
    } else if (multipleDamages != null) {
      for (var i = 0; i < multipleDamages.length; ++i) {
        final curDmg = multipleDamages[i];
        Future.delayed(Duration(milliseconds: 500 * i), () {
          args['damage'] = curDmg;
          finalDamage = _handleDamage(damageType, curDmg, args);
        });
      }
    }

    if (args['blocked'] ?? false) {
      // 这里不能用await，动画会卡住
      setState(
        kDefendFistState,
        resetOnComplete: kStandState,
      );
    } else {
      setState(
        kHitState,
        onComplete: () =>
            setState(kHitRecoveryState, resetOnComplete: kStandState),
      );
    }

    return finalDamage;
  }

  Future<void> onTurnStart(GameCard card) async {
    handleEffectCallback('self_turn_start');

    opponent!.handleEffectCallback('opponent_turn_start');

    final affixes = card.data['affixes'];
    assert(affixes is List && affixes.isNotEmpty);
    final mainAffix = affixes[0];

    final genre = mainAffix['genre'];
    handleEffectCallback('self_use_card_genre_$genre');
    // final tags = mainAffix['tags'];
    // assert(tags is List);
    // for (final tag in tags) {
    //   handleEffectCallback('self_use_card_tag_$tag');
    // }

    if (mainAffix['category'] == 'attack') {
      // 触发自己发动攻击时的效果
      handleEffectCallback('self_attacking');
      // 触发对方被发动攻击时的效果
      opponent!.handleEffectCallback('self_being_attack');
    }

    // 先处理额外词条，其中可能包含一些当前回合就立即起作用的效果
    for (var i = 1; i < affixes.length; ++i) {
      final affix = affixes[i];
      await engine.hetu.invoke(
        'card_script_${affix['script']}',
        positionalArgs: [this, opponent, affix],
      );
    }

    // 最后再处理主词条
    await engine.hetu.invoke(
      'card_script_${affixes[0]['script']}',
      positionalArgs: [this, opponent, affixes[0]],
    );

    if (mainAffix['category'] == 'attack') {
      // 触发自己发动攻击后的效果
      handleEffectCallback('self_attacked');
      // 触发对方被发动攻击后的效果
      opponent!.handleEffectCallback('self_be_attacked');
    }
  }

  void onTurnEnd(GameCard card) {
    handleEffectCallback('self_turn_end');
    opponent!.handleEffectCallback('opponent_turn_end');
    clearAllTurnFlags();
  }
}
