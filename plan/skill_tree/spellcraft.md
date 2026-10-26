# 悟道（spellcraft）

> 流派核心循环：**灵气当回合产出、当回合耗尽**（统一生命周期，持有者下回合开始清空）。
> 玩法张力 = 单回合灵气的高效分配；终局目标 = 万法归宗（单回合凑 10+X 灵气爆发）。
> 关键词条主题：**规划（观星/抽牌/减费）** 与 **元素（轮转/专注/异常）**。

## 关键字

天道：紫微斗数、天机术、逆天改命、未卜先知、窥命
归元：抱元功、蓄灵诀、龟息功、一气化三清、返本归元
守一：万法归一、一以贯之、聚沙成塔、纯阳诀、冰心诀、五雷法
五行：五行轮转、五气朝元、生生不息、混元气、相生相克

## 境界节点（已实现）

- 凝气：「太上感应」回合开始时每10点灵力获得1点灵气
- 筑基：「天道循环」悟道牌灵气费用 -1
- 结丹：「阴阳五行」回合结束时未使用的灵气每层对对手造成 10 点随机元素伤害
- 还婴：「五气朝元」每个回合开始时，你会轮流获得御水术，御火术，土遁，御风术和雷法的攻击力增强（增强百分比 = 自身灵力的一半）
- 化神：「万法归宗」战斗开始后将「绝世·万法归宗」洗入你的牌库。万法归宗：耗费10+X点灵气（费用不受减费影响，且不能以无极之气抵扣，必须全额以灵气支付），并根据实际耗费的灵气数量造成雷元素伤害。

## 分支节点（已实现，待连线）

（和炼魂共享）「紫微斗数」：战斗开始后，将「紫微斗数」洗入你的牌库。「紫微斗数」：消耗。抽一张牌，将其费用改为0

（和炼魂共享）「天道推演」：每回合开始时（抽牌阶段之前）观星一次

（和御剑共享）「抱真守一」：使用元素牌后，手牌里随机一张相同元素牌获得升级

（和御剑共享）「五行轮转」：每使用一种不同的元素牌，灵气+1

## 词条设计总原则

1. **rank 铺满 1~4**：词条应按 rank 梯度分布，让破境后有新词条可 roll（化神强度由万法归宗与数值 ×1.3^rank 承担）。
2. **数值随新指数公式**：`value = (base + increment×(level − 本境界下限)) × 1.3^rank`。
   increment 按本境界内 0~15 级缩放，+1 级相对提升区间起点 ≈ increment/base（全境界恒定有感）。
3. **灵气经济为主轴**：词条多服务"凑灵气 / 高效用灵气"，呼应万法归宗终局。
4. **元素两条路线**：轮转（用不同元素）与专注（连打同元素）并存，奖励不重叠。

### 数值标定参考（公式 ×1.3^rank）

| rank   | 底数倍率 | 说明     |
| ------ | -------- | -------- |
| 1 凝气 | ×1.3     | 入门词条 |
| 2 筑基 | ×1.69    | 达成循环 |
| 3 结丹 | ×2.20    | 中端爆发 |
| 4 还婴 | ×2.86    | 高端机制 |
| 5 化神 | ×3.71    | 终极大招 |

## 主词条（cards.json5）

动态费用约定：焚天烈焰为 `{spell: {base: 0, isDynamic: true}}`，显示 X；万法归宗为
`{spell: {base: 10, isDynamic: true}}`，显示 10+X。两者在支付阶段消耗全部当前灵气，
不参与减费，使用 `attack_by_paid_resource` 按实际支付量计算伤害；焚天烈焰允许 X=0。
万法归宗继续禁止太极抵扣。加费提高最低支付门槛。

### 攻击（11）

