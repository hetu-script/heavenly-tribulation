# 悟道·绝世卡牌与绝世装备·额外词条设计

> 本文承接 `plan/skill_tree/spellcraft.md`（流派总设计）。
> 目标：把悟道 7 张绝世卡牌与 5 件绝世装备的固定额外词条补完，并补充可进入随机池的通用主词条 / 额外词条。
> 现有系统事实（已逐行核对代码）见 §0；设计原则见 §1；卡牌词条见 §2；装备词条见 §3；补充内容见 §4；落地清单见 §5。

---

## 0. 设计必须服从的实现事实

这些是读代码确认的硬约束，所有设计都在此前提之下。

### 0.1 rank 是玩家的投资等级，不是掉落等级

`upgradeRank`（`scripts/main/cardgame/card.ht:596-660`）会 `card.rank += 1` → `updateCardCost` → 等级与词条重 roll。
因此 **`card.rank` 表示"玩家在这张牌上投入了多少资源"**，掉落只是起点。绝世卡也有数据层 `rank: N` 作为掉落下限，掉落时即 `rank = N`。

**结论：每境界 +1 词条槽不是冗余复杂度，它就是成长曲线本身。** 破境必须留下"可数、可见"的回报（多一条词条），否则只剩数值 ×1.3 的隐性收益。

### 0.2 卡牌与装备的词条成长不同构

|          | 解锁规则                                                                              | 能否成长                                                       |
| -------- | ------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| 绝世卡牌 | `_addPredefinedAffixes`（`card.ht:413-430`）：`targetCount = min(列表长度, rank + 1)` | **能**。破境每次再解 1 条（`card.ht:631` 重调）                |
| 绝世装备 | `createItemById`（`item.ht:130-137`）：`unlockCount = min(列表长度, item.rank + 1)`   | **不能**。装备破境未实现，解锁数在生成时根据当时的物品境界固定 |

### 0.4 数值公式

- **卡牌词条**：`value = (base + increment × (level − minLevelForRank(rank))) × 1.3^rank`
  `minLevelForRank(r) = r == 0 ? 0 : r×10`；rank 5 的 level 区间是 50~65。

### 0.6 专属词条标记需要一行代码

inUnpackable: true字段放**绝世卡牌专属词条数据顶层**

在 `_getSupportAffixes` 加一行 `if (affix.inUnpackable == true) continue` 。

### 0.7 观星的后处理通道

`BattleScene.scry`（`battle.dart:1079-1196`）目前只消费 `options` 的两个键：`chosenCostChange` / `othersCostChange`。且：

- `scryBonus` 是**全局 stats**（`battle.dart:1087` 无差别叠加），装备词条可以用这个，会影响全局其他观星操作
- 选择数**硬编码为 1**，展示数 == 可选数（同一个 `actualCount`），单个 `Completer<CustomGameCard>`。
- 唯一的通用后处理口子是 `self_scry` 状态回调（`battle.dart:1189`），但它**不 await 且状态脚本禁止 async**。
- `scry_then_draw`（`card_script.ht:379-382`）**从不转发 `affix.scryOptions`**——数据到脚本这一段是断的。

→ §2.1 提出一个不依赖这些缺口的统一方案。

### 0.8 元素与异常不对称

`Constants.elementAilments`（`common.dart`）定义了 **7 种元素**：金/木/水/火/土/风/雷。
其中水/火/雷/木分别对应寒冰/火焰/雷电/毒素伤害。而金/土/风则是对应无属性伤害
当前悟道主词条只用了 **5 种**（火/水/雷/风/土），**金、木没有主词条**。
一气化三清的抉择只提供 **水/火/雷** 三种增幅状态。
金属性元素属于御剑的飞剑术的属性，而木属性元素属于炼魂流派的毒系攻击的属性。

---

## 1. 设计原则

沿用项目既有约定（`.agents/skills/battlecard/SKILL.md` §4、`.agents/skills/unique-equipment/SKILL.md` §0）：

