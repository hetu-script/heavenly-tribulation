# Plan: 战斗系统改造 - 从自动战斗到手动卡牌选择

## 背景与目标

将当前全自动卡牌战斗改造为传统卡牌游戏的手动出牌模式：

- 牌库统一为10张牌
- 每回合从牌库抽取最上面的 `getHandLimitForRank(rank)` 张牌（3-8张，随境界提升）
- 轮到玩家时，需要手动点击选择一张卡牌执行效果，敌方则使用简单AI策略出牌
- 未打出的手牌回合结束时放回牌库，并洗牌。
- 完全移除自动战斗相关代码

## 关键发现（Discovery）

### 当前战斗流程

1. `BattleScene` 创建 `heroDeckZone` / `enemyDeckZone`（`PiledZone` + `PileStyle.queue`）
2. 卡牌按顺序依次打出，`current` 指针指向当前牌，`next` 链接下一张
3. `_startTurn()` 自动执行当前卡牌效果，然后 `nextCard()` 推进指针
4. 一轮结束后重置所有牌为可用，round++，5轮后获得死气debuff
5. `isAutoBattle` 控制是否自动连续执行

### 可复用基础设施

- `CustomGameCard` 已支持 `onTap`/`onTapUp`（`HandlesGesture` mixin）
- `isEnabled` 可灰显不可用的牌
- `setFocused(true/false)` 有聚焦动画
- `Hovertip.show/hide` 已用于卡牌预览
- 卡牌库场景已有左键点击选择卡牌的模式可借鉴

### 需要新建的部分

- 手牌区（`HandZone`）
- 抽牌/洗牌逻辑
- 玩家输入等待机制（async Completer 或状态机）
- 敌方AI策略
- 卡牌选择高亮状态（区别于 `isFocused`）

## 方案设计

### Phase 1: 数据层与常量调整

**文件: `lib/data/common.dart`**

- 新增 `const kBattleDeckSize = 10;` — 统一牌库大小
- 保留 `kBattleRoundLimit` 但修改数值和含义为16回合后获得死气（而非5轮牌库）

**文件: `scripts/main/data/character/battle_entity.ht`**

- `generateBattleDeck` 中 `deckLimit.limit` 改为固定 `kBattleDeckSize`（10张）
- 不再按境界变化牌库大小

**文件: `lib/logic/logic.dart`**

### Phase 2: 新建手牌区组件

**新增文件: `lib/scene/battle/hand_zone.dart`**

```dart
class HandZone extends PiledZone with HandlesGesture {
  // 手牌区：展示当前回合抽到的牌
  // PileStyle.queue
}
```

- 继承 `PiledZone`，使用 `PileStyle.queue`
- 比 `BattleDeckZone` 更宽松的 `pileOffset`（手牌需要清晰展示每张牌）
- 提供 `drawCards(List<CustomGameCard> deck, int count)` 方法：
  - 移除现有手牌
  - 从 deck 中随机选取 count 张（或洗牌后取前count张）
  - 添加到 handZone
- 提供 `clearHand()` 方法：清空手牌
- 卡牌添加 `onTapUp` 处理：左键点击时通知 `BattleScene` 选择了某张牌
- 需要确保回合结束后手牌区的卡牌只是从UI移除，不影响牌库

### Phase 3: BattleScene 核心流程改造

**文件: `lib/scene/battle/battle.dart`**

#### 3.1 移除自动战斗相关代码

- 删除 `isAutoBattle` 字段及所有使用
- 删除 `startAutoBattle()` 方法
- 删除 `nextTurnButton` 的自动/手动分支逻辑
- 删除 `kMinTurnDuration` 相关的强制等待（或改为可选）

#### 3.2 新增手牌区

```dart
late final HandZone heroHandZone, enemyHandZone;
```

- 位置：heroHandZone 在屏幕下方中央（替换或叠加在 deckZone 上方）
- enemyHandZone 在屏幕上方（可选：敌方手牌背面展示或隐藏）

#### 3.3 改造回合流程

当前 `_startTurn()` 是全自动的，需要改为：

**玩家回合（heroTurn == true）：**

1. 抽牌：`heroHandZone.drawCards(heroDeck, drawCount)`
2. 等待玩家选择：使用 `Completer<CustomGameCard>`
3. 玩家点击卡牌 → 验证可打出（资源足够等）→ 执行效果
4. 执行 `currentCharacter.onTurnStart(selectedCard)`
5. 执行 `currentCharacter.onTurnEnd(selectedCard)`
6. `heroHandZone.clearHand()` — 未打出的牌放回（只是从UI移除）
7. 切换回合

**敌方回合（heroTurn == false）：**

1. 抽牌：`enemyHandZone.drawCards(enemyDeck, enemyDrawCount)`
2. AI策略选择一张牌
3. 自动执行效果
4. `enemyHandZone.clearHand()`
5. 切换回合

#### 3.4 AI策略（初步）

```dart
CustomGameCard _enemySelectCard(List<CustomGameCard> hand) {
  // 血量 < 50% 优先 buff，否则优先 attack
  final buffs = hand.where((c) => c.data['affixes'][0]['category'] == 'buff');
  final attacks = hand.where((c) => c.data['affixes'][0]['category'] == 'attack');

  if (enemy.life < enemy.lifeMax * 0.5 && buffs.isNotEmpty) {
    return buffs.random; // 或随机
  }
  if (attacks.isNotEmpty) return attacks.random;
  return hand.random;
}
```

