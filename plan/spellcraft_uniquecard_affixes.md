# 悟道·绝世卡牌 额外词条设计（定稿）

> 承接 `plan/skill_tree/spellcraft.md`（流派总设计）。
> 本文定稿 7 张绝世卡牌各 5 条固定额外词条；配套内容（主词条改造、公共词条、机制扩展）见 §3；落地清单见 §4。
> §0 为已逐行核对代码的实现事实（旧稿有误处已修正，均附 file:line）。

---

## 0. 实现事实（核对版）

### 0.1 解锁规则

- **绝世卡**：`_addPredefinedAffixes`（`card.ht:412-427`）：`targetCount = min(预定义列表长度, card.rank)`，列表只含额外词条，第 i 条（0 起）在 **rank i+1** 解锁；`upgradeRank`（`card.ht:617-628`）对绝世卡保留全部既有词条并追加解锁下一条。
  → **每张卡 5 条额外词条**：rank 1 掉落的天机术随破境逐步解锁；rank 5 掉落的万法归宗/太上忘情**掉落即 5 条全生效**（终局卡定位）。
  （**额外词条数 = rank 为定稿设计**：旧设计 rank+1 因词条过多、玩家读不过来已废弃；how2play 与 mod 文档、overview、skill 文件已同步修正。）
- 预定义词条实例化（`_addAffixToCard`）**不查** require / rank / categories，列表写什么就解锁什么。
- 装备侧规则不同（`min(含主词条, rank+1)` 且生成时固定），见装备文档 §0。

### 0.2 紫微斗数的 rank（旧稿结论需修正）

- 构造器：构造参数 `genre` 非空且 rank==0 时抬到 1（`card.ht:104-106`，注意是**构造参数**而非数据 genre，affixId 路径不传 genre，不进此分支）；主词条定夺时 `this.rank = Math.max(mainAffix.rank, this.rank)`（`card.ht:179-181`）。紫微斗数数据层**无 rank 字段** → `Math.max(null, …)` 行为不可靠（旧稿"保持默认值 0"也不准确）。
- 洗入路径（`battle.dart:787-789`）目前只传 `affixId` + `isIdentified`，不传 rank。
- **定案**：① 数据层给主词条补 `rank: 1` 兜底，消除 null；② `battle.dart` 洗入处改传 `rank = 角色当前境界`（设计意图：紫微斗数的强度/词条数随授予时机）。角色境界在战斗数据中的字段名实现时确认。

### 0.3 观星通道（含一个活 bug）

- `scry_then_draw`（`card_script.ht:379-382`）写的是 `option: affix.scryOptions`（单数），而脚本侧声明（`battle_character.ht:59`）与 Dart 绑定（`character_binding.dart:101-103`）都读 `namedArgs['options']`（复数）；hetu 对未定义命名参数**静默丢弃** → **scryOptions 当前根本到不了 Dart，天机术的费用修饰不生效且无报错**。修复 = 参数改名单处一行。
- `BattleScene.scry`（`battle.dart:1087-1204`）：options 只消费 `chosenCostChange` / `othersCostChange` 两键；选择数**硬编码 1**（单个 Completer，展示数==可选数）；**永不触发洗牌**（牌库空直接 return）；`self_scry` 状态回调**同步分发不 await**（状态脚本契约禁止 async）；`stats.scryBonus` 全局无差别叠加（`:1095`，含敌我双方一切观星）。

### 0.4 专属词条的池外化（必须先做）

`_getSupportAffixes`（`card.ht:248-300`，随机额外词条池过滤）**没有** `inUnpackable` 守卫（该守卫只存在于主词条选取 `:118`）。
→ 所有专属词条必须在词条数据顶层写 `inUnpackable: true`，并在 `_getSupportAffixes` 加一行 `if (affix.inUnpackable == true) continue`——**否则专属词条会泄漏进随机池**，滚到别的卡上成为死词条。

### 0.5 费用与支付时序

