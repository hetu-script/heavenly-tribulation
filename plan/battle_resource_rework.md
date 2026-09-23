# 战斗费用体系重构：单资源费用模型

> 本文档是战斗费用体系改革的唯一权威依据。
> `scripts/main/cardgame/card.ht`、`lib/data/common.dart`（kGenreCostColors）、
> `lib/data/game.dart`（coloredCost 校验）中"见 plan/battle_resource_rework.md"的引用均指向本文档。
> 与天赋树重构的关系：各流派气的**产出**规则由 `plan/skill_tree/` 的天赋树初始节点实现，
> 本文档只定义**费用**侧模型；两文档的数值锚点必须保持一致（见第 3 节）。

## 1. 决策摘要

| # | 决策 | 状态 |
|---|------|------|
| 1 | 每张卡只花一种资源：流派卡 = 纯有色气，中立卡 = 纯元气 | 已拍板 |
| 2 | 费用公式：流派卡 = rank 点有色气；中立卡 = rank+1 点元气 | 已拍板 |
| 3 | 所有卡的费用在数据层显式写入 `coloredCost`（含 life 键），不再依赖自动推导 | 已拍板 |
| 4 | 多色卡能力保留（支付引擎保持泛化），现阶段不设计、不禁止 | 已拍板 |
| 5 | 法身（avatar）基础卡组改为纯元气费用；现有怒气/煞气费用是旧设计残留 | 已拍板 |
| 6 | 炼魂（vitality）：战初一次性大量煞气 + 每回合限抽 3 张（battleDrawBonus: -2） | 已拍板，等测试再调 |
| 7 | 移除元气的回合结束回血效果；死气（energy_negative_life）保留不动 | 已拍板 |
| 8 | 中立治疗卡 heal 改为 rank: 1 | 已拍板 |
| 9 | 新增中立绝世卡：永远 0 费、最低 rank1，消耗所有元气，每点回复 0.1×等级 比例生命 | 已拍板 |
| 10 | 有色气"持有增伤"双重设计保留 | 已拍板 |
| 11 | 圣化费用特例：未实现，暂缓 | 暂缓 |

## 2. 新费用模型

### 2.1 单资源规则

- **流派卡**（genre ∈ spellcraft/swordcraft/bodyforge/vitality/avatar）：费用 = **rank 点该流派有色气**。
  - 颜色映射：悟道=spell（灵气）、御剑=weapon（剑气）、锻体=unarmed（怒气）、炼魂=curse（煞气）。
  - 法身例外：基础卡组**不花有色气**（见 2.4），按中立卡规则花元气。
- **中立卡**（无 genre）：费用 = **rank+1 点元气**（life）。
- 推论：
  - 所有有色牌至少 1 费（流派卡 rank ≥ 1）。
  - 中立卡至少 1 费（rank0 → 1 元气）。
  - rank0 卡免费：默认拳法（blank_default）、placeholder 通过显式 `coloredCost: { life: 0 }` 实现免费，
    作为任何情况下的保底行动（注意：中立卡模型是 rank+1，免费必须显式写 0，不能依赖 rank0 推导）。
- **多色卡**：未来可能设计（一张卡花两种以上有色气）。引擎端 `_canPayCardCost`/`_payCardCost`
  （lib/scene/battle/battle.dart:838/880）本就按映射泛化处理，无需改动；
  数据校验对混费卡只报警告、不算错误。

### 2.2 数据层全部显式

所有卡的费用**显式写在词条数据的 `coloredCost` 字段中**（元气也以 life 键写在这里），
目的是"数据即文档"——读 cards.json5 即可见每张卡的费用模型，无需反推代码逻辑。

标准公式（沿用现有 `{base, rankIncrement}` 公式机制，随卡牌实例 rank 缩放）：

- 流派有色气标准公式：`coloredCost: { <流派色>: { base: 0, rankIncrement: 1 } }` → 费用 = rank
- 元气标准公式：`coloredCost: { life: { base: 1, rankIncrement: 1 } }` → 费用 = rank+1
- 特例卡允许使用其他公式或固定数值（rankIncrement 机制保留，用于设计与标准模型不同的卡）。

`updateCardCost`（scripts/main/cardgame/card.ht:23）职责随之变化：

- 只做**公式求值 + 写入卡牌实例的 `card.coloredCost`**（life 键保持在首位）。
- 现有的缺省自动推导（按 genre 拆色、_costLadder 阶梯）可以保留作兜底，但数据层不再依赖它。
- **需要支持显式 0 费用**：当前实现对 `amount > 0` 才采纳，显式 `life: 0` 会被过滤并回退默认推导；
  新绝世卡（第 4.3 节）需要"费用恒 0"，应改为"键存在即采纳"。

### 2.3 现有特例

| 特例 | 规则 | 说明 |
|------|------|------|
| 符箓（genre: scroll） | 固定 1 元气 | player.ht:177 已显式写死，不受本次改革影响 |
| 圣化（isExalted） | 费用变 3 点无色 | **未实现**，仅存在于 cards.json5:47-51 的头部注释；暂缓，实现时再并入本模型 |
| 新绝世卡 heal_vigor_all | 永远 0 费（特例，不走中立 rank+1 模型），最低 rank1，效果消耗所有元气 | 见 4.3 |

