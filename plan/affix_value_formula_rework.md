# 词条数值公式重构计划（等级与境界）

> 目标：让「升级」成为全境界有感的机制，同时保持数据膨胀可控。
> 决策记录：
> - 整体指数公式：`value = (base + increment × (level − minLevelForRank(rank))) × rankBaseScale ^ rank + rankIncrement × rank`
> - `rankBaseScale = 1.3`（化神底数 ≈ rank0 的 3.7 倍）
> - 费用公式与词条数值公式**脱钩**——费用用**独立的 `calcCostValue` 函数**（旧的线性公式），不走 `calcAffixValue`，两函数不混在一起
> - 战斗内升级允许突破卡牌等级上限（临时，深拷贝不污染卡库）
> - 战斗内升级每次 **+1 级**（不用 +4），公式保证任何境界 +1 都有感
> - 数据文件（cards/card_affixes/passives json5）**零改动**
> 本项目不考虑存档向后兼容，无需迁移旧数据。

## 一、现状问题

### 1.1 现公式

```
value = base + increment × level + rankIncrement × rank
```

- `base` 是常数：同一词条在 10 级和 55 级时底数完全相同，跨境界成长全靠 `increment × level` 线性爬行。
- `increment` 不敢写大（怕高等级爆炸），于是低等级 +1 级提升约 5%，且常被 `.floor()` 吞成 0。
- 结果：「升级」类词条/天赋（抱真守一、规划中"再次使用：升级"）打到卡牌上经常无可见变化。

### 1.2 等级区间（保持不变，本计划不动）

| 境界 rank | min | max | 区间宽 |
|---|---|---|---|
| 0 无 | 0 | 15 | 16 |
| 1 凝气 | 10 | 25 | 16 |
| 2 筑基 | 20 | 35 | 16 |
| 3 结丹 | 30 | 45 | 16 |
| 4 还婴 | 40 | 55 | 16 |
| 5 化神 | 50 | 65（代码）/ 100（文档，不一致，见 §五） | 16 |

相邻境界 5 级重叠（用户确认保留）。

## 二、新公式（最终版）

```
value = (base + increment × max(0, level − minLevelForRank(rank))) × rankBaseScale ^ rank + rankIncrement × rank
```

- `rankBaseScale = 1.3`，常量定义在 `scripts/main/data/common.ht`。
- **整个"底数 + 等级项"作为一体按境界指数缩放**：含义 = "这张卡在 rank0 时值 base + increment×等级，每破一境整体 ×1.3"。
- `level < minLevelForRank(rank)` 时相对等级按 0 计，不出现负增量。
- `rankIncrement` 语义不变（按境界线性叠加的强力词条通道，DESIGN_NOTE 规则继续有效：天赋树节点不得使用）。

### 2.1 核心性质：区间内每级相对提升恒定，且区间末与破境平滑衔接

在某一境界内，+1 级相对提升 = `increment×1.3^rank / 当前数值`，指数项分子分母约掉，**与 rank 无关**：
区间起点（relativeLevel=0）时 = `increment/base`，区间满级（relativeLevel=15）时 = `increment/(base+15×increment)`。
对 punch_attack（base:7, inc:0.7）：起点 10.0%、满级 4.0%——**同一境界内每级提升恒定，且任何境界都相同**。

更妙的是区间衔接：
- rank0 满级（lv15）= 17.5；rank1 下限（lv10，相对 0）= 7×1.3 = 9.1；rank1 满级（lv25，相对 15）= 17.5×1.3 = 22.75。
- 即 **rank1 区间 [9.1, 22.75] 与 rank0 满级 17.5 重叠**——这就是「低境界满级神装可以越级」的数学表达，5 级重叠的手感被公式自然保留。
- 相邻境界同相对等级处恒 ×1.3（如 rank1 满级 22.75 = rank0 满级 17.5 × 1.3），破境跃迁稳定。

绝对增量随境界放大（凝气 +0.91 点 / 化神 +2.6 点），符合「高境界数字更大」的直觉。战斗中 +1 级在任何境界都醒目——这就是用户要的「每次 +1 且保证有感」，公式天然给出，无需保底补偿。

总跨度 1.3^5≈3.7 封顶，膨胀可控。

### 2.2 数值标定对照（punch_attack {base:7, increment:0.7}）

