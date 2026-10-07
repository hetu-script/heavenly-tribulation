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

|          | 解锁规则                                                                              | 能否成长                                        |
| -------- | ------------------------------------------------------------------------------------- | ----------------------------------------------- |
| 绝世卡牌 | `_addPredefinedAffixes`（`card.ht:413-430`）：`targetCount = min(列表长度, rank + 1)` | **能**。破境每次再解 1 条（`card.ht:631` 重调） |
| 绝世装备 | `createItemById`（`item.ht:130-137`）：`unlockCount = min(列表长度, item.rank + 1)`   | **不能**。装备破境未实现，解锁数在生成时固定    |

这条差异决定了两个列表的写法：

- **卡牌**的 `affixes` 列表是"投资路线图"——第 1 条必须让卡在到达下限 rank 时就成立、就可辨识；后面的条目是给毕业形态的。
- **装备**的 `affixes` 列表是"固定成品"——rank 1 只有 2 个槽（主词条 + **1 个**额外词条），写完就定死，不可能再加。所以每件装备的额外词条必须**只放一条**，且必须是该装备最该有的那一条。

### 0.3 装备额外词条槽位（世界不再加）

| 装备   | rank | 词条总数上限 | **额外词条槽** |
| ------ | ---- | ------------ | -------------- |
| 窥天镜 | 1    | 2            | **1**          |
| 五行珠 | 2    | 3            | **2**          |
| 天机盘 | 3    | 4            | **3**          |
| 蓄灵佩 | 4    | 5            | **4**          |
| 聚灵旗 | 5    | 6            | **5**          |

装备额外词条写在 `passives.json5`（与天赋同池），不走 `card_affixes.json5`。**槽位写不满是常态**，不必凑数。

### 0.4 数值公式

- **卡牌词条**：`value = (base + increment × (level − minLevelForRank(rank))) × 1.3^rank`
  `minLevelForRank(r) = r == 0 ? 0 : r×10`；rank 5 的 level 区间是 50~65。
- **装备词条**：`calculatePassiveAffixValue = (base ?? 0) + increment × level`（`common.ht:167-172`），**无境界指数**。装备词条的 level 在 `[minAffixLevel, item.level]` 随机 roll，`minAffixLevel` 由 `increment` 反推（`|increment| < 1` 时 = `ceil(1/|increment|)`，`item.ht:142-149`）。
  → **装备词条想要确定值，就用机制字段内嵌数值或 `statsBonus`，不要用 `base + increment`。**

### 0.5 一个Pitfall

- **`maxLevel: 0` 不生效**。hetu 把 `0` 当 falsy，`valueData.maxLevel ? ... : ...`（`card.ht:313`）走 else 分支 = 不设上限。如果要达到`maxLevel: 0`的效果，需要条目**同时省略 increment/rankIncrement，或者将其全部设置为0**，此时值退化成 `base × 1.3^rank`。**本文档统一用"省略 increment/rankIncrement"来表达固定值，不写 `maxLevel: 0`。**

### 0.6 专属词条标记需要一行代码

`card_affixes.json5` 加 `inUnpackable`（建议用这个名表示绝世专属词条而不是 `isUnique`，避免与主词条的"这是绝世卡"语义撞车）目前**会被静默忽略**：运行时 `_getSupportAffixes`（`card.ht:249-301`）不读它，校验器 `validateCardAffixes` 也没有未知键扫描。

好消息是**只需改一处**：绝世卡的固定词条走 `_addPredefinedAffixes`，它**完全不调用 ` _getSupportAffixes`**，天生免疫。所以在 `_getSupportAffixes` 加一行 `if (affix.inUnpackable == true) continue` 即可，不必在解禁路径上开洞。

字段必须放**词条顶层**——放进 `filter`/`require` 会被校验器 `checkCriteria`（`game_data_validate.dart:424-458`）硬报错。

### 0.7 观星的后处理通道

`BattleScene.scry`（`battle.dart:1079-1196`）目前只消费 `options` 的两个键：`chosenCostChange` / `othersCostChange`。且：

- `scryBonus` 是**全局 stats**（`battle.dart:1087` 无差别叠加），拿它做单卡词条会污染天道推演与窥天镜。
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

