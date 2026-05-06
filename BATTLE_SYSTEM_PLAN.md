# 战斗系统改造计划：费用 + 弃牌堆 + 多牌回合

## 概述

将当前"每回合出一张牌、全洗回牌库"的模式，改造为杀戮尖塔模式：递增费用、回合内可出多张牌、弃牌堆机制。

## 设计要点回顾

- **费用**：每回合从 1 开始递增，上限 = rank + 2，卡牌消耗 = rank + 1
- **弃牌堆**：打出的牌 + 回合结束剩余手牌 → 弃牌堆；牌库抽干时弃牌堆洗入牌库
- **多牌回合**：费用允许时玩家可连续出牌，主动点击"结束回合"结束；敌方 AI 自动出到出不起为止
- **敌方手牌**：不可见（牌背），打出时翻转展示
- **费用 UI**：单个酒瓶 SpriteButton，带数字
- **双资源体系**：基础费用（出牌门槛）+ 气资源（效果内消耗/生成）

---

## 新 UI 布局

```
英雄侧（左下）：                         敌方侧（右下）：

[酒瓶·费用]                                         [酒瓶·费用]
[牌库][手牌 → → →]                     [← ← ← 手牌][牌库]
```

- **牌库区**：屏幕左下角贴边（英雄）/ 右下角贴边（敌方）
- **手牌区**：紧挨牌库右侧（英雄）/ 左侧（敌方），向屏幕内展开
- **弃牌堆**：移到**旧牌库位置**（头像下方区域），进入弃牌堆的牌缩小至约 60%
- **费用酒瓶**：手牌区上方，靠屏幕边缘对齐

---

## 文件变更清单

### 新建文件

#### 1. `lib/scene/battle/energy_display.dart`

```
EnergyDisplay extends GameComponent
  - 内部一个 SpriteButton（酒瓶图标 + 数字文本）
  - 构造函数：position, isHero
  - update(int current):
    current > 0: spriteId='battle/bottle.png', hoverSpriteId='battle/bottle_hover.png', text='$current'
    current == 0: spriteId='battle/bottle_empty.png', hoverSpriteId='battle/bottle_empty_hover.png', text=null
  - 无 onTap（纯展示）
```

#### 2. `lib/scene/battle/discard_zone.dart`

```
BattleDiscardZone extends PiledZone
  - pileStyle: PileStyle.stack
  - size: GameUI.battleDeckZoneSize（位置用旧牌库位置）
  - piledCardSize: GameUI.battleDeckZoneSize * 0.6（比牌库牌小）
  - pileOffset: Vector2(-0.6, -0.6)
  - 无需 shuffle，保持弃牌顺序
  - visible: 有牌时才可见
```

### 修改文件

#### 3. `lib/ui.dart` — 新增/调整 UI 常量

```dart
// 费用酒瓶
static late Vector2 battleEnergyBottleSize;   // 约 36x48
static late Vector2 p1EnergyDisplayPosition;  // 英雄侧，手牌区上方，靠左
static late Vector2 p2EnergyDisplayPosition;  // 敌方侧，手牌区上方，靠右

// 牌库区新位置 — 屏幕左下/右下角贴边
static late Vector2 p1BattleDeckZonePosition;
static late Vector2 p2BattleDeckZonePosition;

// 手牌区新位置 — 紧挨牌库区
static late Vector2 p1HandZonePosition;
static late Vector2 p2HandZonePosition;

// 弃牌堆 — 使用旧牌库位置（头像下方）
static late Vector2 p1BattleDiscardZonePosition;
static late Vector2 p2BattleDiscardZonePosition;
```

`setSize()` 中补充以上位置的计算逻辑。

#### 4. `lib/scene/battle/character.dart`

新增字段（无新方法）：

```dart
int currentEnergy = 0;   // 当前剩余费用
int maxEnergy = 0;       // 费用上限 = rank + 2
int turnCounter = 0;     // 该角色已行动回合计数
```

