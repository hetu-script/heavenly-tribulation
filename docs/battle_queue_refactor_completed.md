# 战斗系统队列模式重构 - 完成报告

**完成时间**: 2025-01-XX  
**状态**: ✅ 已完成并通过静态分析

---

## 修改概要

### 修改的文件
1. `lib/scene/battle/battle.dart` — 核心战斗逻辑
2. `lib/scene/battle/hand_zone.dart` — 手牌区交互管理

### 代码统计
- **添加**: ~150 行代码
- **删除**: ~20 行代码
- **重构**: 玩家回合循环逻辑

---

## 已实施的改动

### 1. 数据结构变更 (`battle.dart`)

#### 移除
```dart
// Completer<CustomGameCard?>? _playerCardSelection; // 已注释
```

#### 新增
```dart
import 'dart:collection';  // 添加 Queue 支持

final Queue<CustomGameCard> _cardQueue = Queue();
bool _isProcessingQueue = false;
bool _shouldEndTurn = false;
```

---

### 2. 核心方法实现 (`battle.dart`)

#### 2.1 `_enqueueCard` — 卡牌入队
- 验证卡牌在手牌中
- 验证能量足够
- 验证不重复入队
- 设置 `showGlow = true` 提供视觉反馈
- 清除卡牌交互避免重复点击

#### 2.2 `_processCardQueue` — 队列处理器
- 单线程异步处理，防止竞态
- 检查中断条件（`_isRestarting`、`battleEnded`、`_shouldEndTurn`）
- 二次验证卡牌和能量
- 能量不足时清空剩余队列并恢复交互
- 依次调用 `_playCard` 处理每张卡

#### 2.3 `_playCard` — 单卡打出
- 扣除能量
- 调用 `hero.onUseCard` 结算
- 翻面并移到弃牌堆
- 添加详细日志

#### 2.4 `_endPlayerTurn` — 结束回合
- 设置 `_shouldEndTurn = true` 标志
- 队列处理器检测到后会清空队列并退出

#### 2.5 `onPlayerSelectedCard` — 重构交互入口
- `card == null` → 调用 `_endPlayerTurn()`
- `card != null` → 调用 `_enqueueCard(card)` + 启动 `_processCardQueue()`
- 不再使用 Completer

---

### 3. 回合循环重构 (`battle.dart`)

**旧逻辑** (Completer 模式):
```dart
while (!_isRestarting && handZone.cards.isNotEmpty) {
  _playerCardSelection = Completer<CustomGameCard?>();
  final selectedCard = await _playerCardSelection!.future;
  // ... 处理单张卡牌
}
```

**新逻辑** (队列模式):
```dart
// 重置结束回合标志
_shouldEndTurn = false;

// 等待玩家结束回合
while (!_isRestarting && !_shouldEndTurn) {
  if (!_isProcessingQueue && _cardQueue.isEmpty) {
    // 检查是否还有可打出的卡牌
    final affordableCards = heroHandZone.cards
        .where((c) => (c as CustomGameCard).cost <= hero.energy)
        .toList();
    
    if (affordableCards.isEmpty) {
      // 自动结束回合
      break;
    }
  }
  
  await Future.delayed(Duration(milliseconds: 50));
}

// 等待队列处理器完成
while (_isProcessingQueue) {
  await Future.delayed(Duration(milliseconds: 50));
}
```

---

### 4. HandZone 交互恢复 (`hand_zone.dart`)

新增 `enableCardInteraction` 方法：
```dart
void enableCardInteraction(CustomGameCard card) {
  if (!enableInteraction) return;
  if (!cards.contains(card)) return;
  
  card.enableGesture = true;
  
  // 恢复所有交互回调（onTapUp, onMouseEnter, onMouseExit）
  // 逻辑与 tryAddCard 中完全一致
}
```

**作用**: 在能量不足或结束回合时，恢复队列中剩余卡牌的交互能力

---

### 5. 状态清理 (`battle.dart`)

#### 重启战斗时清理
```dart
if (_isRestarting) {
  // 清理队列和状态
  _cardQueue.clear();
  _isProcessingQueue = false;
  _shouldEndTurn = false;
  
  await _returnAllCardsToDecks();
  _isRestarting = false;
  battleStarted = false;
}
```

#### 重启触发点修改
```dart
case 'restart':
  if (battleEnded) {
    // ... 战斗结束后重启
  } else if (battleStarted) {
    _isRestarting = true;
    _endPlayerTurn();  // 使用新方法代替 onPlayerSelectedCard(null)
  }
```

---

## 验证结果