7 张卡的现状与目标：

| 卡                                              | 数据层 rank      | 可解词条数        | `affixes` 现状 |
| ----------------------------------------------- | ---------------- | ----------------- | -------------- |
| 天机术 `spellcraft_scry_draw`                   | 1                | 1 → 5（破境成长） | `[]`           |
| 相生相克 `spellcraft_ailments_by_used_elements` | 2                | 2 → 5             | `[]`           |
| 一气化三清 `spellcraft_element_amplify`         | 3                | 3 → 5             | `[]`           |
| 蓄灵诀 `spellcraft_ailments_to_mana`            | 4                | 4 → 5             | `[]`           |
| 太上忘情 `spellcraft_handcards_to_mana`         | 5                | 5                 | `[]`           |
| 紫微斗数 `spellcraft_draw_cards_reduce_cost`    | **无 rank 字段** | 1 → 5             | **无该键**     |
| 万法归宗 `spellcraft_ultimate_spell`            | 5                | 5                 | **无该键**     |

> ⚠️ **两处需先修**：
>
> 1. `紫微斗数` 缺 `rank`。它由分支节点 `shuffleIntoDeck` 发放，而 `affixId` 路径**短路了全部过滤**（`card.ht:121`），所以 `this.rank` 保持构造默认值 **0**（`card.ht:107`），`targetCount = min(len, 1) = 1`——**只会解出主词条，一个额外词条都不给**。必须显式补 `rank: N`。按照设计，紫微斗数的rank等同于角色当前境界。
> 2. `万法归宗` 已有 `rank: 5`，但缺 `affixes` 键，同样解不出词条。

### 2.1 天机术（rank 1，规划主题）

主词条改为：**观星 X 张，抽 1 张法术牌**（`script: "draw_cards"` + `filter: {cardType: "spell"}`，或保留 `scry_then_draw` 并给它加 filter 参数）。

**关键实现建议**：把"观星修饰"做成**可叠加的纯数据词条**，由观星主脚本从 `card.affixes` 里收集，而不是给 `scry()` API 加一堆参数。理由：

- 不碰 `BattleScene.scry` 已冻结的 `options` 契约；
- 词条天然属于卡牌，卡被洗入别的构筑时行为一致；
- 无内容 id 硬编码，符合"数据驱动"分层。

约定字段（均为 `card_affixes.json5` 词条顶层，`script` 可缺省、`callbacks: []`，仅作数据被主脚本读取）：

| 字段                   | 含义                     |
| ---------------------- | ------------------------ |
| `scryBonus`            | 本牌观星时额外查看 N 张  |
| `scryChosenCostChange` | 本牌观星选中牌费用变化   |
| `scryRetainChosen`     | 本牌观星选中的牌获得保留 |
| `scryUpgradeChosen`    | 本牌观星选中的牌等级 +1  |
| `scryPickBonus`        | 本牌观星时可选 N+ 张     |

主脚本（如 `scry_then_draw`）遍历 `card.affixes[1..]` 累加这些字段，一次性传给 `self.scry(...)`，由 Dart 侧统一兑现。

**固定词条列表**（按解锁顺序）：

| #   | 解禁   | id                             | 效果                                          | 数据                       |
| --- | ------ | ------------------------------ | --------------------------------------------- | -------------------------- |
| 1   | 自带   | `spellcraft_scry_draw_affix_1` | **落子**：本牌观星时额外查看 {0} 张           | `scryBonus: X`             |
| 2   | rank 2 | `spellcraft_scry_draw_affix_2` | **星移**：本牌观星选中的牌费用 -{0}           | `scryChosenCostChange: -X` |
| 3   | rank 3 | `spellcraft_scry_draw_affix_3` | **留观**：本牌观星选中的牌获得保留            | `scryRetainChosen: true`   |
| 4   | rank 4 | `spellcraft_scry_draw_affix_4` | **窥命**：本牌观星选中的牌等级 +{0}           | `scryUpgradeChosen: X`     |
| 5   | rank 5 | `spellcraft_scry_draw_affix_5` | **星算**：本牌观星可选 {0} 张（展示张数不变） | `scryPickBonus: X`         |

**设计说明**：

