import 'dart:math' as math;

// import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/progress_indicator.dart';
import 'package:samsara/cardgame/card.dart';
import 'package:samsara/components/hovertip.dart';
import 'package:samsara/animation/animation_state_controller.dart';
import 'package:samsara/cardgame/custom_card.dart';
// import 'package:samsara/components/task_component.dart';

import '../../engine.dart';
import '../../data.dart';
import 'battledeck_zone.dart';
import '../../ui.dart';
import 'status_effect.dart';

const Set<String> kCardTypes = {
  'attack',
  'buff',
};

const kTopLayerAnimationPriority = 500;
const kStatusEffectIconPriority = 1000;

const String kDefeatState = 'defeat';
const String kDodgeState = 'dodge';
const String kDodgeRecoveryState = 'dodge_recovery';
const String kHitState = 'hit';
const String kHitRecoveryState = 'hit_recovery';
const String kStandState = 'stand';
const Set<String> kPreloadAnimationStates = {
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

  late final DynamicColorProgressIndicator _hpBar; //, _mpBar;

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

  // int get mana => data['stats']['mana'];
  // setMana(int value, {bool animated = true}) {
  //   assert(value <= _mpBar.max);
  //   data['stats']['mana'] = value;
  //   _mpBar.setValue(value, animated: animated);
  // }

  // int get manaMax => data['stats']['manaMax'];
  // set manaMax(int value) {
  //   data['stats']['manaMax'] = value;
  //   _mpBar.max = value;
  // }

  // int get weaponDamage => data['stats']['weaponDamage'];

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

  void _loadAnimFromData({
    required dynamic data,
    required Iterable<String> states,
    required String directory,
    bool isOverlay = false,
  }) {
    assert(data != null);
    for (final state in states) {
      final animData = data[state];
      assert(animData != null);
      final anim = SpriteAnimationWithTicker(
        animationId: '$directory/$state.png',
        srcSize: Vector2(animData['width'], animData['height']),
        stepTime: animData['stepTime'],
        loop: animData['loop'],
        renderRect: Rect.fromLTWH(
          animData['offsetX'].toDouble(),
          animData['offsetY'].toDouble(),
          animData['width'].toDouble() * 2,
          animData['height'].toDouble() * 2,
        ),
      );
      addState(state, anim, isOverlay: isOverlay);
    }
  }

  BattleCharacter({
    super.position,
    super.size,
    this.isHero = false,
    required this.skinId,
    required Set<String> animationStates,
    required Set<String> overlayAnimationStates,
    required this.data,
    required this.deckZone,
  }) : super(
          anchor: Anchor.topCenter,
          priority: kTopLayerAnimationPriority,
        ) {
    assert(GameData.animationsData.containsKey(skinId));

    if (!isHero) {
      flipHorizontally();
    }

    currentAnimationState = kStandState;
    animationStates.addAll(kPreloadAnimationStates);

    final data = GameData.animationsData[skinId];
    _loadAnimFromData(data: data, states: animationStates, directory: skinId);
    _loadAnimFromData(
      data: data,
      states: overlayAnimationStates,
      directory: 'overlay',
      isOverlay: true,
    );
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

    // _mpBar = DynamicColorProgressIndicator(
    //   anchor: isHero ? Anchor.topLeft : Anchor.topRight,
    //   position: Vector2(0, -GameUI.resourceBarHeight * 2),
    //   size: Vector2(width, GameUI.resourceBarHeight),
    //   value: mana,
    //   max: manaMax,
    //   colors: [Colors.lightBlue, Colors.blue],
    //   showNumber: true,
    // );
    // if (!isHero) {
    //   _mpBar.flipHorizontally();
    // }
    // add(_mpBar);
  }

  @override
  void render(Canvas canvas) {
    currentAnimation?.render(canvas);
    if (currentOverlayAnimation != null) {
      if (!currentOverlayAnimation!.ticker.done()) {
        currentOverlayAnimation?.render(canvas);
      }
    }
  }

  @override
  void update(double dt) {
    currentAnimation?.update(dt);
    currentOverlayAnimation?.update(dt);
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

  void _removeStatusEffect(StatusEffect effect) {
    effect.removeFromParent();
    _statusEffects.remove(effect.id);

    if (effect.isPermenant) {
      reArrangePermenantEffects();
    } else {
      reArrangeNonPermenantEffects();
    }
  }

  /// 如果提供了amount，则返回要移除的数量和效果数量的差额，最小是0
  /// 例如10攻打在5防上，差额5，意味着移除全部防之后，还有5点伤害需要处理
  /// 如果是5攻打在10防上，意味着5攻消耗完毕，剩下的攻的数值是0
  /// 返回的是移除的数量
  int removeStatusEffect(String id, {int? amount, double? percentage}) {
    assert(_statusEffects.containsKey(id));
    final effect = _statusEffects[id]!;
    assert(!effect.isPermenant);

    int removedAmount = 0;
    if (amount != null) {
      assert(amount > 0);
      removedAmount = math.min(effect.amount, amount);
    } else if (percentage != null) {
      assert(percentage > 0 && percentage < 1);
      removedAmount = (effect.amount * percentage).truncate();
    } else {
      removedAmount = effect.amount;
    }

    effect.amount -= removedAmount;
    if (effect.amount == 0) {
      _removeStatusEffect(effect);
    }

    return removedAmount;
  }

  void addStatusEffect(String id, {int? amount, bool playSound = false}) {
    amount ??= 1;
    assert(amount > 0);
    StatusEffect effect;
    if (_statusEffects.containsKey(id)) {
      effect = _statusEffects[id]!;
      if (effect.isUnique) return;

      effect.amount += amount;

      if (playSound && effect.soundId != null) {
        engine.play('${effect.soundId}', volume: GameConfig.soundEffectVolume);
      }
    } else {
      effect = StatusEffect(
        priority: kStatusEffectIconPriority,
        id: id,
        amount: amount,
        anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      );
      if (!effect.isHidden) {
        gameRef.world.add(effect);
      }
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
  void handleStatusEffectCallback(String callbackId, [dynamic details]) {
    void invokeScript(StatusEffect effect) {
      engine.hetu.invoke(
        'status_script_${effect.script}_$callbackId',
        positionalArgs: [this, opponent, effect.data, details],
        ignoreUndefined: true, // 如果不存在对应callback就跳过
      );
    }

    // 复制一份列表，因为在执行脚本过程中可能会修改这个列表
    for (final effect in permenantEffects.toList()) {
      invokeScript(effect);
    }

    for (final effect in nonPermenantEffects.toList()) {
      invokeScript(effect);
    }
  }

  void addHintText(String text, {Color? color}) {
    game.addHintText(
      text,
      position: center,
      color: color,
      textStyle: TextStyle(
        fontFamily: GameUI.fontFamily,
      ),
    );
  }

  void reset() {
    setLife(lifeMax, animated: false);
    // setMana(0, animated: false);
    setState(kStandState);
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

  Future<void> changeLife(int value, {bool playSound = false}) async {
    if (value == 0) return;

    // await setState('restore_life');

    int hp = life;
    hp += value;
    if (hp > lifeMax) {
      hp = lifeMax;
    } else if (hp < 0) {
      hp = 0;
    }

    final diff = hp - life;

    if (diff > 0) {
      addHintText(
        '${engine.locale('life')} +$diff',
        color: Colors.lightGreen,
      );

      if (playSound) {
        engine.play('spell-of-healing-876.mp3',
            volume: GameConfig.soundEffectVolume);
      }
    } else {
      addHintText(
        '${engine.locale('life')} -$diff',
        color: Colors.pink,
      );
    }

    setLife(hp);
  }

  // bool consumeMana(int value) {
  //   assert(value > 0);

  //   if (value <= mana) {
  //     addHintText(
  //       '${engine.locale('mana')}-$value',
  //       color: Colors.red,
  //     );
  //     setMana(mana - value);
  //     return true;
  //   } else {
  //     addHintText(
  //       engine.locale('notEnoughMana'),
  //       color: Colors.deepPurple,
  //     );
  //     return false;
  //   }
  // }

  // Future<void> restoreMana(int value) async {
  //   assert(value >= 0);

  //   // await setState('restore_mana');

  //   int mp = mana;
  //   int mpMax = manaMax;
  //   mp += value;
  //   if (mp > mpMax) {
  //     mp = mpMax;
  //   }

  //   final diff = mp - mana;
  //   addHintText(
  //     '${engine.locale('mana')}+$diff',
  //     color: Colors.lightGreen,
  //   );

  //   if (diff > 0) {
  //     engine.play('spell-of-healing-876.mp3',
  //         volume: GameConfig.soundEffectVolume);
  //     setMana(mana);
  //   }
  // }

  Future<void> setState(
    String state, {
    // String? type,
    String? overlay,
    String? recovery,
    String? complete = kStandState,
  }) async {
    // if (type != null) {
    //   assert(kCardTypes.contains(type));
    //   state = '${type}_$state';
    // }

    // String? recoveryState = recovery ? '${state}_recovery' : null;

    await setAnimationState(
      state,
      overlayState: overlay,
      recoveryState: recovery,
      completeState: complete,
    );
  }

  int _handleDamage(dynamic details) {
    assert(details['initialDamage'] > 0);
    if (hasStatusEffect('invincible') > 0) {
      // 伤害免疫效果
      details['damage'] = (details['initialDamage'] * 0.5).truncate();
    }
    //
    //else {
    // switch (damageType) {
    //   case DamageType.physical:
    //     details['damage'] += opponent!.weaponDamage;
    //   default:
    // }

    // 触发对方造成伤害时的效果，可能会增加伤害值
    opponent!.handleStatusEffectCallback('self_doing_damage', details);
    // 触发自己受到伤害时的效果，可能会减少伤害值
    handleStatusEffectCallback('self_taking_damage', details);

    if (details['blocked'] ?? false) {
      engine.play('shield-block-shortsword-143940.mp3',
          volume: GameConfig.soundEffectVolume);
    } else {
      switch (details['kind']) {
        case 'sword':
        case 'flying_sword':
          engine.play('sword-sound-2-36274.mp3',
              volume: GameConfig.soundEffectVolume);
        case 'punch':
          engine.play('punch-or-kick-sound-effect-1-239696.mp3',
              volume: GameConfig.soundEffectVolume);
      }
    }
    // }

    int finalDamage = details['damage'];
    String damageString = finalDamage > 0 ? '-$finalDamage' : '$finalDamage';
    // if (opponent!.hasTurnFlag('ignoreBlock')) {
    //   damageString = '${engine.locale('ignoreBlock')}: $damageString';
    // }
    addHintText(damageString);

    if (finalDamage > 0) {
      int hp = life;
      hp -= finalDamage;
      if (hp < 0) {
        hp = 0;
      }
      setLife(hp);

      // 触发自己受到伤害后的效果
      handleStatusEffectCallback('self_taken_damage', details);
      // 触发对方造成伤害后的效果
      opponent!.handleStatusEffectCallback('self_done_damage', details);
    }

    return finalDamage;
  }

  /// 人物受到伤害，返回实际伤害值（有可能是0）
  int takeDamage(dynamic details) {
    int finalDamage = _handleDamage(details);

    // else if (multipleDamages != null) {
    //   for (var i = 0; i < multipleDamages.length; ++i) {
    //     final curDmg = multipleDamages[i];
    //     Future.delayed(Duration(milliseconds: 250 * i), () {
    //       final thisDetails = {
    //         ...damageDetails,
    //         'initialDamage': curDmg,
    //         'damage': curDmg,
    //       };
    //       finalDamage = _handleDamage(damageType, thisDetails);
    //     });
    //   }
    // }

    bool blocked = details['blocked'] ?? false;

    if (blocked || finalDamage == 0) {
      // 这里不能用await，动画会卡住
      setState(kDodgeState);
    } else {
      setState(kHitState, recovery: kHitRecoveryState);
    }

    return finalDamage;
  }

  /// 返回值是一个map，若map中 skipTurn 的key对应值为true表示跳过此回合
  Future<Map<String, dynamic>> onTurnStart(GameCard card,
      {bool isExtra = false}) async {
    final Map<String, dynamic> details = {
      "isExtra": isExtra,
    };

    opponent!.handleStatusEffectCallback('opponent_turn_start', details);

    handleStatusEffectCallback('self_turn_start', details);

    if (details['skipTurn'] ?? false) {
      addHintText(engine.locale('skipTurn'));
      await Future.delayed(Duration(milliseconds: 500));
      return details;
    }

    // 展示当前卡牌及其详情
    card.enablePreview = false;
    await card.setFocused(true);
    final (_, description) =
        GameData.getDescriptionFromCardData((card as CustomGameCard).data);
    Hovertip.show(
      scene: game,
      target: card,
      direction: HovertipDirection.topCenter,
      // direction: isHero ? HovertipDirection.rightTop : HovertipDirection.leftTop,
      content: description,
      config: ScreenTextConfig(anchor: Anchor.topCenter),
    );

    final affixes = card.data['affixes'];
    assert(affixes is List && affixes.isNotEmpty);
    final mainAffix = affixes[0];

    final genre = mainAffix['genre'];
    handleStatusEffectCallback('self_use_card_genre_$genre');
    // final tags = mainAffix['tags'];
    // assert(tags is List);
    // for (final tag in tags) {
    //   handleEffectCallback('self_use_card_tag_$tag');
    // }

    if (mainAffix['category'] == 'attack') {
      details['attackType'] = mainAffix['attackType'];
      details['damageType'] = mainAffix['damageType'];
      // 触发自己发动攻击时的效果
      handleStatusEffectCallback('self_attacking', details);
      // 触发对方被发动攻击时的效果
      opponent!.handleStatusEffectCallback('self_being_attack', details);

      // 对于攻击类卡牌，先处理额外词条，其中可能包含一些当前回合就立即起作用的buff
      for (var i = 1; i < affixes.length; ++i) {
        final affix = affixes[i];
        // if (affix['isIdentified'] == true) {
        await engine.hetu.invoke(
          'card_script_${affix['script']}',
          positionalArgs: [this, opponent, affix],
        );
        // }
      }

      // 最后再处理主词条
      await engine.hetu.invoke(
        'card_script_main_${mainAffix['script']}',
        positionalArgs: [this, opponent, affixes[0]],
      );

      // 触发自己发动攻击后的效果
      handleStatusEffectCallback('self_attacked', details);
      // 触发对方被发动攻击后的效果
      opponent!.handleStatusEffectCallback('self_be_attacked', details);
    } else {
      // 先处理主词条
      await engine.hetu.invoke(
        'card_script_main_${mainAffix['script']}',
        positionalArgs: [this, opponent, affixes[0]],
      );

      // 最后再处理额外词条，这样某些额外效果可以当回合立即使用刚刚获得的资源
      for (var i = 1; i < affixes.length; ++i) {
        final affix = affixes[i];
        // if (affix['isIdentified'] == true) {
        await engine.hetu.invoke(
          'card_script_${affix['script']}',
          positionalArgs: [this, opponent, affix],
        );
        // }
      }
    }

    return details;
  }

  /// 返回值true表示获得一个额外回合
  Future<Map<String, dynamic>> onTurnEnd(GameCard card) async {
    final details = <String, dynamic>{};
    handleStatusEffectCallback('self_turn_end', details);

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

    opponent!.handleStatusEffectCallback('opponent_turn_end');
    clearAllTurnFlags();
    return details;
  }
}