- **支付先于全部词条脚本**（`_playCard`：支付 → 词条脚本序列）。因此动态费用卡（万法归宗/焚天烈焰）的词条只能读 `cardFlags['paidCost']`；**"打出时灵气≥N"类条件在动态费用卡上恒假**（灵气已在支付阶段耗尽）——`mana_burst` 一类现有词条不要给万法归宗。
- `priority < 0` 的额外词条先于主词条执行（增伤/预施加异常走此通道，`elemental_focus`/`mana_burst` 先例）；支付在一切脚本之前，故 priority<0 的词条**也能读 paidCost**。
- `updateCardCost` 丢弃普通 0 值条目（`card.ht:41-50`）→ `{life: 0}` 的紫微斗数费用表为**空表**：减费对其静默无操作，加费可反向创建条目。旧稿据此删除"此牌费用-2"条目的结论保持不变。
- 免费卡加费兜底：`_applyTurnCostIncrease`（`battle.dart:898-918`）对空费用表回退主词条显式 coloredCost 首键，加费照常生效。

### 0.6 元素与异常

`Constants.elementAilments` 定义 7 元素（金/木/水/火/土/风/雷）→ 异常映射；悟道主词条只用了 5 种（火/水/雷/风/土），金=御剑、木=炼魂。一气化三清的抉择只供水/火/雷三种增幅状态（`buff_element_amplify_*`）。

### 0.7 太上忘情状态确认存在

状态 id = `buff_handcards_to_mana`（`status_effect.json5:797`，参数 `damagePerCard: 10` / `resourcePerCard: 1`），script 基名 `handcards_to_mana` → 函数 `handcards_to_mana_self_turn_end`。旧稿"状态名待考"的疑虑排除；§2.5 的参数覆盖设计以此为准。

---

## 1. 设计原则

沿用项目既有约定（battlecard / unique-equipment skill）：

1. **正反双段式**：强正面 + 限制/代价。
2. **负面类型优先级**：方向性限制 > 对称效果 > 自伤/自异常 > 纯数值惩罚。
3. **专属要克制**。判定标准落实为一条：**消费主词条中间结果的词条必须专属**——天机术（观星选中的牌）、紫微斗数（抽到的那张牌）、蓄灵诀（本次获得的灵气数）、万法归宗（paidCost）、太上忘情（所授状态的参数）。通用效果（抽牌/护甲/治疗）一律公共，不白白从随机池挖掉内容。
4. **列表顺序 = 投资路线图**：第 i 条在 rank i+1 解锁（§0.1），前两条必须让卡在下限境界就"像它自己"。
5. **数值让位于机制**：优先"条件 + 效果"；纯数值中立池已有 21 条。
6. **公共新词条参数化**：阈值/资源 id/过滤条件写入词条数据，脚本保持通用，供其他流派复用。

---

## 2. 七张卡定稿（各 5 条）

### 2.1 天机术 `spellcraft_scry_draw`（rank 1，规划主题）

**实现方案（修订）**：主脚本 `scry_then_draw` 改为**收集** `card.affixes[1..]` 的 `scryOptions` 子表（数值键累加、布尔键取真），合并后随 `options` 传给 `self.scry`（依赖 §0.3 参数名修复）。词条为**纯数据**（不写 script），无优先级/重复打出问题——契约上合法：`docs/docs/mod/battle/card/readme.md` 明确"词条没有 script 字段则不参与任何回调（含打出）"。Dart 侧 scry 需新消费 3 个键（均轻量）：`upgradeChosen`（选中牌等级+1）、`retainChosen`（选中牌获得保留）、`scryBonus`（本次观星额外查看 N，与全局 stats.scryBonus 叠加）；`chosenCostChange`/`othersCostChange` 已就绪。

| 解锁 rank | id | 公共/专属 | 效果 | 数据（scryOptions） |
| --- | --- | --- | --- | --- |
| 1 | `spellcraft_scry_draw_affix_1` | 专属 | 观星未选中的牌费用 +1（**不叠加**：同一卡本场战斗只生效一次） | `{othersCostChange: 1}` |
| 2 | `spellcraft_scry_draw_affix_2` | 专属 | 观星选中的牌等级 +1 | `{upgradeChosen: 1}` |
| 3 | `spellcraft_scry_draw_affix_3` | 专属 | 观星选中的牌费用 -1 | `{chosenCostChange: -1}` |
| 4 | `spellcraft_scry_draw_affix_4` | 专属 | 观星选中的牌获得保留 | `{retainChosen: true}` |
| 5 | `spellcraft_scry_draw_affix_5` | 专属 | 观星时额外查看 2 张 | `{scryBonus: 2}` |

