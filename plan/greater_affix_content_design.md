# 现有卡牌与被动额外词条逐条太古设计计划

> 状态：已实现并完成验证；`greater: true` 已用于默认倍率简写。
>
> 本文是 `plan/greater_affix_rework.md` 的内容设计子计划，覆盖当前 `card_affixes.json5` 全部 73 条卡牌额外词条，以及 `passives.json5` 中 76 条装备/丹药临时额外词条和 12 条绝世装备专用额外词条。主词条不参与太古；`main` 固有数值方案仍按 `plan/main_affix_value_design.md` 另行审核，不在本文实施。

## 1. 标记与通用规则

- `×N[i]`：`greater.values[i] = {mode: "multiply", factor: N}`，本文使用 N = 1.5 或 0.5；`×1.5[0]` 可简写为 `greater: true`，表示对 `value[0]` 应用常量 `kDefaultGreaterAffixFactor`。
- `+N[i]`：`greater.values[i] = {mode: "add", amount: N}`。
- `=N[i]`：`greater.values[i] = {mode: "set", amount: N}`。
- `D:...`：写入 `greater.data`，用于累加数值或写入原机制尚缺的参数，必须由表中指定的脚本消费；涉及效果变化时同步配置 `greater.description`。
- `A:...`：写入 `greater.alt`，替换指定路径的普通机制数据，仅用于移除惩罚等替代场景。
- 未列出其他下标时，其他数值和阈值保持不变。
- “移除”表示按主计划的绝世固定列表迁移淘汰；若无其他随机池或天赋引用，实施时删除原型，不为它制作太古。
- 普通随机词条允许没有 `greater`；绝世固定保留词条必须都有合法且实际有效的太古方案。

本阶段太古只强化原有效果，不追加普通词条不具备的新机制。所有 `D/A` 方案都需要对应的运行时消费，不允许只把数据写入词条而不生效；`statsBonus`、费用规则、状态参数等只调整既有机制的数值或参数，不统一乘倍率。

## 2. 卡牌额外词条

### 2.1 通用、攻击与流派随机词条