- `_5` 的**多选**是本批设计里唯一的重工程（当前 `Completer<CustomGameCard>` 单选、展示数 == 可选数）。

### 2.2 相生相克（rank 2，轮转/自异常主题）

主词条不变：对**双方**施加随机元素异常，种数 = 本回合已用元素种数。

| #   | 解禁   | id                                 | 效果                                                           | 数据                                        |
| --- | ------ | ---------------------------------- | -------------------------------------------------------------- | ------------------------------------------- |
| 1   | 自带   | `spellcraft_ailments_used_affix_1` | **相生**：本回合每使用过一种元素，本次施加层数 +{0}            | `valueData: [{base: 0.5, increment: 0.05}]` |
| 2   | 自带   | `spellcraft_ailments_used_affix_2` | **五行归序**：自身持有 {0} 种以上不同元素异常时，获得 1 点灵气 | `valueData: [{base: 3}]`（固定值）          |
| 3   | rank 3 | `spellcraft_ailments_used_affix_3` | **清浊相生**：打出时移除自身 1 层任意元素异常，抽 1 张牌       | —                                           |
| 4   | rank 4 | `spellcraft_ailments_used_affix_4` | **乱象**：若对手已持有本次将施加的异常，则该异常额外 +1 层     | —                                           |
| 5   | rank 5 | `spellcraft_ailments_used_affix_5` | **化劫**：本场战斗中，每移除 1 层自身元素异常，获得 3 点护甲   | 需永久状态承载                              |

**设计说明**：`attack_debuff` / `ailments_by_used_elements` 系的通用脚本可以传"额外层数"参数，不必新写整套。`_3` 与 `water_mend`（清除全部异常）形成对照：相生相克自己清一层换抽牌，是自异常引擎的**微调节流阀**，避免异常堆到必须用水疗术清场。

`_5` 是"水疗术/清浊"路线的回报，让"铺异常→清异常"的两张牌形成闭环。

### 2.3 一气化三清（rank 3，元素专注主题）

主词条不变：抉择水/火/雷之一，本回合双方造成的该元素伤害 +{0}%。

| #   | 解禁   | id                                   | 效果                                                 | 数据                                             |
| --- | ------ | ------------------------------------ | ---------------------------------------------------- | ------------------------------------------------ |
| 1   | 自带   | `spellcraft_element_amplify_affix_1` | **三清护体**：抉择后，下一次受到该元素伤害时恢复生命 | `valueData: [{base: 1}]`                         |
| 2   | rank 4 | `spellcraft_element_amplify_affix_2` | **同气相求**：对手使用所选元素牌时，你获得 1 点灵气  | 需状态承载                                       |
| 3   | rank 5 | `spellcraft_element_amplify_affix_3` | **一气先行**：抉择后，本回合下一张所选元素牌费用 -1  | 复用 `applyTurnCostModifier`（现有零调用方通道） |
| 4   | rank 6 | `spellcraft_element_amplify_affix_4` | **三清回响**：打出时每有 1 点灵气，本次增幅 +5%      | —                                                |

**设计说明**：`_2` 是**专门针对"对称效果被 AI 低估"的补偿**——敌方不会主动规划元素路线，导致"双方增伤"实际上恒偏向玩家。这条让对手**无意中**使用该元素时给玩家补偿，把不对称从"白拿"变成"有来有回"。

### 2.4 蓄灵诀（rank 4，自异常转灵气引擎）

主词条不变：自身每有 1 种元素异常，获得 1 点灵气（上限 7 种 = 7 灵气）。

⚠️ **不要再加"异常层数增加"或"异常转灵气"的效果**——现有组合（相生相克 + 窥天镜 + 五行珠 + 蓄灵诀）已经是一条强引擎，继续叠加会让它从"构筑选择"变成"必选组合"。这个方向要加的是**消耗、转化、防御**。