### 2.4 法身（avatar）卡组

- 基础（非变身）卡组 = 纯元气费用（流派标签保留，仍影响词条池、天赋互动；只是费用走元气）。
- 现有法身卡的 unarmed/curse 双色费用（kGenreCostColors，lib/data/common.dart:371）是旧设计残留，
  全部改为元气费用；`kGenreCostColors` 中 avatar 条目移除（多色拆分推导代码保留，供未来多色卡使用）。
- 法身不产出任何有色气；**阴气负债机制**（以获得阴气为代价强行打出有色卡）留给
  "打有色卡"的场景（跨流派卡、未来的变身卡），实现可参考死气模式
  （energy_negative_life：回合开始失去生命并耗层）。变身卡组的设计待法身流派正式设计时再定。
- 设计后果（已确认接受）：变身前法身是全流派节奏最慢的（只有每回合 3 元气），
  元气产出词条/卡牌（battleEnergyBonus、先天功等）天然成为法身的核心经济。

## 3. 各流派经济参数锚点

费用模型变更后，每点有色气的购买力翻倍（1 气 = 1 整卡），产出数值必须按新锚点核对。

**稳态产出目标：每回合 ≈ 2.5 ~ 3.5 气**，即支撑"rank2 + rank1 各一张"或"隔回合一张 rank4-5"。

| 流派 | 产出模型（由天赋树初始节点实现） | 备注 |
|------|------|------|
| 悟道 | 每回合按灵力产出灵气 | 缩放公式在天赋树重构时定，需有下限保底 |
| 御剑 | 战初：身法÷10 剑气；之后按上回合打出武器牌数产出 | 滞后产出 |
| 锻体 | 战初：体魄÷10 怒气；之后按上回合受伤产出 | 滞后产出；怒气持有代价（受伤+5%/层）保留 |
| 炼魂 | 战初一次性获得大量煞气（池制，未用量返池） | **每回合限抽 3 张**：初始节点挂 `battleDrawBonus: -2`（机制现成，battle.dart:1206 = kBattleDrawCount(5) + stats.battleDrawBonus；词条已存在于 passives.json5:1054）。需验证负值词条在数值公式/校验中可行。池尽后无余烬产出——保持现状，等测试再调 |
| 法身 | 无有色产出 | 元气经济 + 阴气负债（2.4） |

NPC 依赖天赋树重构中的"自动分配初始节点"，否则有色卡打不出（硬依赖，属天赋树重构范围）。

## 4. 元气改动

### 4.1 移除回合结束回血

- 实现位置：`lib/scene/battle/character.dart` `_settleTurnEndResources()` 中的回血块
  （每剩余 1 层回 2% 生命上限，每层至少 1 点）。
- **函数本身保留**：`_settleTurnEndResources` 作为回合结束资源结算钩子保留（当前为空实现），
  已注释的灵气溢出（overflowed_mana_*）设计以注释形式留在函数体内——
  后续悟道流派境界节点会有相关互动，届时在该钩子中启用。
- 数据/文案同步：`assets/data/status_effect.json5:585` 的注释、
  `assets/locale/zh/rpg/status_effect.json` 中 `status_energy_positive_life_description`。
- 动机：单费制下纯流派卡组的元气基本花不掉，每回合稳定白回 6%+ 生命上限会压死
  chip damage/DoT 设计空间，且"少打牌 = 多回血"激励扭曲。治疗应成为构筑选择而非全局规则。
- 死气（energy_negative_life，回合开始失血耗层）**保留不动**。

### 4.2 heal 卡改为 rank 1

- `cards.json5:536` 的 `heal`（中立治疗卡，无 rank 字段）补 `rank: 1`，
  与 energy_positive_spell 等现有做法一致。
- 按中立模型费用 = rank+1 = **2 元气**（满足"至少 1 元气"的意图）。

### 4.3 新增中立绝世卡：元气治疗

| 项 | 内容 |
|----|------|
| id | `heal_vigor_all`（暂定） |
| 流派 | 无（中立），kind: xinfa |
| isUnique | true（卡组限一张；命名遵守绝世卡约定：`assets/locale/zh/rpg/battlecard.json` 新增 `uniquecard_heal_vigor_all` 键，否则卡名显示原始键名） |
| rank | 最低 rank1（数据中 `rank: 1`）；本卡为特例，不走中立卡 rank+1 费用模型 |
| 费用 | **永远 0 费**：显式 `coloredCost: { life: 0 }`（依赖 2.2 的显式 0 支持），卡面费用恒 0 |
| 效果 | 打出时消耗自身所有元气，每点回复 **0.1 × 卡牌等级** 比例的生命上限（等级 1 = 每点 10%，随等级成长） |
| 实现 | `valueData: [{ increment: 10 }]`——词条值按**百分数**存储（= 10 × 等级，显示 `每点回复 {0}%`），脚本内 ÷100（与 heal_lifeMax 同惯例）；`scripts/main/cardgame/card_script.ht` 新增脚本函数 `heal_vigor_all`：读取 `energy_positive_life` 层数 → 全部移除 → 按 层数 × 词条值/100 × lifeMax 治疗。消耗走效果而非费用（费用系统无法表达动态费用），卡牌描述须写明"消耗所有元气"（已实现：卡名归元功，插画临时复用 xinfa_heal.png） |
| 定位 | 元气回血移除后的构筑级治疗出口；与先天功（产元气）形成组合；法身（纯元气经济）的天然大招 |