- 数值一律内嵌 scryOptions 定值（与绝世装备机制字段同哲学）；本地化描述写死数值、不用占位符，改动时同步文案（项目已有先例）。

### 2.2 相生相克 `spellcraft_ailments_by_used_elements`（rank 2，轮转/自异常）

主词条不变：对双方施加随机元素异常，种数 = 本回合已用元素种数（至少 1），每种 value[0] 层。

| 解锁 rank | id | 公共/专属 | 效果 | 数据 / 脚本 |
| --- | --- | --- | --- | --- |
| 1 | `spellcraft_ailments_by_used_elements_affix_1` | 专属 | 本回合每使用过一种元素，本次施加层数 +1 | priority -1 脚本写 `cardFlags['ailmentBonusPerElement']`，主脚本 `ailments_by_used_elements` 读取叠加；`valueData: [{base:1, isFixed:true}]` |
| 2 | `cleanse_draw` | 公共（新·悟道） | **化浊为清**：移除自身随机 1 种元素异常，抽 1 张牌 | 新通用脚本 `cleanse_draw`；与蓄灵诀 `_2` 共用 |
| 3 | `ailment_kinds_to_mana` | 公共（新·悟道） | 自身持有 3 种以上不同元素异常时，获得 1 点灵气 | 新通用脚本 `gain_resource_by_self_ailment_kinds`；数据 `{threshold: 3, resourceId: energy_positive_spell, count: 1}` |
| 4 | `for_element_ailment_defend` | 公共（新·悟道，§3.3） | 打出时自身每有 1 层元素异常，获得 {0} 护甲 | 新通用脚本 `defend_by_self_ailments`（§3.3） |
| 5 | `draw_by_self_ailment_kinds` | 公共（新·悟道） | 自身持有 3 种以上不同元素异常时，抽 1 张牌 | 新通用脚本；数据 `{threshold: 3, count: 1}` |

- `_1` 消费"本次施加层数"这一主词条中间结果 → 必须专属。
- `_2` 是自异常引擎的**节流阀**：自己清一层换抽牌，避免异常堆到必须用水疗术清场，与 `_3/_4/_5` 的"留异常"奖励形成张力。
- `_3` 与蓄灵诀 `_3`（七情归一）共用同一参数化脚本，仅 threshold/resourceId 不同。
- 协同备注：现有中立词条 `buff_crit`（幸运，rank 1 起在池）可让元素攻击牌必定造成异常（不耗计数器），是本卡的零成本铺设加速器——随机池已提供，无需新内容。

### 2.3 一气化三清 `spellcraft_element_amplify`（rank 3，元素专注）

主词条不变：抉择水/火/雷之一，本回合双方造成的该元素伤害 +{0}%。

**实现方案**：与天机术同 pattern——主脚本 `discover_element_amplify` **收集**词条修饰字段，兑现到抉择授予的 `buff_element_amplify_*` 状态实例上（状态实例字段优先于状态数据默认值）。词条为纯数据（修饰字段见下），状态脚本 `element_amplify` 扩展消费这些字段。