| #   | 解禁   | id                                    | 效果                                                                   | 数据                                                 |
| --- | ------ | ------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------- |
| 1   | rank 4 | `spellcraft_ailments_to_mana_affix_1` | **纳气之后**：若本次获得 ≥{0} 点灵气，获得 {1} 点护甲                  | `valueData: [{base: 3}, {base: 12, increment: 0.6}]` |
| 2   | rank 5 | `spellcraft_ailments_to_mana_affix_2` | **化浊为清**：打出后移除自身 1 种元素异常，抽 1 张牌                   | —                                                    |
| 3   | rank 6 | `spellcraft_ailments_to_mana_affix_3` | **七情归一**：自身持有 {0} 种以上不同元素异常时，额外获得 1 点太极之气 | `valueData: [{base: 5}]`                             |

**设计说明**：太极之气（`kWildcardStatusId`）是万能抵扣资源，用它做顶层奖励既有价值又自带限制（灵气不能靠它支付）。`_1` 把"灵气爆发"转成生存，让引擎回合不至于裸奔。

### 2.5 太上忘情（rank 5，手牌取舍）

主词条不变：回合结束时每有 1 张手牌受到 10 点纯粹伤害；下回合产出阶段每有 1 张手牌额外获得 1 点灵气。

**关键约束**：它的主词条是 `self_buff` 授予状态（`buff_handcards_to_mana`），额外词条的作用时机有分歧——**打出的瞬间**（CardScript）还是**状态结算时**（StatusScript）。两者都可做，但要明确。

| #   | 解禁   | id                                     | 效果                                                             | 数据                                      |
| --- | ------ | -------------------------------------- | ---------------------------------------------------------------- | ----------------------------------------- |
| 1   | rank 5 | `spellcraft_handcards_to_mana_affix_1` | **舍念**：本牌施加的「太上忘情」状态，每张手牌的纯粹伤害 -{0} 点 | `valueData: [{base: 3}]`                  |
| 2   | rank 6 | `spellcraft_handcards_to_mana_affix_2` | **静心**：本牌施加的状态，下回合额外灵气 +{0}                    | `valueData: [{base: 1}]`                  |
| 3   | rank 6 | `spellcraft_handcards_to_mana_affix_3` | **忘我**：本牌结算后，下回合第一张悟道牌伤害 +{0}%               | `valueData: [{base: 30, increment: 2.5}]` |

**设计说明**：`_1` 是**解绑**——把"高风险高回报"调成"中风险中回报"，给不敢攥牌的构筑一条路。**不建议**给太上忘情配 `draw_cards_neutral` 或 `mana_battery`：那会同时扩大手牌收益和灵气收益，风险会瞬间消失。

### 2.6 紫微斗数（rank 需补，即时兑现主题）

主词条改为：**抽 1 张法术牌**（原为"抽 1 张牌，费用改为 0"）。

⚠️ **先补 `rank` 字段**，否则解不出额外词条（见 §2 开头的警告）。

| #   | 解禁   | id                              | 效果                                          | 数据                       |
| --- | ------ | ------------------------------- | --------------------------------------------- | -------------------------- |
| 1   | rank 1 | `spellcraft_draw_cards_affix_1` | **定星**：抽到的牌等级 +1                     | —                          |
| 2   | rank 2 | `spellcraft_draw_cards_affix_2` | **留命**：抽到的牌获得保留                    | —                          |
| 3   | rank 3 | `spellcraft_draw_cards_affix_3` | **星移**：若抽到悟道牌，获得 1 点灵气         | —                          |
| 4   | rank 4 | `spellcraft_draw_cards_affix_4` | **获得防御**（通用，可复用中立 `defend`）     | 建议直接用中立词条而非专属 |
| 6   | rank 5 | `spellcraft_draw_cards_affix_5` | **逆天改命**：若抽到的不是悟道牌，额外抽 1 张 | —                          |

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

## 3. 绝世装备的额外词条

写在 `passives.json5` 的「绝世装备专用词条」区，经 `items.json5` 的 `affixes` 列表引用。**装备破境未实现，槽位在生成时固定**（§0.2）。

原则：装备额外词条是**锦上添花**——不是构筑成立的必要条件。槽位少，宁可留空也不要凑数。

### 3.1 窥天镜（rank 1，1 个槽）

主词条：观星额外查看 2 张；每次观星后自身随机获得 2 种元素异常。

