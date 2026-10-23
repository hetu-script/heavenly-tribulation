# 悟道绝世词条·实施计划

> 输入文档：`plan/spellcraft_uniquecard_affixes.md`（7 张绝世卡词条定稿）、`plan/spellcraft_uniqueequipment_affixes.md`（5 件绝世装备词条定稿）。
> 本文是施工清单：按依赖分 6 个阶段，每项给出文件/函数/改动内容/验收方式。词条的数值与效果描述以定稿文档为准，本文不重复。

---

## 阶段 0 · 前置修复（无内容依赖，最先做）

| # | 文件·位置 | 改动 | 验收 |
| --- | --- | --- | --- |
| 0.1 | `scripts/main/cardgame/card.ht` `_getSupportAffixes`（:248-300） | 过滤循环加 `if (affix.inUnpackable == true) continue` | **必须先于一切专属词条数据落地**，否则专属词条泄漏进随机池 |
| 0.2 | `scripts/main/cardgame/card_script.ht:380` | `option:` → `options:`（参数名与 `battle_character.ht:59` 声明对齐） | 天机术 scryOptions 的费用修正在战斗中生效 |
| 0.3 | `lib/scene/battle/battle.dart` `handleCardAffixCallback`（:1057-1069） | `added_to_hand`/`removed_from_hand` 派发后，对手牌区其余卡补跑同一时机回调 | attune（调息）卡在伙伴进/出手牌时费用正确增减；幂等已由 `card_script.ht:503-505` 保证 |

---

## 阶段 1 · Dart 机制层扩展

| # | 位置 | 改动 | 消费内容 |
| --- | --- | --- | --- |
| 1.1 | `battle.dart` `scry`（:1087-1204） | options 新消费 3 键：`upgradeChosen`（选中牌等级+N）、`retainChosen`（选中牌设 isRetained）、`scryBonus`（本次观星张数+N，与全局 stats.scryBonus 叠加）。约束：单选 Completer、永不洗牌、self_scry 同步分发均不变 | 天机术全部 5 条 |
| 1.2 | `battle.dart` `drawCardsToHand`（:981-1042） | 本批实际入手的牌写入 `character.cardFlags['lastDrawnCards']`（每次调用覆盖写） | 紫微斗数 4 条修饰 |
| 1.3 | `battle.dart` / `character.dart` | `pendingEffects` 跨回合队列（结构仿 `pendingResources`）：`{type: 'genreDamageBonus', genre, percent, oneShot: true}` 下回合首张 genre 牌增伤（消费于出牌伤害结算）；`{type: 'pendingSelfDamage', amount, damageType}` 下回合开始自伤（消费于回合开始回调之后） | 太上忘情·忘我、蓄灵诀·反噬成道 |
| 1.4 | ~~`applyTurnCostModifier` 元素过滤~~ | **无需 Dart 改动**（已确认）：现有签名为单卡 `applyTurnCostModifier(cardData, {delta})`，脚本侧 `getHandCards({elementType: ...})` + 逐卡调用实现，语义为"手牌中所选元素牌本回合 -1 费" | 一气化三清 `_3` |
| 1.5 | `battle.dart:787-789`（shuffleIntoDeck 洗入） | `BattleCard` invoke 增加 `rank: 角色当前境界`（角色境界在战斗数据中的字段名实现时确认） | 紫微斗数词条数随授予境界 |
| 1.6 | `card_script.ht` `self_buff` + 状态实例 | statusParams 覆盖通道：priority -1 词条先把修正写入 `card.cardFlags['statusParams']`，`self_buff` 授予状态时合并进状态实例；状态脚本读实例字段优先于数据默认值。实现时确认脚本侧写状态实例自定义字段的方式（HTStruct 动态属性） | 太上忘情 `_1/_2` |

---

## 阶段 2 · Hetu 脚本（`scripts/main/cardgame/`）

统一签名 `(self, opponent, card, affix)`；调用异步 API（drawCards/scry/discover 等）的脚本必须 `async` 并 `await`。

### 2.1 `card_script.ht` 改造（5 个）