| id                                  | rank | kind              | 元素 | damageType | 效果                                                               | script                                         | valueData                                      |
| ----------------------------------- | ---- | ----------------- | ---- | ---------- | ------------------------------------------------------------------ | ---------------------------------------------- | ---------------------------------------------- |
| punch_attack_exhaust_mana_fire      | 1    | punch             | 火   | fire       | 火伤+火弱点                                                        | attack_debuff                                  | [{8, 0.8}, {4, 0.4}]                           |
| punch_attack_exhaust_mana_ice       | 1    | punch             | 水   | ice        | 冰伤+冰弱点                                                        | attack_debuff                                  | [{8, 0.8}, {4, 0.4}]                           |
| punch_attack_exhaust_mana_lightning | 1    | punch             | 雷   | lightning  | 雷伤+雷弱点                                                        | attack_debuff                                  | [{8, 0.8}, {4, 0.4}]                           |
| wind_blade                          | 1    | airbend           | 风   | ordinary   | 无属性伤+自身迅捷                                                    | attack_buff                                    | [{15, 1.5}, {1, 0.2}]                          |
| fireball                            | 2    | firebend          | 火   | fire       | 火伤                                                               | attack                                         | [{21, 2.1}]                                    |
| ice_block                           | 2    | waterbend         | 水   | ice        | 冰伤                                                               | attack                                         | [{15, 1.5}]                                    |
| chain_lightning                     | 3    | lightning_control | 雷   | lightning  | 段数=本回合已用元素种数（含本牌），每段雷伤                        | attack_multiple_by_used_elements               | [{17, 1.5}]                                    |
| wind_storm                          | 3    | airbend           | 风   | ordinary   | 2 段无属性伤+幻觉（不经计数器，直接附加；调整见额外词条计划 §8）     | attack_multiple_ailment（新）                  | [{9, 0.9}, {2, maxLevel:0}, {1, 0.1}]          |
| falling_stone                       | 4    | earthbend         | 土   | ordinary   | 无属性伤+内伤 {2} 层；灵气≥6 本牌伤害 +{1}%（调整见额外词条计划 §8） | attack_with_energy_count_check（扩展异常尾部） | [{18, 1.8}, {50, maxLevel:0}, {2, maxLevel:0}] |
| ice_storm                           | 4    | waterbend         | 水   | ice        | 段数=手牌中元素牌数（filter: {elementType: true}），每段冰伤       | attack_multiple_by_cards_in_hand               | [{7, 0.7}]                                     |
| fire_storm                          | 5    | firebend          | 火   | fire       | 耗尽剩余灵气（resourceId），每点造成火伤                           | attack_by_paid_resource                          | [{4, 0.4}]                                     |

### 加持（6）

| id                        | rank | kind      | 元素 | 效果                                                                 | script                        | valueData                          |
| ------------------------- | ---- | --------- | ---- | -------------------------------------------------------------------- | ----------------------------- | ---------------------------------- |
| punch_defend_exhaust_mana | 1    | punch     | 无   | 护甲                                                                 | self_buff                     | [{12, 0.6}]                        |
| wind_haste                | 2    | airbend   | 风   | 迅捷+护甲                                                            | speed_quick_defend            | [{1, 0.2}, {8, 0.4}]               |
| water_mend                | 3    | waterbend | 水   | 至多移除 {1} 层元素异常，每移除 1 层回复 {0} 点生命                  | heal_remove_debuffs_by_stack  | [{4, 0.1}, {3, 0.15}]              |
| earth_mend                | 3    | earthbend | 土   | 至多移除 {1} 层元素异常，每移除 1 层获得 {0} 点护甲                  | defend_remove_debuffs_by_stack | [{6, 0.15}, {3, 0.15}]             |
| stone_shield              | 4    | earthbend | 土   | 消耗至多 {1} 点灵气，每点转化为 {0} 点护甲                           | gain_defense_by_mana          | [{3, 0.15}, {15, maxLevel:0}]      |
| mana_surge                | 5    | xinfa     | 无   | 元气 1:1 转化为灵气（费用恒 0，与中立卡 energy_positive_spell 并存） | convert_vigor_all             | [{100}]                            |

## 额外词条（card_affixes.json5）

> 均为 `genres: ["spellcraft"]`，categories 按需。
> **词条 id 用流派风味名**（各流派可有自己 id 的词条）；**script 用通用函数名**，
> 具体的资源 id、过滤条件、阈值放在 affix 数据中，供其他流派复用同一套脚本。

