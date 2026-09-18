# 战斗资源气统一显示（EnergyDisplay 重构）与阴气机制计划

范围：战斗场景中所有资源气（6 阳 6 阴）的显示统一收归 EnergyDisplay 组件；阴气永久化；虚空之气增费机制实现；布局调整。
前置共识（已与作者确认）：

1. **元气**（energy_positive_life，无色费用池）：回合开始自动获得 rank+3，**恒显（0 也显示），并显示上限**。
2. **四色气**（灵/剑/怒/煞）：只有获得时才显示（0 不显示），**无上限**。
3. **无极之气**：特殊气，单独显示；任何有色费用不足时自动抵扣。
4. **阴阳对冲**：获得阴气时先扣减对应阳气；无阳气可扣时以反色图标显示阴气净值。**阴气不再随回合清空，永久存在直到被阳气抵消**（对现行"统一生命周期"的修改）。
5. **虚空之气**（无极的阴气）：只能被无极之气抵消；是**唯一的真正增费机制**——存在时使**所有**有色费用 +1/层，**无上限**（此气极为稀有）。其他阴气没有任何增费效果，它们对费用的影响完全由阴阳对冲体现（阴气抵消阳气，阳气不足自然无法支付）；readme 中"其他阴气使本色费用 +1/层"的描述为废弃设计，从文档中删除。

---

## 现状盘点

**显示侧**：

- `lib/scene/battle/energy_display.dart`：EnergyDisplay 目前只是单个"能量瓶"（SpriteButton + 计数文本），只显示元气层数，位于手牌区上方左右两角（`ui.dart:751-755`）。
- 资源气目前作为 StatusEffect 图标显示在**角色血条下方**（`character.dart` `reArrangeResourceEffects`，:357-374）；阴阳净值/反色已在 StatusEffect 内实现（`status_effect.dart:124-131`，`kNegativeQiInvertMatrix`），对冲逻辑在 `addStatusEffect`（`character.dart:509-517` + `common.dart` `kOppositeStatus`）——这部分机制已就绪，可复用。
- 永久状态图标在能量瓶旁边一排（`reArrangePermanentEffects`，:377-402，锚定 `p1EnergyDisplayPosition`）。

**机制侧**：

- `clearResourceEffects()`（`character.dart:629-640`）目前清空**所有**资源气（含阴气），与共识 4 冲突，需改为只清阳气（煞气返回 karma 池逻辑保留）。
- **增费机制现状**：`_canPayCardCost`/`_payCardCost`（`battle.dart:834-919`）按卡面裸值校验，不读取任何阴气。**虚空之气的增费未实现，需补齐**；其他阴气的增费描述（`docs/docs/mod/battle/readme.md:96-98`、`resource/readme.md` 中"本色费用 +1/层（至多 +2）"）为废弃设计，仅需清理文档。
- **顺带发现的 bug**：`battle.dart:842` `coloredNeeds[entry.key] = coloredNeeds[entry.key] ?? 0 + entry.value`——`+` 优先级高于 `??`，等价于 `?? (0 + entry.value)`，同色系费用在队列中不累积（第二张同色卡的费用被丢弃）。应为 `(coloredNeeds[entry.key] ?? 0) + entry.value`。
- `energy` getter（`character.dart:154`）= 元气层数；`EnergyDisplay.setEnergy` 在战斗开始（battle.dart:650-651）、支付后（:897）、回合开始产出后（:1173）三处调用。

---

## 任务一：EnergyDisplay 重构为资源气行

将 `energy_display.dart` 从"单个瓶子按钮"改为"资源气行"容器（GameComponent），管理 6 个槽位：

| 槽位 | 气 | 显示规则 |
| ---- | -- | -------- |
| 1 | 元气 | 恒显，文本 `当前/上限`（上限定义见"开放问题"） |
| 2-5 | 灵/剑/怒/煞 | 净值为正显示阳气图标+层数；净值为负显示**反色图标**+阴气层数；为 0（不存在）则不显示 |
| 6 | 无极之气 | 单独槽位（视觉上与前五色分隔，如加大间距或分隔线），同净值规则；虚空之气以反色无极图标显示 |

- 图标资源：复用 `status_effect.json5` 中各气状态的 `icon`；反色复用 `kNegativeQiInvertMatrix`（从 `status_effect.dart` 移到公共处或直接在 EnergyDisplay 内引用）。
- 悬浮提示：每个槽位 onMouseEnter 显示对应气的 locale 名称+描述（复用 `status_energy_positive_*`/`status_energy_negative_*` 键，阴气显示时追加阴气描述与增费说明）。
- 数据源与刷新时机：在 `BattleCharacter.addStatusEffect`/`removeStatusEffect` 中，当 `effect.isResource` 时通知对应侧的 EnergyDisplay 刷新（替代现有的 `reArrangeResourceEffects` 调用）；`setEnergy` 的三处旧调用点改为统一刷新。
- 资源状态的 StatusEffect 对象不再 `game.world.add`（纯数据+回调载体），视觉完全由 EnergyDisplay 承担。注意保留 `handleStatusEffectCallback` 的遍历顺序（永久→资源→其他）不变。