| rank | level | 旧值 | 新值 | 说明 |
|---|---|---|---|---|
| 0 | 0 | 7 | 7.0 | 一致 |
| 0 | 15 | 17.5 | 17.5 | 一致 |
| 1 | 10 | 14 | 9.1 | 凝气下限（相对0），低于 rank0 满级 |
| 1 | 25 | 24.5 | 22.75 | 凝气满级，仍低于旧值但区间更陡 |
| 2 | 35 | 31.5 | 29.6 | 较低 |
| 3 | 45 | 38.5 | 38.4 | 接近 |
| 4 | 55 | 45.5 | 50.0 | **反超旧值** |
| 5 | 65 | 52.5 | 65.0 | **反超旧值** |

规律：低段（凝气/筑基下限）新值明显低于旧值，但**高段（还婴/化神满级）新值反超旧值**——
因为 increment 项也被 ×1.3^rank 放大。整体不是单纯「数值变低」，而是「区间内更陡、区间下限更低、上限更高」。
**敌我走同一公式，相对平衡不变**；战斗时长由「区间下限降低」略微拉长（双方起手数值变低），属可接受范围。
若觉得低境界起手数值掉太多，可将 rankBaseScale 微调到 1.35（跨度变陡，区间内相对提升性质不变）。

### 2.3 费用公式脱钩（独立函数）

费用是节奏机制（rank / rank+1 的阶梯设计是有意的），**不应被数值指数影响**。
实现上**另写一个独立函数 `calcCostValue`**，与 `calcAffixValue` 完全分离，不用参数混在一起：

```hetu
/// 计算费用数值（独立函数，与词条数值公式脱钩）：cost = base + increment × level + rankIncrement × rank
/// 费用是节奏机制（rank / rank+1 阶梯），不随词条数值的境界指数缩放
/// level 恒为 0（费用由 rank 决定），故实际 = base + rankIncrement × rank
function calcCostValue(valueData, rank) {
  final base = valueData.base ?? 0
  final increment = valueData.increment ?? 0
  final rankIncrement = valueData.rankIncrement ?? 0
  return base + increment * 0 + rankIncrement * rank   // level 恒 0
}
```

- `card.ht` `_calcCostAmount` 改调 `calcCostValue`（替代原来的 `calcAffixValue(level: 0)`）。
- 现有费用条目多为 `{base:0, rankIncrement:1}`（=rank）或 `{base:1, rankIncrement:1}`（=rank+1），
  故费用 = `base + rankIncrement×rank`，与现状完全一致。
- **结果：coloredCost 数据零改动，费用阶梯不变；词条数值公式可自由迭代而不影响费用。**

### 2.4 天赋树节点（passives）特殊处理

天赋节点无视境界、只按投入点数成长。新公式下若仍传角色 rank，increment 项会被 `minLevelForRank(rank)` 吃掉一截。

- **改动点**：`battle_entity.ht` 三处 `calcAffixValue(passiveData, level: passiveLevel, rank: rank)`
  → 天赋节点改为 `rank: 0`，让 `increment × level` 全额生效（level = 投入点数）。
- 与 DESIGN_NOTE「天赋节点不得用 rankIncrement」一致：天赋节点完全脱离境界维度。

### 2.5 受影响调用点

词条数值走新 `calcAffixValue`；费用走独立的 `calcCostValue`。两函数分离。

| 文件 | 用途 | 是否需改 |
|---|---|---|
| `scripts/main/data/common.ht:146` | `calcAffixValue` 本体 + 新增 `calcCostValue` | **改（新公式 + rankBaseScale 常量；新增 calcCostValue）** |
| `scripts/main/cardgame/card.ht:7` | 费用 `_calcCostAmount` | **改（改调 calcCostValue）** |
| `scripts/main/cardgame/card.ht:273,297` | 卡牌主/额外词条数值 | 否 |
| `scripts/main/data/item/equipment.ht:91,137` | 装备词条 | 否 |
| `scripts/main/data/item/usable.ht:184,221` | 丹药/工具词条 | 否 |
| `scripts/main/data/item/item.ht:148` | 物品通用词条 | 否 |
| `scripts/main/data/character/battle_entity.ht:503,521,806` | 天赋节点 | **改（rank: 0）** |

## 三、战斗内升级：+1 级 + 突破上限