| id                                 | script                              | rank | categories  | 效果                                                                                                                | 关键数据                                                                              | valueData 参考               |
| ---------------------------------- | ----------------------------------- | ---- | ----------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------- |
| `upgrade_hand_cards_spellcraft`    | `upgrade_hand_cards`                | 1    | buff,attack | 升级手牌悟道卡                                                                                                      |                                                                                       |                              |
| `attune`                           | `reduce_cost_by_cards_in_hand`      | 2    | buff,attack | 若手牌中有其他同元素牌，本牌费用 -1（入手时检测减费，离开手牌区还原；callbacks: added_to_hand + removed_from_hand） | filter: {elementType: 'self'}；require: {elementType: true}                           | 无数值（机制词条，缺省 -1）  |
| `ailment_spread`                   | `ailment_spread`                    | 3    | buff,attack | 给对方施加 {0} 层本牌元素对应的元素异常（必然施加，不经异常计数器；元素→异常映射见 Constants.elementAilments）      | require: {elementType: true}                                                          | `[{base:1, increment:0.1}]`  |
| `for_spirituality_increase_damage` | `for_attribute_increase_damage`     | 1    | attack      | 灵力增伤                                                                                                            |                                                                                       |                              |
| `elemental_focus`                  | `increase_damage_by_last_card_used` | 2    | attack      | 若上一张打出的牌与本牌是相同元素，本牌伤害 +{0}%                                                                    | filter: {elementType: 'self'}；require: {elementType: true}；priority: -1             | `[{base:30, increment:2.5}]` |
| `mana_burst`                       | `increase_damage_by_energy_count`   | 3    | attack      | 若打出时灵气 ≥5 层，本牌伤害 +{0}%                                                                                  | resourceId: energy_positive_spell；resourceThreshold: 5；priority: -1                 | `[{base:25, increment:2.0}]` |
| `scry`                             | `scry`                              | 2    | buff        | 观星                                                                                                                |                                                                                       |                              |
| `cycle_draw`                       | `draw_by_last_card_used`            | 3    | buff        | 若上一张打出的牌与本牌是不同元素，抽 {0} 张牌（轮转路线，与专注奖励互斥）                                           | filter: {elementType: true, not: {elementType: 'self'}}；require: {elementType: true} | `[{base:1, maxLevel:0}]`     |
| `mana_battery`                     | `gain_resource_next_turn`           | 4    | buff        | 下回合产出阶段额外获得 {0} 点灵气                                                                                   | resourceId: energy_positive_spell                                                     | `[{base:1, increment:0.02}]` |

## 绝世卡牌

悟道共有 7 张绝世卡：5 张境界梯度卡，以及由天赋授予的紫微斗数、万法归宗。

### 固定词条规则

- 主词条的 `affixes` 只列额外词条，按列表顺序随卡牌境界解锁，**额外词条总数 = rank**。
  rank 1~4 的卡通过破境继续解锁；rank 5 的太上忘情、万法归宗生成时即解锁全部 5 条。
- 紫微斗数由分支洗入时以角色当前境界生成，数据层以 rank 1 兜底，因此词条数也随授予境界增长。
- 消费主词条中间结果（观星选牌、实际支付、本次产能、所授状态参数等）的词条必须专属，
  顶层写 `inUnpackable: true`，不进入随机额外词条池。通用效果优先复用或新增公共词条。
- 列表顺序就是投资路线：低境界先形成卡牌自身特色，高境界再强化联动、取舍和终局爆发。
- 支付先于全部词条脚本。动态费用卡的词条读取 `paidCost`；灵气门槛类词条不能按支付前存量理解。

### 天机术 `spellcraft_scry_draw`（rank 1，规划）

主词条：观星 3 张，随后抽 1 张牌。被选牌置于牌库顶并由后续抽牌入手；未选牌进入弃牌堆。
5 条修饰由主脚本汇总为 `scryOptions`，未选牌加费在同一卡上每场战斗只生效一次。

| 解锁 rank | 词条 | 类型 | 效果 |
| --- | --- | --- | --- |
| 1 | `spellcraft_scry_draw_affix_1` 余星蒙尘 | 专属 | 观星未选中的牌费用 +1 |
| 2 | `spellcraft_scry_draw_affix_2` 摘星 | 专属 | 观星选中的牌等级 +1 |
| 3 | `spellcraft_scry_draw_affix_3` 星引 | 专属 | 观星选中的牌费用 -1 |
| 4 | `spellcraft_scry_draw_affix_4` 星驻 | 专属 | 观星选中的牌获得保留 |
| 5 | `spellcraft_scry_draw_affix_5` 窥天机 | 专属 | 本次观星额外查看 2 张 |