| 解锁 rank | id | 公共/专属 | 效果 | 修饰字段 / 实现 |
| --- | --- | --- | --- | --- |
| 1 | `spellcraft_element_amplify_affix_1` | 专属 | 抉择后，下一次受到所选元素伤害时获得 {0} 点护盾（消耗） | `guardValue`；状态携此字段，`element_amplify` 增加 `self_taking_damage` 行为 |
| 2 | `spellcraft_element_amplify_affix_2` | 专属 | 对手使用所选元素的牌后，你下回合产出阶段 +1 灵气 | `mirrorMana: 1`；状态增加 `opponent_used_card` 时机检查元素，写 `pendingResources` |
| 3 | `spellcraft_element_amplify_affix_3` | 专属 | 抉择后，本回合手牌中所选元素的牌费用 -1 | `chosenCostReduce: -1`；已实现：脚本侧 getHandCards 按元素过滤 + 逐卡 applyTurnCostModifier（无需 Dart 扩展；语义从"下一张"放宽为"手牌中所选元素牌"） |
| 4 | `spellcraft_element_amplify_affix_4` | 专属 | 打出时每有 1 点灵气，本次增幅 +5% | `amplifyPerMana: 5`；主脚本读当前灵气存量（普通费用卡，支付后余量可读）加成果幅 |
| 5 | `spellcraft_element_amplify_affix_5` | 专属 | **三清护体**：本回合受到所选元素的伤害 -30% | `chosenDamageTakenReduce: 30`；与 `_1` 共用状态的消费通道（减伤不消耗、护盾消耗） |

- 全部消费"所选元素"这一主词条中间结果 → 全部专属，但**零新脚本**：只扩展状态字段与主脚本的收集逻辑。
- `_1/_5` 对冲对称代价（敌人用你的元素打你）；`_2` 是"锦上添花"，AI 行为不可控、可能长期不触发，不作为构筑支点。
- `_3` 依赖 `applyTurnCostModifier` 支持按元素过滤（现状只支持流派维度），列为小扩展。

### 2.4 蓄灵诀 `spellcraft_ailments_to_mana`（rank 4，自异常转灵气引擎）

主词条不变：自身每有 1 种元素异常，获得 1 点灵气（上限 7）。
**配套改动**：主脚本 `gain_mana_by_self_ailments` 把本次获得数写入 `cardFlags['lastManaGained']`（供 `_1/_4/_5` 消费）。

| 解锁 rank | id | 公共/专属 | 效果 | 数据 / 脚本 |
| --- | --- | --- | --- | --- |
| 1 | `spellcraft_ailments_to_mana_affix_1` | 专属 | **纳气之后**：若本次获得 ≥3 点灵气，每点使你获得 {1} 点护甲 | 新脚本 `mana_gained_to_defense`；`valueData: [{base:3, isFixed:true}, {base:12, increment:0.6}]` |
| 2 | `cleanse_draw` | 公共（与相生相克 `_2` 共用） | **化浊为清**：移除自身随机 1 种元素异常，抽 1 张牌 | 见 §2.2 |
| 3 | `ailment_kinds_to_ultimate` | 公共（新·悟道） | **七情归一**：自身持有 5 种以上不同元素异常时，获得 1 点太极之气 | 与相生相克 `_3` 同脚本；数据 `{threshold: 5, resourceId: energy_positive_ultimate, count: 1}` |
| 4 | `spellcraft_ailments_to_mana_affix_4` | 专属 | **灵气回响**：若本次获得 ≥1 点灵气，本回合你的悟道牌费用 -1 | 新脚本 `mana_gained_cost_reduce`；`applyTurnCostModifier {amount:-1, genres:[spellcraft]}` |
| 5 | `spellcraft_ailments_to_mana_affix_5` | 专属 | **反噬成道**：若本次获得 ≥5 点灵气，下回合开始受到（获得数×2）点纯粹伤害，且下回合首张悟道牌伤害 +15% | 新脚本 `backlash_path`，写 `pendingEffects`（§3.5）；数值谨慎、可再下调 |

- `_1` 把引擎爆发转成生存，引擎回合不裸奔。
- `_3` 太极之气是万能抵扣（灵气不能靠它支付），作顶层奖励既有价值又自带限制。
- `_5` 是高风险报酬，与 `_2`（清异常降收益）方向相反，给玩家两种构筑取舍。
- 隐性张力：一切治疗都会随机驱散一层自身负面效果（含元素异常）——治疗卡会侵蚀自异常引擎的燃料，构筑时需在"清场保命"与"留异常产能"之间取舍。

### 2.5 太上忘情 `spellcraft_handcards_to_mana`（rank 5，手牌取舍）