#### 5. `lib/scene/battle/hand_zone.dart`

新增方法或参数，支持敌方手牌不可见 + 无交互：

```dart
// 新增布尔参数
final bool isFlipped;  // 敌方手牌区设为 true

// setupCardInteraction 中：isFlipped 时不添加 tap/preview 交互
// clearCardInteraction 同理跳过
```

或直接在 `battle.dart` 中不为 `enemyHandZone` 设置 `onCardSelected`，并保持卡牌 `isFlipped = true`。

#### 6. `lib/scene/battle/battle.dart` — 核心改动

##### 6a. 新增成员

```dart
late final BattleDiscardZone heroDiscardZone, enemyDiscardZone;
late final EnergyDisplay heroEnergyDisplay, enemyEnergyDisplay;
late final SpriteButton endTurnButton;

// 多牌出牌控制
Completer<CustomGameCard>? _playerCardSelection;
Completer<bool>? _playerTurnAction;  // true=出牌, false=结束回合
```

##### 6b. `onLoad()` 变更

- 创建弃牌堆（初始空，不可见，`world.add`）
- 创建费用酒瓶（`camera.viewport.add`）
- 创建 `endTurnButton`（`camera.viewport.add`，默认不可见）
- `endTurnButton.onTap` → 触发 `_playerTurnAction?.complete(false)`
- `enemyHandZone` 不设置 `onCardSelected`，卡牌保持 `isFlipped = true`
- 调整已有组件的新位置常量

##### 6c. `_setEnergy(BattleCharacter character)`

```dart
void _setEnergy(BattleCharacter character) {
  character.turnCounter++;
  character.maxEnergy = (character.data['rank'] as int) + 2;
  character.currentEnergy = min(character.turnCounter, character.maxEnergy);
  // 更新对应 EnergyDisplay
  (character.isHero ? heroEnergyDisplay : enemyEnergyDisplay)
      .update(character.currentEnergy);
}
```

##### 6d. `_shuffleDiscardIntoDeck`

```dart
void _shuffleDiscardIntoDeck(
    BattleDeckZone deck, BattleDiscardZone discard) {
  for (final card in discard.cards.toList()) {
    discard.removeCardByIndex(card.index);
    card.isFlipped = true;
    deck.cards.add(card);
  }
  deck.shuffle();
}
```

##### 6e. `_drawCardsToHand`

替代原 `_drawCards` + `_addCardsToHand` 组合。逻辑：

```dart
Future<int> _drawCardsToHand(
  BattleDeckZone deck,
  BattleDiscardZone discard,
  HandZone hand,
  int count,
) async {
  int drawn = 0;
  while (drawn < count) {
    if (deck.cards.isEmpty) {
      if (discard.cards.isEmpty) break;
      _shuffleDiscardIntoDeck(deck, discard);
    }
    final card = deck.cards.removeLast() as CustomGameCard;
    if (hand == enemyHandZone) {
      card.isFlipped = true; // 敌方手牌保持背面
    } else {
      card.isFlipped = false;
    }
    hand.cards.add(card);
    card.pile = hand;
    hand.setupCardInteraction(card);
    drawn++;
  }
  await hand.sortCards();
  return drawn;
}
```

##### 6f. 重写 `_startTurn()`

新回合流程（伪代码）：