| ID | 太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `defend` | `×1.5[0]` | 护甲数值强化。 |
| `speed_quick` | `×1.5[0]` | 迅捷层数强化。 |
| `dodge_nimble` | `×1.5[0]` | 闪避层数强化。 |
| `heal` | `×1.5[0]` | 治疗量强化。 |
| `buff_crit` | `+1[0]` | 幸运由固定 1 层增至 2 层。 |
| `buff_ward` | `×1.5[0]` | 辟邪层数强化。 |
| `buff_shield` | `×1.5[0]` | 护盾层数强化。 |
| `opponent_vulnerable` | `×1.5[0]` | 易伤层数强化。 |
| `opponent_debuff_speed_slow` | `×1.5[0]` | 缓慢层数强化。 |
| `opponent_debuff_dodge_clumsy` | `×1.5[0]` | 迟钝层数强化。 |
| `opponent_debuff_crit` | `×1.5[0]` | 不幸层数强化。 |
| `opponent_debuff_ward` | `×1.5[0]` | 邪祟层数强化。 |
| `opponent_debuff_shield` | `+1[0]` | 破绽由固定 1 层增至 2 层。 |
| `opponent_reduce_resist_all` | `×1.5[0]` | 降低全抗数值强化。 |
| `opponent_weaken_attack_all` | `×1.5[0]` | 降低攻击数值强化。 |
| `infuse_all_damage_up` | `+1[0]` | 无极之气由固定 1 层增至 2 层。 |
| `infuse_opponent_all_damage_down` | `+1[0]` | 虚空之气由固定 1 层增至 2 层。 |
| `draw_cards_neutral` | `+1[0]` | 抽牌数由固定 1 张增至 2 张。 |
| `upgrade_card` | `+1[0]` | 本牌升级由 +1 级增至 +2 级。 |
| `upgrade_hand_cards_swordcraft` | `+1[0]` | 升级符合条件的御剑手牌由 1 张增至 2 张，每张仍 +1 级。 |
| `upgrade_hand_cards_bodyforge` | `+1[0]` | 升级符合条件的锻体手牌由 1 张增至 2 张。 |
| `upgrade_hand_cards_vitality` | `+1[0]` | 升级符合条件的炼魂手牌由 1 张增至 2 张。 |
| `upgrade_hand_cards_avatar` | `+1[0]` | 升级符合条件的法身手牌由 1 张增至 2 张。 |
| `by_damage_heal` | `×1.5[0]` | 每 10 点伤害的治疗量强化。 |
| `by_damage_defend` | `×1.5[0]` | 每 10 点伤害的护甲量强化。 |
| `for_dexterity_increase_damage` | `D:attributeRate = 0.0075` | `for_attribute_increase_damage` 改为读取词条倍率；身法增伤由每点 0.5% 提至 0.75%。 |
| `for_strength_increase_damage` | `D:attributeRate = 0.0075` | 体魄增伤由每点 0.5% 提至 0.75%。 |
| `for_willpower_increase_damage` | `D:attributeRate = 0.0075` | 念力增伤由每点 0.5% 提至 0.75%。 |
| `for_perception_increase_damage` | `D:attributeRate = 0.0075` | 神识增伤由每点 0.5% 提至 0.75%。 |
| `retain` | **禁止太古** | 保留本身没有合理数值强化；跨回合升级、减费应留给独立词条，不并入本条目。 |
| `upgrade_hand_cards_spellcraft` | `+1[0]` | 升级符合条件的悟道手牌由 1 张增至 2 张。 |
| `attune` | `D:costDelta = -1` | 调息脚本在普通减费 -1 上追加 -1，太古后总减费 -2；还原仍按实际记录执行。 |
| `ailment_spread` | `×1.5[0]` | 元素异常层数强化。 |
| `for_spirituality_increase_damage` | `D:attributeRate = 0.0075` | 灵力增伤由每点 0.5% 提至 0.75%。 |
| `elemental_focus` | `×1.5[0]` | 同元素衔接的伤害百分比强化，条件不变。 |
| `mana_burst` | `×1.5[0]` | 灵气爆发伤害百分比强化，5 点灵气门槛不变。 |
| `scry` | `+1[0]` | 观星由固定 3 张增至 4 张，仍受观星总上限约束。 |
| `cycle_draw` | `+1[0]` | 不同元素衔接抽牌由固定 1 张增至 2 张。 |
| `mana_battery` | `×1.5[0]` | 下回合灵气产出强化。 |

### 2.2 天机术固定词条

| ID | 处理与太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `spellcraft_scry_draw_affix_1` | 保留；`A:scryOptions.othersCostChange = 0` | rank 5 太古；未选牌费用由 +1 改为 +0，即移除惩罚。`_collectScryOptions` 的太古配置采用替换而非继续加费。 |
| `spellcraft_scry_draw_affix_2` | 保留；`D:scryOptions.upgradeChosen += 1` | rank 4 太古；选中牌由升 1 级变为升 2 级，现有观星结算已支持按次数连续升级。 |
| `spellcraft_scry_draw_affix_3` | **移除** | 选中牌减费不再占用本卡固定槽位，也不并入其他太古；无其他引用时删除。 |
| `spellcraft_scry_draw_affix_4` | **移除** | 观星保留不再占用本卡固定槽位；无其他引用时删除。 |
| `spellcraft_scry_draw_affix_5` | 保留并先将普通值由 2 改为 1；`D:scryOptions.scryBonus += 1` | rank 3 太古；本次观星额外查看由 1 张提至 2 张，仍受上限约束。 |

### 2.3 相生相克固定词条及自异常公共词条

