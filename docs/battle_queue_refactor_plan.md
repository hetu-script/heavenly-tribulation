# 战斗系统队列模式重构计划

## 背景

### 当前问题
- **竞态条件Bug**: 玩家在卡牌结算期间快速连续点击最后一张牌，会导致卡牌卡在原地无法结算
- **根本原因**: 使用单个 `Completer` 在异步循环中管理交互状态，存在状态不一致和时机窗口问题
- **用户体验**: 快速点击时部分点击被忽略，感觉不流畅

### 目标方案
采用**队列模式**重构卡牌打出逻辑：
- 被选中的卡牌立即进入"待打出队列"
- 队列中的卡牌依次异步结算
- 已选中的卡牌显示发光效果（`showGlow = true`），提示玩家
- 不支持撤销，已入队的卡牌必定会被打出（除非能量不足时跳过）

---

## 设计方案

### 1. 核心数据结构

```dart
class BattleScene extends Scene {
  // 待打出队列
  final Queue<CustomGameCard> _cardQueue = Queue();
  
  // 队列处理状态锁
  bool _isProcessingQueue = false;
  
  // 移除旧的 Completer（不再需要）
  // Completer<CustomGameCard?>? _playerCardSelection; // 删除
}
```

### 2. 卡牌状态

引入"待打出"状态的视觉反馈：

| 状态         | 位置      | 交互    | 视觉效果           |
| ------------ | --------- | ------- | ------------------ |
| 手牌         | HandZone  | 可点击  | 正常显示           |
| 待打出       | HandZone  | 已禁用  | `showGlow = true`  |
| 结算中       | HandZone  | 已禁用  | `showGlow = true`  |
| 已打出       | Discard   | 不可见  | `isFlipped = true` |

### 3. 交互流程

#### 旧流程（Completer 模式）
```
玩家点击卡牌 A
  ↓
complete Completer
  ↓
扣能量 → 清除交互 → await 结算 → 移到弃牌堆
  ↓
while 循环创建新 Completer
  ↓
等待下一次点击
```

**问题**: 在 `await 结算` 期间点击 B 会被忽略或产生竞态。

#### 新流程（队列模式）
```
玩家点击卡牌 A
  ↓
A 入队 → A.showGlow = true → 启动队列处理器（如果未运行）
  ↓
队列处理器: 从队列取出 A
  ↓
验证 A 仍在手牌 && 能量足够
  ↓
扣能量 → 清除交互 → await 结算 → 移到弃牌堆
  ↓
队列处理器: 继续处理下一张（B）或退出
```

**优势**: 
- 点击立即入队，不会丢失
- 队列处理器单线程，避免竞态
- 发光效果提供视觉反馈

---

## 实现步骤

### Phase 1: 数据结构和基础方法

#### 1.1 修改 BattleScene 类
**文件**: `lib/scene/battle/battle.dart`

```dart
// 添加字段
final Queue<CustomGameCard> _cardQueue = Queue();
bool _isProcessingQueue = false;

// 移除字段
// Completer<CustomGameCard?>? _playerCardSelection; ← 删除
```

#### 1.2 实现入队方法
```dart
/// 将卡牌加入待打出队列
void _enqueueCard(CustomGameCard card) {
  // 验证卡牌在手牌中
  if (!heroHandZone.cards.contains(card)) return;
  
  // 验证能量足够（使用当前能量）
  if (card.cost > hero.energy) return;
  
  // 验证不重复入队
  if (_cardQueue.contains(card)) return;
  
  // 入队并标记
  _cardQueue.add(card);
  card.showGlow = true;
  
  // 清除卡牌交互（避免重复点击）
  heroHandZone.clearCardInteraction(card);
  
  engine.info('卡牌入队: ${card.data['name']}, 队列长度: ${_cardQueue.length}');
}
```

#### 1.3 实现队列处理器
```dart
/// 处理待打出队列（异步单线程）
Future<void> _processCardQueue() async {
  // 防止重入
  if (_isProcessingQueue) return;
  _isProcessingQueue = true;
  
  try {
    while (_cardQueue.isNotEmpty) {
      // 检查中断条件
      if (_isRestarting || battleEnded) {
        _cardQueue.clear();
        break;
      }
      
      final card = _cardQueue.removeFirst();
      
      // 二次验证：卡牌仍在手牌且能量足够
      if (!heroHandZone.cards.contains(card)) {
        engine.warning('卡牌已不在手牌中，跳过: ${card.data['name']}');
        card.showGlow = false;
        continue;
      }
      
      if (card.cost > hero.energy) {
        engine.warning('能量不足，跳过: ${card.data['name']} (cost: ${card.cost}, energy: ${hero.energy})');
        card.showGlow = false;
        // 清空剩余队列（能量不足意味着后续卡牌也打不出）
        for (final remainingCard in _cardQueue) {
          remainingCard.showGlow = false;
          heroHandZone.enableCardInteraction(remainingCard);
        }
        _cardQueue.clear();
        break;
      }
      
      // 执行打出逻辑
      await _playCard(card);
    }
  } finally {
    _isProcessingQueue = false;
  }
}
```