设计意图：规划主题核心；被放弃的未来更加昂贵，但加费延迟到弃牌重洗后兑现。

### 相生相克 `spellcraft_ailments_by_used_elements`（rank 2，轮转/自异常）

主词条：对双方施加随机元素异常，种数 = 本回合已使用元素种数（至少 1），每种 {0} 层，
不经异常计数器。对称效果通过自异常构筑形成不对称收益。

| 解锁 rank | 词条 | 类型 | 效果 |
| --- | --- | --- | --- |
| 1 | `spellcraft_ailments_by_used_elements_affix_1` 五行相激 | 专属 | 本回合每使用过一种元素，本次每种异常的施加层数 +{0} |
| 2 | `cleanse_draw` 化浊为清 | 公共·悟道 | 移除自身随机 1 种元素异常，抽 {0} 张牌 |
| 3 | `ailment_kinds_to_mana` 以毒攻毒 | 公共·悟道 | 自身持有不少于 3 种元素异常时，获得 1 点灵气 |
| 4 | `for_element_ailment_defend` 以厄为铠 | 公共·悟道 | 自身每有 1 层元素异常，获得 {0} 点护甲 |
| 5 | `draw_by_self_ailment_kinds` 处变不惊 | 公共·悟道 | 自身持有不少于 3 种元素异常时，抽 1 张牌 |

设计意图：铺异常、留异常获益与清异常换抽牌形成节流取舍；不要只把自异常当纯代价。

### 一气化三清 `spellcraft_element_amplify`（rank 3，元素专注）

主词条：抉择水/火/雷之一，本回合双方造成的该元素伤害 +{0}%，使用独立乘区。
修饰字段写入状态实例；减费由脚本筛选手牌后逐卡调用回合级费修。

| 解锁 rank | 词条 | 类型 | 效果 |
| --- | --- | --- | --- |
| 1 | `spellcraft_element_amplify_affix_1` 灵台守一 | 专属 | 下一次受到所选元素伤害时获得 1 层护盾，兑现后消耗 |
| 2 | `spellcraft_element_amplify_affix_2` 借力导气 | 专属 | 对手使用所选元素牌后，下回合产出阶段 +1 灵气 |
| 3 | `spellcraft_element_amplify_affix_3` 元素亲和 | 专属 | 本回合手牌中所选元素牌费用 -1 |
| 4 | `spellcraft_element_amplify_affix_4` 灵气共鸣 | 专属 | 打出时每有 1 点灵气，本次增幅 +5% |
| 5 | `spellcraft_element_amplify_affix_5` 三清护体 | 专属 | 本回合受到所选元素伤害 -30%，不消耗 |

设计意图：专注路线爆发；防御修饰用于对冲双方共同增伤的代价，借力导气只作锦上添花。

### 蓄灵诀 `spellcraft_ailments_to_mana`（rank 4，自异常转灵气）

主词条：自身每有一种元素异常，获得 {0} 点灵气；七种异常全部持有即 7 点。
本次实际获得数写入 `lastManaGained`，供后续词条消费。

| 解锁 rank | 词条 | 类型 | 效果 |
| --- | --- | --- | --- |
| 1 | `spellcraft_ailments_to_mana_affix_1` 纳气之后 | 专属 | 若本次获得不少于 {0} 点灵气，每点获得 {1} 点护甲 |
| 2 | `cleanse_draw` 化浊为清 | 公共·悟道 | 移除自身随机 1 种元素异常，抽 {0} 张牌 |
| 3 | `ailment_kinds_to_ultimate` 七情归一 | 公共·悟道 | 自身持有不少于 5 种元素异常时，获得 1 点太极之气 |
| 4 | `spellcraft_ailments_to_mana_affix_4` 灵气回响 | 专属 | 若本次获得灵气，本回合手牌中悟道牌费用 -1 |
| 5 | `spellcraft_ailments_to_mana_affix_5` 反噬成道 | 专属 | 若本次获得不少于 {0} 点灵气，下回合开始受到获得数 ×{1} 点纯粹伤害，且下回合首张悟道牌伤害 +{2}% |

设计意图：相生相克铺异常 → 蓄灵诀转灵气 → 万法归宗爆发；清异常提高稳定性，留异常追求上限。
治疗会随机驱散一层负面，也会侵蚀自异常燃料。