| ID | 处理与太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `spellcraft_ailments_by_used_elements_affix_1` | 保留；`+1[0]` | rank 3 太古；每种已用元素提供的异常层数加成由 1 提至 2。 |
| `cleanse_draw` | 保留在随机池；`+1[0]` | 清除 1 种自身异常不变，抽牌由 1 张增至 2 张；不再作为本卡固定词条。 |
| `ailment_kinds_to_mana` | 保留；`D:count += 1` | rank 4 太古；达到 3 种异常时灵气由 1 点增至 2 点，门槛不变。 |
| `for_element_ailment_defend` | 保留在随机池；`×1.5[0]` | 每层自身异常提供的护甲强化；不再作为本卡固定词条。 |
| `for_element_ailment_heal` | 保留在随机池；`×1.5[0]` | 每层自身异常提供的治疗量强化。 |
| `draw_by_self_ailment_kinds` | 保留在随机池；`D:count += 1` | 达到 3 种异常时抽牌由 1 张增至 2 张；不再作为本卡固定词条。 |

### 2.4 一气化三清固定词条

| ID | 处理与太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `spellcraft_element_amplify_affix_1` | **移除** | 护盾效果不再占用固定槽位；无其他引用时删除。 |
| `spellcraft_element_amplify_affix_2` | **移除** | 镜像产灵不再占用固定槽位；无其他引用时删除。 |
| `spellcraft_element_amplify_affix_3` | 保留；`D:chosenCostReduce -= 1` | rank 5 太古；所选元素手牌费用由 -1 提至 -2。 |
| `spellcraft_element_amplify_affix_4` | 保留；`D:amplifyPerMana += 5` | rank 4 太古；每点灵气提供的自身增幅由 5% 提至 10%。 |
| `spellcraft_element_amplify_affix_5` | 保留；`D:chosenDamageTakenReduce += 15` | rank 3 太古；所选元素减伤由 30% 提至 45%。 |

### 2.5 蓄灵诀固定词条及相关公共词条

| ID | 处理与太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `spellcraft_ailments_to_mana_affix_1` | 保留；`×1.5[1]` | rank 3 太古；获得灵气的 3 点门槛和 `value[0]` 不变，每点灵气转化的护甲 `value[1]` 强化。 |
| `ailment_kinds_to_ultimate` | 保留在随机池；`D:count += 1` | 达到 5 种异常时太极之气由 1 点增至 2 点；不再作为本卡固定词条。 |
| `spellcraft_ailments_to_mana_affix_4` | 保留；`D:costDelta = -1` | rank 5 太古；悟道手牌费用由 -1 提至 -2，仍要求本次实际获得灵气。 |
| `spellcraft_ailments_to_mana_affix_5` | 保留；`=30[2]` | rank 4 太古；获得灵气的门槛和延迟自伤不变，下回合首张悟道牌增伤由固定 15% 提至 30%。 |

### 2.6 太上忘情固定词条及公共词条

| ID | 处理与太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `spellcraft_handcards_to_mana_affix_1` | 保留；`D:statusParams.damagePerCard -= 2` | rank 5 太古；每张手牌的纯粹伤害修正由 -3 提至 -5，仍只调整本牌所授状态的自伤数值。 |
| `spellcraft_handcards_to_mana_affix_2` | 保留；`D:statusParams.resourcePerCard += 1` | rank 3 太古；每张手牌的下回合额外灵气由 +1 提至 +2。 |
| `spellcraft_handcards_to_mana_affix_3` | **移除** | 下回合首张悟道牌增伤不再占用本卡固定槽位；无其他引用时删除。 |
| `spellcraft_handcards_to_mana_affix_4` | 保留并补充固定普通数值 `value[0] = 1`；`+1[0]` | rank 4 太古；随机获得保留的悟道手牌由 1 张增至 2 张，实施时按数量不重复抽取。 |
| `hand_size_defend` | 保留在随机池；`×1.5[0]` | 手牌数量门槛 `value[1]` 不变，护甲 `value[0]` 强化；不再作为本卡固定词条。 |

### 2.7 紫微斗数固定词条