#### 3.5 状态机改造

当前 `battleStarted` + `nextTurnButton` 控制流程。改造后：

- `nextTurnButton` 移除（因为玩家出牌后即自动结束）

### Phase 4: BattleDeckZone 改造

**文件: `lib/scene/battle/battledeck_zone.dart`**

当前 `BattleDeckZone` 的职责：

- 展示整个牌库（10张牌堆叠在一起）
- 追踪 `current` 指针和 `round`

改造后职责：

- 仍然展示整个牌库（作为视觉参考，可选背面朝上或显示数量）
- 不再用于顺序出牌
- 或者改为只展示牌库数量/剩余牌数

**决策：** 保留 `BattleDeckZone` 作为牌库展示，但改为 `PileStyle.stack` 堆叠显示，或简化为一个牌背图标+数量文字。

### Phase 5: 卡牌交互改造

**文件: `lib/scene/battle/hand_zone.dart`**

为手牌区的每张卡牌设置交互：

```dart
card.onTapUp = (button, position) {
  if (button == kPrimaryButton) {
    if (!card.isEnabled) return; // 资源不足等不可打出
    _onCardSelected(card);
  }
};
```

需要新增的视觉反馈：

- 可选中的卡牌：正常显示
- 不可选中的卡牌（资源不足）：`isEnabled = false` 灰显
- 选中后的卡牌：`setFocused(true)` + 播放效果
- 敌方手牌：背面朝上（`backSpriteId`）

### Phase 6: 死气机制调整

**文件: `lib/scene/battle/battle.dart`**

当前：

```dart
if (currentCharacter.deckZone.round >= kBattleRoundLimit) {
  currentCharacter.addStatusEffect('energy_negative_life',
      amount: currentCharacter.deckZone.round);
}
```

改造后：

- 死气和 `roundCount`（回合数）绑定，而非 `deckZone.round`
- 每 `kBattleRoundLimit` 个回合（即第5、10、15...回合）开始时获得死气
- 或改为每回合开始时检查 `roundCount >= kBattleRoundLimit`

### Phase 7: 练习模式与开发模式

**文件: `lib/scene/battle/battle.dart`**

- 完全移除 `isAutoBattle` 和 `startAutoBattle()`
- `isPractice` 保留（不影响战斗逻辑，只影响战后结算）
- `engine.config.developMode` 不再影响战斗流程（可保留控制台菜单）

### Phase 8: UI 布局调整

**文件: `lib/ui.dart`**

新增/调整：

- `handZonePosition` — 手牌区位置（屏幕下方中央）
- `handCardSize` — 手牌大小（可与 `battleCardSize` 相同或略小）
- `handCardOffset` — 手牌间距（比 `battleDeckZone` 更宽松）

当前 `p1BattleDeckZonePosition` 在左下角，`p2BattleDeckZonePosition` 在右下角。
建议：

- 手牌区放在屏幕底部中央（横跨左右）
- 牌库区缩小为角落的小堆叠（仅作视觉参考）

## 文件变更清单

| 文件                                           | 变更类型 | 说明                       |
| ---------------------------------------------- | -------- | -------------------------- |
| `lib/scene/battle/battle.dart`                 | 大幅修改 | 核心战斗流程改造           |
| `lib/scene/battle/battledeck_zone.dart`        | 修改     | 牌库区职责调整             |
| `lib/scene/battle/hand_zone.dart`              | 新建     | 手牌区组件                 |
| `lib/scene/battle/character.dart`              | 轻微修改 | `onTurnStart` 签名可能不变 |
| `lib/ui.dart`                                  | 修改     | 新增手牌区布局常量         |
| `lib/data/common.dart`                         | 修改     | 新增牌库大小常量           |
| `scripts/main/data/character/battle_entity.ht` | 修改     | 牌库生成改为固定10张       |
| `lib/app.dart`                                 | 轻微修改 | 移除 `isAutoBattle` 参数   |
| `lib/scene/battle/prebattle/prebattle.dart`    | 轻微修改 | 移除自动战斗相关UI         |

## 风险与注意事项

1. **异步等待玩家输入**: `_startTurn()` 当前是 async 顺序执行，改造后需要在玩家选择处 `await completer.future`。确保 UI 事件循环不被阻塞。
2. **卡牌数据共享**: 手牌和牌库共享 `CustomGameCard` 实例。
3. **敌方手牌可见性**: 保持背面朝上，只有当对方打出一张牌时（使用setFocus），将此牌翻面

## 决策记录

- **牌库大小**: 固定10张（不随境界变化）
- **每回合抽牌数**: `getHandLimitForRank(rank)` 返回值（3-8张）
- **每回合出牌数**: 1张（不引入费用系统）
- **敌方AI**: 血量<50%优先buff，否则优先attack
- **死气机制**: 与总回合数绑定，每5回合触发
- **自动战斗**: 完全移除
- **手牌卡牌**: 不clone，使用引用，加入手牌时从牌库区移除，并加入手牌区，同时播放卡牌移动的动画。
- **牌库区展示**: 保留，改为角落堆叠（背面朝上，带有两个像素的微小偏移来体现牌堆）