1. **正反双段式**：每个绝世 = 强正面 + 限制/代价。
2. **负面类型优先级**：方向性限制（流派软锁、机制互斥）> 对称效果 > 自伤/自异常 > 纯数值惩罚。
3. **专属词条要克制**。专属词条的复用率是 1——7 张卡 × 6 条 = 42 条一次性内容。判定标准：
   - **必须专属**：引用了"本牌特有的中间结果"（如"观星选中的那张牌"）。滚到别的卡上就是死词条。
   - **不该专属**：通用效果（获得防御、回复生命、抽牌）。它们在任何卡上都成立，锁成专属只是白白从随机池里挖掉一条。
4. **列表顺序 = 投资路线图**（卡牌专用）。`affixes[0]`（rank 1 解锁）与 `affixes[1]`（rank 2 解锁）必须让这张卡在下限境界就**像它自己**。把通用生存词条放在末尾。
5. **数值让位于机制**。额外词条优先写"条件 + 效果"，避免纯数值堆叠——纯数值在中立池里已经有了（`defend` `heal` `by_damage_defend` 等 21 条）。

---

## 2. 绝世卡牌的固定额外词条

7 张卡的现状：

| 卡                                              | 数据层 rank      | `affixes` 现状 |
| ----------------------------------------------- | ---------------- | -------------- |
| 天机术 `spellcraft_scry_draw`                   | 1                | `[]`           |
| 相生相克 `spellcraft_ailments_by_used_elements` | 2                | `[]`           |
| 一气化三清 `spellcraft_element_amplify`         | 3                | `[]`           |
| 蓄灵诀 `spellcraft_ailments_to_mana`            | 4                | `[]`           |
| 太上忘情 `spellcraft_handcards_to_mana`         | 5                | `[]`           |
| 紫微斗数 `spellcraft_draw_cards_reduce_cost`    | **无 rank 字段** | **无该键**     |
| 万法归宗 `spellcraft_ultimate_spell`            | 5                | **无该键**     |

> ⚠️ **两处需先修**：
>
> 1. `紫微斗数` 缺 `rank`。它由分支节点 `shuffleIntoDeck` 发放，而 `affixId` 路径**短路了全部过滤**（`card.ht:121`），所以 `this.rank` 保持构造默认值 **0**（`card.ht:107`），`targetCount = min(len, 1) = 1`——**只会解出主词条，一个额外词条都不给**。必须显式补 `rank: N`。按照设计，紫微斗数的rank等同于角色当前境界，这一点应该在将该牌洗入牌库时赋予。
> 2. `万法归宗` 已有 `rank: 5`，但缺 `affixes` 键，同样解不出词条。

### 2.1 天机术（rank 1，规划主题）

**关键实现建议**：把"观星修饰"做成优先级比主词条更高的脚本，然后在词条脚本执行时，会动态修改卡牌本身的`scryOptions`，而在主词条执行时，因为传入的 scryOptions 不同而触发不同层次的效果。

- 词条天然属于卡牌，卡被洗入别的构筑时行为一致；
- 无内容 id 硬编码，符合"数据驱动"分层。

scryOptions 约定字段（均为 `card_affixes.json5` 词条顶层，`script` 可缺省、`callbacks: []`，仅作数据被主脚本读取）：

| scryOptions 字段   | 含义                                                        |
| ------------------ | ----------------------------------------------------------- |
| `scryBonus`        | 本牌观星时额外查看 N 张 (和角色stats中的属性同名，叠加计算) |
| `pickBonus`        | 本牌观星时可选 +N 张                                        |
| `retainChosen`     | 本牌观星选中的牌获得保留                                    |
| `upgradeChosen`    | 本牌观星选中的牌等级 +1                                     |
| `chosenCostChange` | 本牌观星选中牌费用变化                                      |
| `othersCostChange` | 本牌观星未选中牌费用变化                                    |

主脚本（如 `scry_then_draw`）遍历 `card.affixes[1..]` 累加这些字段，一次性传给 `self.scry(...)`，由 Dart 侧统一兑现。

**词条列表**（按解锁顺序）：

**天机术的所有词条都是此卡牌专属词条**，不会出现在其他卡牌上。