主词条不变：`self_buff` 授予 `buff_handcards_to_mana` 状态（回合结束每手牌 10 点纯粹伤害 → 下回合每手牌 1 点灵气，触发后移除）。

**实现方案**：词条以 priority -1 把 `statusParams` 修正写入 `card.cardFlags`，`self_buff` 授予状态时合并（状态实例字段 > 状态数据默认值，`handcards_to_mana` 脚本改为优先读实例字段）。`_1/_2` 走此通道。此通道实现为**通用机制**（任何 self_buff 授予状态的卡均可复用），非太上忘情专属。

| 解锁 rank | id | 公共/专属 | 效果 | 数据 / 脚本 |
| --- | --- | --- | --- | --- |
| 1 | `spellcraft_handcards_to_mana_affix_1` | 专属 | **舍念**：本牌施加的状态，每张手牌的纯粹伤害 -3 | `statusParams: {damagePerCard: -3}` |
| 2 | `spellcraft_handcards_to_mana_affix_2` | 专属 | **静心**：本牌施加的状态，每张手牌的额外灵气 +1 | `statusParams: {resourcePerCard: 1}` |
| 3 | `spellcraft_handcards_to_mana_affix_3` | 专属 | **忘我**：本牌结算后，下回合第一张悟道牌伤害 +{0}% | 写 `pendingEffects`；`valueData: [{base:30, increment:2.5}]` |
| 4 | `spellcraft_handcards_to_mana_affix_4` | 专属 | **藏锋**：打出时，手牌中随机一张悟道牌获得保留 | 新通用脚本 `retain_random_card_with_filter`，filter `{genre: spellcraft}` |
| 5 | `hand_size_defend` | 公共（新·中立） | **无情**：打出时若手牌数 ≥4，获得 {0} 点护甲 | 新通用脚本 `defend_by_hand_count`；`valueData: [{base:12, increment:0.6}, {base:4, isFixed:true}]` |

- `_1` 是**解绑**：把"高风险高回报"调成"中风险中回报"。
- `_4` 与主词条形成闭环：保留的手牌在回合结束同时放大伤害与次回合灵气，是"主动选择的风险"。
- 维持旧稿警告：**不要**给太上忘情配 `draw_cards_neutral` / `mana_battery`（同时扩大手牌收益与灵气收益，风险消失）。

### 2.6 紫微斗数 `spellcraft_draw_cards_reduce_cost`（rank = 授予时角色境界，§0.2）

主词条修订：**抽 1 张法术牌（filter `{cardType: "spell"}`），将其费用降为 0**（`reduceCost: {}` 空条件表；动态费用条目不参与归零——`clearReducibleCardCosts` 已豁免，写进文案）。原为"抽 1 张牌费用改 0"，收窄为法术牌以强化"定向获得"定位。`isEphemeral`/`isUnpackable` 不变。

**实现方案**：`drawCardsToHand`（Dart）把本批抽到的牌记录进 `self.cardFlags['lastDrawnCards']`（小改动）；主脚本改为专用 `ziwei_draw`：先走 `draw_cards` 等效流程（filter + reduceCost 经 options 传入），再收集词条修饰字段对 `lastDrawnCards[0]` 兑现。

| 解锁 rank | id | 公共/专属 | 效果 | 数据 / 修饰字段 |
| --- | --- | --- | --- | --- |
| 1 | `defend` | **公共（现有中立词条复用）** | 获得 {0} 点护甲 | 直接引用现有词条 id |
| 2 | `spellcraft_draw_cards_affix_1` | 专属 | **定星**：抽到的牌等级 +1 | `drawnUpgrade: 1` |
| 3 | `spellcraft_draw_cards_affix_2` | 专属 | **留命**：抽到的牌获得保留 | `drawnRetain: true` |
| 4 | `spellcraft_draw_cards_affix_3` | 专属 | **星移**：若抽到悟道牌，获得 1 点灵气 | `drawnManaIfGenre: {genre: spellcraft, resourceId: energy_positive_spell, count: 1}` |
| 5 | `spellcraft_draw_cards_affix_4` | 专属 | **逆天改命**：若抽到的不是悟道牌，额外抽 1 张（第二张不再归零） | `drawnExtraDrawIfNotGenre: {genre: spellcraft, count: 1}` |