| 函数 | 改动 | 消费词条 |
| --- | --- | --- |
| `scry_then_draw` | 收集 `card.affixes[1..]` 的 `scryOptions` 子表（数值键累加、布尔键取真），合并后随 `options` 传给 `self.scry` | 天机术全部 |
| `discover_element_amplify` | 收集词条修饰字段（`guardValue`/`mirrorMana`/`chosenCostReduce`/`amplifyPerMana`/`chosenDamageTakenReduce`），授予状态时写入状态实例；`chosenCostReduce` 走 `applyTurnCostModifier`；`amplifyPerMana` 读当前灵气存量加成果幅 | 一气化三清全部 |
| `gain_mana_by_self_ailments` | 本次获得数写入 `cardFlags['lastManaGained']` | 蓄灵诀 `_1/_4/_5` |
| `self_buff` | 授予状态时合并 `card.cardFlags['statusParams']`（见 1.6） | 太上忘情 `_1/_2` |
| `ailments_by_used_elements` | 读取 `cardFlags['ailmentBonusPerElement']` 叠加施加层数 | 相生相克 `_1` |

### 2.2 `card_script.ht` 新建（19 个）

| 函数 | 行为 | 数据字段 | 消费词条 |
| --- | --- | --- | --- |
| `ailment_bonus_per_element` | priority -1：按本回合已用元素种数写 `cardFlags['ailmentBonusPerElement']`（主词条读取叠加） | valueData | 相生相克 `_1` |
| `cleanse_draw` | async：移除自身随机 1 种元素异常（按 `Constants.elementAilments` 值集判定），抽 1 张 | — | `cleanse_draw`（相生相克 `_2` / 蓄灵诀 `_2`） |
| `gain_resource_by_self_ailment_kinds` | 自身元素异常种数 ≥ `affix.threshold` → 获得 `affix.count` 层 `affix.resourceId` | threshold / resourceId / count | 相生相克 `_3`、蓄灵诀 `_3`（七情归一，仅参数不同） |
| `draw_by_self_ailment_kinds` | 同条件抽 `affix.count` 张 | threshold / count | 相生相克 `_5` |
| `defend_by_self_ailments` | 自身每 1 层元素异常 → value[0] 护甲 | valueData | `for_element_ailment_defend`（相生相克 `_4`） |
| `heal_by_self_ailments` | 自身每 1 层元素异常 → value[0] 治疗（**先计数结算、再执行治疗**：`changeLife` 会随机驱散一层负面含元素异常，顺序反了数值会被自己的治疗吃掉） | valueData | `for_element_ailment_heal` |
| `heal_remove_debuffs_by_stack` | 至多移除 value[1] 层（跨 `affix.debuffs` 合计），每层结算 value[0] 治疗；`removeStatusEffect` 返回实际移除层数据以计数 | valueData / debuffs | `water_mend` 改造 |
| `defend_remove_debuffs_by_stack` | 同上，每层获得 value[0] 护甲 | valueData / debuffs | `earth_mend` 新卡 |
| `retain_random_card_with_filter` | 手牌中随机 1 张 `affix.filter` 匹配的牌设 isRetained | filter | 太上忘情 `_4`（藏锋） |
| `defend_by_hand_count` | 手牌数 ≥ value[1] → 获得 value[0] 护甲 | valueData×2 | `hand_size_defend`（太上忘情 `_5` 无情） |
| `mana_gained_to_defense` | `lastManaGained` ≥ value[0] → 每点获得 value[1] 护甲 | valueData×2 | 蓄灵诀 `_1`（纳气之后） |
| `mana_gained_cost_reduce` | `lastManaGained` ≥ 1 → `applyTurnCostModifier {amount: -1, genres: [spellcraft]}` | — | 蓄灵诀 `_4`（灵气回响） |
| `backlash_path` | `lastManaGained` ≥ 5 → `pendingEffects` 追加 genreDamageBonus + pendingSelfDamage（数值见定稿） | valueData | 蓄灵诀 `_5`（反噬成道） |
| `ziwei_draw` | async：紫微斗数专用主脚本——走 `draw_cards` 等效流程（filter `{cardType:'spell'}` + reduceCost 经 options 传入），再收集词条 `drawnUpgrade`/`drawnRetain`/`drawnManaIfGenre`/`drawnExtraDrawIfNotGenre` 修饰字段，对 `cardFlags['lastDrawnCards'][0]` 兑现；额外抽的第二张不再归零。**顺序注意：先对第一张兑现完全部修饰，最后才处理逆天改命的额外抽**——`lastDrawnCards` 每次抽牌覆盖写，额外抽会冲掉记录 | 修饰字段 | 紫微斗数 `_1.._4` |
| `ailment_by_excess_paid` | priority -1：超额部分每点对对手施加 1 层 `affix.buffId`（先于伤害结算） | threshold / buffId | 万法归宗 `_1`（落雷击顶，无层数封顶） |
| `defend_by_excess_paid` | 超额部分 × value[0] 护甲 | threshold / valueData | 万法归宗 `_2`（万法余波） |
| `damage_boost_if_opponent_status` | priority -1：对手持有 `affix.buffId` → 本牌伤害 +value[0]% | buffId / valueData | 万法归宗 `_3`（雷行九霄，buffId=ailment_lightning） |
| `increase_damage_by_used_elements` | priority -1：`usedElements` 种数 × value[0]% 增伤 | valueData | 万法归宗 `_4`（一法破万法） |
| `draw_and_self_buff` | async：抽 value[0] 张（options 传 `{reduceCost: {}}` 置零，动态条目豁免）+ 自施 `affix.buffId` value[1] 层（source: self） | buffId / valueData×2 | 万法归宗 `_5`（归宗之后，buffId=energy_negative_spell） |