| rank | id                             | 效果                                       | 数据                   |
| ---- | ------------------------------ | ------------------------------------------ | ---------------------- |
| 1    | `spellcraft_scry_draw_affix_1` | [专属] 本牌观星选中的牌等级 +{0}           | `upgradeChosen: X`     |
| 2    | `spellcraft_scry_draw_affix_2` | [专属] 本牌观星选中的牌费用 -{0}           | `chosenCostChange: -X` |
| 3    | `spellcraft_scry_draw_affix_3` | [专属] 本牌观星选中的牌获得保留            | `retainChosen: true`   |
| 4    | `spellcraft_scry_draw_affix_4` | [专属] 本牌观星时额外查看 {0} 张           | `scryBonus: X`         |
| 5    | `spellcraft_scry_draw_affix_5` | [专属] 本牌观星可选 {0} 张（展示张数不变） | `pickBonus: X`         |

**设计说明**：

- `_5` 的**多选**是本批设计里唯一的重工程（当前 `Completer<CustomGameCard>` 单选、展示数 == 可选数）。

### 2.2 相生相克（rank 2，轮转/自异常主题）

主词条不变：对**双方**施加随机元素异常，层数 = 本回合已用元素种数。

| rank | id                                             | 效果                                                  | 数据                                    |
| ---- | ---------------------------------------------- | ----------------------------------------------------- | --------------------------------------- |
| 1    | `spellcraft_ailments_by_used_elements_affix_1` | [专属] 本回合每使用过一种元素，本次施加层数 +1        | `valueData: [{base: 1, isFixed: true}]` |
| 2    |                                                | [公共] 自身持有 3 种以上不同元素异常时，获得 1 点灵气 | `valueData: [{base: 3, isFixed: true}]` |
| 3    |                                                | [公共] 自身持有 3 种以上不同元素异常时，抽 1 张牌     | `valueData: [{base: 3, isFixed: true}]` |

**设计说明**：`attack_debuff` / `ailments_by_used_elements` 系的通用脚本可以传"额外层数"参数，不必新写整套。`_3` 与 `water_mend`（清除全部异常）形成对照：相生相克自己清一层换抽牌，是自异常引擎的**微调节流阀**，避免异常堆到必须用水疗术清场。

`_5` 是"水疗术/清浊"路线的回报，让"铺异常→清异常"的两张牌形成闭环。

### 2.3 一气化三清（rank 3，元素专注主题）

主词条不变：抉择水/火/雷之一，本回合双方造成的该元素伤害 +{0}%。

| rank | id                                   | 效果                                                            | 数据                                             |
| ---- | ------------------------------------ | --------------------------------------------------------------- | ------------------------------------------------ |
| 1    | `spellcraft_element_amplify_affix_1` | 抉择后，下一次受到该元素伤害时获得护盾                          | `valueData: [{base: 1}]`                         |
| 2    | `spellcraft_element_amplify_affix_2` | 对手的下个回合使用你所选元素牌时，你的下个回合额外获得 1 点灵气 | 需状态承载                                       |
| 3    | `spellcraft_element_amplify_affix_3` | 抉择后，本回合下一张所选元素牌费用 -1                           | 复用 `applyTurnCostModifier`（现有零调用方通道） |
| 4    | `spellcraft_element_amplify_affix_4` | 打出时每有 1 点灵气，本次增幅 +5%                               | —                                                |

### 2.4 蓄灵诀（rank 4，自异常转灵气引擎）

主词条不变：自身每有 1 种元素异常，获得 1 点灵气（上限 7 种 = 7 灵气）。

| #   | 解禁   | id                                    | 效果                                                                   | 数据                                                 |
| --- | ------ | ------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------- |
| 1   | 自带   | `spellcraft_ailments_to_mana_affix_1` | **纳气之后**：若本次获得 ≥{0} 点灵气，每点灵气使你获得 {1} 点护甲      | `valueData: [{base: 3}, {base: 12, increment: 0.6}]` |
| 2   | 自带   | `spellcraft_ailments_to_mana_affix_2` | **化浊为清**：打出后移除自身 1 种元素异常，抽 1 张牌                   | —                                                    |
| 3   | rank 5 | `spellcraft_ailments_to_mana_affix_3` | **七情归一**：自身持有 {0} 种以上不同元素异常时，额外获得 1 点太极之气 | `valueData: [{base: 5}]`                             |