- 洗入时 rank = 角色境界 → 凝气期获得只有 `_1`（抽牌+护甲），化神期获得 5 条全解，符合"投资路线图"。
- `_1` 有意复用中立 `defend`：验证"绝世卡固定词条可直接引用公共词条"的链路，零新内容成本。
- 旧稿两条已删并说明：「此牌费用 -2」在空费用表上是空操作（§0.5）；「抽到的牌费用 -1」被「费用为 0」完全覆盖。

### 2.7 万法归宗 `spellcraft_ultimate_spell`（rank 5，终局爆发）

主词条不变：耗费 10+X 点灵气（禁太极抵扣、不免动态费），按 paidCost 每点造成 {0} 雷电伤害。
**先补数据层 `affixes` 键**（现状缺失）。rank 5 掉落 → 5 条全解锁（§0.1）。

| # | id | 公共/专属 | 效果 | 数据 / 脚本 |
| --- | --- | --- | --- | --- |
| 1 | `spellcraft_ultimate_spell_affix_1` | 专属 | **落雷击顶**：实际支付超过 10 点的每点灵气，对对手施加 1 层感电 | priority -1 读 paidCost，先于伤害结算；阈值自动读主词条动态费用 base（可用 `threshold` 字段覆盖），无数值表 |
| 2 | `spellcraft_ultimate_spell_affix_2` | 专属 | **万法余波**：实际支付超过 10 点的每点灵气，获得 {0} 点护甲 | 新脚本 `defend_by_excess_paid` 读 paidCost−10；`valueData: [{base:5}]` |
| 3 | `spellcraft_ultimate_spell_affix_3` | 专属 | **雷行九霄**：若对手已持有感电，本牌伤害 +{0}% | priority -1；`valueData: [{base:20, increment:2}]` |
| 4 | `spellcraft_ultimate_spell_affix_4` | 专属（可公共化备选） | **一法破万法**：本回合每使用过一种元素，本牌伤害 +{0}% | priority -1 读 `usedElements`；`valueData: [{base:8, increment:1}]` |
| 5 | `spellcraft_ultimate_spell_affix_5` | 专属 | **归宗之后**：打出后抽 1 张牌并使其费用变为0，但你获得3点逆灵之气 | 新脚本 `draw_and_self_buff`；`buffId: energy_negative_spell`；`valueData: [{base:1, isFixed:true}, {base:3, isFixed:true}]` |

- **落雷击顶与雷行九霄是双档关系**：火/水/雷/木攻击卡在目标持有对应异常时转化为元素伤害（无视护甲、只吃抗性，每牌耗 1 层异常）。落雷击顶（priority -1 先于伤害结算）让本次万法归宗命中时目标已持感电 → **当次伤害即转化为雷电、无视护甲**，剩余层数在对手回合开始耗尽（每层 1~10 点雷伤 DOT）；雷行九霄对应"事前已铺设感电"的更高回报（转化 + DOT + 增伤）。两者同场可叠加。
- 逆灵之气是 isResource 而非 isDebuff——**辟邪（buff_ward）无法抵消它**，归宗之后的代价必定落地。
- **对抗面与节奏**：落雷击顶/相生相克式的"直接施加"异常会被辟邪按层抵消、被对手的不幸按层抵消（不消耗异常计数器≠无对抗面）；元素转化每张牌只耗 1 层对应异常，因此落雷击顶无封顶的多层铺设，只有在"连打雷系牌"的构筑里才不浪费。

## 3. 配套补充内容

### 3.1 改造 `water_mend`（甘霖术）

现"回血 + 移除自身**全部**元素异常"整层清空、不计数。改为按层移除：