## 任务二：布局调整

- `ui.dart`：新增资源气行位置常量（如 `p1QiBarPosition/p2QiBarPosition` 与槽位尺寸，建议槽位 40×40、间距 smallIndent）。
- 资源气行放在**永久状态行上方**：永久状态行当前锚定 `p1EnergyDisplayPosition`（手牌区上方一行），气行再上移一行高度。
- 检查并视情况上移：结束回合按钮（`battle.dart:625-632`，屏幕左中）、出牌展示区（`p1BattleCardUsedPosition`，`ui.dart:785-792`），避免与新的气行重叠。
- `reArrangePermanentEffects` 保持锚定不变或改为锚定气行下沿；删除 `reArrangeResourceEffects`（血条下方不再显示气）。
- 敌方（p2）镜像处理。

## 任务三：阴气永久化

- `clearResourceEffects()`：只清空 6 种阳气（`energy_positive_*`）；阴气（`energy_negative_*`）跳过。煞气返回 karma 池、跳字提示逻辑保留。
- 影响评估（需在文档中注明，属预期行为变化）：
  - **死气**：现存 `energy_negative_life_self_turn_start` 回调（回合开始掉血、消耗 1 层）将每回合持续触发直到被元气抵消——压力从"一次性"变为"持续 Dot"，强度显著上升，数值（5%/层）可能需要后续平衡。
  - 其余阴气（逆灵/止戈/非战/无心/虚空）的攻击削弱同样变为常驻；虚空之气的全体增费（任务四）在被无极之气抵消前常驻生效。
- 文档同步：`docs/docs/how2play/rpg/battle/resource/readme.md` 的"统一生命周期"章节、`docs/docs/mod/battle/readme.md` 流程第 4 步。

## 任务四：虚空之气增费实现 + 文档清理 + 修复队列费用累积 bug

- 实现虚空之气增费（共识 5）：在 `_canPayCardCost`/`_payCardCost`/`_missingCostReport` 中，每色有效有色费用 = `qiCost[色] + 持有者虚空之气（energy_negative_ultimate）层数`，**无上限**。增费部分与卡面费用走同一条支付路径（先扣本色气、缺口由无极抵扣），即增费只改变需求数量，不改变支付顺序。
- 由于阴气永久化（任务三），虚空之气的增费在被无极之气抵消前**常驻生效**，这是有意的压力设计（获取极为稀有）。
- 清理文档中其他阴气的增费描述：`docs/docs/mod/battle/readme.md`（费用与增费段落）、`docs/docs/how2play/rpg/battle/resource/readme.md`（阴气行中的"本色费用 +1/层"列，虚空行保留并改为"所有有色费用 +1/层，无上限"）、`card/readme.md`（费用小节）；其他阴气对费用的影响统一表述为"阴阳对冲后阳气不足则无法支付"。
- 修复 `battle.dart:842` 的 `??` 优先级 bug（队列同色系费用累积）：改为 `(coloredNeeds[entry.key] ?? 0) + entry.value`。
- 敌方 AI 的 `_canPayCardCost` 过滤自动受益，无需单独处理。

## 任务五：收尾与同步

- 删除 `character.dart` 中 `reArrangeResourceEffects` 及其调用点（资源图标重排逻辑移交 EnergyDisplay）。
- `energy` getter 与 `setEnergy` 调用点清理（battle.dart:650-651、897、1173）。
- 本地化：气行槽位提示若需新键（如"上限"说明文本），在 `assets/locale/zh/rpg/status_effect.json` 补充。
- 文档：`docs/docs/mod/battle/readme.md`（流程与费用章节）、`resource/readme.md`（生命周期与增费规则）与实际实现对齐。

---

## 开放问题

1. **元气"上限"的定义**：当前代码不存在元气上限概念（旧的溢出截断逻辑已在 addStatusEffect 中注释掉）。候选方案：
   - (a) 上限 = 本回合产出（rank+3），仅作显示参照，超出（如灵气转化）照常持有；
   - (b) 新增 stats 属性（如 `vigorMax`），获得时截断——会改变机制，需另议。
   建议先用 (a) 纯显示方案。
2. **死气永久化后的数值平衡**（见任务三影响评估），建议实际手感测试后决定是否调整 5%/层。
3. 气行槽位的美术（分隔样式、反色效果在纯色调图标上的辨识度）需实际效果确认。

## 附带设计问题结论（气的双重作用：攻击加成 + 费用）

**结论：保留双重作用，不拆分为纯费用 + 独立 buff 系统。** 理由详见讨论记录，要点：持有即增益、花费即放弃增益的机会成本是该战斗系统的核心张力；现有机制（怒气防御侧风险、滞后产出、对方可见残留、阴阳对冲）均围绕双重作用构建；拆分会引入与 enhance/weaken 平行的第三套增伤体系，得不偿失。