**设计说明**：太极之气（`kWildcardStatusId`）是万能抵扣资源，用它做顶层奖励既有价值又自带限制（灵气不能靠它支付）。`_1` 把"灵气爆发"转成生存，让引擎回合不至于裸奔。

### 2.5 太上忘情（rank 5，手牌取舍）

主词条不变：回合结束时每有 1 张手牌受到 10 点纯粹伤害；下回合产出阶段每有 1 张手牌额外获得 1 点灵气。

**关键约束**：它的主词条是 `self_buff` 授予状态（`buff_handcards_to_mana`），额外词条的作用时机有分歧——**打出的瞬间**（CardScript）还是**状态结算时**（StatusScript）。两者都可做，但要明确。

| #   | 解禁 | id                                     | 效果                                                             | 数据                                      |
| --- | ---- | -------------------------------------- | ---------------------------------------------------------------- | ----------------------------------------- |
| 1   | 自带 | `spellcraft_handcards_to_mana_affix_1` | **舍念**：本牌施加的「太上忘情」状态，每张手牌的纯粹伤害 -{0} 点 | `valueData: [{base: 3}]`                  |
| 2   | 自带 | `spellcraft_handcards_to_mana_affix_2` | **静心**：本牌施加的状态，下回合额外灵气 +{0}                    | `valueData: [{base: 1}]`                  |
| 3   | 自带 | `spellcraft_handcards_to_mana_affix_3` | **忘我**：本牌结算后，下回合第一张悟道牌伤害 +{0}%               | `valueData: [{base: 30, increment: 2.5}]` |

**设计说明**：`_1` 是**解绑**——把"高风险高回报"调成"中风险中回报"，给不敢攥牌的构筑一条路。**不建议**给太上忘情配 `draw_cards_neutral` 或 `mana_battery`：那会同时扩大手牌收益和灵气收益，风险会瞬间消失。

### 2.6 紫微斗数

主词条改为：**抽 1 张法术牌**（原为"抽 1 张牌，费用改为 0"）。

| rank | id                              | 效果                                          | 数据 |
| ---- | ------------------------------- | --------------------------------------------- | ---- |
| 1    |                                 | 获得防御                                      |      |
| 2    | `spellcraft_draw_cards_affix_1` | **定星**：抽到的牌等级 +1                     | —    |
| 3    | `spellcraft_draw_cards_affix_2` | **留命**：抽到的牌获得保留                    | —    |
| 4    | `spellcraft_draw_cards_affix_3` | **星移**：若抽到悟道牌，获得 1 点灵气         | —    |
| 5    | `spellcraft_draw_cards_affix_4` | **逆天改命**：若抽到的不是悟道牌，额外抽 1 张 | —    |

**设计说明**：

- 原草案的「此牌费用 -2」**在这张卡上是空操作**。紫微斗数是 `coloredCost: {life: 0}`，而 `updateCardCost` 会丢弃普通 0 值条目（`card.ht:42-54` 的 `life > 0` 守卫），所以它的 `coloredCost` 是**空表**；空的费用表上减费是静默无操作（`_modifyCardCostByDelta` 与 `applyTurnCostModifier` 的 `cost.isEmpty` 分支只对**增费**方向创建条目）。**该条目已删除。**
- 原草案的「抽到的牌费用 -1」与「费用为 0」并列是**冗余**——按顺序结算时后者完全覆盖前者。保留"费用为 0"的语义即可（走 `draw_cards` 的 `reduceCost` 子表），但**必须明确动态费用不参与归零**（`clearReducibleCardCosts` 已保证，需写进文案）。
- 这张卡的定位是"**立即获得一张合适的牌**"，与天机术的"操纵牌库未来"分工。所以它的词条都围绕"抽到的那张牌"。

### 2.7 万法归宗（rank 5，终局爆发）

主词条不变：耗费 10+X 点灵气，每点造成 {0} 雷电伤害。

⚠️ **先补 `affixes` 键**。rank 5 可解 6 条，掉落即全部生效。

