import 'dart:math' show Random;

import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/gestures/gesture_mixin.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/component/progress_indicator.dart';
import 'package:samsara/component/fading_text.dart';
import 'package:samsara/cardgame/card.dart';
import 'package:samsara/component/tooltip.dart';

import '../../../config.dart';
import '../../../data.dart';
import 'common.dart';
import 'deck_zone.dart';
import '../../../ui.dart';

const kTopLayerAnimationPriority = 200;
const kHintTextPriority = 500;

const String kDefeatState = 'defeat';
const String kStandState = 'stand';
const String kHitState = 'hit';
const String kHitRecoveryState = 'hit_recovery';
const String kNormalAttackState = 'attack_normal';
const String kNormalAttackRecoveryState = 'attack_normal_recovery';
const String kNormalDefendState = 'defend_normal';
const Set<String> kPreloadAnimationStates = {
  kDefeatState,
  kStandState,
  kHitState,
  kHitRecoveryState,
  kNormalAttackState,
  kNormalAttackRecoveryState,
  kNormalDefendState,
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

class StatusEffect extends GameComponent with HandlesGesture {
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

  int amount;

  late final int effectPriority;

  late final StatusEffectType type;

  bool get isPermenant => type == StatusEffectType.permenant;

  late final bool isUnique;

  final List<String> callbacks = [];

  String? soundId;

  late ScreenTextStyle countTextStyle;

  late final String title, description;

  StatusEffect({
    required this.id,
    required this.amount,
    super.position,
    super.anchor,
    super.priority,
  }) {
    assert(GameData.statusEffectData.containsKey(id));
    final data = GameData.statusEffectData[id];
    type = getStatusEffectType(data['type']);
    isUnique = data['unique'] ?? false;
    effectPriority = data['priority'] ?? 0;
    size = isPermenant
        ? GameUI.permenantStatusEffectIconSize
        : GameUI.statusEffectIconSize;
    for (final callbackId in data['callbacks']) {
      callbacks.add(callbackId);
    }
    soundId = data['sound'];
    countTextStyle = defaultEffectCountStyle.copyWith(rect: border);

    title = engine.locale('$id.title');
    description = engine.locale('$id.description');

    onMouseEnter = () {
      Tooltip.show(
        scene: gameRef,
        target: this,
        preferredDirection: anchor.x == 0
            ? TooltipDirection.topLeft
            : TooltipDirection.topRight,
        title: title,
        description: description,
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
    if (amount > 1) {
      drawScreenText(canvas, '$amount', style: countTextStyle);
    }
  }
}

class BattleCharacter extends GameComponent {
  final String skinId;

  final Map<String, SpriteAnimationWithTicker> _animations = {};
  late String _currentState;

  SpriteAnimationWithTicker get currentAnimation {
    assert(_animations.containsKey(_currentState),
        'Could not find animation state: [$_currentState]');
    return _animations[_currentState]!;
  }

  final bool isHero;

  final dynamic data;

  late final DynamicColorProgressIndicator _hpBar, _mpBar;

  int get life => data['stats']['life'];
  set life(int value) {
    assert(value <= _hpBar.max);
    data['stats']['life'] = value;
    _hpBar.value = value.toDouble();
  }

  int get lifeMax => data['stats']['lifeMax'];
  set lifeMax(int value) {
    data['stats']['lifeMax'] = value;
    _hpBar.max = value.toDouble();
  }

  int get mana => data['stats']['mana'];
  set mana(int value) {
    assert(value <= _mpBar.max);
    data['stats']['mana'] = value;
    _mpBar.value = value.toDouble();
  }

  int get manaMax => data['stats']['manaMax'];
  set manaMax(int value) {
    data['stats']['manaMax'] = value;
    _mpBar.max = value.toDouble();
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

  final BattleDeck deckZone;

  final Set<String> _turnFlags = {};
  setTurnFlag(String id) => _turnFlags.add(id);
  hasTurnFlag(String id) => _turnFlags.contains(id);
  removeTurnFlag(String id) => _turnFlags.remove(id);
  clearTurnFlag() => _turnFlags.clear();

  final Set<String> _gameFlags = {};
  setGameFlag(String id) => _gameFlags.add(id);
  hasGameFlag(String id) => _gameFlags.contains(id);
  removeGameFlag(String id) => _gameFlags.remove(id);
  clearGameFlag() => _gameFlags.clear();

  BattleCharacter({
    super.position,
    super.size,
    this.isHero = false,
    required this.skinId,
    required Set<String> animationStates,
    required this.data,
    required this.deckZone,
  }) : super(anchor: Anchor.topCenter, flipH: isHero ? false : true) {
    // _currentState = '${kStandState}_$skinId';
    _currentState = kStandState;
    // cardAnimations.addAll(kPreloadAnimationStates.map((e) => '${e}_$skinId'));
    animationStates.addAll(kPreloadAnimationStates);
    for (final state in animationStates) {
      assert(GameData.animationData.containsKey(skinId));
      final data = GameData.animationData[skinId][state];
      assert(data != null);
      _animations[state] = SpriteAnimationWithTicker(
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
    }
  }

  @override
  Future<void> onLoad() async {
    for (final anim in _animations.values) {
      await anim.load();
    }

    _hpBar = DynamicColorProgressIndicator(
      anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      position: Vector2(0, -GameUI.resourceBarHeight),
      size: Vector2(width, GameUI.resourceBarHeight),
      value: life.toDouble(),
      max: lifeMax.toDouble(),
      colors: [Colors.red, Colors.green],
      showNumber: true,
      flipH: isHero ? false : true,
    );
    add(_hpBar);

    _mpBar = DynamicColorProgressIndicator(
      anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      position: Vector2(0, -GameUI.resourceBarHeight * 2),
      size: Vector2(width, GameUI.resourceBarHeight),
      value: mana.toDouble(),
      max: manaMax.toDouble(),
      colors: [Colors.lightBlue, Colors.blue],
      showNumber: true,
      flipH: isHero ? false : true,
    );
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

  bool hasStatusEffect(String id) => _statusEffects.containsKey(id);

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
            GameUI.size!.x -
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

  void clearStatusEffects() {
    for (final effect in _statusEffects.values) {
      effect.removeFromParent();
    }

    _statusEffects.clear();
  }

  /// 返回要移除的数量大于效果数量的差额
  /// 例如10攻打在5防上，差额5，意味着移除全部防之后，还有5点伤害需要处理
  int removeStatusEffect(String id, {int? amount, double? percentage}) {
    int diff = 0;

    void removeAll(StatusEffect effect) {
      effect.removeFromParent();
      _statusEffects.remove(effect.id);

      if (effect.isPermenant) {
        reArrangePermenantEffects();
      } else {
        reArrangeNonPermenantEffects();
      }
    }

    if (_statusEffects.containsKey(id)) {
      final effect = _statusEffects[id]!;

      if (amount != null) {
        assert(amount > 0);
        diff = amount - effect.amount;
        if (diff < 0) {
          effect.amount = -diff;
        } else {
          removeAll(effect);
        }
      } else if (percentage != null) {
        assert(!effect.isPermenant);
        assert(percentage > 0 && percentage < 1);
        effect.amount -= (effect.amount * percentage).truncate();
        if (effect.amount == 0) {
          removeAll(effect);
        }
      } else {
        removeAll(effect);
      }
    }
    return diff > 0 ? diff : 0;
  }

  void addStatusEffect(String id, {int count = 1}) {
    assert(count > 0);
    StatusEffect effect;
    if (_statusEffects.containsKey(id)) {
      effect = _statusEffects[id]!;
      if (effect.isUnique) return;

      effect.amount += count;

      if (effect.soundId != null) {
        engine.play('${effect.soundId}', volume: GameConfig.soundEffectVolume);
      }

      return;
    } else {
      effect = StatusEffect(
        priority: 4000,
        id: id,
        amount: count,
        anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      );
      gameRef.world.add(effect);
      _statusEffects[id] = effect;

      if (effect.soundId != null) {
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
        '${effect.id}_$callbackId',
        namespace: 'StatusEffect',
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
      textPaint: TextPaint(
        style: TextStyle(
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
    clearStatusEffects();
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

    await setState('restore_life', resetOnComplete: true);

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

    await setState('restore_mana', resetOnComplete: true);

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

  bool containsState(String stateId) {
    // return _animations.containsKey('${stateId}_$skinId');
    return _animations.containsKey(stateId);
  }

  Future<void> setState(
    String state, {
    bool resetOnComplete = false,
    void Function()? onComplete,
  }) {
    // engine.info('${isHero ? 'hero' : 'enemy'} new state: $state');
    // state = '${state}_$skinId';
    if (_currentState != state) {
      _currentState = state;
    }
    final anim = currentAnimation;
    anim.ticker.reset();
    anim.ticker.onComplete = () {
      onComplete?.call();
      if (resetOnComplete) {
        setState(kStandState);
      }
    };
    return anim.ticker.completed;
  }

  Future<void> setSpellState({String? state}) async {
    state ??= 'normal';
    await setState('spell_$state', resetOnComplete: true);
  }

  Future<void> setDefendState({String? state}) async {
    state ??= 'normal';
    await setState('defend_$state', resetOnComplete: true);
  }

  Future<void> setAttackState({String? state}) async {
    state ??= 'normal';
    final savedPriority = priority;
    priority = kTopLayerAnimationPriority;
    final recoveryAnimationId = 'attack_${state}_recovery';

    await setState(
      'attack_$state',
      onComplete: () {
        if (containsState(recoveryAnimationId)) {
          setState(recoveryAnimationId, resetOnComplete: true);
        } else {
          setState(kStandState);
        }
      },
    );
    priority = savedPriority;
  }

  void _handleDamageCallback(
      String damageType, int damage, Map<String, dynamic> args) {
    assert(damage > 0);
    switch (damageType) {
      case DamageType.weapon:
        args['damage'] += opponent!.weaponAttack;
        // 触发对方发动武器攻击的效果
        opponent!.handleEffectCallback('self_weapon_attacking', args);
        // 触发自己被武器攻击的效果
        handleEffectCallback('self_weapon_attacked', args);
      default:
    }
  }

  int _handleDamage(String damageType, int damage, Map<String, dynamic> args) {
    _handleDamageCallback(damageType, damage, args);

    if (args['blocked'] ?? false) {
      engine.play('shield-block-shortsword-143940.mp3',
          volume: GameConfig.soundEffectVolume);
    } else {
      engine.play('sword-sound-2-36274.mp3',
          volume: GameConfig.soundEffectVolume);
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

    int d = 0;
    Map<String, dynamic> args = {};
    if (damage != null) {
      args['damage'] = damage;
      d = _handleDamage(damageType, damage, args);
    } else if (multipleDamages != null) {
      for (var i = 0; i < multipleDamages.length; ++i) {
        final curDmg = multipleDamages[i];
        Future.delayed(Duration(milliseconds: 500 * i), () {
          args['damage'] = curDmg;
          d = _handleDamage(damageType, curDmg, args);
        });
      }
    }

    if (args['blocked'] ?? false) {
      // 这里不能用await，动画会卡住
      setState(
        kNormalDefendState,
        resetOnComplete: true,
      );
    } else {
      setState(
        kHitState,
        onComplete: () => setState(kHitRecoveryState, resetOnComplete: true),
      );
    }

    return d;
  }

  void onTurnStart() {
    handleEffectCallback('self_turn_start');
    opponent!.handleEffectCallback('opponent_turn_start');
  }

  void onTurnEnd() {
    handleEffectCallback('self_turn_end');
    opponent!.handleEffectCallback('opponent_turn_end');
    clearTurnFlag();
  }

  void onBeforeUseCard(Card card) {
    final genres = card.data['genre'];
    assert(genres is List);
    for (final genre in genres) {
      handleEffectCallback('self_use_card_genre_$genre');
    }
    final tags = card.data['tags'];
    assert(tags is List);
    for (final tag in tags) {
      handleEffectCallback('self_use_card_tag_$tag');
    }
  }
}
