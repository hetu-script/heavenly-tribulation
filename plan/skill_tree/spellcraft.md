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
- 结丹：「阴阳五行」回合结束时未使用的灵气每层对对手造成 5 点随机元素伤害
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

### 攻击（11）

| id                                  | rank | kind              | 元素 | damageType | 效果                                                               | script                                         | valueData                                      |
| ----------------------------------- | ---- | ----------------- | ---- | ---------- | ------------------------------------------------------------------ | ---------------------------------------------- | ---------------------------------------------- |
| punch_attack_exhaust_mana_fire      | 1    | punch             | 火   | fire       | 火伤+火弱点                                                        | attack_debuff                                  | [{8, 0.8}, {4, 0.4}]                           |
| punch_attack_exhaust_mana_ice       | 1    | punch             | 水   | ice        | 冰伤+冰弱点                                                        | attack_debuff                                  | [{8, 0.8}, {4, 0.4}]                           |
| punch_attack_exhaust_mana_lightning | 1    | punch             | 雷   | lightning  | 雷伤+雷弱点                                                        | attack_debuff                                  | [{8, 0.8}, {4, 0.4}]                           |
| wind_blade                          | 1    | airbend           | 风   | physical   | 物理伤+自身迅捷                                                    | attack_buff                                    | [{15, 1.5}, {1, 0.2}]                          |
| fireball                            | 2    | firebend          | 火   | fire       | 火伤                                                               | attack                                         | [{21, 2.1}]                                    |
| ice_block                           | 2    | waterbend         | 水   | ice        | 冰伤                                                               | attack                                         | [{15, 1.5}]                                    |
| chain_lightning                     | 3    | lightning_control | 雷   | lightning  | 段数=本回合已用元素种数（含本牌），每段雷伤                        | attack_multiple_by_used_elements               | [{17, 1.5}]                                    |
| wind_storm                          | 3    | airbend           | 风   | physical   | 2 段物理伤+幻觉（不经计数器，直接附加；调整见额外词条计划 §8）     | attack_multiple_ailment（新）                  | [{9, 0.9}, {2, maxLevel:0}, {1, 0.1}]          |
| falling_stone                       | 4    | earthbend         | 土   | physical   | 物理伤+内伤 {2} 层；灵气≥6 本牌伤害 +{1}%（调整见额外词条计划 §8） | attack_with_energy_count_check（扩展异常尾部） | [{18, 1.8}, {50, maxLevel:0}, {2, maxLevel:0}] |
| ice_storm                           | 4    | waterbend         | 水   | ice        | 段数=手牌中元素牌数（filter: {elementType: true}），每段冰伤       | attack_multiple_by_cards_in_hand               | [{7, 0.7}]                                     |
| fire_storm                          | 5    | firebend          | 火   | fire       | 耗尽剩余灵气（resourceId），每点造成火伤                           | attack_exhaust_energy                          | [{4, 0.4}]                                     |

### 加持（5）

| id                        | rank | kind      | 元素 | 效果                                                                 | script               | valueData                     |
| ------------------------- | ---- | --------- | ---- | -------------------------------------------------------------------- | -------------------- | ----------------------------- |
| punch_defend_exhaust_mana | 1    | punch     | 无   | 护甲                                                                 | self_buff            | [{12, 0.6}]                   |
| wind_haste                | 2    | airbend   | 风   | 迅捷+护甲                                                            | speed_quick_defend   | [{1, 0.2}, {8, 0.4}]          |
| water_mend                | 3    | waterbend | 水   | 治疗并移除自身全部元素异常（debuffs 列表 = 7 种 ailment\_\*）        | heal_remove_debuffs  | [{18, 1.8}]                   |
| stone_shield              | 4    | earthbend | 土   | 护甲 = 当前灵气 ×{0}（至多转化 {1} 点灵气）                          | gain_defense_by_mana | [{3, 0.15}, {15, maxLevel:0}] |
| mana_surge                | 5    | xinfa     | 无   | 元气 1:1 转化为灵气（费用恒 0，与中立卡 energy_positive_spell 并存） | convert_vigor_all    | [{100}]                       |

## 额外词条（card_affixes.json5）

> 均为 `genres: ["spellcraft"]`，categories 按需。
> **词条 id 用流派风味名**（各流派可有自己 id 的词条）；**script 用通用函数名**，
> 具体的资源 id、过滤条件、阈值放在 affix 数据中，供其他流派复用同一套脚本。