### 4.4 经济牌费用连带变化（需人工核对数值）

- 产气卡（energy_positive_spell/weapon/unarmed/curse 等，中立、rank:1）按中立模型
  费用 = 2 元气：转换率（2 元气 → 1+ 有色气）比旧模型差，但元气对流派卡组本是闲置资源，
  可接受；上线后测试再调。
- 先天功（energy_positive_life，绝世、rank:2）按模型费用 = 3 元气，"花元气产元气"
  的数值需人工核对其净收益。

## 5. 有色气双重设计：保留

- **持有增伤**：灵气/剑气/怒气/煞气在打出匹配 cardType 的伤害牌时 +5 基础伤害/层
  （status_script.ht:317-344）；无极之气不限类型；怒气另有代价（自身受伤 +5%/层）。
  "花气打牌 vs 攒气增伤"是每回合的核心张力，单费制下决策更纯粹（每点气的机会成本 = 1 整卡）。
- **生命周期**：回合开始清空所有阳气；煞气未用量返回 karma 池。维持不动。

## 6. 改动清单（已全部实施）

- [x] `scripts/main/cardgame/card.ht`
  - 重写 `updateCardCost`：只做显式公式求值；支持显式 0 费用（键存在即采纳，0 值条目不写入费用表）；
    缺省兜底改为同模型推导（流派色 rank 点 / 无流派 rank+1 元气）；`_costLadder` 阶梯已删除。
- [x] `assets/data/cards.json5`
  - 头部费用注释重写（新模型 + 标准公式 + 特例说明）。
  - 全部 86 张卡费用显式化：45 张流派卡公式改写为 {base: 0, rankIncrement: 1}（保留原色，含跨色设计）；
    11 张法身卡改为元气 {base: 1, rankIncrement: 1}；23 张中立卡与 4 张炼魂尾部卡补显式费用；
    placeholder/blank_default 显式 `life: 0`。
  - `heal` 补 `rank: 1`。
  - 新增 `heal_vigor_all` 词条（isUnique，见 4.3；插画临时复用 xinfa_heal.png）。
  - isExalted 注释标注"未实现，暂缓"。
- [x] `lib/data/common.dart`：`kGenreCostColors` 移除 avatar 条目；更新注释。
- [x] `lib/data/game.dart`（`_validateBattleCardCostColored`）：按新口径——流派卡 Σcolored == rank、
  中立卡（含法身）life == rank+1；rank 缺失按 0 折算；全 0 免费卡跳过；混费/多色只给软警告。
- [x] `lib/scene/battle/character.dart`：删除 `_settleTurnEndResources` 中的回血块；
  函数本身保留为空实现的回合结束资源结算钩子（灵气溢出设计以注释形式留在函数体内，
  待悟道境界节点启用），调用处保留。
- [x] `assets/data/status_effect.json5`：energy_positive_life 注释移除回血描述。
- [x] `assets/locale/zh/rpg/status_effect.json`：`status_energy_positive_life_description` 同步。
- [x] `assets/locale/zh/rpg/battlecard.json`：新增 `uniquecard_heal_vigor_all`（归元功）及
  `affix_heal_vigor_all` 描述键；`exhaustResource_description` 改写为单资源模型。
- [x] `scripts/main/cardgame/card_script.ht`：新增 `heal_vigor_all` 函数（词条值按百分数存储，脚本内 ÷100）。
- [x] 文档：`docs/docs/mod/battle/readme.md`（流程第 6/9 步、费用段、溢出段）、
  `docs/docs/how2play/rpg/battle/resource/readme.md`（费用模型/产出模型/溢出/流派表重写）。
- [x] `lib/scene/battle/battle.dart` 支付端：**零改动**（泛化映射已支持）。
- [x] UI 卡面费用渲染：**零改动**（按映射泛化绘制）。

## 7. 暂缓项（明确不做）

- 圣化（isExalted）费用特例：未实现，实现时再并入本模型。
- 多色卡设计：引擎能力保留，不设计不禁止。
- 炼魂池尽后的"余烬"产出、法身变身前的效费补偿：等实装测试后再调。
- 法身变身卡组：随法身流派正式设计。
- 各流派初始节点的资源产出实现、NPC 自动分配节点：属天赋树重构（plan/skill_tree/）范围。

## 8. 验证

- `flutter analyze` 无新增问题。
- `python build.py` 重新编译脚本成功（改了 .ht 必须执行）。
- cards.json5 / status_effect.json5 / locale JSON 解析通过。
- 数据校验（game.dart）对全卡表无错误级报告。
