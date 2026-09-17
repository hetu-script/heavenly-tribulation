import 'dart:math' as math;

import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/progress_indicator.dart';
import 'package:samsara/animation/animation_state_controller.dart';
import 'package:samsara/cardgame/custom_card.dart';

import '../../global.dart';
import '../../data/game.dart';
import '../../data/common.dart';
import 'battledeck_zone.dart';
import '../../ui.dart';
// import '../../logic/logic.dart';
import 'status_effect.dart';
import 'common.dart';
import 'battle.dart';

const kMinCardDisplayDuration = 1000;
const kDamagePercentageMin = -0.75;

Color getDamageColor(String damageType) {
  return switch (damageType) {
    'chi' => Colors.purple,
    'fire' => Colors.deepOrange,
    'ice' => Colors.lightBlueAccent,
    'lightning' => Colors.amber,
    'poison' => Colors.purpleAccent,
    'psychic' => Colors.green,
    'pure' => Colors.red,
    _ => Colors.cyan,
  };
}

Color getResourceColor(String resourceType) {
  return switch (resourceType) {
    'energy_positive_life' || 'energy_negative_life' => Colors.lightGreen,
    'energy_positive_spell' || 'energy_negative_spell' => Colors.purple,
    'energy_positive_weapon' || 'energy_negative_weapon' => Colors.lightBlue,
    'energy_positive_unarmed' || 'energy_negative_unarmed' => Colors.red,
    'energy_positive_curse' || 'energy_negative_curse' => Colors.white,
    'energy_positive_ultimate' || 'energy_negative_ultimate' => Colors.pink,
    _ => Colors.cyan,
  };
}

class BattleCharacter extends GameComponent with AnimationStateController {
  static final random = math.Random();

  final String skinId;

  final bool isHero;

  BattleCharacter? opponent;

  final dynamic data;

  final _sw = Stopwatch();

  final Set<String> animationStates = {};
  final Set<String> overlayAnimationStates = {};

  late final DynamicColorProgressIndicator hpBar;
  late int _life;
  int get life => _life;

  /// 将生命设为指定值，如果animated为true，则会有动画效果
  void setLife(
    int value, {
    bool animated = true,
    bool overflow = false,
    int? max,
  }) {
    max ??= _lifeMax;
    if (!overflow) {
      _life = value.clamp(0, max);
    } else {
      if (value < 0) {
        _life = 0;
      } else {
        _life = value;
      }
    }
    hpBar.setValue(_life, animated: animated);
  }

  late int _lifeMax;
  int get lifeMax => _lifeMax;

  /// 设置角色生命上限，最低为 1
  void setLifeMax(int value, {bool rejuvenate = false}) {
    if (value < 1) value = 1;
    final int characterLifeMax = data['stats']['battleLifeMax'];
    int diff = (value - characterLifeMax).abs();
    _lifeMax = hpBar.max = value;
    if (value > characterLifeMax) {
      addHintText('${engine.locale('lifeMax')} +$diff',
          color: Colors.lightGreen);
      hpBar.labelColor = Colors.yellow;
      if (rejuvenate) {
        _life += diff;
      }
    } else if (value < characterLifeMax) {
      addHintText('${engine.locale('lifeMax')} -$diff', color: Colors.pink);
      hpBar.labelColor = Colors.grey;
      if (_life > _lifeMax) {
        _life = _lifeMax;
      }
    }
    hpBar.setValue(_life);
    hpBar.max = _lifeMax;
  }

  final Map<String, StatusEffect> _statusEffects = {};

  List<StatusEffect> get effects {
    final list = _statusEffects.values.toList();
    list.sort((e1, e2) => e2.effectPriority.compareTo(e1.effectPriority));
    return list;
  }

  List<StatusEffect> get otherEffects {
    final list = _statusEffects.values
        .where((element) => !element.isPermanent && !element.isResource)
        .toList();
    list.sort((e1, e2) => e2.effectPriority.compareTo(e1.effectPriority));
    return list;
  }

  List<StatusEffect> get resourceEffects {
    final list =
        _statusEffects.values.where((element) => element.isResource).toList();
    list.sort((e1, e2) => e2.effectPriority.compareTo(e1.effectPriority));
    return list;
  }

  List<StatusEffect> get nonPermanentEffects {
    final list =
        _statusEffects.values.where((element) => !element.isPermanent).toList();
    list.sort((e1, e2) => e2.effectPriority.compareTo(e1.effectPriority));
    return list;
  }

  List<StatusEffect> get permanentEffects {
    final list =
        _statusEffects.values.where((element) => element.isPermanent).toList();
    list.sort((e1, e2) => e2.effectPriority.compareTo(e1.effectPriority));
    return list;
  }

  final BattleDeckZone deckZone;

  /// 元气（无色费用）= energy_positive_life 状态层数（§4.1：energy 计数器已归一为状态）。
  /// 回合开始获得 rank + 3 层，支付无色费用移除对应层数，回合结束按剩余层数回血。
  int get energy => hasStatusEffect('energy_positive_life');

  /// 本回合打出的武器攻击牌数量（回合开始时结转为上回合数据后清零，§4.2 剑气产出依据）
  int weaponCardsPlayed = 0;
  int lastTurnWeaponCards = 0;

  /// 本回合自身受到的伤害（回合开始时结转为上回合数据后清零，§4.3 怒气产出依据）
  int damageTaken = 0;
  int lastTurnDamageTaken = 0;

