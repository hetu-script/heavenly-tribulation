// import 'dart:math' show Random;

import 'package:samsara/samsara.dart';
import 'package:samsara/components/progress_indicator.dart';
import 'package:samsara/cardgame/card.dart';
import 'package:samsara/components/hovertip.dart';
import 'package:samsara/animation/animation_state_controller.dart';
import 'package:samsara/cardgame/custom_card.dart';

import '../../../engine.dart';
import '../../../data.dart';
import 'common.dart';
import 'deck_zone.dart';
import '../../../ui.dart';
// import '../../common.dart';
import 'status_effect.dart';

const kTopLayerAnimationPriority = 200;

const String kAttackFistState = 'attack_fist';
const String kAttackFistRecoveryState = 'attack_fist_recovery';
const String kBuffFistState = 'buff_fist';
const String kDefeatState = 'defeat';
const String kDodgeState = 'dodge';
const String kDodgeRecoveryState = 'dodge_recovery';
const String kHitState = 'hit';
const String kHitRecoveryState = 'hit_recovery';
const String kStandState = 'stand';
const Set<String> kPreloadAnimationStates = {
  kAttackFistState,
  kAttackFistRecoveryState,
  kBuffFistState,
  kDefeatState,
  kDodgeState,
  kDodgeRecoveryState,
  kHitState,
  kHitRecoveryState,
  kStandState,
};

class BattleCharacter extends GameComponent with AnimationStateController {
  final String skinId;

  final bool isHero;

  final dynamic data;

  late final DynamicColorProgressIndicator _hpBar, _mpBar;

  int get life => data['stats']['life'];
  setLife(int value, {bool animated = true}) {
    assert(value <= _hpBar.max);
    data['stats']['life'] = value;
    _hpBar.setValue(value, animated: animated);
  }

  int get lifeMax => data['stats']['lifeMax'];
  set lifeMax(int value) {
    data['stats']['lifeMax'] = value;
    _hpBar.max = value;
  }

  int get mana => data['stats']['mana'];
  setMana(int value, {bool animated = true}) {
    assert(value <= _mpBar.max);
    data['stats']['mana'] = value;
    _mpBar.setValue(value, animated: animated);
  }

  int get manaMax => data['stats']['manaMax'];
  set manaMax(int value) {
    data['stats']['manaMax'] = value;
    _mpBar.max = value;
  }

  int get weaponDamage => data['stats']['weaponDamage'];

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

  /// 返回拥有的该 id 的状态的数值，如果不存在该状态，返回 0
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

  /// 返回要移除的数量和效果数量的差额，最小是0
  /// 例如10攻打在5防上，差额5，意味着移除全部防之后，还有5点伤害需要处理
  /// 如果是5攻打在10防上，意味着5攻消耗完毕，剩下的攻的数值是0
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