```
_setEnergy(currentCharacter)
apply start_turn status effects

// 抽牌
_drawCardsToHand(deck, discard, hand, rank+2)

if hand not empty:
  if hero turn:
    // 循环出牌
    while currentEnergy > 0:
      enable hand card interactions (只对可负担的牌)
      if no affordable cards → break

      show endTurnButton
      _playerTurnAction = Completer<bool>()
      _playerCardSelection = Completer<CustomGameCard>()

      result = await _playerTurnAction.future
      if result == false → break

      card = await _playerCardSelection.future
      currentEnergy -= card.cost
      energyDisplay.update(currentEnergy)

      // 打出卡牌
      card.removeFromPile()
      hand.clearCardInteraction(card)
      await character.onTurnStart(card, isExtra: false)
      await character.onTurnEnd(card)

      // 进弃牌堆
      discard.placeCard(card)
      card.isFlipped = true

    hide endTurnButton
    disable all hand card interactions

  else (enemy turn):
    while currentEnergy > 0:
      affordable = hand cards where cost <= currentEnergy
      if affordable empty → break

      card = _enemySelectCard(affordable)
      currentEnergy -= card.cost
      energyDisplay.update(currentEnergy)

      // 打出前翻到正面给玩家看
      card.isFlipped = false
      await Future.delayed(600ms)

      card.removeFromPile()
      hand.clearCardInteraction(card)
      await character.onTurnStart(card, isExtra: false)
      await character.onTurnEnd(card)

      discard.placeCard(card)
      card.isFlipped = true

// 回合结束
apply end_turn status effects
// 剩余手牌 → 弃牌堆
for each card in hand:
  hand.clearCardInteraction(card)
  discard.placeCard(card)
  card.isFlipped = true
await hand.clearHand()

// 检查 extraTurn，若需要则重入本流程
switch turn, check battle end, roundCount++
```

##### 6g. `_onHeroCardSelected` 修改

```dart
void _onHeroCardSelected(CustomGameCard card) {
  if (card.cost > currentCharacter.currentEnergy) return; // 负担不起，忽略
  _playerCardSelection?.complete(card);
  _playerTurnAction?.complete(true);
}
```

##### 6h. `_enemySelectCard` 修改

签名接受 `List<CustomGameCard>`（已由调用方过滤可负担的牌），内部逻辑不变。

##### 6i. 移除的方法

- `_returnCardsToDeck` — 手牌进弃牌堆，不再回牌库
- `_drawCards` / `_addCardsToHand` — 合并至 `_drawCardsToHand`

##### 6j. `_cleanupForRestart` 修改

清除手牌 + 弃牌堆，所有牌回牌库。

##### 6k. `_onBattleEnd` 修改

隐藏 `endTurnButton`、弃牌堆、费用显示。

---

## 需调整的细节

1. **敌方手牌**：`enemyHandZone.onCardSelected = null`，所有敌方手牌 `isFlipped = true`，`setupCardInteraction` 跳过 preview/hover
2. **打出时翻面**：敌方出牌前 `card.isFlipped = false` 给玩家看清，进入弃牌堆后恢复 `true`
3. **弃牌堆缩略**：`piledCardSize = deckZoneSize * 0.6`
4. **endTurnButton**：可用现有 `ui/button1.png` sprite，文字 `结束回合`，位于屏幕中央偏左（在HandZone的focusedPosition左边或者右边，大小为GameUI.hugeIndent，文字为'结束\n回合'）；仅英雄回合可见
5. **手牌上限 10**：当前 draw = rank+2(≤5)，天然不触达；预留 `hand.cards.length >= 10` 时跳过抽牌
6. **extraTurn**：重入回合流程时重新设定 energy 并重抽牌

---

## 验证步骤

1. `flutter build windows --debug` 编译通过
2. 进入战斗，确认：
   - 牌库/手牌在新位置，弃牌堆在旧牌库位置（有牌时可见）
   - 第 1 回合英雄费用 = 1，酒瓶显示 "1"
   - 选牌出牌 → 费用减少，酒瓶数字更新
   - 选负担不起的牌 → 无响应
   - 点击"结束回合" → 剩余手牌进弃牌堆
   - 敌方手牌全部背面，打出的瞬间翻到正面
   - 敌方 AI 自动出牌到费用不足
   - 牌库抽干时弃牌堆洗入牌库
   - 弃牌堆卡牌明显比牌库牌小
3. 重启战斗 → 弃牌堆清空，牌全部回牌库
4. 战斗结束后 UI 正常清理