| ID | 处理与太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `spellcraft_draw_cards_affix_1` | 保留；`D:drawnUpgrade += 1` | rank 3 太古；抽到的牌由升 1 级提至升 2 级。 |
| `spellcraft_draw_cards_affix_2` | **移除** | 抽牌保留不再占用固定槽位；无其他引用时删除。 |
| `spellcraft_draw_cards_affix_3` | 保留；`D:drawnManaIfGenre.count += 1` | rank 4 太古；抽到悟道牌时灵气由 1 点增至 2 点。 |
| `spellcraft_draw_cards_affix_4` | 保留；`D:drawnExtraDrawIfNotGenre.count += 1` | rank 5 太古；未抽到悟道牌时额外抽牌由 1 张增至 2 张，额外抽到的牌不归零费用。 |

### 2.8 万法归宗固定词条

| ID | 处理与太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `spellcraft_ultimate_spell_affix_1` | 保留；`D:ailmentPerExcess += 1` | rank 3 太古；超额支付每点灵气施加的感电由 1 层增至 2 层，仍按实际超额支付量计算。 |
| `spellcraft_ultimate_spell_affix_2` | **移除** | 超额支付转护甲不再占用固定槽位；无其他引用时删除。 |
| `spellcraft_ultimate_spell_affix_3` | **移除** | 事前感电增伤不再占用固定槽位；无其他引用时删除。 |
| `cycle_enhance` | 保留；`×1.5[0]` | rank 4 太古；本回合每种已用元素提供的伤害百分比强化。 |
| `spellcraft_ultimate_spell_affix_5` | 保留；`+1[0]` | rank 5 太古；抽牌由 1 张增至 2 张，`value[1]` 逆灵之气仍固定为 3 层不变。 |

## 3. 装备、丹药与聚灵阵被动额外词条

以下均使用 `greater.values[0]`，除非明确写为 `D`。被动来源先按所属物品或聚灵阵 rank 的满级计算未取整普通贡献，再应用本表；角色同 ID 多来源仍汇总后统一取整。

### 3.1 套路增伤与攻击属性

| ID | 太古方案 | 说明 |
| --- | --- | --- |
| `increase_damage_punch` | `×1.5[0]` | 拳法增伤。 |
| `increase_damage_kick` | `×1.5[0]` | 腿法增伤。 |
| `increase_damage_qinna` | `×1.5[0]` | 擒拿增伤。 |
| `increase_damage_dianxue` | `×1.5[0]` | 点穴增伤。 |
| `increase_damage_sword` | `×1.5[0]` | 剑法与御剑增伤。 |
| `increase_damage_sabre` | `×1.5[0]` | 刀法增伤。 |
| `increase_damage_spear` | `×1.5[0]` | 枪法增伤。 |
| `increase_damage_staff` | `×1.5[0]` | 棍法增伤。 |
| `increase_damage_bow` | `×1.5[0]` | 弓术增伤。 |
| `increase_damage_dart` | `×1.5[0]` | 暗器增伤。 |
| `increase_damage_airbend` | `×1.5[0]` | 御风增伤。 |
| `increase_damage_earthbend` | `×1.5[0]` | 土遁增伤。 |
| `increase_damage_waterbend` | `×1.5[0]` | 御水增伤。 |
| `increase_damage_firebend` | `×1.5[0]` | 御火增伤。 |
| `increase_damage_lightning_control` | `×1.5[0]` | 雷法增伤。 |
| `increase_damage_sigil` | `×1.5[0]` | 咒术增伤。 |
| `increase_damage_power_word` | `×1.5[0]` | 真言增伤。 |
| `unarmedAttack` | `×1.5[0]` | 徒手攻击。 |
| `weaponAttack` | `×1.5[0]` | 武器攻击。 |
| `spellAttack` | `×1.5[0]` | 法术攻击。 |
| `curseAttack` | `×1.5[0]` | 咒术攻击。 |

### 3.2 抗性、阈值与战斗属性