| 槽  | id                            | 效果                          | 取舍                                                       |
| --- | ----------------------------- | ----------------------------- | ---------------------------------------------------------- |
| 1   | `heaven_peeking_mirror_extra` | **窥命**：观星选中的牌等级 +1 | 强化"看得越多，能拿的越好"，与主词条的异常代价形成正面对冲 |

**未采纳的方向**（留作备选）：观星时手牌同元素牌每张使本牌费用 -1、观星时按已用元素种类获得灵气。两者都偏离"观星深度"这个主轴。

### 3.2 五行珠（rank 2，2 个槽）

主词条：你造成的元素异常层数 +2；你受到的元素异常层数 +2。

| 槽  | id                            | 效果                                                         |
| --- | ----------------------------- | ------------------------------------------------------------ |
| 1   | `five_elements_pearl_extra_1` | **同源**：你造成的元素异常层数 {0}；你受到的元素异常层数 {0} |
| 2   | `five_elements_pearl_extra_2` | **相济**：每回合第一次获得元素异常时，获得 1 点灵气          |

**设计说明**：`_2` 把"受异常"从纯代价转成收益，是自异常引擎的第二个正面。这在对称效果被 AI 低估的前提下尤其重要。

### 3.3 天机盘（rank 3，3 个槽）

主词条：回合开始额外抽 1 张；通过此效果抽到的非悟道牌本回合费用 +1。

| 槽  | id                                | 效果                                                  |
| --- | --------------------------------- | ----------------------------------------------------- |
| 1   | `heavenly_mechanism_disc_extra_1` | **推演**：回合开始观星 {0} 张                         |
| 2   | `heavenly_mechanism_disc_extra_2` | **锁星**：观星选中的牌费用 -{0}                       |
| 3   | `heavenly_mechanism_disc_extra_3` | **软锁强化**：非悟道牌费用 +{0}（与主词条的课税叠加） |

**设计说明**：`_1` 直接用现成机制字段 `turnStartScry`。`_3` 是"软流派锁最强形态"的延伸，rank 3 装备给到 +1 已足够。

### 3.4 蓄灵佩（rank 4，4 个槽）

主词条：回合结束至多保留 2 点灵气；每保留 1 点，下回合开始受到 3 点纯粹伤害。

| 槽  | id                              | 效果                                                |
| --- | ------------------------------- | --------------------------------------------------- |
| 1   | `spirit_storing_amulet_extra_1` | **扩储**：保留上限 +{0}                             |
| 2   | `spirit_storing_amulet_extra_2` | **温养**：每保留 1 点的代价伤害 -{0}                |
| 3   | `spirit_storing_amulet_extra_3` | **余韵**：每保留 1 点，下回合额外获得 {0} 点灵气    |
| 4   | `spirit_storing_amulet_extra_4` | **淤积**：保留的灵气每点使本回合首次受到的伤害 -{0} |

**设计说明**：`_1` 与 `_2` 分别放松"上限"和"代价"两个约束，是玩家最容易感知的强化方向。**注意**：保留的灵气不触发阴阳五行结算（`status_script.ht:332-346` 已处理），这条语义要写进装备文案。

### 3.5 聚灵旗（rank 5，5 个槽）

主词条：回合开始时灵气 +3；你打出的非悟道牌费用 +2。

| 槽  | id                                | 效果                                                         |
| --- | --------------------------------- | ------------------------------------------------------------ |
| 1   | `spirit_gathering_banner_extra_1` | **旗鼓**：回合开始灵气 +{0}                                  |
| 2   | `spirit_gathering_banner_extra_2` | **纯道**：每打出一张悟道牌，本回合灵气 +{0}（每回合限 1 次） |
| 3   | `spirit_gathering_banner_extra_3` | **斥外**：你受到的非悟道来源伤害 -{0}                        |
| 4   | `spirit_gathering_banner_extra_4` | **聚气成势**：灵气达到 {0} 时，本回合受到的伤害 -{1}%        |
| 5   | `spirit_gathering_banner_extra_5` | **一炁**：回合结束时，若灵气为 0，获得 {0} 点护甲            |

**设计说明**：`_2` 与 `_5` 服务万法归宗的凑气目标。`_3`/`_4` 是纯悟道构筑的生存补偿——它为了 +3 灵气付出了"非悟道牌 +2 费"的代价，容易被杂牌构筑惩罚，需要防守面。