| 字段 | 值 |
| --- | --- |
| `script` | `heal_remove_debuffs_by_stack`（新建：至多移除 value[1] 层（跨 debuffs 列表合计），每移除 1 层结算 value[0] 治疗；`removeStatusEffect` 返回实际移除层数可据以计数） |
| `valueData[0]` | `{base: 4, increment: 0.1}`（每层治疗） |
| `valueData[1]` | `{base: 3, increment: 0.15}`（至多移除层数） |
| `uniqueIds` | `["for_element_ailment_heal"]`（与 §3.3 额外词条互斥） |

### 3.2 新卡 `earth_mend`（护甲版清异常）

| id | rank | kind | 元素 | cardType | 效果 | script | valueData |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `earth_mend` | 3 | earthbend | 土 | spell | 至多移除 {1} 层元素异常，每移除 1 层获得 {0} 点护甲 | `defend_remove_debuffs_by_stack`（新建） | `[{base:6, increment:0.15}, {base:3, increment:0.15}]` |

`uniqueIds: ["for_element_ailment_defend"]`，与 §3.3 额外词条互斥。

### 3.3 补两条公共额外词条（元素异常 → 生命/护甲）

| id | script（新建） | rank | categories | genres | 效果 | uniqueId |
| --- | --- | --- | --- | --- | --- | --- |
| `for_element_ailment_heal` | `heal_by_self_ailments` | 3 | buff | spellcraft | 打出时自身每有 1 层任意元素异常，回复 {0} 生命 | `for_element_ailment_heal` |
| `for_element_ailment_defend` | `defend_by_self_ailments` | 3 | buff | spellcraft | 打出时自身每有 1 层任意元素异常，获得 {0} 护甲 | `for_element_ailment_defend` |

`for_element_ailment_defend` 同时被相生相克 `_4` 引用（§2.2）。

结算顺序注意：`heal_by_self_ailments` 必须先按当前异常层数计数、结算治疗量，再执行治疗（`changeLife` 会随机驱散一层负面效果、含元素异常；顺序反了数值会被自己的治疗吃掉）。

### 3.4 补"调息"（attune）的重算缺口（已核实属实）

`reduce_cost_by_cards_in_hand` 只在进/出手牌的那张牌自己身上重算（`added_to_hand` 1 个派发点 `battle.dart:1018`、`removed_from_hand` 3 个）；其余手牌不补跑 → 抽到同元素伙伴时先前已减费的卡不复查，伙伴离手时已减费的卡不恢复。
**修复方向（Dart 机制层）**：`handleCardAffixCallback`（`battle.dart:1057-1069`）派发后，对手牌区其余卡牌补跑同一时机回调。`_added_to_hand` 已内建幂等撤销（`card_script.ht:503-505` 先还原再检测），重复调用安全。

### 3.5 机制扩展清单（本批全部新通道）

**Dart（`battle.dart` / `character_binding.dart` / `card_cost.dart`）**：

| 通道 | 内容 | 体量 |
| --- | --- | --- |
| scry options | 修复 `option`→`options` 传参；新消费 `upgradeChosen`/`retainChosen`/`scryBonus` 三键 | 小 |
| `lastDrawnCards` | `drawCardsToHand` 把本批抽到的牌记入 `self.cardFlags['lastDrawnCards']` | 小 |
| `pendingEffects` | 跨回合效果队列（仿 `pendingResources`）：`genreDamageBonus{genre,percent,oneShot}`（忘我/反噬成道）、`pendingSelfDamage{amount,damageType}`（反噬成道） | 中 |
| `applyTurnCostModifier` | 确认/扩展元素维度过滤（一气化三清 `_3`）；流派维度已支持 | 小 |
| 洗入 rank | `battle.dart:787-789` 洗入紫微斗数时传 `rank = 角色境界` | 小 |

**Hetu（`card_script.ht`）**：

