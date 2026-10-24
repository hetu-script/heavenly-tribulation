# 悟道·绝世装备 额外词条设计（定稿）

> 承接 `plan/skill_tree/spellcraft.md`（流派总设计）与 `plan/spellcraft_uniquecard_affixes.md`（绝世卡词条定稿）。
> 本文定稿 5 件绝世装备各 5 条固定额外词条，**全部使用公共词条**（结论与理由见 §1）。
> 旧稿开头的四张绝世卡候选词条（蓄灵诀/太上忘情/紫微斗数/万法归宗）已并入卡牌文档定稿，本文不再保留。

---

## 0. 实现事实（装备侧，已逐行核对）

- **解锁规则**：`createItemById`（`item.ht:127-130`）：`unlockCount = min(affixes 列表长度（含主词条）, item.rank + 1)`，**装备破境未实现，解锁数在生成时固定**。
  → **rank N 的装备永远只有前 N 条额外词条生效**，第 N+1 条起为休眠内容（待破境系统）。本文按"每件 5 条"设计，**列表顺序 = 优先级顺序**：
  - 窥天镜 rank 1 → 生效 1 条；五行珠 rank 2 → 2 条；天机盘 rank 3 → 3 条；蓄灵佩 rank 4 → 4 条；聚灵旗 rank 5 → 5 条全生效。
- **数值**：`calculatePassiveAffixValue = (base ?? 0) + increment × level`（**无境界指数**）；level 在 `[minAffixLevel, item.level]` 随机 roll（`|increment| < 1` 时 `minAffixLevel = ceil(1/|increment|)`，`item.ht:141-145`）；**机制型词条（无 increment 且无 rankIncrement）跳过 roll**，数值定值内嵌在机制字段里。
  → **要确定值就用机制字段 / statsBonus 内嵌定值；引用现有随机池词条则接受 level 方差**（如 spirituality 在 rank 2 装备上 roll 出 0.5×(20~35) 的灵力，方差不小，见 §4 风险 3）。
  → **风险**：绝世装备掉落发放时若未显式传 `level`，词条 roll 区间行为需实现时确认（`item.ht:147`）。
- **通道**：装备词条只能经透传白名单 `_kPassiveMechanismFields`（`battle_entity.ht:583-591`：`battleStatus` / `deckCostReduction` / `shuffleIntoDeck` / `turnStartScry` / `turnStartExtraDraw` / `energyRetain` / `statsBonus`）+ 普通属性值聚合进战斗（`characterCalculateStats`）。
- 聚合规则：battleStatus 按状态 id 合并层数累加；deckCostReduction 规则列表拼接全部生效；turnStartScry 求和；turnStartExtraDraw count 求和、costIncrease 后者覆盖；energyRetain 按 resourceId 合并（max 取大、代价取首个配置）；statsBonus 逐键累加。

---

## 1. 结论：同意全部使用公共词条

用户意见：装备额外词条不做专属。我同意，且认为装备比卡牌**更适合**公共化：

1. **技术上装备没有"中间结果"可消费**。卡牌词条可以读"本牌观星选中的牌 / 实际支付的灵气 / 施加的状态参数"，这类词条有必须专属的理由（见卡牌文档 §1 原则 3）；装备词条一切行为都经由全局聚合通道（§0 白名单）兑现，任何词条挂在任何装备上行为一致——专属化不会带来任何表达力，只会制造 25 个一次性 id。
2. **内容经济上更优**：新机制词条做成公共 id，未来其他流派绝世装备、甚至天赋树节点都可以直接引用（天赋树引用 passive id 时无视用途标记）。
3. **构筑协同可见**：玩家看到熟悉词条出现在不同装备上，更容易形成"这件装备和我构筑里 X 的配合"的判断。

**但"公共"需要三层语义**，本文按此执行：

| 层 | 含义 | 判定 |
| --- | --- | --- |
| A | **复用现有随机池词条**（如 `battleDrawBonus` `persistent`） | 首选，零新内容成本 |
| B | **新共享词条，进随机池**（写 `isEquipmentExtraAffix` + kinds/rank 门控） | 效果对任意构筑成立（观星深度、异常层数修正等通用机制） |
| C | **新共享词条，不进随机池**（不写用途标记，id 可被固定列表/天赋树引用） | 涉及**流派色资源产消**或**流派费修**——其他流派 roll 到就是死词条或纯负面 |