| ID | 太古方案 | 说明 |
| --- | --- | --- |
| `elementalResist` | `×1.5[0]` | 全元素抗性。 |
| `fireResist` | `×1.5[0]` | 火抗。 |
| `iceResist` | `×1.5[0]` | 水抗。 |
| `lightningResist` | `×1.5[0]` | 雷抗。 |
| `poisonResist` | `×1.5[0]` | 毒抗。 |
| `elementalResistMax` | `×1.5[0]` | 全元素抗性上限，仍受实际抗性上限约束。 |
| `fireResistMax` | `×1.5[0]` | 火抗上限。 |
| `iceResistMax` | `×1.5[0]` | 水抗上限。 |
| `lightningResistMax` | `×1.5[0]` | 雷抗上限。 |
| `poisonResistMax` | `×1.5[0]` | 毒抗上限。 |
| `persistent` | `×1.5[0]` | 护甲保持。 |
| `penetration` | `×1.5[0]` | 护甲穿透。 |
| `quickThreshold` | `×1.5[0]` | 贡献更负，进一步降低迅捷阈值，属于增益。 |
| `slowThreshold` | `×0.5[0]` | 普通值为自身缓慢惩罚；太古将惩罚减半，而不是放大惩罚。 |
| `nimbleThreshold` | `×1.5[0]` | 贡献更负，进一步降低闪避阈值。 |
| `clumsyThreshold` | `×0.5[0]` | 普通值为自身迟钝惩罚；太古将惩罚减半。 |
| `critThreshold` | `×1.5[0]` | 贡献更负，进一步降低暴击阈值。 |
| `critMultiplier` | `×1.5[0]` | 暴击倍率。 |
| `ailmentThreshold` | `×1.5[0]` | 贡献更负，进一步降低异常充能阈值，仍受下限约束。 |
| `ailmentMultiplier` | `×1.5[0]` | 元素异常伤害。 |
| `dexterity` | `×1.5[0]` | 身法。 |
| `spirituality` | `×1.5[0]` | 灵力。 |
| `strength` | `×1.5[0]` | 体魄。 |
| `willpower` | `×1.5[0]` | 念力。 |
| `perception` | `×1.5[0]` | 神识。 |
| `lifeMax` | `×1.5[0]` | 生命上限。 |
| `karmaMax` | `×1.5[0]` | 业力上限。 |

### 3.3 战斗开始与每回合资源词条

| ID | 太古方案 | 说明 |
| --- | --- | --- |
| `start_battle_with_defense` | `×1.5[0]` | 初始护甲。 |
| `start_battle_with_speed_quick` | `×1.5[0]` | 初始迅捷。 |
| `start_battle_with_dodge_nimble` | `×1.5[0]` | 初始闪避。 |
| `start_battle_with_buff_crit` | `×1.5[0]` | 初始幸运。 |
| `start_battle_with_buff_ward` | `×1.5[0]` | 初始辟邪。 |
| `start_battle_with_buff_shield` | `+1[0]` | 初始护盾 +1；避免 rank 5 满级普通值约 1.625、乘 1.5 后仍取整为 2 的无效强化。 |
| `start_battle_with_buff_all_damage` | `+1[0]` | 无极之气 +1；避免 rank 3 普通值 0.9、太古值 1.35 都取整为 1 的无效强化。 |
| `start_battle_with_opponent_vulnerable` | `×1.5[0]` | 对手初始易伤。 |
| `start_battle_with_opponent_speed_slow` | `×1.5[0]` | 对手初始缓慢。 |
| `start_battle_with_opponent_dodge_clumsy` | `×1.5[0]` | 对手初始迟钝。 |
| `start_battle_with_opponent_debuff_crit` | `×1.5[0]` | 对手初始不幸。 |
| `start_battle_with_opponent_debuff_ward` | `×1.5[0]` | 对手初始邪祟。 |
| `start_battle_with_opponent_debuff_shield` | `+1[0]` | 对手初始破绽 +1，避免高境界乘倍率后取整无提升。 |
| `start_battle_with_opponent_debuff_all_damage` | `+1[0]` | 对手虚空之气 +1。 |
| `start_battle_with_opponent_energy_negative_life` | `×1.5[0]` | 对手初始死气。 |
| `start_battle_with_opponent_energy_negative_spell` | `×1.5[0]` | 对手初始逆灵之气。 |
| `start_battle_with_opponent_energy_negative_weapon` | `×1.5[0]` | 对手初始止戈之气。 |
| `start_battle_with_opponent_energy_negative_unarmed` | `×1.5[0]` | 对手初始非战之气。 |
| `start_battle_with_opponent_energy_negative_curse` | `×1.5[0]` | 对手初始无心之气。 |
| `start_battle_with_opponent_energy_negative_ultimate` | `+1[0]` | 对手混沌之气 +1，避免低增量乘倍率后取整无提升。 |
| `start_turn_with_energy_positive_life` | `×1.5[0]` | 每回合元气。 |
| `start_turn_with_energy_positive_spell` | `×1.5[0]` | 每回合灵气。 |
| `start_turn_with_energy_positive_weapon` | `×1.5[0]` | 每回合剑气。 |
| `start_turn_with_energy_positive_unarmed` | `×1.5[0]` | 每回合怒气。 |
| `start_turn_with_energy_positive_ultimate` | `+1[0]` | 每回合太极之气 +1，避免低增量乘倍率后取整无提升。 |

