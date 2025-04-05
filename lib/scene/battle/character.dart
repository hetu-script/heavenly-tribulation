import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/progress_indicator.dart';
import 'package:samsara/components/hovertip.dart';
import 'package:samsara/animation/animation_state_controller.dart';
import 'package:samsara/cardgame/custom_card.dart';
// import 'package:samsara/components/task_component.dart';

import '../../engine.dart';
import '../../game/data.dart';
import 'battledeck_zone.dart';
import '../../game/ui.dart';
import 'status_effect.dart';
import 'common.dart';
import 'battle.dart';

const kDamagePercentageMin = -0.75;

const kResourceMax = {
  'energy_positive_spell': 'manaMax',
  'energy_positive_weapon': 'chakraMax',
};

const kNegativeResourceNames = {
  'life',
  'leech',
  'pure',
  'unarmed',
  'weapon',
  'spell',
  'curse',
};

Color getDamageColor(String damageType) {
  return switch (damageType) {
    'chi' => Colors.purple,
    'elemental' => Colors.yellow,
    'psychic' => Colors.green,
    'pure' => Colors.red,
    _ => Colors.cyan,
  };
}

Color getResourceColor(String resourceType) {
  return switch (resourceType) {
    'energy_positive_life' || 'energy_negative_life' => Colors.lightGreen,
    'energy_positive_leech' || 'energy_negative_leech' => Colors.grey,
    'energy_positive_pure' || 'energy_negative_pure' => Colors.blueGrey,
    'energy_positive_poison' || 'energy_negative_poison' => Colors.yellow,
    'energy_positive_spell' || 'energy_negative_spell' => Colors.purple,
    'energy_positive_weapon' || 'energy_negative_weapon' => Colors.lightBlue,
    'energy_positive_unarmed' || 'energy_negative_unarmed' => Colors.red,
    'energy_positive_curse' || 'energy_negative_curse' => Colors.white,
    'energy_positive_ultimate' || 'energy_negative_ultimate' => Colors.pink,
    _ => Colors.cyan,
  };
}

class BattleCharacter extends GameComponent with AnimationStateController {
  final String skinId;

  final bool isHero;

  final dynamic data;

  final Set<String> animationStates;
  final Set<String> overlayAnimationStates;

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