即：公共 ≠ 必须进随机池。C 层词条对其他流派绝世装备同样可用（例如未来某流派想要"非本流派牌 +1 费"的软锁词条，直接引用 `non_spellcraft_tax` 的换流派变体思路即可——届时再参数化流派字段）。

---

## 2. 五件装备定稿（各 5 条，列表顺序 = 解锁顺序）

### 2.1 窥天镜 `heaven_peeking_mirror`（rank 1，talisman/pearl）

主词条：观星额外查看 1 张（statsBonus scryBonus+2）；每次观星后自身随机获得 2 种元素异常（battleStatus `scry_self_ailments`）。
rank 1 → **只有第 1 条生效**，其余 4 条休眠。

| 槽 | 词条 id | 层 | 效果 | 取舍说明 |
| --- | --- | --- | --- | --- |
| 1 | `spirituality` | A（现有） | 灵力 +increment×level | 灵力经太上感应转化为灵气产能 |
| 2 | `scry_focus` | B（新） | 观星额外查看 1 张（statsBonus `{scryBonus: 1}`） | 唯一生效位必须直接强化主词条："看得越多，能拿的越好" |
| 3 | `turn_start_scry_minor` | B（新） | 每回合开始时观星 1 张（turnStartScry: 1） | 与天道推演分支同通道、数值减半版 |
| 4 | `ailment_ward` | B（新） | 你受到的元素异常层数 -1（statsBonus `{ailmentReceiveBonus: -1}`） | 对冲主词条的自异常代价；修正后 ≤0 静默不施加（`character.dart:516-524`） |
| 5 | `ailment_to_mana_echo` | C（新） | 每回合你第一次获得元素异常时，获得 1 点灵气 | 把主词条的自异常接入蓄灵诀引擎（新状态 `first_ailment_to_mana`） |

### 2.2 五行珠 `five_elements_pearl`（rank 2，jewelry/amulet）

主词条：你造成的元素异常层数 +2；你受到的元素异常层数 +2（statsBonus 双向）。
rank 2 → 前 2 条生效。

| 槽 | 词条 id | 层 | 效果 | 取舍说明 |
| --- | --- | --- | --- | --- |
| 1 | `spirituality` | A（现有） | 灵力 +increment×level | — |
| 2 | `ailmentMultiplier` | A（现有） | 元素异常伤害 +increment×level% | 双向放大器的"造成"侧直接受益 |
| 3 | `ailmentThreshold` | A（现有） | 元素异常充能阈值降低 | 同上，让施加更频繁；rank 3 门控只限随机池，固定列表不受限 |
| 4 | `ailment_inflict_focus` | B（新） | 你造成的元素异常层数 +1（statsBonus `{ailmentInflictBonus: 1}`） | 主词条同方向再加强 |
| 5 | `ailment_to_mana_echo` | C（新，与窥天镜共用） | 每回合你第一次获得元素异常时，获得 1 点灵气 | 把"受到 +2"从纯代价转成收益 |

- 注：`ailment_to_mana_echo` 同时出现在窥天镜 `_3` 与五行珠 `_4`；两件同时装备时 battleStatus 按状态 id 合并、层数不累加触发次数（每回合仍只触发一次）——可接受的边际递减，避免双份引擎。

### 2.3 天机盘 `heavenly_mechanism_disc`（rank 3，talisman/pearl）

主词条：回合开始额外抽 1 张（`turnStartExtraDraw`）；经此抽到的非悟道牌本回合费用 +1（costIncrease，抽到时的回合级课税）。
rank 3 → 前 3 条生效。

| 槽 | 词条 id | 层 | 效果 | 取舍说明 |
| --- | --- | --- | --- | --- |
| 1 | `non_spellcraft_tax` | C（新） | 你的非悟道牌费用 +1（deckCostReduction `{color: all, amount: -1, notGenres: [spellcraft]}`，组牌阶段永久课税） | 软流派锁延伸；与主词条的"抽到时课税"是**两个通道**，可叠加 |
| 2 | `scry_focus` | B（新） | 观星额外查看 1 张 | — |
| 3 | `turn_start_scry_minor` | B（新，与窥天镜共用） | 每回合开始时观星 1 张 | 过牌+规划是同一主题的两面 |
| 4 | `deckMinSizeReduce` | A（现有） | 牌库下限 -increment×level | 精简牌库提高引擎浓度 |
| 5 | `battleDrawBonus` | A（现有） | 战斗抽牌数 +increment×level | 直接加强过牌引擎主词条 |