### 3.4 纯机制普通装备词条

| ID | 太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `handSizeMax` | `D:statsBonus.handSizeMax += 1` | 手牌上限由 +1 提至 +2，按来源聚合 `statsBonus`。 |
| `ailment_ward` | `D:statsBonus.ailmentReceiveBonus -= 1` | 受到的元素异常修正由 -1 提至 -2，仍受最低实际施加层数约束。 |
| `ailment_inflict_focus` | `D:statsBonus.ailmentInflictBonus += 1` | 造成的元素异常修正由 +1 提至 +2，普通随机池与五行珠固定词条使用同一方案。 |

## 4. 绝世装备专用与固定迁移词条

### 4.1 共用机制词条

| ID | 处理与太古方案 | 最终效果与消费说明 |
| --- | --- | --- |
| `scry_shield` | `D:statusParams.shieldAmount += 1` | 每回合首次观星获得护盾由 1 层提至 2 层，由观星状态脚本消费。 |
| `scry_retention` | **由新词条 `scry_upgrade` 替代** | 原观星保留不符合窥天镜固定成长；无其他引用时删除原 ID。`scry_upgrade` 普通使每回合首次观星选中牌升 1 级，太古 `D:statusParams.upgradeChosen += 1` 提至升 2 级。 |
| `scry_mana` | `D:statusParams.manaBonus += 1` | 每回合首次观星获得灵气由 1 点提至 2 点；回合开始观星登记到本次产出阶段，行动中观星直接获得。 |
| `non_spellcraft_tax` | **并入天机盘主词条，不制作太古** | 与固定牌库下限共同构成主词条，保留非悟道牌费用 +1 的构筑限制。 |
| `deckMinSizeReduce` | **并入天机盘主词条，不制作太古** | 通过 `statsBonus.deckMinSizeReduce = -2` 固定生效，不再随等级放大。 |
| `battleDrawBonus` | 普通值固定为 1；`+1[0]` | 每回合抽牌普通 +1、太古 +2，避免等级倍率超出手牌实际上限。 |
| `basicEnergyBonus` | **移除出绝世固定列表，不制作太古** | 当前不进普通随机池；蓄灵佩迁移后无其他引用时删除。 |
| `spell_mana_trickle` | `D:statusParams.manaBonus += 1` | 每回合产出灵气由 1 点提至 2 点，复用 `turn_start_mana_bonus`。 |
| `mana_threshold_guard` | `D:statusParams.reductionPercent += 10` | 灵气不少于 5 点的门槛不变，减伤由 20% 提至 30%。 |
| `mana_empty_defend` | **移除出绝世固定列表，不制作太古** | 聚灵旗迁移后无其他引用时删除。 |
| `spellcraft_cost_down` | `D:deckCostReduction.amount += 1` | 悟道牌费用由 -1 提至 -2，仍按规则列表聚合并受动态费用豁免约束。 |
| `turnStartExtraDraw` | `D:turnStartExtraDraw.count += 1` | 回合开始额外抽牌由 1 张提至 2 张；聚灵旗固定额外词条使用。 |