让「升级」关键字对满级卡依然有效，每次 +1 级（公式保证有感），天然可控。

### 3.1 改动点：`scripts/main/cardgame/card.ht` `upgradeCard`

```hetu
/// 升级卡牌等级
/// 永久路径（打造/养剑）clamp 在等级上限；战斗内临时路径（inBattle: true）允许突破上限
/// （战斗用牌是深拷贝，临时升级不污染卡库；增量线性有界）
/// 新公式下 +1 级相对提升全境界恒定（≈ increment/base），无需保底补偿
function upgradeCard(card, {inBattle: false}) {
  if (!inBattle) {
    final maxLevel = maxLevelForRank(card.rank)
    if (card.level >= maxLevel) return   // 永久路径满级不升
  }
  card.level += 1
  _updateAffixValue(card, card.affixes.first)
}
```

- 永久路径（打造、养剑装备升级）保持 clamp。
- 战斗内路径传 `inBattle: true`，突破上限。
- **不需要 floor 保底补偿**：新公式 +1 级相对提升在区间内恒定（区间起点 ≈ increment/base，满级 ≈ increment/(base+15×inc)），且任何境界一致，floor 后必有可见变化（旧公式的「升了等于没升」已随公式重构消除）。

### 3.2 战斗内升级调用点核对

- `lib/scene/battle/character.dart:1398` 抱真守一 `upgradeCard` → 传 `inBattle: true`。
- 规划中的 swordcraft「再次使用：升级」词条 → 走同一入口，每次 +1。
- `refreshHandCardDescription` 已在升级后调用，卡面预测会刷新。

## 四、数据文件：零改动确认

| 文件 | 是否要改 |
|---|---|
| cards.json5 词条数值 | ❌ 新公式直接兼容现有 base/increment |
| card_affixes.json5 | ❌ |
| passives.json5 装备/丹药词条 | ❌ |
| coloredCost 费用 | ❌ calcCostValue 保持旧线性，费用不变 |

唯一可选打磨：若低境界起手数值偏低，微调 rankBaseScale（不动数据）。increment 不必改。

## 五、文档修正

- `docs/docs/how2play/rpg/cultivation/level/readme.md` 化神上限 **100 → 65**（与代码 `maxLevelForRank(5)=(5+2)*10-5=65` 对齐）。代码无需改。
- 卡牌/词条数值说明同步新公式。

## 六、验收清单

- [ ] `calcAffixValue` 新公式实装，`rankBaseScale=1.3`；新增独立 `calcCostValue`（旧线性）。
- [ ] 费用阶梯与改前完全一致（抽查各 rank 流派卡/中立卡费用）。
- [ ] 各境界主词条数值符合 §2.2 标定表（区间内每级提升恒定，区间末与破境 ×1.3 衔接）。
- [ ] 天赋节点走 `rank:0`，投入点数增量全额生效。
- [ ] 装备/丹药/工具词条数值符合各境界预期。
- [ ] 战斗内升级 +1 突破上限，满级卡有可见数值变化；永久路径仍 clamp。
- [ ] 卡面描述/预测刷新正常。
- [ ] 文档同步（化神上限、数值说明）。

## 七、改动文件汇总

| 文件 | 改动 |
|---|---|
| `scripts/main/data/common.ht` | `calcAffixValue` 新公式 + `rankBaseScale` 常量；新增独立 `calcCostValue` |
| `scripts/main/cardgame/card.ht` | `_calcCostAmount` 改调 calcCostValue；`upgradeCard` 加 inBattle 参数 + 突破上限 |
| `scripts/main/data/character/battle_entity.ht` | 天赋节点 calcAffixValue 改 rank:0（3 处） |
| `lib/scene/battle/character.dart` | 抱真守一调用传 inBattle:true |
| `docs/docs/how2play/rpg/cultivation/level/readme.md` | 化神上限 100→65 |
| `docs/docs/how2play/rpg/**` | 数值说明同步 |

## 八、后续（不在本计划）

- 「再次使用：升级」词条数据落地（cards/card_affixes.json5）→ 属 swordcraft/spellcraft 重构。
- 战斗内临时等级的 UI 呈现（卡面等级角标显示 +N）。
- 若终局手感数值偏低，微调 rankBaseScale（1.3 → 1.35）。