  /// 降低角色生命上限，最低为 1
  void setLifeMax(int value) {
    if (value < 0) value = 1;
    final int characterLifeMax = data['stats']['lifeMax'];
    int diff = (value - characterLifeMax).abs();
    if (value > characterLifeMax) {
      addHintText('${engine.locale('lifeMax')} +$diff',
          color: Colors.lightGreen);
      _hpBar.labelColor = Colors.yellow;
      _life += diff;
    } else if (value < characterLifeMax) {
      addHintText('${engine.locale('lifeMax')} -$diff', color: Colors.pink);
      _hpBar.labelColor = Colors.grey;
    }
    _lifeMax = _hpBar.max = value;
    if (_life < _lifeMax) {
      _life = _lifeMax;
    }
    _hpBar.setValue(_life);
    _hpBar.max = _lifeMax;
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

  final Map<String, dynamic> turnFlags = {};

  BattleCharacter({
    super.position,
    super.size,
    this.isHero = false,
    required this.skinId,
    required this.animationStates,
    required this.overlayAnimationStates,
    required this.data,
    required this.deckZone,
  }) : super(anchor: Anchor.topCenter) {
    assert(GameData.animationsData.containsKey(skinId));
    audioPlayer = engine;

    if (!isHero) {
      flipHorizontally();
    }

    currentAnimationState = kStandState;
    animationStates.addAll(kPreloadAnimationStates);
  }

  @override
  Future<void> onLoad() async {
    // 普通动画在每个皮肤下都有一套单独的数据
    for (final state in animationStates) {
      final anim = await GameData.createAnimationFromData(skinId, state);
      addState(state, anim, isOverlay: false);
    }
    // 叠加动画的数据另外保存
    for (final state in overlayAnimationStates) {
      final anim = await GameData.createAnimationFromData('overlay', state);
      addState(state, anim, isOverlay: true);
    }

    // await loadStates();

    _life = data['life'];
    _lifeMax = data['stats']['lifeMax'];

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
    final centerPoint = Vector2(GameUI.size.x / 2,
        GameUI.hugeIndent + GameUI.battleCharacterAvatarSize.y);
    for (var i = 0; i < permenantEffects.length; ++i) {
      final effect = permenantEffects.elementAt(i);
      if (isHero) {
        effect.position = Vector2(
          centerPoint.x -
              GameUI.versusIconSize.x / 2 -
              GameUI.hugeIndent -
              i * (GameUI.permenantStatusEffectIconSize.x + GameUI.smallIndent),
          centerPoint.y,
        );
      } else {
        effect.position = Vector2(
          centerPoint.x +
              GameUI.versusIconSize.x / 2 +
              GameUI.hugeIndent +
              i * (GameUI.permenantStatusEffectIconSize.x + GameUI.smallIndent),
          centerPoint.y,
        );
      }
    }
  }

  /// 非永久效果位置在血条上方
  void reArrangeNonResourceEffects() {
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

  /// 返回的是移除的实际数量
  /// 如果 exhaust 为 true ，并且该状态有对应的 energy_negative
  /// 则会在没有足够资源时获得反面的资源
  int removeStatusEffect(
    String id, {
    int? amount,
    double? percentage,
    String? exhaust,
  }) {
    int removeAmount = 0;
    StatusEffect? existEffect;
    bool resourceIconNeedsRearranging = false;
    if (_statusEffects.containsKey(id)) {
      existEffect = _statusEffects[id]!;
      assert(!existEffect.isPermenant);
      assert(existEffect.amount > 0);

      if (amount != null) {
        assert(amount > 0);
        removeAmount = math.min(existEffect.amount, amount);
      } else if (percentage != null) {
        assert(percentage > 0 && percentage < 1);
        removeAmount = (existEffect.amount * percentage).round();
      } else {
        removeAmount = existEffect.amount;
      }
      assert(removeAmount > 0);

      existEffect.amount -= removeAmount;

      if (existEffect.amount <= 0) {
        _statusEffects.remove(existEffect.id);
        existEffect.removeFromParent();
      }

      if (existEffect.isPermenant) {
        reArrangePermenantEffects();
      } else {
        if (existEffect.isResource) {
          resourceIconNeedsRearranging = true;
        } else {
          reArrangeNonResourceEffects();
        }
      }
    }

    if (amount != null && removeAmount < amount && exhaust != null) {
      // 目前只有攻击类卡牌，并且是在消耗阳气时，才会触发枯竭
      assert(id.startsWith('energy_positive'));
      assert(kNegativeResourceNames.contains(exhaust));
      // 触发资源枯竭时的情况
      final hint = engine.locale('resourceLacking',
          interpolations: [engine.locale('status_$id')]);
      addHintText(hint, color: Colors.grey);

      final rest = amount - removeAmount;
      final oppositeId = 'energy_negative_$exhaust';
      // 理论上这里只会获得负面资源（阴气），所以不用处理回调函数
      addStatusEffect(oppositeId, amount: rest, handleCallback: false);

      resourceIconNeedsRearranging = true;
    }

    if (resourceIconNeedsRearranging) {
      reArrangeResourceEffects();
    }

    return removeAmount;
  }

  void addStatusEffect(String id, {int? amount, bool handleCallback = true}) {
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
    final effectData = GameData.statusEffects[id];
    final buffDetails = {};

    if (effectData['isNegative'] == true) {
      // 触发自己获得负面效果时的效果
      handleStatusEffectCallback('self_gaining_debuff', buffDetails);
      // 触发对方获得负面效果时的效果
      opponent!
          .handleStatusEffectCallback('opponent_gaining_debuff', buffDetails);

      if (buffDetails['cancelDebuff'] == true) {
        addHintText(engine.locale('immuneDebuff'));
        return;
      }
    }

    int checkOverflow(int target) {
      final max = kResourceMax[id];
      if (max != null) {
        final int maxValue = data['stats'][max];
        if (target > maxValue) {
          buffDetails['overflow'] = target - maxValue;
          // 触发对方资源溢出时的效果
          opponent!.handleStatusEffectCallback(
              'opponent_overflowed_energy', buffDetails);
          // 触发资源溢出时的效果
          final result =
              handleStatusEffectCallback('self_overflowed_energy', buffDetails);
          if (result == null || result == false) {
            target = maxValue;
            addHintText(
              engine.locale('resourceOverflowed',
                  interpolations: [engine.locale('status_$id')]),
              color: Colors.blue,
            );
          } else {
            target -= maxValue;
          }
        }
      }

      return target;
    }

    int finalAmount = amount;
    StatusEffect effect;
    if (_statusEffects.containsKey(id)) {
      effect = _statusEffects[id]!;
      if (effect.isUnique) return;

      final originalAmount = effect.amount;
      effect.amount = checkOverflow(originalAmount + amount);
      finalAmount = effect.amount - originalAmount;
    } else {
      if (kOppositeStatus.containsKey(id)) {
        final oppositeId = kOppositeStatus[id]!;
        final oppositeAmount = hasStatusEffect(oppositeId);
        if (oppositeAmount > 0) {
          final toBeRemoved = math.min(amount, oppositeAmount);
          removeStatusEffect(oppositeId, amount: toBeRemoved);
          amount -= toBeRemoved;
        }
      }
      if (amount <= 0) return;

      effect = StatusEffect(
        id: id,
        amount: amount,
        anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      );

      finalAmount = checkOverflow(amount);
      if (finalAmount <= 0) return;

      effect.amount = finalAmount;
      _statusEffects[id] = effect;

      if (!effect.isHidden) {
        gameRef.world.add(effect);

        if (effect.isResource) {
          addHintText(
            '${engine.locale('status_$id')} +$finalAmount',
            color: getResourceColor(id),
          );
          reArrangeResourceEffects();
        } else if (effect.isPermenant) {
          reArrangePermenantEffects();
        } else {
          reArrangeNonResourceEffects();
        }
      }
    }

    if (finalAmount > 0) {
      if (effectData['isPermenant'] != true && handleCallback) {
        if (id.startsWith('energy_positive')) {
          // 触发自己获得阳气后的效果
          handleStatusEffectCallback('self_gained_energy_positive');
          // 触发对方获得阳气后的效果
          opponent!
              .handleStatusEffectCallback('opponent_gained_energy_positive');
        }
      }
    }
  }

  dynamic _invokeScript(StatusEffect effect, String callbackId,
      [dynamic details]) {
    assert(effect.script != null);
    details ??= {};

    final funcId = 'status_script_${effect.script}_$callbackId';
    engine.debug('invoke effect callback: [$funcId]');
    dynamic result = engine.hetu
        .invoke(funcId, positionalArgs: [this, opponent, effect.data, details]);
    return result;
  }

  /// details既是入参也是出参，脚本可能会获取或修改details中的内容
  dynamic handleStatusEffectCallback(String callbackId, [dynamic details]) {
    dynamic result;

    // 永久效果的执行优先级更高
    for (final effect in permenantEffects) {
      if (effect.callbacks.contains(callbackId)) {
        final r = _invokeScript(effect, callbackId, details);
        if (r != null) {
          result = r;
        }
      }
    }

    for (final effect in nonPermenantEffects) {
      if (effect.callbacks.contains(callbackId)) {
        final r = _invokeScript(effect, callbackId, details);
        if (r != null) {
          result = r;
        }
      }
    }

    return result;
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
    _life = _lifeMax = data['stats']['lifeMax'];
    _hpBar.max = _lifeMax;
    _hpBar.setValue(_lifeMax);
    _hpBar.labelColor = Colors.yellow;
    // setMana(0, animated: false);
    setState(kStandState);
    clearAllStatusEffects();
    turnFlags.clear();
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
  void changeLife(int value, {bool playSound = false, bool isHeal = false}) {
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
      if (isHeal) {
        // 触发自己恢复生命时的效果
        handleStatusEffectCallback('self_heal');
        // 触发对方恢复生命时的效果
        opponent!.handleStatusEffectCallback('opponent_heal');
      }

      addHintText(
        '${engine.locale('life')} +${hp - life}',
        color: Colors.lightGreen,
      );
    } else {
      // // 触发自己失去生命时的效果，可能会改变伤害值
      // handleStatusEffectCallback('self_lose_life');
      // // 触发对方失去生命时的效果，可能会改变伤害值
      // opponent!.handleStatusEffectCallback('opponent_lose_life');

      addHintText(
        '${engine.locale('life')} -${life - hp}',
        color: Colors.pink,
      );
    }

    setLife(hp);
  }

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
  ///   penetration: 0.0, // 伤害穿透百分比
  /// }
  /// 状态效果修改伤害时，并非直接在基础值上修改，
  /// 而是对 baseChange 和 percentageChange 进行修改
  /// 最终伤害计算方法
  /// (baseValue + baseValueChange) * (1 + percentageChange1) * (1 + percentageChange2) * (1 + percentageChange3)
  /// 乘区1：攻击增强，攻击削弱，抗性，弱点，伤害增加，乘区1最小值为-0.75，也就是说最小伤害是0.25
  /// 乘区2：从闪避中获得的免疫，从迟钝中获得的踉跄
  /// 乘区3：正气的伤害增加，戾气的伤害减少
  int takeDamage(dynamic damageDetails, {bool recovery = true}) {
    damageDetails['baseChange'] ??= 0;
    damageDetails['percentageChange1'] ??= 0.0;
    damageDetails['percentageChange2'] ??= 0.0;
    damageDetails['percentageChange3'] ??= 0.0;
    damageDetails['penetration'] ??= 0;

    assert(opponent != null && opponent!.turnFlags['damage'] != null);

    damageDetails['baseChange'] +=
        opponent!.turnFlags['damage']['baseChange'] ?? 0;
    damageDetails['percentageChange1'] +=
        opponent!.turnFlags['damage']['percentageChange1'] ?? 0.0;
    damageDetails['percentageChange2'] +=
        opponent!.turnFlags['damage']['percentageChange2'] ?? 0.0;
    damageDetails['percentageChange3'] +=
        opponent!.turnFlags['damage']['percentageChange3'] ?? 0.0;
    damageDetails['penetration'] +=
        opponent!.turnFlags['damage']['penetration'] ?? 0;

    assert(damageDetails['baseValue'] > 0);

    // isMain 为 true 表示伤害来源来自主词条的攻击
    // 否则的话意味着是某些状态效果或者额外词条造成的伤害
    // if (damageDetails['isMain'] == true) {
    // 触发对方造成伤害时的效果，可能会改变伤害值
    handleStatusEffectCallback('opponent_doing_damage', damageDetails);
    // 触发自己造成伤害时的效果，可能会改变伤害值
    opponent!.handleStatusEffectCallback('self_doing_damage', damageDetails);
    // }

    // 触发自己受到伤害时的效果
    handleStatusEffectCallback('self_taking_damage', damageDetails);
    // 触发对方受到伤害时的效果
    opponent!
        .handleStatusEffectCallback('oponent_taking_damage', damageDetails);

    if (damageDetails['cancelDamage'] == true) {
      addHintText(engine.locale('missedHit'));
      return 0;
    }

    int baseDamage = damageDetails['baseValue'];
    final int baseChange = damageDetails['baseChange'] ?? 0;

    baseDamage += baseChange;

    double percentage1 = damageDetails['percentageChange1'];
    if (percentage1 < kDamagePercentageMin) percentage1 = kDamagePercentageMin;
    double percentage2 = damageDetails['percentageChange2'];
    double percentage3 = damageDetails['percentageChange3'];

    int finalDamage =
        (baseDamage * (1 + percentage1) * (1 + percentage2) * (1 + percentage3))
            .round();
    if (finalDamage < 0) {
      engine.error(
          'unexpected: calculated damage < 0 on damage details: \n$damageDetails');
      finalDamage = 0;
    }
    String damageString = finalDamage > 0 ? '-$finalDamage' : '$finalDamage';

    addHintText(damageString,
        color: getDamageColor(damageDetails['damageType']));

    if (damageDetails['blocked'] ?? false) {
      engine.play('shield-block-shortsword-143940.mp3',
          volume: engine.config.soundEffectVolume);
    } else {
      engine.play('hit-flesh-02-266309.mp3',
          volume: engine.config.soundEffectVolume);
    }

    if (finalDamage > 0) {
      int hp = life;
      hp -= finalDamage;
      if (hp < 0) {
        hp = 0;
      }
      setLife(hp);

      damageDetails['finalDamage'] = finalDamage;

      // isMain 为 true 表示伤害来源来自主词条的攻击
      // 否则的话意味着是某些状态效果或者额外词条造成的伤害
      // if (damageDetails['isNeutral'] != true) {
      // 触发对方造成伤害后的效果
      handleStatusEffectCallback('opponent_done_damage', damageDetails);
      // 触发自己造成伤害后的效果
      opponent!.handleStatusEffectCallback('self_done_damage', damageDetails);

      // 触发自己受到伤害后的效果
      handleStatusEffectCallback('self_taken_damage', damageDetails);
      // 触发对方受到伤害后的效果
      opponent!
          .handleStatusEffectCallback('opponent_taken_damage', damageDetails);
      // }

      opponent!.turnFlags['damage']['total'] += finalDamage;
    }

    bool blocked = damageDetails['blocked'] ?? false;

    if (blocked || finalDamage == 0) {
      // 这里不能用await，动画会卡住
      setCompositeState(startup: kDodgeState, complete: kStandState);
    } else {
      setCompositeState(startup: kHitState, complete: kStandState);
    }

    return finalDamage;
  }

  /// 返回值是一个map，若map中 skipTurn 的key对应值为true表示跳过此回合
  Future<Map<String, dynamic>> onTurnStart(CustomGameCard card,
      {bool isExtra = false}) async {
    // 重置 turnflag
    // turnFlags 是词条 callback 调用使用的出入参
    turnFlags.clear();
    // 重置主词条本回合累计伤害计数
    turnFlags['damage'] = {
      'total': 0,
    };
    // isExtra 表示这是某些机制触发的再次行动回合
    turnFlags["isExtra"] = isExtra;

    opponent!.handleStatusEffectCallback('opponent_turn_start');
    handleStatusEffectCallback('self_turn_start');

    if (turnFlags['skipTurn'] ?? false) {
      addHintText(engine.locale('skipTurn'));
      await Future.delayed(Duration(milliseconds: 500));
      return turnFlags;
    }

    if (turnFlags['defensePersisted'] ?? false) {
      addHintText(engine.locale('defensePersisted'));
    }

    // 展示当前卡牌及其详情
    if (card.data['isIdentified'] != true) {
      card.data['isIdentified'] = true;
      final (description, _) = GameData.getDescriptionFromCardData(card.data);
      card.description = description;
    }

    card.enablePreview = false;
    await card.setFocused(true);
    final isDetailed = (game as BattleScene).isDetailedHovertip;
    final (_, description) = GameData.getDescriptionFromCardData(
      card.data,
      isDetailed: isDetailed,
      showDetailedHint: false,
    );
    Hovertip.show(
      scene: game,
      target: card,
      direction: HovertipDirection.topCenter,
      // direction: isHero ? HovertipDirection.rightTop : HovertipDirection.leftTop,
      content: description,
      config: ScreenTextConfig(
        anchor: Anchor.topCenter,
        textAlign: TextAlign.center,
      ),
    );

    final List affixes = card.data['affixes'];
    assert(affixes.isNotEmpty);
    final mainAffix = affixes[0];

    final category = mainAffix['category'];
    final genre = mainAffix['genre'];
    final kind = mainAffix['kind'];
    turnFlags['category'] = category;
    turnFlags['genre'] = genre;
    turnFlags['kind'] = kind;

    handleStatusEffectCallback('self_use_card_category_$category');
    handleStatusEffectCallback('self_use_card_genre_$genre');
    handleStatusEffectCallback('self_use_card_kind_$kind');
    // final tags = mainAffix['tags'];
    // assert(tags is List);
    // for (final tag in tags) {
    //   handleEffectCallback('self_use_card_tag_$tag');
    // }

    switch (mainAffix['category']) {
      case 'attack':
        turnFlags['attackType'] = mainAffix['attackType'];
        turnFlags['damageType'] = mainAffix['damageType'];
        // 触发自己发动攻击时的效果
        handleStatusEffectCallback('self_attacking');
        // 触发对方被发动攻击时的效果
        opponent!.handleStatusEffectCallback('opponent_attacking');
      case 'buff':
        // 触发自己发动加持时的效果
        handleStatusEffectCallback('self_buffing');
        // 触发对方发动加持时的效果
        opponent!.handleStatusEffectCallback('opponent_buffing');
      case 'ongoing':
        // 触发自己发动持续牌时的效果
        handleStatusEffectCallback('self_ongoing');
        // 触发对方发动持续牌时的效果
        opponent!.handleStatusEffectCallback('opponent_ongoing');
    }

    // 先处理优先级高于主词条的额外词条
    // 其中可能包含一些当前回合就立即起作用的buff
    final beforeMain = affixes.where((affix) {
      return affix['isMain'] != true && (affix['priority'] ?? 0) < 0;
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
      return affix['isMain'] != true && (affix['priority'] ?? 0) >= 0;
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
      handleStatusEffectCallback('self_attacked');
      // 触发对方被发动攻击后的效果
      opponent!.handleStatusEffectCallback('opponent_attacked');
    }

    if (mainAffix['isEphemeral'] == true) {
      // 触发自己使用消耗牌后的效果
      handleStatusEffectCallback('self_consumed');
      // 触发对方使用消耗牌后的效果
      opponent!.handleStatusEffectCallback('opponent_consumed');
    }

    return turnFlags;
  }

  /// 返回值true表示获得一个额外回合
  Future<Map<String, dynamic>> onTurnEnd(CustomGameCard card) async {
    handleStatusEffectCallback('self_turn_end');
    opponent!.handleStatusEffectCallback('opponent_turn_end');

    await card.setFocused(false);
    Hovertip.hide(card);
    card.enablePreview = true;

    if (turnFlags['staggeringTurn'] == true) {
      addHintText(engine.locale('staggeringTurn'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    if (turnFlags['immuneDamage'] == true) {
      addHintText(engine.locale('immuneDamage'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    if (turnFlags['extraTurn'] == true) {
      addHintText(engine.locale('extraTurn'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    return turnFlags;
  }
}