### 4.2 五件悟道绝世装备的固定太古顺序

| 装备 | rank 3 | rank 4 | rank 5 |
| --- | --- | --- | --- |
| 窥天镜 | `scry_upgrade`：选中牌升 2 级 | `scry_shield`：观星护盾 2 层 | `scry_mana`：观星产灵 2 点 |
| 五行珠 | `ailment_inflict_focus`：造成异常修正由 +1 提至 +2 | `ailmentThreshold`：阈值贡献 ×1.5，仍受下限 | `ailmentMultiplier`：异常伤害 ×1.5 |
| 天机盘 | `battleDrawBonus`：每回合抽牌 +2 | `handSizeMax`：手牌上限 +2 | `spellcraft_cost_down`：悟道牌费用 -2 |
| 蓄灵佩 | `lifeMax`：生命上限 ×1.5 | `persistent`：护甲保持 ×1.5 | `spell_mana_trickle`：回合产灵 2 点 |
| 聚灵旗 | `mana_threshold_guard`：减伤 30%，阈值不变 | `spellcraft_cost_down`：悟道牌费用 -2 | `turnStartExtraDraw`：额外抽 2 张 |

五件装备的固定太古均只强化原有效果，不再为随机池与固定列表中的同一词条设计不同的太古机制。

## 5. 实施前必须确认的要点

1. **低增量取整**：初始护盾、无极/虚空/混沌等词条使用 +1 而非乘 1.5，避免太古前后最终整数相同。
2. **负向词条方向**：`slowThreshold`、`clumsyThreshold` 是自身惩罚，采用 ×0.5；对手缓慢、迟钝等仍采用 ×1.5。
3. **系统上下限**：牌库下限使用独立的全局绝对下限；天机盘的牌库修正收归固定主词条，不参与太古。抽牌只增加请求数量，仍按现有手牌空间截断；观星仍遵守最多查看数量。
4. **次数与阈值**：升级、抽牌、资源、费用使用整数加法或定值；获得门槛、异常种数门槛和延迟自伤不随太古放大。
5. **机制消费**：本文所有 `D/A` 字段都要登记进数据校验和 MOD 契约，并由对应 CardScript、状态脚本或被动聚合入口实际消费。
6. **文案**：移除惩罚或普通文案无法表达的机制参数变化必须配置 `greater.description`；普通描述不得提前展示太古效果。
7. **移除引用**：标记“移除”的词条先检查随机池、绝世列表、天赋树和测试引用，确认无引用后再删除，不强制为淘汰内容制作太古。
8. **数值复核结果**：一气化三清与太上忘情沿用表内方案；天机盘抽牌改用固定 +1/+2，牌库修正收归主词条并固定为 -2，避免原始倍率被手牌或牌库上限吞没。

## 6. 覆盖清单

- 卡牌额外词条：73/73。普通与随机池方案 39 条；绝世固定及迁移 34 条，其中 8 条标记移除，`retain` 禁止太古，其余均有具体方案。
- 装备/丹药/聚灵阵额外被动：76/76。
- 绝世装备专用额外词条：12/12，其中 `scry_retention` 由 `scry_upgrade` 替代，`basicEnergyBonus` 与 `mana_empty_defend` 标记移除，其余均有具体方案。
- 被动主词条、工具词条和仅天赋使用的境界/分支节点不在本次额外词条太古范围内。