---

## 4. 可补充进现有设计的内容

### 4.1 补"清异常"主词条

`water_mend`（甘霖术）现在"回复生命 + 移除自身**全部**元素异常"。用户草案提到要改成"至多移除 x 层，每移除一层获得生命" —— **这需要新脚本**，因为 `heal_remove_debuffs`（`card_script.ht:301-307`）是整层清空、不计数。

建议新增脚本 `heal_remove_debuffs_by_stack`：

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

### 4.2 补护甲版清异常卡

用户草案的 `earth_mend`（注意原文拼写为 `eartch_mend`）目前**不存在**。建议作为土系加持卡加入：

| id           | rank | kind      | 元素 | cardType | 效果                                                | script                           | valueData                                                  |
| ------------ | ---- | --------- | ---- | -------- | --------------------------------------------------- | -------------------------------- | ---------------------------------------------------------- |
| `earth_mend` | 3    | earthbend | 土   | spell    | 至多移除 {1} 层元素异常，每移除 1 层获得 {0} 点护甲 | `defend_remove_debuffs_by_stack` | `[{base: 6, increment: 0.15}, {base: 3, increment: 0.15}]` |

`uniqueIds: ["for_element_ailment_defend"]`，与 `water_mend` 的互斥去重（`card.ht:232-237` / `:259`）。

### 4.3 补两条额外词条（元素异常 → 生命/护甲）

| id                       | script（建议新建）             | rank | categories   | genres     | 效果                                           | uniqueId                     |
| ------------------------ | ------------------------------ | ---- | ------------ | ---------- | ---------------------------------------------- | ---------------------------- |
| `element_ailment_heal`   | `gain_life_by_self_ailments`   | 3    | buff, attack | spellcraft | 打出时自身每有 1 层任意元素异常，回复 {0} 生命 | `for_element_ailment_heal`   |
| `element_ailment_defend` | `gain_defend_by_self_ailments` | 3    | buff, attack | spellcraft | 打出时自身每有 1 层任意元素异常，获得 {0} 护甲 | `for_element_ailment_defend` |

> ⚠️ **语义澄清**：作为**卡牌额外词条**，它只能是**打出时一次性结算**（CardScript 是 on-play）。如果你想的是"持续生效"，那属于 `passives.json5` 的装备/天赋词条，不是卡牌词条。二者不要混。
>
> ⚠️ **顺序依赖**：校验器（`game_data_validate.dart:544-551`）要求 `uniqueIds` 里每个 id 都必须是**某个实际词条的 `uniqueId`**。所以必须**先建词条、再在 `water_mend` / `earth_mend` 上引用**，顺序不能反。
>
> ⚠️ **多用复数 `uniqueIds: [...]`**。种子阶段（`card.ht:232-237`）只读复数形式，singular 的 `uniqueId` 只有在重建阶段（`:371`）才有回退。

### 4.4 补"调息"（attune）的重算缺口

`spellcraft_affixes.md:15` 记录的待办已确认属实：`reduce_cost_by_cards_in_hand` 只在**进入/离开手牌的那张牌自己**身上重算（`added_to_hand` 1 个派发点、`removed_from_hand` 3 个）。

后果：抽到同元素伙伴时，先前已减费的卡**不会**被复查；伙伴离手时已减费的卡也**不会**恢复——只有它**自己**离手才恢复。

修复方向（需 Dart 侧改动，属机制层）：在 `handleCardAffixCallback` 的 `added_to_hand` / `removed_from_hand` 派发之后，对**手牌区其余卡牌**补跑一次这两个时机的回调。注意**幂等**——`_added_to_hand` 已经内建了幂等撤销（`card_script.ht:505`），可以安全重复调用。

### 4.5 三处小体量 Dart 扩展（`spellcraft.md:115` 提到，此处细化）

1. **观星修饰字段**（§2.1 的 6 个字段）——在 `BattleScene.scry` 里消费，或让主脚本收集后传参。
2. **`scryPickBonus` 多选**（仅当决定做 §2.1 的第 6 条时）——需 `Completer<List<CustomGameCard>>` + 确认动作 + 剩余次数提示。

---

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
