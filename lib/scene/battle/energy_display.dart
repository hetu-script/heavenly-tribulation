import 'package:flutter/material.dart' hide Viewport;
import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/components/ui/hovertip.dart';

import '../../global.dart';
import '../../data/game.dart';
import '../../data/common.dart';
import '../../ui.dart';
import 'character.dart';
import 'status_effect.dart' show kNegativeQiInvertMatrix;

/// 资源气槽位配置：按 元气/灵/剑/怒/煞/无极 顺序，(阳气 id, 阴气 id)
const _kQiSlots = [
  ('energy_positive_life', 'energy_negative_life'),
  ('energy_positive_spell', 'energy_negative_spell'),
  ('energy_positive_weapon', 'energy_negative_weapon'),
  ('energy_positive_unarmed', 'energy_negative_unarmed'),
  ('energy_positive_curse', 'energy_negative_curse'),
  ('energy_positive_ultimate', 'energy_negative_ultimate'),
];

/// 元气（无色费用池）的阳气 id，该槽位恒显并显示上限（kBattleBaseEnergy + 词条加成，纯显示参照，可超出）
const _kVigorStatusId = 'energy_positive_life';

/// 单个资源气槽位：阴阳净值显示（阴气以反色图标显示），悬浮提示说明
class _QiSlot extends GameComponent with HandlesGesture {
  _QiSlot({
    required this.yangId,
    required this.yinId,
    required this.alwaysVisible,
    required super.size,
  }) : super(isVisible: false);

  final String yangId;
  final String yinId;

  /// 元气槽位恒显（0 也显示）；其余槽位只在持有时显示
  final bool alwaysVisible;

  Sprite? _sprite;

  /// 阴气反色渲染的缓存画笔（惰性创建）
  Paint? _invertPaint;

  int _amount = 0;
  int _max = 0;
  bool _isYin = false;
  String _description = '';

  static final _countTextConfig = ScreenTextConfig(
    anchor: Anchor.bottomRight,
    outlined: true,
    textStyle: TextStyle(
      fontFamily: GameUI.fontFamilyKaiti,
      color: Colors.white,
      fontSize: 12.0,
      fontWeight: FontWeight.bold,
    ),
  );

  @override
  Future<void> onLoad() async {
    final icon = GameData.statusEffects[yangId]['icon'];
    if (icon != null) {
      _sprite = await Sprite.load(icon);
    }
    onMouseEnter = () {
      Hovertip.show(
        scene: game,
        target: this,
        direction: HovertipDirection.topLeft,
        content: _description,
        width: 200.0,
      );
    };
    onMouseExit = () {
      Hovertip.hide(this);
    };
  }

  /// 刷新显示：阴阳净值（同一时刻至多存在一侧），阴气反色
  void updateQi(int yang, int yin, {int max = 0}) {
    _isYin = yin > 0;
    _amount = _isYin ? yin : yang;
    _max = max;
    isVisible = alwaysVisible || _amount > 0;
    final id = _isYin ? yinId : yangId;
    final data = GameData.statusEffects[id];
    _description =
        '${engine.locale(data['title'])}\n${engine.locale(data['description'])}';
  }

  @override
  void render(Canvas canvas) {
    if (!isVisible) return;

    if (_isYin) {
      _invertPaint ??= Paint()
        ..colorFilter = const ColorFilter.matrix(kNegativeQiInvertMatrix);
      _sprite?.render(canvas, size: size, overridePaint: _invertPaint);
    } else {
      _sprite?.render(canvas, size: size);
    }
    final text = alwaysVisible ? '$_amount/$_max' : '$_amount';
    drawScreenText(canvas, text,
        config: _countTextConfig.copyWith(size: size));
  }
}

/// 资源气行：统一管理所有资源气（6 阳 6 阴）的显示，
/// 位于永久状态行上方单独一行。
/// 元气恒显并显示上限（kBattleBaseEnergy + 词条加成，纯显示参照，可超出）；
/// 其余气只在持有时显示；无极之气与前五色之间有额外间隔。
class EnergyDisplay extends GameComponent {
  EnergyDisplay({
    required super.position,
    required this.isHero,
  });

  final bool isHero;

  final List<_QiSlot> _slots = [];

  @override
  Future<void> onLoad() async {
    for (final (yangId, yinId) in _kQiSlots) {
      final slot = _QiSlot(
        yangId: yangId,
        yinId: yinId,
        alwaysVisible: yangId == _kVigorStatusId,
        size: GameUI.qiSlotSize,
      );
      _slots.add(slot);
      add(slot);
    }
  }

  /// 根据角色的资源气状态刷新显示；隐藏槽位收起，后续槽位递补
  /// 英雄从左向右排列，敌方从右向左排列（元气靠近屏幕边缘）
  void refresh(BattleCharacter character) {
    final slotStep = GameUI.qiSlotSize.x + GameUI.smallIndent;
    // 英雄从左边缘开始；敌方从行右缘开始
    double offsetX = isHero ? 0 : GameUI.qiRowWidth - GameUI.qiSlotSize.x;
    for (var i = 0; i < _slots.length; ++i) {
      final slot = _slots[i];
      final yang = character.hasStatusEffect(slot.yangId);
      final yin = character.hasStatusEffect(slot.yinId);
      final max = slot.alwaysVisible
          ? kBattleBaseEnergy +
              ((character.data['stats']['battleEnergyBonus'] ?? 0) as int)
          : 0;
      slot.updateQi(yang, yin, max: max);
      if (!slot.isVisible) continue;
      // 无极之气与前五色之间加大间隔
      if (i == _kQiSlots.length - 1) {
        offsetX += isHero ? GameUI.largeIndent : -GameUI.largeIndent;
      }
      slot.position = Vector2(offsetX, 0);
      offsetX += isHero ? slotStep : -slotStep;
    }
  }
}