  int turnCount = 0;

  final Map<String, dynamic> turnFlags = {};
  final Map<String, dynamic> cardFlags = {};

  BattleCharacter({
    super.position,
    super.size,
    required this.isHero,
    required this.skinId,
    Iterable<String> animationStates = const [],
    Iterable<String> overlayAnimationStates = const [],
    required this.data,
    required this.deckZone,
    bool isDummy = false,
  }) : super(anchor: Anchor.topCenter) {
    // 这一行是为了让 AnimationStateController 可以在恰当的时机播放音效
    audioPlayer = engine;

    if (!isHero) {
      flipHorizontally();
    }

    currentAnimationState = kStandState;

    this.animationStates.addAll(animationStates);
    this.overlayAnimationStates.addAll(overlayAnimationStates);

    this.animationStates.addAll(kPreloadAnimationStates);
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

    _life = data['life'].toInt();
    _lifeMax = data['stats']['battleLifeMax'].toInt();

    hpBar = DynamicColorProgressIndicator(
      anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      position: Vector2(0, -GameUI.resourceBarHeight),
      size: Vector2(width, GameUI.resourceBarHeight),
      value: _life,
      max: _lifeMax,
      colors: [Colors.red, Colors.green],
      showNumber: true,
      labelFontSize: 10.0,
      labelColor: Colors.white,
    );
    if (!isHero) {
      hpBar.flipHorizontally();
    }
    add(hpBar);
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

  /// 元素抗性唯一真值来源：resistant/weakness 状态净值（含全元素对），上限 75
  /// 战斗开始时 stats（含全抗折算）已转换为 resistant_X 永久图标，故不再读 stats
  /// 允许负抗性（定案）：弱点净值超过抗性时伤害加深，与 weakness 既有语义一致
  int getElementalResist(String damageType) {
    int resist = hasStatusEffect('resistant_$damageType');
    resist -= hasStatusEffect('weakness_$damageType');
    final resistMax = data['stats']['${damageType}ResistMax'].toInt();
    return resist > resistMax ? resistMax : resist;
  }

  /// 预测 [attacker] 的词条 [affix] 对自己造成的伤害。
  /// 只计算确定性部分（与 takeDamage 同顺序）：增强/削弱净值 → 元素抗性/弱点 →
  /// 暴击（豪气必暴或暴击计数器满阈值，扣除衰气减倍率）、异常（豪气必异常或异常计数器满阈值）；
  /// 不计算护甲、穿透与脚本回调类修正。
  /// 返回 (伤害, 是否暴击, 异常层数)；非攻击类词条返回 null。
  (int, bool, int)? predictDamage(BattleCharacter attacker, dynamic affix) {
    final List value = affix['value'];

    final String damageType = affix['damageType'];
    final bool isElemental = damageType == 'fire' ||
        damageType == 'ice' ||
        damageType == 'lightning' ||
        damageType == 'poison';

    int damage = (value[0] as num).toInt();

    // 乘区1：攻击增强/削弱净值，下限 kDamagePercentageMin（同 takeDamage）
    final String? cardType = affix['cardType'];
    if (cardType != null) {
      final int enhanceNet = attacker.hasStatusEffect('enhance_$cardType') -
          attacker.hasStatusEffect('weaken_$cardType');
      if (enhanceNet != 0) {
        num p1 = 0.01 * enhanceNet;
        if (p1 < kDamagePercentageMin) p1 = kDamagePercentageMin;
        damage = (damage * (1 + p1)).round();
      }
    }

    // 元素抗性/弱点（弱点为负抗性，已包含在净值中）
    if (damage > 0 && isElemental) {
      damage = (damage * (1 - 0.01 * getElementalResist(damageType))).round();
    }

    // 暴击（豪气必暴，或暴击计数器满阈值）：物理伤害按暴击倍率计算，衰气按层循环扣除（同 takeDamage）
    bool isCrit = false;
    if (damage > 0 && damageType == 'physical') {
      final attackerStats = attacker.data['stats'];
      final int critThreshold =
          (attackerStats['critThreshold'] ?? kBaseCritThreshold).toInt();
      if (attacker.turnFlags['guaranteedCrit'] == true ||
          attacker.hasStatusEffect('crit_charge') >= critThreshold) {
        int critMultiplier =
            (attackerStats['critMultiplier'] ?? kBaseCritMultiplier).toInt();
        final int consumed = math.min(attacker.hasStatusEffect('debuff_crit'),
            ((critMultiplier - 100) / 50).ceil());
        critMultiplier -= 50 * consumed;
        if (critMultiplier < 100) critMultiplier = 100;
        damage = (damage * critMultiplier / 100).round();
        isCrit = true;
      }
    }

    // 异常（幸运必异常，或异常计数器满阈值）：元素伤害固定每满 10 点 1 层，不幸逐层抵消（同 takeDamage）
    int ailmentStacks = 0;
    if (damage > 0 && isElemental) {
      final attackerStats = attacker.data['stats'];
      final int ailmentThreshold =
          (attackerStats['ailmentThreshold'] ?? kBaseAilmentThreshold).toInt();
      if (attacker.turnFlags['guaranteedAilment'] == true ||
          attacker.hasStatusEffect('ailment_charge') >= ailmentThreshold) {
        ailmentStacks = damage ~/ 10;
        ailmentStacks -=
            math.min(ailmentStacks, attacker.hasStatusEffect('debuff_crit'));
      }
    }

    return (damage, isCrit, ailmentStacks);
  }

  /// 非永久效果位置在血条上方
  void reArrangeOtherEffects() {
    for (var i = 0; i < otherEffects.length; ++i) {
      final effect = otherEffects.elementAt(i);
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

  /// 永久效果位置：能量瓶旁边，英雄向右排列，敌人向左排列
  void reArrangePermanentEffects() {
    final iconStep =
        GameUI.permanentStatusEffectIconSize.x + GameUI.smallIndent;
    for (var i = 0; i < permanentEffects.length; ++i) {
      final effect = permanentEffects.elementAt(i);
      if (isHero) {
        effect.position = Vector2(
          GameUI.p1EnergyDisplayPosition.x +
              GameUI.battleEnergyBottleSize.x / 2 +
              GameUI.smallIndent +
              i * iconStep,
          GameUI.p1EnergyDisplayPosition.y -
              GameUI.permanentStatusEffectIconSize.y / 2,
        );
      } else {
        effect.position = Vector2(
          GameUI.p2EnergyDisplayPosition.x -
              GameUI.battleEnergyBottleSize.x / 2 -
              GameUI.smallIndent -
              i * iconStep,
          GameUI.p2EnergyDisplayPosition.y -
              GameUI.permanentStatusEffectIconSize.y / 2,
        );
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
  /// 资源类状态为全有或全无：存量不足时一点也不移除，返回 0
  int removeStatusEffect(
    String id, {
    int? amount,
    double? percentage,
    bool force = false,
  }) {
    int removedAmount = 0;
    StatusEffect? existEffect;
    bool resourceIconNeedsRearranging = false;
    bool doRemove = true;
    if (_statusEffects.containsKey(id)) {
      existEffect = _statusEffects[id]!;
      assert(!existEffect.isPermanent);
      assert(existEffect.amount > 0);

      if (amount != null) {
        assert(amount > 0);
        if (existEffect.amount < amount) {
          if (!existEffect.isResource || force) {
            removedAmount = existEffect.amount;
          } else {
            doRemove = false;
          }
        } else {
          removedAmount = amount;
        }
      } else if (percentage != null) {
        if (percentage <= 0) {
          engine.warning(
              'percentage must be positive and less than 1. percentage: $percentage');
          return 0;
        } else if (percentage > 1) {
          engine.warning(
              'percentage must be positive and less than 1. percentage: $percentage');
          percentage = 1;
        }
        removedAmount = (existEffect.amount * percentage).ceil();
      } else if (force) {
        removedAmount = existEffect.amount;
      }

      if (doRemove) {
        existEffect.amount -= removedAmount;

        if (existEffect.amount <= 0) {
          _statusEffects.remove(existEffect.id);
          existEffect.removeFromParent();
        }

        if (existEffect.isPermanent) {
          reArrangePermanentEffects();
        } else {
          if (existEffect.isResource) {
            resourceIconNeedsRearranging = true;
          } else {
            reArrangeOtherEffects();
          }
        }
      }
    }

    if (!doRemove && existEffect?.isResource == true) {
      final hint = engine.locale('resourceLacking',
          interpolations: [engine.locale('status_$id')]);
      addHintText(hint, color: Colors.grey);
    }

    if (resourceIconNeedsRearranging) {
      reArrangeResourceEffects();
    }

    return removedAmount;
  }

  void addStatusEffect(String id, {int? amount, bool handleCallback = true}) {
    if (amount == null || amount <= 0) {
      engine.error('Status effect [$id] added with amount <= 0, set to 1');
      amount = 1;
    }
    assert(amount > 0);
    if (!GameData.statusEffects.containsKey(id)) {
      engine.error('Status effect [$id] not found!');
      return;
    }
    final effectData = GameData.statusEffects[id];
    // final buffDetails = {};

    bool isNewlyAdded = false;
    StatusEffect effect;
    if (_statusEffects.containsKey(id)) {
      effect = _statusEffects[id]!;
      if (effect.isUnique) return;

      effect.amount += amount;
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

      isNewlyAdded = true;
      effect = StatusEffect(
        id: id,
        amount: amount,
        anchor: isHero ? Anchor.topLeft : Anchor.topRight,
      );

      effect.amount = amount;
      _statusEffects[id] = effect;
    }

    // final maxId = kResourceMaxId[id];
    // if (maxId != null) {
    //   // 检查资源是否溢出
    //   final int maxValue = data['stats'][maxId];
    //   if (effect.amount > maxValue) {
    //     dynamic result;
    //     final overflowedAmount = effect.amount - maxValue;
    //     if (handleCallback) {
    //       buffDetails['overflow'] = overflowedAmount;
    //       // 触发对方资源溢出时的效果
    //       opponent!.handleStatusEffectCallback(
    //           'opponent_overflowed_energy', buffDetails);
    //       // 触发资源溢出时的效果，返回 true 表示保留溢出的值
    //       result =
    //           handleStatusEffectCallback('self_overflowed_energy', buffDetails);
    //     }

    //     if (!GameLogic.truthy(result)) {
    //       effect.amount = maxValue;
    //       addHintText(
    //         engine.locale('resourceOverflowed',
    //             interpolations: [engine.locale('status_$id')]),
    //         color: Colors.blue,
    //       );
    //     }
    //   }
    // }

    if (effect.amount <= 0) {
      _statusEffects.remove(effect.id);
      return;
    }

    if (isNewlyAdded && !effect.isHidden) {
      game.world.add(effect);

      if (effect.isResource) {
        reArrangeResourceEffects();
      } else if (effect.isPermanent) {
        reArrangePermanentEffects();
      } else {
        reArrangeOtherEffects();
      }
    }

    if (effect.isResource) {
      addHintText(
        '${engine.locale('status_$id')} +$amount',
        color: getResourceColor(id),
      );
    }

    if (handleCallback) {
      if (id.startsWith('energy_positive')) {
        // 触发回调时传入资源 id 与数量，脚本可据此区分具体的阳气种类
        final energyDetails = {'id': id, 'amount': amount};
        // 触发对方获得阳气后的效果
        opponent!.handleStatusEffectCallback(
            'opponent_gained_energy_positive', energyDetails);
        // 触发自己获得阳气后的效果
        handleStatusEffectCallback(
            'self_gained_energy_positive', energyDetails);
      } else if (effectData['isDebuff'] == true) {
        // 一次获得多层只触发一次；debuffDetails 在双方回调间共享，
        // 脚本（如辟邪 buff_ward）可写入 cancelAmount 按层抵消本次获得
        final debuffDetails = <String, dynamic>{'id': id, 'amount': amount};
        // 触发对方获得负面效果后的效果
        opponent!.handleStatusEffectCallback(
            'opponent_gained_debuff', debuffDetails);
        // 触发自己获得负面效果后的效果
        handleStatusEffectCallback('self_gained_debuff', debuffDetails);
        // 脚本写入的数值经 hetu 传递可能是 double，统一按 num 解析
        final cancelAmountRaw = debuffDetails['cancelAmount'];
        int cancelAmount = cancelAmountRaw is num ? cancelAmountRaw.toInt() : 0;
        // 兼容旧的全量取消标记
        if (debuffDetails['cancelDebuff'] == true) {
          cancelAmount = amount;
        }
        cancelAmount = math.min(cancelAmount, amount);
        final int remaining = amount - cancelAmount;
        if (cancelAmount > 0) {
          removeStatusEffect(id, amount: cancelAmount);
        }
        if (remaining > 0 &&
            data['passives']['gained_debuff_affect_opponent'] != null) {
          // 天赋：自己获得负面效果时，对手获得同样的负面效果
          // （被抵消的部分不会传播；handleCallback: false 防止双方都有此天赋时无限循环，
          // 同时被传播方无法再以辟邪等方式响应此次获得）
          opponent!
              .addStatusEffect(id, amount: remaining, handleCallback: false);
        }
      }
    }
  }

  /// 清空所有资源气（统一生命周期，决策 5：资源持有至持有者的下个回合开始）。
  /// 煞气（energy_positive_curse）未用量返回 karma 池（§4.5）；其余资源直接移除。
  /// 由 battle.dart 在回合开始时于回合开始回调之后、产出结算之前显式调用。
  void clearResourceEffects() {
    for (final effect in resourceEffects) {
      if (effect.id == 'energy_positive_curse' && effect.amount > 0) {
        data['karma'] += effect.amount;
        addHintText(
            engine
                .locale('karmaPoolReturnHint', interpolations: [effect.amount]),
            color: Colors.purple);
      }
      removeStatusEffect(effect.id, force: true);
    }
  }

  /// 回合开始资源产出（统一生命周期：在 clearResourceEffects 之后调用，顺序显式保证）。
  /// 元气 rank + 3（获得时与持有的死气自然对冲）；剑气/怒气按滞后一轮模型结算；
  /// 煞气从 karma 池提取；灵气节点加成缺省 0（§7 天赋树落地后补充）。
  void produceTurnStartResources() {
    final int rank = data['rank'];

    // 元气 = 无色费用池（§4.1）
    addStatusEffect('energy_positive_life', amount: rank + 3);

    // 灵气：enable_mana
    // 悟道节点回合产出加成缺省 1，天赋树落地后在此补充（§4.4）
    if (data['passives']['enable_mana'] != null) {
      addStatusEffect('energy_positive_spell', amount: 1);
    }

    // 剑气：上回合打出的武器牌数量（§4.2；节点加成缺省 0，预留读取位）
    if (data['passives']['enable_chakra'] != null && lastTurnWeaponCards > 0) {
      addStatusEffect('energy_positive_weapon', amount: lastTurnWeaponCards);
    }

    // 怒气：上回合自身受到的伤害 ÷ 10（§4.3；节点加成缺省 0，预留读取位）
    if (data['passives']['enable_rage'] != null && lastTurnDamageTaken > 0) {
      addStatusEffect('energy_positive_unarmed',
          amount: lastTurnDamageTaken ~/ 10);
    }

    // 煞气：从 karma 池提取 min(karmaMax, max(1, 池存量 ~/ 10))（§4.5；提取节点加成缺省 0，预留）
    if (data['passives']['enable_karma'] != null) {
      final int karma = data['karma'];
      if (karma > 0) {
        final int karmaMax = (data['stats']['karmaMax'] ?? 0) as int;
        final int extract = math.min(karmaMax, math.max(1, karma ~/ 10));
        if (extract > 0) {
          data['karma'] = karma - extract;
          addStatusEffect('energy_positive_curse', amount: extract);
        }
      }
    }
  }

  dynamic _invokeScript(StatusEffect effect, String callbackId,
      [dynamic details]) {
    assert(effect.script != null);
    details ??= {};

    final funcId = '${effect.script}_$callbackId';
    engine.info('invoke effect callback: [$funcId]');
    dynamic result = engine.hetu.invoke(
      funcId,
      namespace: 'StatusScript',
      positionalArgs: [this, opponent, effect.data, details],
    );
    return result;
  }

  /// details既是入参也是出参，脚本可能会获取或修改details中的内容
  dynamic handleStatusEffectCallback(String callbackId, [dynamic details]) {
    dynamic result;

    void handle(StatusEffect effect) {
      if (effect.callbacks.contains(callbackId)) {
        final r = _invokeScript(effect, callbackId, details);
        if (r != null) {
          result = r;
        }
      }
    }

    // 永久效果的执行优先级更高
    for (final effect in permanentEffects) {
      handle(effect);
    }

    for (final effect in resourceEffects) {
      handle(effect);
    }

    for (final effect in otherEffects) {
      handle(effect);
    }

    return result;
  }

  void addHintText(String text, {Color? color}) {
    game.addHintText(
      text,
      position: center,
      textStyle: TextStyle(
        fontFamily: GameUI.fontFamilyKaiti,
        color: color,
      ),
    );
  }

  void reset() {
    if (!isLoaded) return;
    turnFlags.clear();
    cardFlags.clear();
    turnCount = 0;
    weaponCardsPlayed = 0;
    lastTurnWeaponCards = 0;
    damageTaken = 0;
    lastTurnDamageTaken = 0;
    _life = data['life'].toInt();
    _lifeMax = data['stats']['battleLifeMax'].toInt();
    hpBar.max = _lifeMax;
    hpBar.setValue(_life);
    hpBar.labelColor = Colors.white;
    setState(kStandState);
    clearAllStatusEffects();
  }

  /// 尝试消耗指定的生命，如果消耗值大于生命，返回 false
  bool consumeLife(int value) {
    assert(value > 0);
    if (life < value) return false;
    changeLife(life - value);
    return true;
  }

  /// 增加或减少指定的生命
  /// damageType 用于跳字着色（DOT 等脚本侧伤害传入）
  void changeLife(int value,
      {bool playSound = false, bool isHeal = false, String? damageType}) {
    if (value == 0) return;

    final currentLifeMax = math.max(life, lifeMax);

    int hp = life;
    hp += value;
    if (hp > currentLifeMax) {
      hp = currentLifeMax;
    } else if (hp < 0) {
      hp = 0;
    }
    if (hp == life) return;

    if (hp > life) {
      if (isHeal) {
        // 触发对方恢复生命时的效果
        opponent!.handleStatusEffectCallback('opponent_heal');
        // 触发自己恢复生命时的效果
        handleStatusEffectCallback('self_heal');
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
        color: damageType != null ? getDamageColor(damageType) : Colors.pink,
      );
    }

    setLife(hp, max: currentLifeMax);
  }

  /// 人物受到伤害，返回实际伤害值（有可能是0）
  /// 出发伤害时和伤害后的状态效果，并最终结算伤害数值
  /// details 是脚本发过来的数据对象，内容如下:
  /// {
  ///   kind: affix.kind,
  ///   cardType: affix.cardType,
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
  /// 乘区1: 攻击增强，攻击削弱（图标净值，在下方结算），伤害增加，乘区1最小值为-0.75，也就是说最小伤害是0.25
  /// 乘区2: 从闪避中获得的免疫，从迟钝中获得的踉跄
  /// 乘区3: 正气的伤害增加，戾气的伤害减少
  /// 元素抗性在乘区结算之后按状态净值单独结算（元素无视护甲，不进护甲分支）
  int takeDamage(dynamic damageDetails, {bool recovery = true}) {
    assert(damageDetails['baseValue'] > 0);
    assert(opponent != null && opponent!.cardFlags['damage'] != null);

    damageDetails['baseChange'] ??= 0;
    damageDetails['percentageChange1'] ??= 0.0;
    damageDetails['percentageChange2'] ??= 0.0;
    damageDetails['percentageChange3'] ??= 0.0;
    damageDetails['penetration'] ??= 0.0;

    damageDetails['baseChange'] +=
        opponent!.cardFlags['damage']['baseChange'] ?? 0;
    damageDetails['percentageChange1'] +=
        opponent!.cardFlags['damage']['percentageChange1'] ?? 0.0;
    damageDetails['percentageChange2'] +=
        opponent!.cardFlags['damage']['percentageChange2'] ?? 0.0;
    damageDetails['percentageChange3'] +=
        opponent!.cardFlags['damage']['percentageChange3'] ?? 0.0;
    damageDetails['penetration'] +=
        opponent!.cardFlags['damage']['penetration'] ?? 0;

    // 护甲穿透属性（战斗开始由属性转换为永久状态，图标即真值）：每层 1%
    damageDetails['penetration'] += opponent!.hasStatusEffect('penetration') * 0.01;

    // isMain 为 true 表示伤害来源来自主词条的攻击
    // 否则的话意味着是某些状态效果或者额外词条造成的伤害

    // 触发自己造成伤害时的效果，可能会改变伤害值
    opponent!.handleStatusEffectCallback('self_doing_damage', damageDetails);
    // 触发对方造成伤害时的效果，可能会改变伤害值
    handleStatusEffectCallback('opponent_doing_damage', damageDetails);

    // 触发对方受到伤害时的效果
    opponent!
        .handleStatusEffectCallback('opponent_taking_damage', damageDetails);
    // 触发自己受到伤害时的效果
    handleStatusEffectCallback('self_taking_damage', damageDetails);

    if (damageDetails['cancelDamage'] == true) {
      opponent!.addHintText(engine.locale('missedHit'));
      return 0;
    }

    String damageType = damageDetails['damageType'];
    int baseDamage = damageDetails['baseValue'];
    final int baseChange = damageDetails['baseChange'] ?? 0;

    baseDamage += baseChange;

    num percentage1 = damageDetails['percentageChange1'];
    // 攻击增强/削弱（阶段4.5收敛：脚本退役，直接读取攻击方状态净值，图标即真值）
    // 恢复 weaken 的 cardType 匹配：weaken_weapon 只削弱武器攻击，与 enhance 对称
    final String? cardType = damageDetails['cardType'];
    if (cardType != null) {
      final int enhanceNet = opponent!.hasStatusEffect('enhance_$cardType') -
          opponent!.hasStatusEffect('weaken_$cardType');
      if (enhanceNet != 0) percentage1 += 0.01 * enhanceNet;
    }
    if (percentage1 < kDamagePercentageMin) percentage1 = kDamagePercentageMin;
    num percentage2 = damageDetails['percentageChange2'];
    num percentage3 = damageDetails['percentageChange3'];

    int finalDamage =
        (baseDamage * (1 + percentage1) * (1 + percentage2) * (1 + percentage3))
            .round();
    if (finalDamage < 0) {
      engine.error(
          'unexpected: calculated damage < 0 on damage details: \n${damageDetails.toString()}');
      finalDamage = 0;
    }

    // 元素抗性：四种元素伤害在乘区结算后按状态净值减免（允许负抗性加深伤害）
    final bool isElemental = damageType == 'fire' ||
        damageType == 'ice' ||
        damageType == 'lightning' ||
        damageType == 'poison';
    if (finalDamage > 0 && isElemental) {
      final int resist = getElementalResist(damageType);
      finalDamage = (finalDamage * (1 - 0.01 * resist)).round();
    }

    // 暴击：只有物理伤害可以暴击，独立乘区，在护甲扣除之前计入
    // 计数器机制：攻击方 crit_charge 达到 critThreshold 时，本次伤害消耗阈值层数并暴击；
    // 豪气（guaranteedCrit）走独立路径，必定暴击且不消耗计数器
    damageDetails['isCritical'] = false;
    if (finalDamage > 0 && damageType == 'physical') {
      final attackerStats = opponent!.data['stats'];
      final bool guaranteed = opponent!.turnFlags['guaranteedCrit'] == true;
      if (guaranteed) {
        opponent!.turnFlags['guaranteedCrit'] = false;
      }
      final int critThreshold =
          (attackerStats['critThreshold'] ?? kBaseCritThreshold).toInt();
      bool isCrit = guaranteed;
      if (!isCrit &&
          opponent!.hasStatusEffect('crit_charge') >= critThreshold) {
        opponent!.removeStatusEffect('crit_charge', amount: critThreshold);
        isCrit = true;
      }
      if (isCrit) {
        int critMultiplier =
            (attackerStats['critMultiplier'] ?? kBaseCritMultiplier).toInt();
        // 衰气：每层使本次暴击倍率 -50%（暴击倍率下限 100%），
        // 按层循环消耗，直到倍率降为 100% 或衰气耗尽
        while (critMultiplier > 100 &&
            opponent!.hasStatusEffect('debuff_crit') > 0) {
          critMultiplier -= 50;
          if (critMultiplier < 100) critMultiplier = 100;
          opponent!.removeStatusEffect('debuff_crit', amount: 1);
        }
        finalDamage = (finalDamage * critMultiplier / 100).round();
        damageDetails['isCritical'] = true;
      }
    }

    // 护甲在所有乘区结算完毕后，按数值抵扣最终伤害（杀戮尖塔式）
    // 阶段1重构：原先由 defense_self_taking_damage 脚本在乘区前扣除，
    // 会导致攻击方的增伤乘区放大护甲吸收量
    if (finalDamage > 0 && (damageType == 'physical' || damageType == 'chi')) {
      // final defenseId = 'defense_${damageDetails['damageType']}';
      // if (hasStatusEffect(defenseId) > 0) {
      if (hasStatusEffect('defense') > 0) {
        num penetration = (damageDetails['penetration'] ?? 0.0) as num;
        // 真气伤害自带 50% 防御穿透（伤害类型固有规则）
        if (damageDetails['damageType'] == 'chi') {
          penetration += 0.5;
        }
        penetration = penetration.clamp(0.0, 1.0);
        final int toBeBlocked = (finalDamage * (1 - penetration)).round();
        if (toBeBlocked > 0) {
          final int blocked =
              removeStatusEffect('defense', amount: toBeBlocked);
          if (blocked > 0) {
            damageDetails['blocked'] = true;
            damageDetails['blockedAmount'] = blocked;
            finalDamage -= blocked;
            assert(finalDamage >= 0);
          }
        }
      }
    }

    String damageString = finalDamage > 0 ? '-$finalDamage' : '$finalDamage';
    if (damageDetails['isCritical'] == true) {
      damageString = '$damageString ${engine.locale('critHint')}';
    }

    addHintText(damageString,
        color: damageDetails['isCritical'] == true
            ? Colors.orange
            : getDamageColor(damageDetails['damageType']));

    if (damageDetails['blocked'] ?? false) {
      engine.play(GameSound.block, volume: engine.config.soundEffectVolume);
    } else {
      engine.play(GameSound.slash, volume: engine.config.soundEffectVolume);
    }

    if (finalDamage > 0) {
      int hp = life;
      hp -= finalDamage;
      if (hp < 0) {
        hp = 0;
      }
      setLife(hp);

      damageDetails['finalDamage'] = finalDamage;

      opponent!.cardFlags['damage']['total'] += finalDamage;
      opponent!.turnFlags['totalDamage'] += finalDamage;
      // 怒气滞后产出模型的数据源（§4.3）：累计自身本回合实际受到的伤害
      damageTaken += finalDamage;

      // 充能：每次实际造成伤害的实例为攻击方对应计数器 +1
      //（物理 → crit_charge，元素 → ailment_charge；检查触发在先、充能在后，
      // 因此充满阈值的那次伤害本身不会立即触发）
      if (damageType == 'physical') {
        opponent!.addStatusEffect('crit_charge');
      } else if (isElemental) {
        opponent!.addStatusEffect('ailment_charge');
      }
    }

    // 元素异常触发：火/冰/雷/毒共享计数器，攻击方 ailment_charge 达到 ailmentThreshold 时，
    // 本次伤害消耗阈值层数并造成异常，层数为每满 10 点最终伤害 1 层，类别取本次伤害的元素
    // 豪气：元素攻击必定造成异常（独立路径，不消耗计数器，豪气的消耗在出牌时的状态脚本中完成，这里只清除标记）
    if (finalDamage > 0 && isElemental) {
      final attackerStats = opponent!.data['stats'];
      int stacks = 0;
      if (opponent!.turnFlags['guaranteedAilment'] == true) {
        opponent!.turnFlags['guaranteedAilment'] = false;
        stacks = finalDamage ~/ 10;
      } else {
        final int ailmentThreshold =
            (attackerStats['ailmentThreshold'] ?? kBaseAilmentThreshold)
                .toInt();
        if (opponent!.hasStatusEffect('ailment_charge') >= ailmentThreshold) {
          opponent!
              .removeStatusEffect('ailment_charge', amount: ailmentThreshold);
          stacks = finalDamage ~/ 10;
        }
      }
      // 不幸：攻击方有不幸时按层抵消其赋予的元素异常，
      // 直到异常全部抵消或衰气耗尽
      if (stacks > 0) {
        final int negated =
            math.min(stacks, opponent!.hasStatusEffect('debuff_crit'));
        if (negated > 0) {
          stacks -= negated;
          opponent!.removeStatusEffect('debuff_crit', amount: negated);
        }
      }
      if (stacks > 0) {
        final ailmentId = 'element_dot_$damageType';
        addStatusEffect(ailmentId, amount: stacks);
        // 写入施加方的异常伤害倍率（以最后一次触发为准）
        _statusEffects[ailmentId]?.data['ailmentMultiplier'] =
            (attackerStats['ailmentMultiplier'] ?? kBaseAilmentMultiplier)
                .toInt();
      }
    }

    damageDetails['finalDamage'] = finalDamage;

    // isMain 为 true 表示伤害来源来自主词条的攻击
    // 否则的话意味着是某些状态效果或者额外词条造成的伤害

    // 触发自己造成伤害后的效果
    opponent!.handleStatusEffectCallback('self_done_damage', damageDetails);
    // 触发对方造成伤害后的效果
    handleStatusEffectCallback('opponent_done_damage', damageDetails);

    // 触发对方受到伤害后的效果
    opponent!
        .handleStatusEffectCallback('opponent_taken_damage', damageDetails);
    // 触发自己受到伤害后的效果
    handleStatusEffectCallback('self_taken_damage', damageDetails);

    // bool blocked = damageDetails['blocked'] ?? false;

    if (finalDamage == 0) {
      // 这里不能用await，动画会卡住
      setCompositeState(startup: [kDodgeState], complete: kStandState);
    } else {
      setCompositeState(startup: [kHitState]);
    }

    return finalDamage;
  }

  Future<void> onStartTurn({bool isExtra = false}) async {
    // 重置 turnFlags
    turnFlags.clear();
    // 重置主词条本回合累计伤害计数
    turnFlags['totalDamage'] = 0;
    // isExtra 表示这是某些机制触发的再次行动回合
    turnFlags["isExtra"] = isExtra;

    // 回合统计结转（滞后一轮产出模型的数据源，须在回合开始回调之前归档）
    lastTurnWeaponCards = weaponCardsPlayed;
    weaponCardsPlayed = 0;
    lastTurnDamageTaken = damageTaken;
    damageTaken = 0;

    setState(kStandState);

    opponent!.handleStatusEffectCallback('opponent_turn_start');
    handleStatusEffectCallback('self_turn_start');

    if (turnFlags['skipTurn'] ?? false) {
      addHintText(engine.locale('skipTurn'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    if (turnFlags['defensePersisted'] ?? false) {
      addHintText(engine.locale('defensePersisted'));
    }
  }

  /// 返回值是一个map，若map中 skipTurn 的key对应值为true表示跳过此回合
  Future<void> onUseCard(CustomGameCard card) async {
    _sw.start();
    // 重置 cardFlags
    cardFlags.clear();

    if (card.data['isIdentified'] != true) {
      card.data['isIdentified'] = true;
      final (description, _) = GameData.getBattleCardDescription(
        card.data,
        showRequirement: false,
        isDetailed: false,
      );
      card.description = description;
    }

    // 展示当前卡牌及其详情
    card.enableGesture = false;
    card.moveTo(
      duration: 0.3,
      toPosition: isHero
          ? GameUI.p1BattleCardUsedPosition
          : GameUI.p2BattleCardUsedPosition,
      toSize: GameUI.battleCardUsedSize,
    );

    final List affixes = card.data['affixes'];
    assert(affixes.isNotEmpty);
    final mainAffix = affixes[0];
    final extraAffixes = affixes.skip(1);

    final category = mainAffix['category'];
    final genre = mainAffix['genre'];
    final kind = mainAffix['kind'];
    cardFlags['category'] = category;
    cardFlags['genre'] = genre;
    cardFlags['kind'] = kind;
    cardFlags['damage'] = <String, dynamic>{'total': 0};

    cardFlags['cardType'] = mainAffix['cardType'];
    cardFlags['damageType'] = mainAffix['damageType'];

    // 剑气滞后产出模型的数据源（§4.2）：累计本回合打出的武器牌数量
    if (mainAffix['cardType'] == 'weapon') {
      weaponCardsPlayed += 1;
    }

    opponent!.handleStatusEffectCallback('opponent_using_card');
    handleStatusEffectCallback('self_using_card');

    // 先处理优先级高于主词条的额外词条
    // 其中可能包含一些当前回合就立即起作用的buff
    final beforeMain = extraAffixes.where((affix) {
      return (affix['priority'] ?? 0) < 0;
    }).toList();
    // 多个词条时，按照优先级排序
    beforeMain.sort((a, b) {
      return ((b['priority'] ?? 0) as int).compareTo(a['priority'] ?? 0);
    });
    for (final affix in beforeMain) {
      final scriptId = affix['script'];
      if (scriptId == null) continue;
      engine.hetu.invoke(
        scriptId,
        namespace: 'CardScript',
        positionalArgs: [this, opponent, affix, mainAffix],
      );
    }

    // 处理主词条
    final mainScriptId = mainAffix['script'];
    if (mainScriptId != null) {
      final animation = mainAffix['animation'] ?? {};
      await setCompositeState(
        startup: animation['startup'],
        recovery: animation['recovery'],
        actions: animation['actions'],
        overlays: animation['overlays'],
        sound: animation['sound'],
      );
      engine.hetu.invoke(
        mainScriptId,
        namespace: 'CardScript',
        positionalArgs: [this, opponent, mainAffix, mainAffix],
      );
    }

    // 最后处理其他词条
    // 其中可能包含一些需求资源或有关主词条造成的伤害等情况的词条
    // 这样可能会当回合就触发一些联动
    final afterMain = extraAffixes.where((affix) {
      return (affix['priority'] ?? 0) >= 0;
    }).toList();
    // 多个词条时，按照优先级排序
    afterMain.sort((a, b) {
      return ((b['priority'] ?? 0) as int).compareTo(a['priority'] ?? 0);
    });
    for (final affix in afterMain) {
      final scriptId = affix['script'];
      if (scriptId == null) continue;
      engine.hetu.invoke(
        scriptId,
        namespace: 'CardScript',
        positionalArgs: [this, opponent, affix, mainAffix],
      );
    }

    if (mainAffix['category'] == 'attack') {
      // 触发自己发动攻击后的效果
      handleStatusEffectCallback('self_attacked');
      // 触发对方被发动攻击后的效果
      opponent!.handleStatusEffectCallback('opponent_attacked');
    }

    final delta = _sw.elapsedMilliseconds;
    if (delta < kMinCardDisplayDuration) {
      await Future.delayed(
          Duration(milliseconds: kMinCardDisplayDuration - delta));
    }
    _sw.stop();
    _sw.reset();

    opponent!.handleStatusEffectCallback('opponent_used_card');
    handleStatusEffectCallback('self_used_card');
  }

  /// 返回值true表示获得一个额外回合
  Future<void> onEndTurn() async {
    // 回合结束资源结算（顺序显式保证：先灵气溢出利用，后元气回血，见 §4.6/§4.1；
    // 灵气转化出的元气层数可赶上同回合的元气回血）
    engine.hetu.invoke('turn_end_resource_settlement',
        namespace: 'StatusScript', positionalArgs: [this, opponent]);

    handleStatusEffectCallback('self_turn_end');
    opponent!.handleStatusEffectCallback('opponent_turn_end');

    if (turnFlags['staggering'] == true) {
      addHintText(engine.locale('staggering'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    if (turnFlags['invincible'] == true) {
      addHintText(engine.locale('invincible'));
      await Future.delayed(Duration(milliseconds: 350));
    }

    if (turnFlags['extraTurn'] == true) {
      addHintText(engine.locale('extraTurn'));
      await Future.delayed(Duration(milliseconds: 350));
    }
  }

  Future<void> drawCards(int count) async {
    final battleScene = game as BattleScene;

    if (isHero) {
      await battleScene.drawCardsToHand(battleScene.heroDeckZone,
          battleScene.heroDiscardZone, battleScene.heroHandZone, count);
    } else {
      await battleScene.drawCardsToHand(battleScene.enemyDeckZone,
          battleScene.enemyDiscardZone, battleScene.enemyHandZone, count);
    }
  }
}