| #   | 解禁   | id                                  | 效果                                                                | 数据                                    |
| --- | ------ | ----------------------------------- | ------------------------------------------------------------------- | --------------------------------------- |
| 1   | rank 5 | `spellcraft_ultimate_spell_affix_1` | **雷行九霄**：若对手已持有感电，本次每点灵气的伤害 +{0}%            | `valueData: [{base: 20, increment: 2}]` |
| 2   | rank 6 | `spellcraft_ultimate_spell_affix_2` | **一法破万法**：本回合每使用过一种元素，本牌伤害 +{0}%              | `valueData: [{base: 8, increment: 1}]`  |
| 3   | rank 6 | `spellcraft_ultimate_spell_affix_3` | **万法余波**：实际支付超过 10 点的每点灵气，获得 {0} 点护甲         | `valueData: [{base: 5}]`                |
| 4   | rank 6 | `spellcraft_ultimate_spell_affix_4` | **雷霆余烬**：若本牌击杀目标，返还 {0}% 已支付灵气                  | `valueData: [{base: 50}]`               |
| 5   | rank 6 | `spellcraft_ultimate_spell_affix_5` | **无极不渡**：本牌不能被任何费用返还效果影响；打出后获得 {0} 点护甲 | `valueData: [{base: 20}]`               |
| 6   | rank 6 | `spellcraft_ultimate_spell_affix_6` | **归宗之后**：打出后抽 1 张牌，但下回合第一张牌费用 +1              | —                                       |

**设计说明**：

- **绝对不要给万法归宗配 `refund_cost`**——那会直接抹掉动态费用的代价结构，把核弹变成无代价循环。
- `_3` 的「万法余波」需要新脚本：`attack_by_paid_resource` 读的是 `paidCost` 的**全额**，要算 `paid - 10` 必须另写。这是本批唯一需要新写的攻击类脚本。
- `_1` 与 `_2` 都不改变"支付多少灵气"这个核心决策，只改变"之前如何规划"的回报——这正是设计文档推荐的组合方向。

---

## 4. 可补充进现有设计的内容

### 4.1 "清异常"主词条

#### 4.1.1 改造 `water_mend`

`water_mend`（甘霖术）现在"回复生命 + 移除自身**全部**元素异常"。每移除一层获得生命" —— **这需要新增脚本 `heal_remove_debuffs_by_stack`**，因为 `heal_remove_debuffs`（`card_script.ht:301-307`）是整层清空、不计数。

```
// 至多移除 value[1] 层（跨 debuffs 列表合计），每移除 1 层结算 value[0] 的治疗
// removeStatusEffect 返回实际移除层数（battle_character.ht:42），可据此计数
```

改造后的 `water_mend` 词条：

| 字段           | 值                                           |
| -------------- | -------------------------------------------- |
| `script`       | `heal_remove_debuffs_by_stack`               |
| `valueData[0]` | `{base: 4, increment: 0.1}`（每层治疗）      |
| `valueData[1]` | `{base: 3, increment: 0.15}`（至多移除层数） |
| `uniqueIds`    | `["for_element_ailment_heal"]`               |

#### 4.1.2 护甲版清异常卡

`earth_mend`作为土系加持卡加入：

| id           | rank | kind      | 元素 | cardType | 效果                                                | script                           | valueData                                                  |
| ------------ | ---- | --------- | ---- | -------- | --------------------------------------------------- | -------------------------------- | ---------------------------------------------------------- |
| `earth_mend` | 3    | earthbend | 土   | spell    | 至多移除 {1} 层元素异常，每移除 1 层获得 {0} 点护甲 | `defend_remove_debuffs_by_stack` | `[{base: 6, increment: 0.15}, {base: 3, increment: 0.15}]` |

`uniqueIds: ["for_element_ailment_defend"]`，与额外词条版本互斥去重。

#### 4.1.3 增加更多“自身每有一种异常”

补一个自身每有一种异常获得x护甲的悟道流派非绝世主词条。

### 4.3 补两条额外词条（元素异常 → 生命/护甲）

| id                           | script（新建）            | rank | categories | genres     | 效果                                           | uniqueId                     |
| ---------------------------- | ------------------------- | ---- | ---------- | ---------- | ---------------------------------------------- | ---------------------------- |
| `for_element_ailment_heal`   | `heal_by_self_ailments`   | 3    | buff       | spellcraft | 打出时自身每有 1 层任意元素异常，回复 {0} 生命 | `for_element_ailment_heal`   |
| `for_element_ailment_defend` | `defend_by_self_ailments` | 3    | buff       | spellcraft | 打出时自身每有 1 层任意元素异常，获得 {0} 护甲 | `for_element_ailment_defend` |