| id                               | script                              | rank | categories  | 效果                                                                                                                | 关键数据                                                                              | valueData 参考               |
| -------------------------------- | ----------------------------------- | ---- | ----------- | ------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ---------------------------- |
| upgrade_hand_cards_spellcraft    | upgrade_hand_cards                  | 1    | buff,attack | 升级手牌悟道卡                                                                                                      |                                                                                       |                              |
| `attune`                         | `reduce_cost_by_cards_in_hand`      | 2    | buff,attack | 若手牌中有其他同元素牌，本牌费用 -1（入手时检测减费，离开手牌区还原；callbacks: added_to_hand + removed_from_hand） | filter: {elementType: 'self'}；require: {elementType: true}                           | 无数值（机制词条，缺省 -1）  |
| `ailment_spread`                 | `ailment_spread`                    | 3    | buff,attack | 给对方施加 {0} 层本牌元素对应的元素异常（必然施加，不经异常计数器；元素→异常映射见 Constants.elementAilments）      | require: {elementType: true}                                                          | `[{base:1, increment:0.1}]`  |
| for_spirituality_increase_damage | for_attribute_increase_damage       | 2    | attack      | 灵力增伤                                                                                                            |                                                                                       |                              |
| `elemental_focus`                | `increase_damage_by_last_card_used` | 3    | attack      | 若上一张打出的牌与本牌是相同元素，本牌伤害 +{0}%                                                                    | filter: {elementType: 'self'}；require: {elementType: true}；priority: -1             | `[{base:30, increment:2.5}]` |
| `mana_burst`                     | `increase_damage_by_energy_count`   | 4    | attack      | 若打出时灵气 ≥5 层，本牌伤害 +{0}%                                                                                  | resourceId: energy_positive_spell；resourceThreshold: 5；priority: -1                 | `[{base:25, increment:2.0}]` |
| scry                             | scry                                | 2    | buff        | 观星                                                                                                                |                                                                                       |                              |
| `cycle_draw`                     | `draw_by_last_card_used`            | 3    | buff        | 若上一张打出的牌与本牌是不同元素，抽 {0} 张牌（轮转路线，与专注奖励互斥）                                           | filter: {elementType: true, not: {elementType: 'self'}}；require: {elementType: true} | `[{base:1, maxLevel:0}]`     |
| `mana_battery`                   | `gain_resource_next_turn`           | 4    | buff        | 下回合产出阶段额外获得 {0} 点灵气                                                                                   | resourceId: energy_positive_spell                                                     | `[{base:1, increment:0.02}]` |

## 绝世卡牌

| 卡名           | rank | kind  | 效果                                                                                            | 设计意图                                                                   |
| -------------- | ---- | ----- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| **天机术**     | 1    | xinfa | 观星，然后抽 1 张牌                                                                             | 自选最优牌入手，服务凑灵气/凑元素；与紫微斗数（随机）差异化                |
| **相生相克**   | 2    | xinfa | 对对手施加随机元素异常，种数 = 本回合已使用元素种数（至少 1 种），每种 {0} 层（不经异常计数器） | 轮转路线循环卡，与 chain_lightning 共用 usedElements，为蓄灵诀铺垫异常种类 |
| **蓄灵诀**     | 3    | xinfa | 对手每有一种元素异常，你获得 1 灵气                                                             | 异常种类→灵气，服务万法归宗门槛；与 ailment_spread 联动                    |
| **一气化三清** | 4    | xinfa | 选择一种元素，本回合你的该元素牌伤害 +X%                                                        | 专注路线爆发，让单元素构筑有终局手段                                       |
| **太上忘情**   | 5    | xinfa | 本回合你的灵气不会随回合结束清空（突破统一生命周期，仅此一回合）                                | 终局囤积特例，配合万法归宗跨回合攒爆发；极稀有                             |

## 绝世装备

| 装备       | kind   | rank | 效果                                              | 设计意图                                                   |
| ---------- | ------ | ---- | ------------------------------------------------- | ---------------------------------------------------------- |
| **天机盘** | 法器   | 1    | 观星时额外查看 1 张                               |                                                            |
| **五行珠** | amulet | 2    | 你造成的元素异常层数 +2                           | 强化 DOT，间接服务蓄灵诀的异常种类计数                     |
| **蓄灵佩** | amulet | 4    | 每个回合结束时，至多保留 2 点未使用的灵气到下回合 | 万法归宗门槛的稳定路径（平滑累积）；规则特例，占绝世装备位 |
| **聚灵旗** | 法器   | 5    | 回合开始时时灵气 + 2                              |                                                            |