> 超额（excess）统一口径：`paidCost[affix.resourceId ?? 'energy_positive_spell'] − affix.threshold`；threshold 缺省时读主词条动态费用条目的 base（万法归宗 = 10）。

### 2.3 `status_script.ht` + 状态数据

| 项 | 改动 |
| --- | --- |
| `element_amplify`（`buff_element_amplify_*` 三状态共用脚本） | 扩展消费状态实例字段：`guardValue`（`self_taking_damage`：受所选元素伤害时获得护盾并消耗）、`chosenDamageTakenReduce`（同时机减伤、不消耗）、`mirrorMana`（`opponent_used_card`：对手用所选元素牌后写 pendingResources +1 灵气）；`status_effect.json5` 三状态 callbacks 补 `self_taking_damage` / `opponent_used_card` |
| `handcards_to_mana` | `damagePerCard`/`resourcePerCard` 读状态实例字段优先于状态数据默认值（配 1.6） |
| `first_ailment_to_mana` | 新建（`self_gained_debuff`）：每回合第一次获得元素异常（按 Constants.elementAilments 值集判定）→ +1 层 `energy_positive_spell`；turnFlags 记每回合一次 |
| `mana_threshold_guard` | 新建（`self_taking_damage`）：`energy_positive_spell` ≥ threshold（5）→ 伤害 -reductionPercent（20%） |
| `mana_empty_defend` | 新建（`self_turn_end`）：`energy_positive_spell` 为 0 → 获得 defense（8）护甲 |
| `turn_start_mana_bonus` | **复用现有脚本**：新状态 `turn_start_spell_mana_1` 纯数据变体（manaBonus: 1） |

---

## 阶段 3 · 数据文件

| 文件 | 内容 |
| --- | --- |
| `assets/data/card_affixes.json5` | 27 条专属词条（顶层 `inUnpackable: true`，id 清单见卡牌定稿 §2 各表）+ 7 条公共词条：`cleanse_draw` / `ailment_kinds_to_mana` / `ailment_kinds_to_ultimate` / `draw_by_self_ailment_kinds` / `for_element_ailment_heal` / `for_element_ailment_defend` / `hand_size_defend` |
| `assets/data/cards.json5` | 7 张绝世卡填 `affixes`（顺序 = 定稿表顺序）；紫微斗数补 `rank: 1` + `affixes` + 主词条 filter 收窄 `{cardType: "spell"}`；万法归宗补 `affixes`；`water_mend` 改 script/valueData/uniqueIds；新增 `earth_mend` |
| `assets/data/passives.json5` | 10 条装备公共词条（装备定稿 §3.1，注意 B 层写用途标记 + kinds/rank，C 层不写） |
| `assets/data/status_effect.json5` | 4 个新状态（装备定稿 §3.2）+ `buff_element_amplify_*` 三状态 callbacks 补位 |
| `assets/data/items.json5` | 5 件装备 `affixes` 列表按定稿顺序追加 |

---

## 阶段 4 · 本地化