### 太上忘情 `spellcraft_handcards_to_mana`（rank 5，手牌取舍）

主词条：获得「太上忘情」状态——回合结束时每有一张手牌受到 10 点纯粹伤害；
下回合产出阶段每有一张手牌额外获得 1 点灵气，触发后移除。
舍念、静心通过 `statusParams` 修正本次所授状态实例。

| 解锁 rank | 词条 | 类型 | 效果 |
| --- | --- | --- | --- |
| 1 | `spellcraft_handcards_to_mana_affix_1` 舍念 | 专属 | 本牌施加的状态，每张手牌的纯粹伤害 -3 |
| 2 | `spellcraft_handcards_to_mana_affix_2` 静心 | 专属 | 本牌施加的状态，每张手牌的额外灵气 +1 |
| 3 | `spellcraft_handcards_to_mana_affix_3` 忘我 | 专属 | 下回合第一张悟道牌伤害 +{0}% |
| 4 | `spellcraft_handcards_to_mana_affix_4` 藏锋 | 专属 | 手牌中随机一张悟道牌获得保留 |
| 5 | `hand_size_defend` 无情 | 公共·中立 | 若手牌数不少于 {1}，获得 {0} 点护甲 |

设计意图：跨回合蓄爆但不改变资源统一生命周期；保留和抽牌同时放大反噬与次回合收益。
不再配置同时扩大手牌与灵气收益的抽牌、下回合灵气词条。

### 紫微斗数 `spellcraft_draw_cards_reduce_cost`（rank = 授予时角色境界）

主词条：消耗，抽 1 张法术牌并将其费用降为 0；动态费用条目不参与归零。
`isEphemeral`、`isUnpackable`；洗入时 rank = 角色当前境界。先完成首张牌的全部修饰，
再处理额外抽牌，避免 `lastDrawnCards` 被覆盖。

| 解锁 rank | 词条 | 类型 | 效果 |
| --- | --- | --- | --- |
| 1 | `defend` | 公共·现有中立 | 获得 {0} 点护甲 |
| 2 | `spellcraft_draw_cards_affix_1` 定星 | 专属 | 抽到的牌等级 +1 |
| 3 | `spellcraft_draw_cards_affix_2` 留命 | 专属 | 抽到的牌获得保留 |
| 4 | `spellcraft_draw_cards_affix_3` 星移 | 专属 | 若抽到悟道牌，获得 1 点灵气 |
| 5 | `spellcraft_draw_cards_affix_4` 逆天改命 | 专属 | 若抽到的不是悟道牌，额外抽 1 张；第二张不再归零 |

设计意图：定向获得法术牌，词条数随授予境界成长；免费主牌不再配置无意义的自身减费词条。

### 万法归宗 `spellcraft_ultimate_spell`（rank 5，终局爆发）

主词条：耗费 10+X 点灵气，禁止太极抵扣且动态费用不受减费；
按 `paidCost` 中实际支付的灵气，每点造成 {0} 点雷电伤害。超额量 = 实际支付灵气 − 10。

| 解锁 rank | 词条 | 类型 | 效果 |
| --- | --- | --- | --- |
| 1 | `spellcraft_ultimate_spell_affix_1` 落雷击顶 | 专属 | 超额部分每点对对手施加 1 层感电 |
| 2 | `spellcraft_ultimate_spell_affix_2` 万法余波 | 专属 | 超额部分每点获得 {0} 点护甲 |
| 3 | `spellcraft_ultimate_spell_affix_3` 雷行九霄 | 专属 | 若对手已持有感电，本牌伤害 +{0}% |
| 4 | `spellcraft_ultimate_spell_affix_4` 一法破万法 | 专属 | 本回合每使用过一种元素，本牌伤害 +{0}%；实现口径含本牌雷元素 |
| 5 | `spellcraft_ultimate_spell_affix_5` 归宗之后 | 专属 | 抽 {0} 张牌并使其费用变为 0（动态费用除外），自身获得 {1} 点逆灵之气 |

设计意图：超额支付同时转化为进攻、防御与后续节奏；逆灵之气是资源而非减益，辟邪不能抵消。
落雷击顶与雷行九霄本意为“本次铺垫”和“事前铺设”双档配合，当前时序偏差见文末。