### 4.4 补"调息"（attune）的重算缺口

`spellcraft_affixes.md:15` 记录的待办已确认属实：`reduce_cost_by_cards_in_hand` 只在**进入/离开手牌的那张牌自己**身上重算（`added_to_hand` 1 个派发点、`removed_from_hand` 3 个）。

后果：抽到同元素伙伴时，先前已减费的卡**不会**被复查；伙伴离手时已减费的卡也**不会**恢复——只有它**自己**离手才恢复。

修复方向（需 Dart 侧改动，属机制层）：在 `handleCardAffixCallback` 的 `added_to_hand` / `removed_from_hand` 派发之后，对**手牌区其余卡牌**补跑一次这两个时机的回调。注意**幂等**——`_added_to_hand` 已经内建了幂等撤销（`card_script.ht:505`），可以安全重复调用。

### 4.5 三处小体量 Dart 扩展（`spellcraft.md:115` 提到，此处细化）

1. **观星修饰字段**（§2.1 的 6 个字段）——在 `BattleScene.scry` 里消费，或让主脚本收集后传参。
2. **`scryPickBonus` 多选**（仅当决定做 §2.1 的第 6 条时）——需 `Completer<List<CustomGameCard>>` + 确认动作 + 剩余次数提示。

## 5. 落地清单与风险

### 5.1 数据文件改动

- `assets/data/cards.json5`：补 `紫微斗数` 的 `rank` 与 `affixes`；补 `万法归宗` 的 `affixes`；7 张绝世卡填入固定词条 id 列表；`water_mend` 改 script 与 valueData；新增 `earth_mend` / `vine_bind`。
- `assets/data/card_affixes.json5`：新增约 25 条专属词条（带 `inUnpackable`）；新增 2 条元素异常转生命/护甲词条。
- `assets/data/passives.json5`：新增 15 条装备额外词条（5 件 × 至多对应槽位）。
- `assets/data/items.json5`：5 件绝世装备的 `affixes` 列表追加额外词条 id。
- `assets/data/status_effect.json5`：新增相生相克 `_5`、一气化三清 `_2` 所需的状态。

### 5.2 脚本改动

- `scripts/main/cardgame/card_script.ht`：观星修饰字段的收集与传递；`heal_remove_debuffs_by_stack`、`defend_remove_debuffs_by_stack`、`gain_life_by_self_ailments`、`gain_defend_by_self_ailments`、万法余波、弃星成算。
- `scripts/main/cardgame/status_script.ht`：新增/改动的状态行为。
- `scripts/main/cardgame/card.ht`：`_getSupportAffixes` 加 `inUnpackable` 守卫（**一行**）。

### 5.3 本地化

- `assets/locale/zh/rpg/battlecard.json`：全部新增词条的 `affix_*` 与 `affix_*_description`；`uniquecard_*` 若改名需同步。
- `assets/locale/zh/rpg/passive.json`：装备额外词条的 `passive_*_description`。
- `assets/locale/zh/rpg/status_effect.json`：新增状态的名称与描述。
- `assets/locale/zh/rpg/item.json`：若装备文案需更新机制说明。

### 5.4 校验与风险

- `dart run utils/data_validate/game_data_validate.dart`（当前基线 **0 错误 / 7 提示**）。
- `python build.py` 重编译脚本；`flutter analyze` 验证 Dart。

**已知风险**：

1. **`uniqueIds` 的顺序依赖**——词条必须先于引用它的主词条存在，否则校验器报悬空引用。
2. **观星多选（§2.1 `_5`）是唯一的重工程**，放在最后解锁位，可延后或砍掉。
3. **数值标定的锚点缺失**——化神期「灵力」的实际成长曲线决定了 `太上感应` 能产多少灵气，进而决定 rank 5 卡牌的费用约束强度。这个数字未定时，本文档的 `valueData` 只能给量级参考。