| 文件 | 内容 |
| --- | --- |
| `assets/locale/zh/rpg/battlecard.json` | 27 专属 + 7 公共词条的 `affix_*` 名与 `affix_*_description`；紫微斗数、甘霖术文案更新（动态费用不参与归零需写明）；新增 `earth_mend` 相关键；涉及状态的词条在词条数据补 `keywords`（如落雷击顶→`status_ailment_lightning`、归宗之后→`status_energy_negative_spell`），使卡面悬浮提示可展开 |
| `assets/locale/zh/rpg/passive.json` | 10 条装备词条 `passive_*_description` |
| `assets/locale/zh/rpg/status_effect.json` | 4 个新状态的名称与描述 |
| `assets/locale/zh/rpg/item.json` | 5 件装备 flavortext 如需提及词条位则更新（可选） |

---

## 阶段 5 · 校验器同步与构建验证

1. `utils/data_validate/game_data_validate.dart` 契约表同步——卡词条新机制字段：`scryOptions` / `statusParams` / `threshold` / `resourceId` / `count` / `guardValue` / `mirrorMana` / `chosenCostReduce` / `amplifyPerMana` / `chosenDamageTakenReduce` / `drawnUpgrade` / `drawnRetain` / `drawnManaIfGenre` / `drawnExtraDrawIfNotGenre` / `inUnpackable`（卡词条约定）；若回调时机有白名单需补 `opponent_used_card`。
2. `dart run utils/data_validate/game_data_validate.dart` → 保持 0 错误。
3. `python build.py` 重编译脚本（Windows 下 hetu 可能有 PATH 问题，可用 dart install 绝对路径的 hetu.bat）。
4. `flutter analyze`。

---

## 依赖顺序与并行建议

```
阶段 0（前置修复）→ 阶段 1（Dart）∥ 阶段 2（Hetu）→ 阶段 3（数据，依赖 2 的函数存在，
否则校验器报 script 悬空引用）→ 阶段 4（本地化）→ 阶段 5（校验与构建）
```

- 装备线（passives / status_effect / items + 2.3 下半）与卡牌线互不依赖，可全程并行。
- 每阶段结束可独立验证：0/1/2 用 `python build.py` + `flutter analyze`；3/4 用数据校验器；5 全量。

---

## 实现前确认点（开工前先查清）

1. **角色境界字段名**：`battle.dart` 洗入紫微斗数时传 rank 用（1.5），确认战斗数据中角色境界的字段（如 `characterData['rank']`）。
2. **状态实例字段写入方式**：太上忘情 statusParams 通道（1.6）需要脚本侧给已授予的状态实例写自定义字段（HTStruct 动态属性），确认可行路径。
3. **单次获得层数是否截断**：资源文档（`how2play/rpg/battle/resource/readme.md` 溢出节）声明"单次获得的层数受上限（灵力/身法）约束、超出截断"，但 `addStatusEffect` 与状态数据中未见对应实现——若未实现（文档滞后），蓄灵诀单次 7 点、聚灵旗 +3 等产能无截断风险；若已实现，万法归宗凑费曲线需重估。

---

## 实测场景清单（战斗内 walkthrough）

- **天机术**：5 个 scryOptions 键逐一验证；弃星成算的加费在洗牌后兑现；观星永不洗牌。
- **紫微斗数**：凝气/化神两种授予 rank 的词条数差异；抽法术牌归零（动态费用卡不归零）；定星/留命/星移/逆天改命各修饰兑现。
- **万法归宗**：paid 10/15/20 三档——落雷击顶感电层数（无封顶）且**当次伤害转化为雷电、无视护甲**；万法余波护甲；有无感电下的雷行九霄差异；0/3 种已用元素下的一法破万法；归宗之后的抽牌归零 + 逆灵对冲下回合产出（逆灵是 isResource 非 isDebuff，**辟邪不能抵消**）。
- **太上忘情**：statusParams 覆盖后的每手牌伤害/灵气数值；藏锋保留；无情阈值。
- **蓄灵诀**：lastManaGained 三件套（纳气/回响/反噬）+ 化浊为清 + 七情归一。
- **相生相克**：ailmentBonusPerElement 叠层；公共三件套的阈值判定。
- **一气化三清**：抉择后护盾（消耗）/减伤（不消耗）/减费/灵气增幅/mirrorMana。
- **装备 5 件**：穿脱后聚合正确（主词条 + 前 N 条）；确认窥天镜只第 1 条生效、聚灵旗 5 条全生效；五行珠与窥天镜同穿时 `first_ailment_to_mana` 每回合只触发一次。
- **回归**：attune 修复后多卡互动；阴气对冲未被 `ailment_` 修正放大（归宗之后自施 3 层逆灵恒定）；资源生命周期无回归。