## 绝世装备

### 固定词条与公共化规则

- `affixes[0]` 必须是主词条。生成时解锁前 `rank + 1` 条（含主词条），即**额外词条 = rank**。
- 装备破境尚未实现，解锁数在生成时固定：窥天镜只生效第 1 条额外词条，五行珠前 2 条，
  天机盘前 3 条，蓄灵佩前 4 条，聚灵旗 5 条全部生效；后续槽位是休眠内容。
- 装备额外词条全部公共化，不制造一次性专属 id：
  - A：复用现有随机池词条，如 `spirituality`、`battleDrawBonus`。
  - B：新共享词条并进入随机池，配置 `isEquipmentExtraAffix`、kinds 和 rank。
  - C：新共享词条但不进随机池；用于流派资源或流派费修，可被固定列表和天赋直接引用。
- 固定数值优先写入机制字段或 `statsBonus`；复用随机池词条则接受 `base + increment × level`
  及生成等级带来的方差。装备所有效果仍经既有被动聚合和白名单通道，无需新增 Dart 机制字段。
- 观星最终查看数量上限为 5：先合计基础数量、全局 `scryBonus` 与卡牌局部加成，再按 5 和牌库剩余数截断。
  达到上限后额外深度饱和，观星后修饰不受影响；需在 Dart `scry` 入口统一实现。

### 窥天镜 `heaven_peeking_mirror`（rank 1，talisman/pearl）

主词条 `heaven_peeking_mirror`：观星额外查看 2 张；每次观星后自身随机获得 2 种元素异常（各 1 层）。
按解锁规则，仅第 1 条额外词条生效。

| 槽 | 词条 | 层 | 效果 |
| --- | --- | --- | --- |
| 1 | `spirituality` | A | 灵力 +increment×level，经太上感应转化为灵气产能 |
| 2 | `scry_focus` | C | 观星额外查看 1 张 |
| 3 | `scry_retention` | C | 每回合第一次观星后，选中的牌获得保留 |
| 4 | `ailment_ward` | B | 受到的元素异常层数 -1 |
| 5 | `ailment_to_mana_echo` | C | 每回合第一次获得元素异常时，获得 1 点灵气 |

设计意图：“看得越多，心神越乱”；自异常既可喂养蓄灵诀，也可用后续词条对冲。

### 五行珠 `five_elements_pearl`（rank 2，jewelry/amulet）

主词条 `five_elements_pearl`：造成的元素异常层数 +2；受到的元素异常层数 +2。
按解锁规则，前 2 条额外词条应生效。

| 槽 | 词条 | 层 | 效果 |
| --- | --- | --- | --- |
| 1 | `spirituality` | A | 灵力 +increment×level |
| 2 | `ailmentMultiplier` | A | 元素异常伤害 +increment×level% |
| 3 | `ailmentThreshold` | A | 元素异常充能阈值降低 |
| 4 | `ailment_inflict_focus` | B | 造成的元素异常层数 +1 |
| 5 | `ailment_to_mana_echo` | C | 每回合第一次获得元素异常时，获得 1 点灵气 |

设计意图：双向异常放大器；与窥天镜共用首次异常转灵气时，每回合仍只触发一次。

### 天机盘 `heavenly_mechanism_disc`（rank 3，talisman/pearl）

主词条 `turnStartExtraDraw`：回合开始额外抽 1 张；通过此效果抽到的非悟道牌本回合费用 +1。
按解锁规则，前 3 条额外词条应生效。

| 槽 | 词条 | 层 | 效果 |
| --- | --- | --- | --- |
| 1 | `non_spellcraft_tax` | C | 非悟道牌费用 +1（组牌阶段，与主词条的抽牌课税可叠加） |
| 2 | `scry_focus` | C | 观星额外查看 1 张 |
| 3 | `scry_retention` | C | 每回合第一次观星后，选中的牌获得保留 |
| 4 | `deckMinSizeReduce` | A | 牌库下限 -increment×level |
| 5 | `battleDrawBonus` | A | 战斗抽牌数 +increment×level |

设计意图：稳定过牌与规划；组牌课税和抽牌课税是两条独立通道，纯悟道构筑均不受罚。

### 蓄灵佩 `spirit_storing_amulet`（rank 4，jewelry/amulet）

