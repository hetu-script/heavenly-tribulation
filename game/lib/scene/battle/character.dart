import 'dart:math' as math;

// import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:heavenly_tribulation/scene/battle/battle.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/progress_indicator.dart';
import 'package:samsara/components/hovertip.dart';
import 'package:samsara/animation/animation_state_controller.dart';
import 'package:samsara/cardgame/custom_card.dart';
// import 'package:samsara/components/task_component.dart';

import '../../engine.dart';
import '../../data.dart';
import 'battledeck_zone.dart';
import '../../ui.dart';
import 'status_effect.dart';
import 'common.dart';

const kSpriteScale = 2.0;

class BattleCharacter extends GameComponent with AnimationStateController {
  final String skinId;

  final bool isHero;

  final dynamic data;

  late final DynamicColorProgressIndicator _hpBar; //, _mpBar;

  late int _life;
  int get life => _life;

  /// 将生命设为指定值，如果animated为true，则会有动画效果
  void setLife(int value, {bool animated = true}) {
    assert(value >= 0 && value <= _lifeMax);
    _life = value;
    _hpBar.setValue(value, animated: animated);
  }

  late int _lifeMax;
  int get lifeMax => _lifeMax;
  void setLifeMax(int value) {
    final characterLifeMax = data['stats']['lifeMax'];
    if (value > characterLifeMax) {
      _hpBar.labelColor = Colors.yellow;
    } else if (value < characterLifeMax) {
      _hpBar.labelColor = Colors.grey;
    }
    _lifeMax = _hpBar.max = value;
  }

  BattleCharacter? opponent;

  final Map<String, StatusEffect> _statusEffects = {};

  List<StatusEffect> get effects {
    final list = _statusEffects.values.toList();
    list.sort((e1, e2) => e2.effectPriority.compareTo(e1.effectPriority));
    return list;
  }

  List<StatusEffect> get nonPermenantEffects {
    final list =
        _statusEffects.values.where((element) => !element.isPermenant).toList();
    list.sort((e1, e2) => e2.effectPriority.compareTo(e1.effectPriority));
    return list;
  }

  List<StatusEffect> get permenantEffects {
    final list =
        _statusEffects.values.where((element) => element.isPermenant).toList();
    list.sort((e1, e2) => e2.effectPriority.compareTo(e1.effectPriority));
    return list;
  }

  final BattleDeckZone deckZone;

  final Map<String, dynamic> turnDetails = {};

  // 这些是让脚本操作的接口
  setTurnFlag(String id, dynamic value) => turnDetails[id] = value;
  getTurnFlag(String id) => turnDetails[id];
  removeTurnFlag(String id) => turnDetails.remove(id);
  clearAllTurnFlags() => turnDetails.clear();
  getGameFlag(String id) => (game as BattleScene).gameDetails[id];