- 改造：`scry_then_draw`（收集 scryOptions + 参数改名）、`discover_element_amplify`（收集修饰字段）、`gain_mana_by_self_ailments`（写 `lastManaGained`）、`self_buff`（合并 `statusParams`）、`ailments_by_used_elements`（读 `ailmentBonusPerElement`）。
- 新建：`cleanse_draw`、`gain_resource_by_self_ailment_kinds`、`draw_by_self_ailment_kinds`、`defend_by_self_ailments`、`heal_by_self_ailments`、`heal_remove_debuffs_by_stack`、`defend_remove_debuffs_by_stack`、`retain_random_card_with_filter`、`defend_by_hand_count`、`mana_gained_to_defense`、`mana_gained_cost_reduce`、`backlash_path`、`ziwei_draw`、`ailment_bonus_per_element`、`defend_by_excess_paid`、`ailment_by_excess_paid`、`draw_and_self_buff`、万法归宗 `_3/_4` 的 priority -1 增伤（可复用/扩展现有 increase_damage 系）。

**状态（`status_script.ht` + `status_effect.json5`）**：

- 扩展 `buff_element_amplify_*`（3 个）：`element_amplify` 脚本增加 `guardValue`（受击护盾，消耗）、`chosenDamageTakenReduce`（减伤）、`mirrorMana`（`opponent_used_card` 时机）字段消费；状态数据 callbacks 补 `self_taking_damage` / `opponent_used_card`。
- `handcards_to_mana` 脚本改为状态实例字段优先（`damagePerCard`/`resourcePerCard` 可被 `statusParams` 覆盖）。

**校验器**：新词条机制字段（`scryOptions` / 修饰字段 `guardValue` 等 / `statusParams` / `threshold` / `resourceId` / 专属词条 `inUnpackable` 约定）需同步进校验器契约表，否则新内容逃逸校验。

---

## 4. 落地清单与风险

### 4.1 数据文件

- `assets/data/cards.json5`：紫微斗数补 `rank: 1` + `affixes`；万法归宗补 `affixes`；7 张卡填入 5 条词条 id 列表；`water_mend` 改 script/valueData；新增 `earth_mend`；紫微斗数主词条 filter 收窄为 `{cardType: "spell"}`。
- `assets/data/card_affixes.json5`：新增约 27 条专属词条（带 `inUnpackable: true`）+ 7 条公共词条（`cleanse_draw` / `ailment_kinds_to_mana` / `ailment_kinds_to_ultimate` / `draw_by_self_ailment_kinds` / `for_element_ailment_heal` / `for_element_ailment_defend` / `hand_size_defend`）。

### 4.2 脚本

- `card.ht`：`_getSupportAffixes` 加 `inUnpackable` 守卫（**一行，必须最先做**）。
- `card_script.ht` / `status_script.ht`：见 §3.5。

### 4.3 本地化

- `battlecard.json`：全部新词条 `affix_*` 名称与 `affix_*_description`；紫微斗数/甘霖术文案更新（动态费用不参与归零需写明）；`uniquecard_*` 若改名需同步。

### 4.4 校验

- `dart run utils/data_validate/game_data_validate.dart`（基线 0 错误）→ 契约表同步后应保持 0 错误。
- `python build.py` 重编译；`flutter analyze`。

### 4.5 风险

1. **`uniqueIds` 顺序依赖**：词条必须先于引用它的主词条存在（校验器报悬空引用）。
2. **观星多选（pickBonus）已移出本批**：5 条定稿不依赖任何重工程。
3. **数值标定锚点缺失**：化神期灵力成长曲线未定，文中 valueData 只给量级参考；蓄灵诀 `_1`（每点 12 护甲）、反噬成道等偏强数值建议实装后第一批回调。
4. **一气化三清 `_2` 触发率不可控**（依赖 AI 用所选元素），定位为锦上添花。
5. **跨回合 `pendingEffects` 是本批最大的新机制**（2 种类型：genreDamageBonus / pendingSelfDamage，消费方为忘我与反噬成道），需先在 Dart 侧定型结构再写内容。
6. **单次获得层数上限待确认**：资源文档（`resource/readme.md` 溢出节）声明"单次获得的层数受上限（灵力/身法）约束、超出截断"，但 `addStatusEffect` 与状态数据中未见对应实现——若未实现（文档滞后）则无事；若已实现，蓄灵诀单次 7 点、聚灵旗 +3 等产能会被截断，万法归宗凑费曲线需重估。