主词条 `energyRetainSpell`：至多保留 2 点未使用灵气到下回合；每保留 1 点，
下回合开始受到 3 点纯粹伤害。保留部分不触发阴阳五行结算。按解锁规则，前 4 条额外词条应生效。

| 槽 | 词条 | 层 | 效果 |
| --- | --- | --- | --- |
| 1 | `spirituality` | A | 灵力 +increment×level，增加保留池的来源 |
| 2 | `lifeMax` | A | 生命上限 +increment×level，缓冲保留代价 |
| 3 | `persistent` | A | 护甲保留，强化蓄势回合的生存 |
| 4 | `basicEnergyBonus` | A | 回合元气 +increment×level，可经灵气涌动转化为灵气 |
| 5 | `spell_mana_trickle` | C | 回合产出阶段灵气 +1 |

设计意图：服务万法归宗的跨回合蓄爆。`energyRetain` 多来源按上限取大、代价取首个配置，
不能用第二个同资源保留词条叠加上限，因此额外强化全部走产能与生存。

### 聚灵旗 `spirit_gathering_banner`（rank 5，talisman/pearl）

主词条 `spirit_gathering_banner`：回合产出阶段灵气 +3；非悟道牌费用 +2。5 条额外词条全部生效。

| 槽 | 词条 | 层 | 效果 |
| --- | --- | --- | --- |
| 1 | `spirituality` | A | 灵力 +increment×level |
| 2 | `mana_threshold_guard` 聚气成势 | C | 灵气不少于 5 时，受到的伤害 -20% |
| 3 | `mana_empty_defend` 一炁 | C | 回合结束时若灵气为 0，获得 8 点护甲 |
| 4 | `spellcraft_cost_down` | C | 悟道牌费用 -1，与天道循环同通道 |
| 5 | `turnStartExtraDraw` | A·共享主词条复用 | 回合开始额外抽 1 张；抽到的非悟道牌本回合费用 +1 |

设计意图：纯悟道 all-in；攥灵气有防御，花空灵气有兜底。与天机盘同穿时额外抽牌数相加，
课税配置相同，不发生冲突。

### 装备新增公共词条与状态

观星分工：天道推演等天赋提供触发源，装备只提供观星深度与观星后修饰，不再通过装备复制回合开始观星。
`scry_focus` 与 `scry_retention` 均为 C 层，不进入随机池：前者依赖观星触发源且最多查看 5 张会饱和，后者同样需要外部触发源。

| 词条 | 机制 | 分层与用途 |
| --- | --- | --- |
| `ailment_ward` | `statsBonus: {ailmentReceiveBonus: -1}` | B；amulet/ring/pearl，rank 2 |
| `ailment_inflict_focus` | `statsBonus: {ailmentInflictBonus: 1}` | B；amulet/ring/pearl，rank 2 |
| `scry_focus` | `statsBonus: {scryBonus: 1}` | C；不进随机池 |
| `scry_retention` | `battleStatus: scry_retention` | C；不进随机池 |
| `ailment_to_mana_echo` | `battleStatus: first_ailment_to_mana` | C；不进随机池 |
| `spell_mana_trickle` | `battleStatus: turn_start_spell_mana_1` | C；不进随机池 |
| `non_spellcraft_tax` | `deckCostReduction: {color: all, amount: -1, notGenres: [spellcraft]}` | C；不进随机池 |
| `spellcraft_cost_down` | `deckCostReduction: {color: spell, amount: 1, genres: [spellcraft]}` | C；不进随机池 |
| `mana_threshold_guard` | `battleStatus: mana_threshold_guard` | C；不进随机池 |
| `mana_empty_defend` | `battleStatus: mana_empty_defend` | C；不进随机池 |

需要新增的 5 个状态：`scry_retention`（每回合首次观星后，选中牌获得保留）、
`first_ailment_to_mana`（每回合首次获得元素异常转 1 灵气）、
`turn_start_spell_mana_1`（复用 `turn_start_mana_bonus`，`manaBonus: 1`）、
`mana_threshold_guard`（灵气 ≥5 时受伤 -20%）、`mana_empty_defend`（回合结束灵气为 0 时 +8 护甲）。
其中有参数的行为均写在状态数据中；观星保留直接读取 `self_scry` 提供的选中牌。