#### 1.4 实现单卡打出逻辑
```dart
/// 执行单张卡牌的打出流程
Future<void> _playCard(CustomGameCard card) async {
  engine.info('开始打出卡牌: ${card.data['name']}');
  
  // 1. 扣除能量
  hero.energy -= card.cost;
  heroHandZone.energy = hero.energy;
  heroEnergyDisplay.setEnergy(hero.energy);
  
  // 2. 卡牌结算
  await hero.onUseCard(card);
  
  // 3. 翻面并移到弃牌堆
  card.isFlipped = true;
  card.showGlow = false;
  heroDiscardZone.tryAddCard(card);
  await heroDiscardZone.sortCards();
  
  engine.info('卡牌打出完成: ${card.data['name']}, 剩余能量: ${hero.energy}');
}
```

---

### Phase 2: 修改交互入口

#### 2.1 重构 `onPlayerSelectedCard`
**当前逻辑**: 完成 Completer
**新逻辑**: 将卡牌入队并启动处理器

```dart
void onPlayerSelectedCard(CustomGameCard? card) {
  // null 表示结束回合
  if (card == null) {
    _endPlayerTurn();
    return;
  }
  
  // 加入队列
  _enqueueCard(card);
  
  // 启动队列处理器（不 await，让它在后台运行）
  _processCardQueue();
}
```

#### 2.2 新增结束回合方法
```dart
/// 结束玩家回合
void _endPlayerTurn() {
  engine.info('玩家请求结束回合');
  
  // 清空队列并恢复所有卡牌状态
  for (final card in _cardQueue) {
    card.showGlow = false;
    if (heroHandZone.cards.contains(card)) {
      heroHandZone.enableCardInteraction(card as CustomGameCard);
    }
  }
  _cardQueue.clear();
  
  // 设置标志，等待队列处理器完成当前卡牌后退出
  _shouldEndTurn = true;
}
```

**需要新增标志**:
```dart
bool _shouldEndTurn = false;
```

在 `_processCardQueue` 中检查：
```dart
if (_shouldEndTurn) {
  _cardQueue.clear();
  break;
}
```

---

### Phase 3: 修改回合循环

#### 3.1 重构 `_startTurn` 中的玩家回合部分

**旧代码**:
```dart
if (heroTurn) {
  endTurnButton.isEnabled = true;
  while (!_isRestarting && handZone.cards.isNotEmpty) {
    assert(_playerCardSelection == null);
    _playerCardSelection = Completer<CustomGameCard?>();
    final selectedCard = await _playerCardSelection!.future;
    if (selectedCard == null) break;
    
    currentCharacter.energy -= selectedCard.cost;
    // ... 结算逻辑
  }
  endTurnButton.isEnabled = false;
}
```

**新代码**:
```dart
if (heroTurn) {
  endTurnButton.isEnabled = true;
  
  // 重置结束回合标志
  _shouldEndTurn = false;
  
  // 等待玩家结束回合（通过 _shouldEndTurn 标志）
  while (!_isRestarting && !_shouldEndTurn) {
    // 等待队列处理器空闲
    if (!_isProcessingQueue && _cardQueue.isEmpty) {
      // 检查是否还有可打出的卡牌
      final affordableCards = heroHandZone.cards
          .where((c) => (c as CustomGameCard).cost <= hero.energy)
          .toList();
      
      if (affordableCards.isEmpty) {
        // 没有可打出的卡牌，自动结束回合
        engine.info('没有可打出的卡牌，自动结束回合');
        break;
      }
    }
    
    // 短暂等待，避免忙等
    await Future.delayed(Duration(milliseconds: 50));
  }
  
  // 等待队列处理器完成
  while (_isProcessingQueue) {
    await Future.delayed(Duration(milliseconds: 50));
  }
  
  endTurnButton.isEnabled = false;
}
```

**注意**: 这个 `while` 循环不再是"等待选牌 → 处理 → 等待选牌"的模式，而是"持续运行直到玩家结束回合"。

---

### Phase 4: 清理和兼容性

#### 4.1 移除旧代码
- 删除 `_playerCardSelection` 字段及相关 assert
- 删除 `Completer` 相关导入（如果不再使用）

#### 4.2 HandZone 交互管理
**现状**: `HandZone` 目前只有 `clearCardInteraction` 方法，**缺少 `enableCardInteraction`**。

需要在 `lib/scene/battle/hand_zone.dart` 中添加：