### 2.4 蓄灵佩 `spirit_storing_amulet`（rank 4，jewelry/amulet）

主词条：回合结束至多保留 2 点灵气（energyRetain）；每保留 1 点下回合开始受 3 点纯粹伤害。
rank 4 → 前 4 条生效。

| 槽 | 词条 id | 层 | 效果 | 取舍说明 |
| --- | --- | --- | --- | --- |
| 1 | `spirituality` | A（现有） | 灵力 +increment×level | 灵力→太上感应→灵气产能，直接喂保留池 |
| 2 | `lifeMax` | A（现有） | 生命上限 +increment×level | 缓冲保留代价（3 点纯粹/点） |
| 3 | `persistent` | A（现有） | 护甲保留 | 蓄灵回合不挨打崩盘，呼应"蓄势不动" |
| 4 | `basicEnergyBonus` | A（现有） | 回合元气 +increment×level | 元气经灵气涌动 1:1 转灵气 |
| 5 | `spell_mana_trickle` | C（新） | 回合产出阶段灵气 +1（新状态 `turn_start_spell_mana_1`，复用 `turn_start_mana_bonus` 脚本、manaBonus 改为 1） | 稳定的灵气细流 |

- energyRetain 按 resourceId 合并时 max 取大、代价取首个配置（§0）——**无法用第二个 energyRetain 词条叠加保留上限**，故本装备的强化全部走"产能 + 生存"两侧，不动保留机制本身。

### 2.5 聚灵旗 `spirit_gathering_banner`（rank 5，talisman/pearl）

主词条：回合产出阶段灵气 +3（battleStatus `turn_start_mana_bonus`）；非悟道牌费用 +2（deckCostReduction）。
rank 5 → 5 条全生效。

| 槽 | 词条 id | 层 | 效果 | 取舍说明 |
| --- | --- | --- | --- | --- |
| 1 | `spirituality` | A（现有） | 灵力 +increment×level | — |
| 2 | `mana_threshold_guard` | C（新） | **聚气成势**：灵气 ≥5 时，受到的伤害 -20%（新状态，self_taking_damage 时机读灵气存量） | 攥灵气等万法归宗的回合不再裸奔 |
| 3 | `mana_empty_defend` | C（新） | **一炁**：回合结束时若灵气为 0，获得 8 点护甲（新状态，self_turn_end 时机） | 与 `_1` 互补：全打空也有兜底，鼓励"敢花" |
| 5 | `spellcraft_cost_down` | C（新） | 悟道牌费用 -1（deckCostReduction `{color: spell, amount: 1, genres: [spellcraft]}`，同天道循环节点） | rank 5 的 all-in 信号补强：纯悟道构筑全面降费 |
| 4 | `turnStartExtraDraw` | A（现有**共享 id 直接复用**） | 回合开始额外抽 1 张（附带非悟道牌抽到时 +1 费，与主词条课税叠加） | 天机盘主词条同 id——公共化的最佳示范：纯悟道构筑中课税无感，过牌纯白拿 |

- 聚灵旗与天机盘同时装备时：`turnStartExtraDraw` count 求和为 +2 抽，costIncrease 配置相同无冲突（§0 聚合规则）。

---

## 3. 新增内容汇总

### 3.1 新增公共词条（passives.json5，写在「绝世装备专用词条」区之后）

| id | 机制字段 | 层 | 用途标记 / kinds / rank | 说明 |
| --- | --- | --- | --- | --- |
| `scry_focus` | `statsBonus: {scryBonus: 1}` | B | isEquipmentExtraAffix；kinds [amulet, ring, pearl]；rank 1 | 观星深度 +1 |
| `ailment_ward` | `statsBonus: {ailmentReceiveBonus: -1}` | B | isEquipmentExtraAffix；kinds [amulet, ring, pearl]；rank 2 | 受到的元素异常 -1 |
| `ailment_inflict_focus` | `statsBonus: {ailmentInflictBonus: 1}` | B | isEquipmentExtraAffix；kinds [amulet, ring, pearl]；rank 2 | 造成的元素异常 +1 |
| `turn_start_scry_minor` | `turnStartScry: 1` | B | isEquipmentExtraAffix；kinds [amulet, ring, pearl]；rank 2 | 回合开始观星 1 |
| `ailment_to_mana_echo` | `battleStatus: first_ailment_to_mana` | C | 不写用途标记 | 首次获异常→灵气 |
| `spell_mana_trickle` | `battleStatus: turn_start_spell_mana_1` | C | 不写用途标记 | 回合灵气 +1 |
| `non_spellcraft_tax` | `deckCostReduction: {color: all, amount: -1, notGenres: [spellcraft]}` | C | 不写用途标记 | 非悟道牌 +1 费 |
| `spellcraft_cost_down` | `deckCostReduction: {color: spell, amount: 1, genres: [spellcraft]}` | C | 不写用途标记 | 悟道牌 -1 费 |
| `mana_threshold_guard` | `battleStatus: mana_threshold_guard` | C | 不写用途标记 | 聚气成势 |
| `mana_empty_defend` | `battleStatus: mana_empty_defend` | C | 不写用途标记 | 一炁 |