  void _loadAnimFromData({
    required dynamic data,
    required Iterable<String> states,
    required String directory,
    bool isOverlay = false,
  }) {
    assert(data != null);
    for (final state in states) {
      final animData = data[state];
      if (animData == null) {
        final err =
            'Animation state data for [$state] not found in directory [$directory]';
        engine.error(err);
        throw err;
      }
      final anim = SpriteAnimationWithTicker(
        animationId: '$directory/$state.png',
        srcSize: Vector2(animData['width'], animData['height']),
        stepTime: animData['stepTime'],
        loop: animData['loop'],
        renderRect: Rect.fromLTWH(
          animData['offsetX'] * kSpriteScale,
          animData['offsetY'] * kSpriteScale,
          animData['width'] * kSpriteScale,
          animData['height'] * kSpriteScale,
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
  }) : super(anchor: Anchor.topCenter) {
    assert(GameData.animations.containsKey(skinId));
    this.engine = engine;

    if (!isHero) {
      flipHorizontally();
    }

    currentAnimationState = kStandState;
    animationStates.addAll(kPreloadAnimationStates);

    _loadAnimFromData(
      data: GameData.animations[skinId],
      states: animationStates,
      directory: skinId,
    );
    _loadAnimFromData(
      data: GameData.animations['overlay'],
      states: overlayAnimationStates,
      directory: 'overlay',
      isOverlay: true,
    );
  }

  @override
  Future<void> onLoad() async {
    await loadStates();

    _life = _lifeMax = data['stats']['life'];

    _hpBar = DynamicColorProgressIndicator(
      anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      position: Vector2(0, -GameUI.resourceBarHeight),
      size: Vector2(width, GameUI.resourceBarHeight),
      value: life,
      max: lifeMax,
      colors: [Colors.red, Colors.green],
      showNumber: true,
      labelFontSize: 10.0,
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

  /// 永久效果位置在角色头像下方
  void reArrangePermenantEffects() {
    final centerPoint = Vector2(
        GameUI.size.x / 2, GameUI.hugeIndent * 2 + GameUI.versusBannerSize.y);
    for (var i = 0; i < permenantEffects.length; ++i) {
      final effect = permenantEffects.elementAt(i);
      if (isHero) {
        effect.position = Vector2(
          centerPoint.x -
              GameUI.versusIconSize.x / 2 -
              GameUI.indent -
              i * (GameUI.permenantStatusEffectIconSize.x + GameUI.smallIndent),
          GameUI.indent + GameUI.versusBannerSize.y,
        );
      } else {
        effect.position = Vector2(
          centerPoint.x +
              GameUI.versusIconSize.x / 2 +
              GameUI.indent +
              i * (GameUI.permenantStatusEffectIconSize.x + GameUI.smallIndent),
          GameUI.indent + GameUI.versusBannerSize.y,
        );
      }
    }
  }

  /// 非永久效果位置在血条上方
  void reArrangeNonresourceEffects() {
    final nonResourceEffects =
        nonPermenantEffects.where((e1) => !e1.isResource);
    for (var i = 0; i < nonResourceEffects.length; ++i) {
      final effect = nonResourceEffects.elementAt(i);
      if (isHero) {
        effect.position = Vector2(
            GameUI.p1CharacterAnimationPosition.x -
                GameUI.heroSpriteSize.x / 2 +
                i * GameUI.statusEffectIconSize.x,
            GameUI.p1CharacterAnimationPosition.y -
                (GameUI.statusEffectIconSize.y + GameUI.resourceBarHeight));
      } else {
        effect.position = Vector2(
            GameUI.p2CharacterAnimationPosition.x -
                GameUI.heroSpriteSize.x / 2 +
                (i + 1) * GameUI.statusEffectIconSize.x,
            GameUI.p2CharacterAnimationPosition.y -
                (GameUI.statusEffectIconSize.y + GameUI.resourceBarHeight));
      }
    }
  }

  /// 资源位于血条下方
  void reArrangeResourceEffects() {
    final resourceEffects = nonPermenantEffects.where((e1) => e1.isResource);
    for (var i = 0; i < resourceEffects.length; ++i) {
      final effect = resourceEffects.elementAt(i);
      if (isHero) {
        effect.position = Vector2(
            GameUI.p1CharacterAnimationPosition.x -
                GameUI.heroSpriteSize.x / 2 +
                i * GameUI.statusEffectIconSize.x,
            GameUI.p1CharacterAnimationPosition.y);
      } else {
        effect.position = Vector2(
            GameUI.p2CharacterAnimationPosition.x -
                GameUI.heroSpriteSize.x / 2 +
                (i + 1) * GameUI.statusEffectIconSize.x,
            GameUI.p2CharacterAnimationPosition.y);
      }
    }
  }

  void clearAllStatusEffects() {
    for (final effect in _statusEffects.values) {
      effect.removeFromParent();
    }

    _statusEffects.clear();
  }

  /// 如果提供了amount，则返回要移除的数量和效果数量的差额，最小是0
  /// 例如10攻打在5防上，差额5，意味着移除全部防之后，还有5点伤害需要处理
  /// 如果是5攻打在10防上，意味着5攻消耗完毕，剩下的攻的数值是0
  /// 返回的是移除的实际数量
  int removeStatusEffect(
    String id, {
    int? amount,
    double? percentage,
    bool hintLacking = true,
  }) {
    if (_statusEffects.containsKey(id)) {
      final effect = _statusEffects[id]!;
      assert(!effect.isPermenant);
      assert(effect.amount > 0);

      int removedAmount = 0;
      if (amount != null) {
        assert(amount > 0);
        removedAmount = math.min(effect.amount, amount);
      } else if (percentage != null) {
        assert(percentage > 0 && percentage < 1);
        removedAmount = (effect.amount * percentage).round();
      } else {
        removedAmount = effect.amount;
      }

      effect.amount -= removedAmount;
      if (effect.amount <= 0) {
        _statusEffects.remove(effect.id);
        effect.removeFromParent();

        if (effect.isPermenant) {
          reArrangePermenantEffects();
        } else {
          if (effect.isResource) {
            reArrangeResourceEffects();
          } else {
            reArrangeNonresourceEffects();
          }
        }
      }

      return removedAmount;
    } else {
      if (hintLacking) {
        final hint = engine.locale('resourceLacking',
            interpolations: [engine.locale('status_$id')]);
        addHintText(hint, color: Colors.grey);
      }
      return 0;
    }
  }

  void addStatusEffect(String id, {int? amount}) {
    if (amount == 0) return;
    if (amount == null) {
      if (kDebugMode) {
        engine.warn(
            'Status effect [$id] added without a specific amount, set to 1');
      }
      amount = 1;
    }
    assert(amount > 0);
    if (!GameData.statusEffects.containsKey(id)) {
      engine.error('Status effect [$id] not found!');
      return;
    }
    final data = GameData.statusEffects[id];

    if (data['isPermenant'] != true) {
      if (id.startsWith('energy_positive')) {
        // 触发自己获得阳气时的效果
        handleStatusEffectCallback('self_gain_positive_energy');
        // 触发对方获得阳气时的效果
        opponent!.handleStatusEffectCallback('opponent_gain_positive_energy');
      } else if (id.startsWith('energy_negative')) {
        // 触发自己获得阴气时的效果
        handleStatusEffectCallback('self_gain_negative_energy');
        // 触发对方获得阴气时的效果
        opponent!.handleStatusEffectCallback('opponent_gain_negative_energy');
      } else if (id.startsWith('injury')) {
        // 触发自己获得伤势时的效果
        handleStatusEffectCallback('self_gain_injury');
        // 触发对方获得伤势时的效果
        opponent!.handleStatusEffectCallback('opponent_gain_injury');
      }
    }

    StatusEffect effect;
    if (_statusEffects.containsKey(id)) {
      effect = _statusEffects[id]!;
      if (effect.isUnique) return;

      effect.amount += amount;
    } else {
      if (kOppositeEffect.containsKey(id)) {
        final oppositeId = kOppositeEffect[id]!;
        final oppositeAmount = hasStatusEffect(oppositeId);
        if (oppositeAmount > 0) {
          if (amount > oppositeAmount) {
            removeStatusEffect(oppositeId, amount: oppositeAmount);
          } else {
            removeStatusEffect(oppositeId, amount: amount);
          }
          amount -= oppositeAmount;
        }
      }

      if (amount > 0) {
        effect = StatusEffect(
          id: id,
          amount: amount,
          anchor: isHero ? Anchor.topLeft : Anchor.topRight,
        );
        _statusEffects[id] = effect;
        if (!effect.isHidden) {
          gameRef.world.add(effect);
        }
        if (effect.isPermenant) {
          reArrangePermenantEffects();
        } else {
          if (effect.isResource) {
            reArrangeResourceEffects();
          } else {
            reArrangeNonresourceEffects();
          }
        }
      }
    }
  }

  void _invokeScript(
      StatusEffect effect, String callbackId, dynamic details) async {
    if (effect.script != null) {
      final funcId = 'status_script_${effect.script}_$callbackId';
      engine.debug('invoke effect callback: [$funcId]');
      engine.hetu.invoke(funcId,
          positionalArgs: [this, opponent, effect.data, details]);
    }
  }

  /// details既是入参也是出参，脚本可能会获取或修改details中的内容
  void handleStatusEffectCallback(String callbackId, [dynamic details]) async {
    // 永久效果的执行优先级更高
    for (final effect in permenantEffects) {
      if (effect.callbacks.contains(callbackId)) {
        _invokeScript(effect, callbackId, details);
      }
    }

    for (final effect in nonPermenantEffects) {
      if (effect.callbacks.contains(callbackId)) {
        _invokeScript(effect, callbackId, details);
      }
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
    clearAllTurnFlags();
    // TODO: resetGameFlags
  }

  /// 尝试消耗指定的生命，如果消耗值大于生命，返回 false
  bool consumeLife(int value) {
    assert(value > 0);
    if (life < value) return false;
    changeLife(life - value);
    return true;
  }

  /// 增加或减少指定的生命
  Future<void> changeLife(int value, {bool playSound = false}) async {
    if (value == 0) return;

    int hp = life;
    hp += value;
    if (hp > lifeMax) {
      hp = lifeMax;
    } else if (hp < 0) {
      hp = 0;
    }
    if (hp == life) return;

    if (hp > life) {
      // 触发自己恢复生命时的效果，可能会改变伤害值
      handleStatusEffectCallback('self_heal');
      // 触发对方恢复生命时的效果，可能会改变伤害值
      opponent!.handleStatusEffectCallback('opponent_heal');

      addHintText(
        '${engine.locale('life')} +${hp - life}',
        color: Colors.lightGreen,
      );
    } else {
      // 触发自己失去生命时的效果，可能会改变伤害值
      handleStatusEffectCallback('self_lose_life');
      // 触发对方失去生命时的效果，可能会改变伤害值
      opponent!.handleStatusEffectCallback('opponent_lose_life');

      addHintText(
        '${engine.locale('life')} -${life - hp}',
        color: Colors.pink,
      );
    }

    setLife(hp);
  }

  Future<void> setState(
    String state, {
    String? sound,
    String? overlay,
    String? recovery,
    String? complete,
  }) =>
      setAnimationState(
        state,
        sound: sound,
        overlayState: overlay,
        recoveryState: recovery,
        completeState: complete ?? kStandState,
      );

  /// 人物受到伤害，返回实际伤害值（有可能是0）
  /// 出发伤害时和伤害后的状态效果，并最终结算伤害数值
  /// details 是脚本发过来的数据对象，内容如下：
  /// {
  ///   kind: affix.kind,
  ///   attackType: affix.attackType,
  ///   damageType: affix.damageType,
  ///   baseValue: damage, // 伤害基础值
  ///   baseChange: 0, // 伤害基础值修正
  ///   percentageChange1: 0.0, // 伤害百分比修正，乘区1
  ///   percentageChange2: 0.0, // 伤害百分比修正，乘区2
  ///   percentageChange3: 0.0, // 伤害百分比修正，乘区3
  /// }
  /// 状态效果修改伤害时，并非直接在基础值上修改，
  /// 而是对 baseValueChange 和 percentageChange 进行修改
  /// 最终伤害计算方法
  /// (baseValue + baseValueChange) * (1 + percentageChange1) * (1 + percentageChange2) * (1 + percentageChange3)
  /// 乘区1：攻击增强，攻击削弱，抗性，弱点
  /// 乘区2：从闪避中获得的免疫，从迟钝中获得的踉跄
  Future<int> takeDamage(dynamic details, {bool recovery = true}) async {
    assert(details['baseValue'] > 0);

    // isMain 为 true 表示伤害来源来自主词条的攻击
    // 否则的话意味着是某些状态效果或者额外词条造成的伤害
    if (details['isMain'] == true) {
      // 触发对方造成伤害时的效果，可能会改变伤害值
      handleStatusEffectCallback('opponent_doing_damage', details);
      // 触发自己造成伤害时的效果，可能会改变伤害值
      opponent!.handleStatusEffectCallback('self_doing_damage', details);
    }

    // 触发自己受到伤害时的效果
    handleStatusEffectCallback('self_taking_damage', details);
    // 触发对方受到伤害时的效果
    opponent!.handleStatusEffectCallback('oponent_taking_damage', details);

    final int baseDamage = details['baseValue'] + (details['baseChange'] ?? 0);
    int finalDamage = (baseDamage *
            (1 + (details['percentageChange1'] ?? 0)) *
            (1 + (details['percentageChange2'] ?? 0)) *
            (1 + (details['percentageChange3'] ?? 0)))
        .round();
    if (finalDamage < 0) {
      engine.error('calculated damage < 0 on details: \n$details');
      finalDamage = 0;
    }
    String damageString = finalDamage > 0 ? '-$finalDamage' : '$finalDamage';
    Color color = switch (details['damageType']) {
      'chi' => Colors.purple,
      'elemental' => Colors.yellow,
      'spiritual' => Colors.green,
      'pure' => Colors.red,
      _ => Colors.white,
    };
    addHintText(damageString, color: color);

    if (details['blocked'] ?? false) {
      engine.play('shield-block-shortsword-143940.mp3',
          volume: GameConfig.soundEffectVolume);
    } else {
      engine.play('hit-flesh-02-266309.mp3',
          volume: GameConfig.soundEffectVolume);
    }

    if (finalDamage > 0) {
      int hp = life;
      hp -= finalDamage;
      if (hp < 0) {
        hp = 0;
      }
      setLife(hp);

      details['finalDamage'] = finalDamage;

      // isMain 为 true 表示伤害来源来自主词条的攻击
      // 否则的话意味着是某些状态效果或者额外词条造成的伤害
      if (details['isMain'] == true) {
        // 触发对方造成伤害后的效果
        handleStatusEffectCallback('opponent_done_damage', details);
        // 触发自己造成伤害后的效果
        opponent!.handleStatusEffectCallback('self_done_damage', details);

        opponent!.turnDetails['turnDamage'] += finalDamage;
      }

      // 触发自己受到伤害后的效果
      handleStatusEffectCallback('self_taken_damage', details);
      // 触发对方受到伤害后的效果
      opponent!.handleStatusEffectCallback('opponent_taken_damage', details);
    }

    bool blocked = details['blocked'] ?? false;

    if (blocked || finalDamage == 0) {
      // 这里不能用await，动画会卡住
      setState(kDodgeState);
    } else {
      setState(kHitState, recovery: recovery ? kHitRecoveryState : null);
    }

    return finalDamage;
  }

  /// 返回值是一个map，若map中 skipTurn 的key对应值为true表示跳过此回合
  Future<Map<String, dynamic>> onTurnStart(CustomGameCard card,
      {bool isExtra = false}) async {
    turnDetails.clear();
    // turn flag 是词条 callback 调用使用的出入参
    turnDetails["isExtra"] = isExtra;
    // 重置主词条本回合累计伤害计数
    turnDetails['turnDamage'] = 0;

    opponent!.handleStatusEffectCallback('opponent_turn_start', turnDetails);
    handleStatusEffectCallback('self_turn_start', turnDetails);

    if (turnDetails['skipTurn'] ?? false) {
      addHintText(engine.locale('skipTurn'));
      await Future.delayed(Duration(milliseconds: 500));
      return turnDetails;
    }

    // 展示当前卡牌及其详情
    if (card.data['isIdentified'] != true) {
      card.data['isIdentified'] = true;
      final (description, _) = GameData.getDescriptionFromCardData(card.data);
      card.description = description;
    }

    card.enablePreview = false;
    await card.setFocused(true);
    final (_, description) = GameData.getDescriptionFromCardData(card.data);
    Hovertip.show(
      scene: game,
      target: card,
      direction: HovertipDirection.topCenter,
      // direction: isHero ? HovertipDirection.rightTop : HovertipDirection.leftTop,
      content: description,
      config: ScreenTextConfig(anchor: Anchor.topCenter),
    );

    final List affixes = card.data['affixes'];
    assert(affixes.isNotEmpty);
    final mainAffix = affixes[0];

    final genre = mainAffix['genre'];
    handleStatusEffectCallback('self_use_card_genre_$genre');
    // final tags = mainAffix['tags'];
    // assert(tags is List);
    // for (final tag in tags) {
    //   handleEffectCallback('self_use_card_tag_$tag');
    // }

    switch (mainAffix['category']) {
      case 'attack':
        turnDetails['attackType'] = mainAffix['attackType'];
        turnDetails['damageType'] = mainAffix['damageType'];
        // 触发自己发动攻击时的效果
        handleStatusEffectCallback('self_attacking', turnDetails);
        // 触发对方被发动攻击时的效果
        opponent!.handleStatusEffectCallback('opponent_attacking', turnDetails);
      case 'buff':
        // 触发自己发动加持时的效果
        handleStatusEffectCallback('self_buffing', turnDetails);
        // 触发对方发动加持时的效果
        opponent!.handleStatusEffectCallback('opponent_buffing', turnDetails);
      case 'ongoing':
        // 触发自己发动持续牌时的效果
        handleStatusEffectCallback('self_ongoing', turnDetails);
        // 触发对方发动持续牌时的效果
        opponent!.handleStatusEffectCallback('opponent_ongoing', turnDetails);
    }

    // 先处理优先级高于主词条的额外词条
    // 其中可能包含一些当前回合就立即起作用的buff
    final beforeMain = affixes.where((affix) {
      return affix['isMain'] != true && affix['isBeforeMain'] == true;
    }).toList();
    // 多个词条时，按照优先级排序
    beforeMain.sort((a, b) {
      return ((b['priority'] ?? 0) as int).compareTo(a['priority'] ?? 0);
    });
    for (final affix in beforeMain) {
      final scriptId = affix['script'];
      assert(scriptId != null);
      await engine.hetu.invoke(
        'card_script_$scriptId',
        positionalArgs: [this, opponent, affix, mainAffix],
      );
    }

    // 处理主词条
    final mainScriptId = mainAffix['script'];
    assert(mainScriptId != null);
    await engine.hetu.invoke(
      'card_script_main_$mainScriptId',
      positionalArgs: [this, opponent, mainAffix],
    );

    // 最后处理其他词条
    // 其中可能包含一些需求资源或有关主词条造成的伤害等情况的词条
    // 这样可能会当回合就触发一些联动
    final afterMain = affixes.where((affix) {
      return affix['isMain'] != true && affix['isBeforeMain'] != true;
    }).toList();
    // 多个词条时，按照优先级排序
    afterMain.sort((a, b) {
      return ((b['priority'] ?? 0) as int).compareTo(a['priority'] ?? 0);
    });
    for (final affix in afterMain) {
      final scriptId = affix['script'];
      assert(scriptId != null);
      await engine.hetu.invoke(
        'card_script_$scriptId',
        positionalArgs: [this, opponent, affix, mainAffix],
      );
    }

    if (mainAffix['category'] == 'attack') {
      // 触发自己发动攻击后的效果
      handleStatusEffectCallback('self_attacked', turnDetails);
      // 触发对方被发动攻击后的效果
      opponent!.handleStatusEffectCallback('opponent_attacked', turnDetails);
    }

    if (mainAffix['isEphemeral'] == true) {
      // 触发自己使用消耗牌后的效果
      handleStatusEffectCallback('self_consumed', turnDetails);
      // 触发对方使用消耗牌后的效果
      opponent!.handleStatusEffectCallback('opponent_consumed', turnDetails);
    }

    return turnDetails;
  }

  /// 返回值true表示获得一个额外回合
  Future<Map<String, dynamic>> onTurnEnd(CustomGameCard card) async {
    handleStatusEffectCallback('self_turn_end', turnDetails);
    opponent!.handleStatusEffectCallback('opponent_turn_end', turnDetails);

    await card.setFocused(false);
    Hovertip.hide(card);
    card.enablePreview = true;

    if (turnDetails['staggeringTurn'] == true) {
      addHintText(engine.locale('staggeringTurn'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    if (turnDetails['invincibleTurn'] == true) {
      addHintText(engine.locale('invincibleTurn'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    if (turnDetails['extraTurn'] == true) {
      addHintText(engine.locale('extraTurn'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    return turnDetails;
  }
}