```dart
void enableCardInteraction(CustomGameCard card) {
  if (!enableInteraction) return;
  if (!cards.contains(card)) return;
  
  card.enableGesture = true;
  
  // 恢复交互回调（参考 tryAddCard 中的逻辑）
  card.onTapUp = (button, position) {
    Hovertip.hide(card);
    onCardSelected?.call(card);
    card.removeFromPile();
    setSpreadCenter(card, false);
  };
  
  card.onMouseEnter = () {
    card.setFocused(true);
    card.showGlow = true;
    final (_, description) = GameData.getBattleCardDescription(
      card.data,
      isDetailed: true,
      showAffixes: false,
    );
    Hovertip.show(
      scene: game,
      target: card,
      direction: HovertipDirection.topCenter,
      content: description,
      config: ScreenTextConfig(
        anchor: Anchor.topCenter,
        textAlign: TextAlign.center,
      ),
    );
    setSpreadCenter(card, true);
  };
  
  card.onMouseExit = () {
    card.setFocused(false);
    card.showGlow = false;
    Hovertip.hide(card);
    setSpreadCenter(card, false);
  };
}
```

**注意**: 这个方法需要与 `tryAddCard` 保持一致，复用相同的交互逻辑。

#### 4.3 测试点
1. **基础流程**: 依次点击3张牌，验证顺序打出
2. **快速点击**: 快速连续点击多张牌，验证全部入队并依次结算
3. **能量不足**: 点击超过能量的卡牌组合，验证中途停止
4. **结束回合**: 点击部分牌后点击"结束回合"，验证队列清空
5. **重启战斗**: 开发模式下重启，验证队列和标志正确重置

---

## 优缺点分析

### 优点
✅ **彻底解决竞态条件**: 单线程队列处理，无状态不一致  
✅ **用户体验流畅**: 快速点击不会丢失，立即视觉反馈  
✅ **代码更清晰**: 移除 Completer 的复杂状态管理，逻辑更线性  
✅ **易于扩展**: 未来可增加"撤销"、"队列预览"等功能  
✅ **符合《杀戮尖塔》体验**: 玩家可以快速规划连招  

### 缺点/限制
⚠️ **不可撤销**: 一旦入队无法取消（设计决策）  
⚠️ **需要 `enableCardInteraction`**: 如果 HandZone 不支持需要添加  
⚠️ **回合结束等待**: 需要轮询等待队列处理完成（可优化为 Completer 通知）  

---

## 后续优化（可选）

### 1. 队列可视化
在 UI 上显示待打出队列，让玩家看到"接下来会打出哪些牌"

### 2. 撤销功能
添加"撤销上一张牌"按钮（需要保存能量快照和状态回滚）

### 3. 使用 Completer 优化回合结束
替换 `while` 轮询为：
```dart
final turnCompleter = Completer<void>();
// 在 _endPlayerTurn 中 complete
await turnCompleter.future;
```

### 4. 动画优化
入队时卡牌轻微抖动或位置微调，增强反馈

---

## 风险评估

| 风险                         | 概率 | 影响 | 缓解措施                                     |
| ---------------------------- | ---- | ---- | -------------------------------------------- |
| HandZone 不支持恢复交互      | 中   | 高   | 先检查实现，如不存在则添加                   |
| 队列处理器卡死               | 低   | 高   | 添加超时保护和日志                           |
| 能量计算错误导致连续打出失败 | 中   | 中   | 严格二次验证，跳过无效卡牌                   |
| 与其他战斗逻辑冲突           | 低   | 中   | 充分测试偷袭、练习模式、特殊技能等边缘场景   |

---

## 实施计划

### 时间估算
- Phase 1: 2 小时（数据结构和核心方法）
- Phase 2: 1 小时（修改交互入口）
- Phase 3: 1.5 小时（重构回合循环）
- Phase 4: 1.5 小时（清理和测试）

**总计**: ~6 小时

### 检查清单
- [ ] Phase 1: 添加队列和处理器
- [ ] Phase 2: 修改 `onPlayerSelectedCard`
- [ ] Phase 3: 重构 `_startTurn` 玩家回合
- [ ] Phase 4: 检查 HandZone 交互方法
- [ ] 测试基础流程
- [ ] 测试快速点击
- [ ] 测试能量不足
- [ ] 测试结束回合
- [ ] 测试重启战斗
- [ ] 代码审查和优化

---

## 相关文件

### 需要修改
- `lib/scene/battle/battle.dart` — 主要修改
- `lib/scene/battle/hand_zone.dart` — 可能需要添加 `enableCardInteraction`

### 需要测试
- 所有战斗场景（正常战斗、偷袭、练习模式）
- 特殊卡牌效果（额外回合、能量操作等）
- 重启战斗（开发模式）

---

**创建日期**: 2025-01-XX  
**作者**: Kiro AI  
**状态**: 待实施