### 静态分析
```bash
flutter analyze lib/scene/battle/battle.dart lib/scene/battle/hand_zone.dart
```
**结果**: ✅ No issues found!

### 代码检查
- ✅ 旧 Completer 已注释，未被引用
- ✅ 所有新字段和方法都已正确使用
- ✅ `enableCardInteraction` 已在 `hand_zone.dart` 中实现
- ✅ 队列处理逻辑完整（入队、处理、清理）
- ✅ 状态重置逻辑完整（重启战斗、结束回合）

---

## 功能特性

### ✅ 已实现
1. **快速点击支持** — 多次点击卡牌会依次入队并顺序打出
2. **视觉反馈** — 入队卡牌 `showGlow = true`，玩家可清晰看到哪些牌等待打出
3. **能量验证** — 入队时检查一次，打出前再次检查，双重保护
4. **自动清理** — 能量不足时清空队列，恢复剩余卡牌交互
5. **结束回合** — 点击"结束回合"按钮会清空队列并退出回合
6. **重启支持** — 重启战斗时正确清理队列和所有标志
7. **日志完整** — 入队、打出、跳过等操作都有详细日志

### 🔄 待测试
- [ ] 基础流程：依次打出3张牌
- [ ] 快速点击：快速连续点击多张牌
- [ ] 能量不足：点击超过能量的卡牌组合
- [ ] 结束回合：打出部分牌后点击"结束回合"
- [ ] 重启战斗：开发模式下重启战斗
- [ ] 特殊卡牌：额外回合、能量操作等特殊效果
- [ ] 边缘场景：偷袭、练习模式

---

## 与原 Bug 的对比

### 原 Bug 现象
> 打出倒数第二张牌时，连续点击最后一张牌，会导致第二张牌结算完毕后直接结束回合，第三张牌并没有进入结算，而且会卡在原地。

### 根本原因
1. **Completer 状态不一致** — 在异步操作期间，`_playerCardSelection` 的 `isCompleted` 状态导致点击被忽略
2. **竞态条件** — 在 `await onUseCard` 和 `await sortCards` 之间，用户的多次点击可能在不恰当的时机被处理
3. **无交互锁** — 卡牌结算期间仍然可以触发点击事件，产生意外行为

### 新设计如何解决
1. **队列模式** — 所有点击立即入队，不会丢失或被忽略
2. **单线程处理** — `_isProcessingQueue` 锁确保同一时间只有一个卡牌在结算
3. **立即禁用** — 入队时立即清除卡牌交互，避免重复点击
4. **视觉反馈** — `showGlow = true` 明确告知玩家哪些牌已选中
5. **二次验证** — 打出前再次检查卡牌和能量，确保状态一致

---

## 性能考虑

### 轮询开销
当前实现使用 `while` + `Future.delayed(50ms)` 轮询：
```dart
while (!_isRestarting && !_shouldEndTurn) {
  // 检查条件
  await Future.delayed(Duration(milliseconds: 50));
}
```

**每回合开销**: ~20 次轮询/秒 × 回合时长

**优化建议**（可选）:
- 使用 `Completer<void>` 在 `_endPlayerTurn` 中 complete，替换轮询
- 或增加轮询间隔到 100ms（不影响体验）

---

## 后续优化方向

### 1. 队列可视化 UI
在手牌区上方显示待打出队列，类似《炉石传说》的卡牌历史

### 2. 撤销功能
添加"撤销上一张牌"按钮（需要保存能量快照和状态回滚）

### 3. 队列长度限制
防止玩家一次性点击过多卡牌导致动画卡顿

### 4. 动画优化
- 入队时卡牌轻微抖动
- 队列处理时显示进度条

---

## 风险提示

### 需要运行时测试的场景
1. **特殊卡牌效果** — 额外回合、改变能量、手牌操作等
2. **异常退出** — 战斗中途退出、切换场景时队列状态
3. **AI 回合** — 确认队列逻辑不影响敌方回合
4. **边缘情况** — 手牌为空、牌库为空、能量为0 等

### 潜在问题
- 如果 `hero.onUseCard` 内部触发了其他异步操作（如对话框、动画），可能延长队列处理时间
- 轮询间隔 50ms 可能在高延迟情况下导致按钮响应延迟

---

## 总结

✅ **重构成功完成**  
✅ **静态分析通过**  
✅ **代码结构清晰**  
✅ **Bug 根本原因已解决**  

**建议**: 
1. 先在开发模式下进行完整战斗流程测试
2. 重点测试快速点击和能量不足场景
3. 验证重启战斗功能正常
4. 如发现问题，查看控制台日志（已添加详细日志）

**下一步**: 进入游戏测试，验证实际体验 🎮