### 3.2 新增状态（status_effect.json5）

| 状态 id | script | callbacks | 数据 | 行为 |
| --- | --- | --- | --- | --- |
| `first_ailment_to_mana` | `first_ailment_to_mana`（新建） | `["self_gained_debuff"]` | resourceId: energy_positive_spell | 每回合第一次获得元素异常时 +1 灵气（turnFlags 记每回合一次；需判定是否元素异常——查 Constants.elementAilments 值集） |
| `turn_start_spell_mana_1` | `turn_start_mana_bonus`（**复用现有脚本**） | `["self_produce_resources"]` | manaBonus: 1 | 纯数据变体，零脚本成本 |
| `mana_threshold_guard` | `mana_threshold_guard`（新建） | `["self_taking_damage"]` | threshold: 5, reductionPercent: 20, resourceId: energy_positive_spell | 灵气≥阈值时受伤 -20% |
| `mana_empty_defend` | `mana_empty_defend`（新建） | `["self_turn_end"]` | defense: 8, resourceId: energy_positive_spell | 回合结束灵气为 0 → +8 护甲 |

全部机制字段（battleStatus/turnStartScry/deckCostReduction/statsBonus）均为白名单已有形状，**无需扩展 `_kPassiveMechanismFields`**；statsBonus 的 3 个键（scryBonus/ailmentInflictBonus/ailmentReceiveBonus）Dart 侧消费点已存在。

### 3.3 items.json5 改动

5 件装备的 `affixes` 列表在主词条后追加对应词条 id（§2 各表顺序）。其余字段不变。

---

## 4. 落地清单与风险

### 4.1 清单

- `assets/data/passives.json5`：新增 10 条公共词条（§3.1）。
- `assets/data/items.json5`：5 件装备 `affixes` 列表追加（§3.3）。
- `assets/data/status_effect.json5`：新增 4 个状态（§3.2）。
- `scripts/main/cardgame/status_script.ht`：新建 `first_ailment_to_mana` / `mana_threshold_guard` / `mana_empty_defend` 三个脚本函数（`turn_start_spell_mana_1` 复用现有脚本）。
- 本地化：`passive.json`（10 条 `passive_*_description`）、`status_effect.json`（4 组名称+描述）；装备 flavortext 若需提及词条位再更新 `item.json`。
- 校验：`game_data_validate.dart` 保持 0 错误（本批无新机制字段形状，校验器契约表无需改动）；`python build.py` 重编译。

### 4.2 风险

1. **休眠内容占比**：窥天镜 4/5、五行珠 3/5 的词条在装备破境实现前永不生效。这是有意的前瞻设计；若想立即全生效，需要把"装备破境"排上日程，或接受低境界装备只配少量词条。
2. **B 层词条进池后的平衡**：`scry_focus`/`turn_start_scry_minor` 对非悟道构筑接近死词条（无观星手段时），但观星至少还有中立 `scry` 词条与天道推演分支可得，定为"窄但非死"。若实装后池子体验变差，可降级为 C 层。
3. **引用现有池词条的数值方差**：level 在境界区间内随机（§0），`spirituality`/`battleDrawBonus` 等在高 rank 装备上数值波动大；若实测过强，给这些引用条目显式收敛 level 区间或改为机制字段定值。
4. **跌落发放时未传 level** 的行为需实现时确认（`item.ht:147`），否则词条 roll 区间不确定。
5. `ailment_ward` 使受到异常 -1，与五行珠主词条"受到 +2"同穿时净 +1——有意为之的对冲组合，文案需写清。