    // amount 比状态数值小，这里返回0表示amount全部消耗完毕了。
    return diff > 0 ? diff : 0;
  }

  void addStatusEffect(String id, {int? amount, bool playSound = false}) {
    // 数量可以是大于 0 或者小于 0，但不能等于 0
    amount ??= 1;
    assert(amount != 0);
    StatusEffect effect;
    if (_statusEffects.containsKey(id)) {
      int newVal = 0;

      effect = _statusEffects[id]!;
      if (effect.isUnique) return;

      newVal = effect.amount + amount;

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
        amount: amount,
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

  /// details既是入参也是出参，脚本可能会获取或修改details中的内容
  void handleEffectCallback(String callbackId,
      [Map<String, dynamic>? details]) {
    details ??= {};
    void invokeScript(StatusEffect effect) {
      engine.hetu.invoke(
        'status_script_${effect.id}_$callbackId',
        positionalArgs: [this, opponent, details],
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

  void addHintText(String text, {Color? color}) {
    game.addHintText(text, position: center, color: color);
  }

  void reset() {
    setLife(lifeMax, animated: false);
    setMana(0, animated: false);
    setState('stand');
    clearAllStatusEffects();
    _turnFlags.clear();
    // TODO: resetGameFlags
  }

  bool consumeLife(int value) {
    assert(value > 0);

    if (value < life) {
      addHintText(
        '${engine.locale('life')}-$value',
        color: Colors.red,
      );
      setLife(life - value);
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
      color: Colors.lightGreen,
    );

    if (diff > 0) {
      engine.play('spell-of-healing-876.mp3',
          volume: GameConfig.soundEffectVolume);
      setLife(hp);
    }
  }

  bool consumeMana(int value) {
    assert(value > 0);

    if (value <= mana) {
      addHintText(
        '${engine.locale('mana')}-$value',
        color: Colors.red,
      );
      setMana(mana - value);
      return true;
    } else {
      addHintText(
        engine.locale('notEnoughMana'),
        color: Colors.deepPurple,
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
      color: Colors.lightGreen,
    );

    if (diff > 0) {
      engine.play('spell-of-healing-876.mp3',
          volume: GameConfig.soundEffectVolume);
      setMana(mana);
    }
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

  int _handleDamage(String damageType, Map<String, dynamic> details) {
    assert(details['damage'] > 0);
    if (hasStatusEffect('invincible') > 0) {
      // 拥有无敌状态的时候，不会触发格挡，也不会触发“造成伤害时”的效果
      details['damage'] = 0;
    } else {
      switch (damageType) {
        case DamageType.sword:
          details['damage'] += opponent!.weaponDamage;
        default:
      }
      // 触发自己受到伤害时的效果，此时的伤害还未作用于角色身上，最终可能会被减免
      handleEffectCallback('self_taking_damage', details);
      // 触发对方造成伤害时的效果
      opponent!.handleEffectCallback('self_doing_damage', details);

      if (details['blocked'] ?? false) {
        engine.play('shield-block-shortsword-143940.mp3',
            volume: GameConfig.soundEffectVolume);
      } else {
        switch (damageType) {
          case 'sword':
            engine.play('sword-sound-2-36274.mp3',
                volume: GameConfig.soundEffectVolume);
          case 'fist':
            engine.play('punch-or-kick-sound-effect-1-239696.mp3',
                volume: GameConfig.soundEffectVolume);
        }
      }
    }

    int finalDamage = details['damage'];
    String damageString = finalDamage > 0 ? '-$finalDamage' : '$finalDamage';
    if (opponent!.hasTurnFlag('ignoreBlock')) {
      damageString = '${engine.locale('ignoreBlock')}: $damageString';
    }
    addHintText(damageString);

    if (finalDamage > 0) {
      int hp = life;
      hp -= finalDamage;
      if (hp < 0) {
        hp = 0;
      }
      setLife(hp);

      // 触发自己受到伤害后的效果
      handleEffectCallback('self_taken_damage', details);
      // 触发对方造成伤害后的效果
      opponent!.handleEffectCallback('self_done_damage', details);
    }

    return finalDamage;
  }

  /// 人物受到伤害，返回实际伤害值（有可能是0）
  int takeDamage(String damageType, {int? damage, List<int>? multipleDamages}) {
    assert(damage != null ||
        (multipleDamages != null && multipleDamages.isNotEmpty));

    Map<String, dynamic> damageDetails = {
      "damageType": damageType,
    };
    int finalDamage = 0;
    if (damage != null) {
      damageDetails['damage'] = damage;
      finalDamage = _handleDamage(damageType, damageDetails);
    } else if (multipleDamages != null) {
      for (var i = 0; i < multipleDamages.length; ++i) {
        final curDmg = multipleDamages[i];
        Future.delayed(Duration(milliseconds: 250 * i), () {
          final thisDetails = {...damageDetails, 'damage': curDmg};
          finalDamage = _handleDamage(damageType, thisDetails);
        });
      }
    }

    bool blocked = damageDetails['blocked'] ?? false;

    if (blocked || damage == 0) {
      // 这里不能用await，动画会卡住
      setState(
        kDodgeState,
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

  /// 返回值是一个map，若map中 skipTurn 的key对应值为true表示跳过此回合
  Future<Map<String, dynamic>> onTurnStart(GameCard card,
      {bool isExtra = false}) async {
    final Map<String, dynamic> details = {
      "isExtra": isExtra,
    };

    opponent!.handleEffectCallback('opponent_turn_start', details);

    handleEffectCallback('self_turn_start', details);

    if (details['skipTurn'] ?? false) {
      addHintText(engine.locale('skipTurn'));
      await Future.delayed(Duration(milliseconds: 500));
      return details;
    }

    // 展示当前卡牌及其详情
    card.enablePreview = false;
    await card.setFocused(true);
    Hovertip.show(
      scene: game,
      target: card,
      direction: HovertipDirection.topCenter,
      // direction: isHero ? HovertipDirection.rightTop : HovertipDirection.leftTop,
      content: (card as CustomGameCard).extraDescription,
      config: ScreenTextConfig(anchor: Anchor.topCenter),
    );

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
      details['damageType'] = mainAffix['kind'];
      // 触发自己发动攻击时的效果
      handleEffectCallback('self_attacking', details);
      // 触发对方被发动攻击时的效果
      opponent!.handleEffectCallback('self_being_attack', details);
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
      assert(details['damageType'] != null);
      // 触发自己发动攻击后的效果
      handleEffectCallback('self_attacked', details);
      // 触发对方被发动攻击后的效果
      opponent!.handleEffectCallback('self_be_attacked', details);
    }

    return details;
  }

  /// 返回值true表示获得一个额外回合
  Future<Map<String, dynamic>> onTurnEnd(GameCard card) async {
    final details = <String, dynamic>{};
    handleEffectCallback('self_turn_end', details);

    await card.setFocused(false);
    card.isEnabled = false;
    Hovertip.hide(card);
    card.enablePreview = true;

    if (details['dodgeTurn'] ?? false) {
      addHintText(engine.locale('dodgeTurn'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    if (details['extraTurn'] ?? false) {
      addHintText(engine.locale('extraTurn'));
      return details;
    }

    opponent!.handleEffectCallback('opponent_turn_end');
    clearAllTurnFlags();
    return details;
  }
}
