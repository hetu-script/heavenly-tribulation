# 悟道（spellcraft）主词条整理实施计划

> 范围：**仅主词条**（cards.json5 / card_script.ht / battle_character.ht + Dart 绑定 / 本地化）。
> 额外词条、绝世卡（蓄灵诀/一气化三清/太上忘情）、绝世装备留待后续计划。
> 设计总纲见 `plan/skill_tree/spellcraft.md`；本文件已经过偏差评审，是最终卡表。

## 一、现状分析结论

### 现有悟道主词条（12 张 + 2 张授予卡）

| id                                           | rank | 元素     | 问题               |
| -------------------------------------------- | ---- | -------- | ------------------ |
| punch_attack_exhaust_mana_fire/ice/lightning | 1    | 火/水/雷 | **缺 elementType** |
| punch_defend_exhaust_mana                    | 1    | 无       |                    |
| wind_blade                                   | 1    | 风       |                    |
| ice_block / fireball                         | 2    | 水/火    |                    |
| chain_lightning                              | 3    | 雷       | 需要调整脚本和描述 |
| falling_stone                                | 4    | 土       | 需要调整脚本和描述 |
| punch_defend_exhaust_mana                    | 1    | 无       | **缺 elementType** |
| stone_shield                                 | 1    | 土       |                    |
| wind_haste                                   | 1    | 风       |                    |

覆盖缺口：**无 rank5 随机池卡**；风/土/木曲线单薄；缺灵气经济主动手段（元气→灵气转化）。

### 机制事实（实现依据）

- 数值公式 `calcAffixValue`：`value = (base + increment×(level − minLevelForRank(rank))) × 1.3^rank`；
  `minLevelForRank(r) = r×10`，`maxLevelForRank(r) = (r+2)×10−5`（rank1 区间 10~25，共 16 级，increment 打满）。
- 费用独立：`calcCostValue = base + rankIncrement×rank`，流派卡 = `{spell: {base: 0, rankIncrement: 1}}`。
- 脚本可用挂钩：`self.turnFlags`（回合内键值，回合开始清空）、`self.cardFlags`
  （本牌键值，打出时已写入 category/genre/kind/cardType/damageType/paidCost/damage）。
- 元素判定口径（与分支「五行轮转」一致）：`elementType ?? damageType`，无 elementType 的元素拳回退到 damageType。
- 护甲 = 状态 `defense`，`hasStatusEffect('defense')` 可读；元素异常 = `burning/frostbite/electricshock/poisoned`。
- 执行顺序：priority<0 额外词条 → 主词条（先动画）→ 其余额外词条。本次全部新脚本均为**主词条脚本**。
- 伤害预测（`predictDamage`）只算确定性修正；依赖状态的临时加成（灵气门槛、元素种类数等）不进预测，卡面预测偏低属可接受行为。
- `wind_shear`（段数=当前速度）**废弃**：speed_quick 在 6 层阈值被消耗，常态 0~5 层会出现 0 段废卡；乘区独立，预测不准。
- 万法归宗（rank5 授予绝世，雷系爆发）不在本次范围，卡池 rank5 由「焚天烈焰」承担，定位（火系、随机池、可被精炼）不冲突。

### 用户评审决议

1. wind_shear → **sandstorm**（飞沙走石，土系多段）；wood_regrow → **water_mend**（甘霖术，水系治疗）；stone_spike → **earth_armor**（岩甲术，土系防御）。
2. **保留** thunder_bolt 概念但改造：**rank3 风系物理多段+迟钝**（`wind_thunder` 风雷破）。

## 二、最终卡表（攻击 9 + 加持 7 = 16 张随机池卡）

### 攻击

| id                                  | rank | kind              | 元素 | damageType | 效果                                         | script                                 | animation  |
| ----------------------------------- | ---- | ----------------- | ---- | ---------- | -------------------------------------------- | -------------------------------------- | ---------- |
| punch_attack_exhaust_mana_fire      | 1    | punch             | 火   | fire       | 火伤+火弱点（保留，补 elementType）          | attack_debuff                          | 保持原样   |
| punch_attack_exhaust_mana_ice       | 1    | punch             | 水   | ice        | 冰伤+冰弱点（保留，补 elementType）          | attack_debuff                          | 保持原样   |
| punch_attack_exhaust_mana_lightning | 1    | punch             | 雷   | lightning  | 雷伤+雷弱点（保留，补 elementType）          | attack_debuff                          | 保持原样   |
| wind_blade                          | 1    | airbend           | 风   | physical   | 物理伤+自身迅捷（保留）                      | attack_buff                            | 保持原样   |
| fire_ball                           | 2    | firebend          | 火   | fire       | 火伤                                         | attack                                 | 保持原样   |
| ice_block                           | 2    | waterbend         | 水   | ice        | 冰伤                                         | attack                                 | 保持原样   |
| wind_storm                          | 3    | airbend           | 风   | physical   | 2 段物理伤+迟钝                              | attack_multiple_debuff（新）           | wind_blade |
| chain_lightning                     | 3    | lightning_control | 雷   | lightning  | 每段 = 本回合已用不同元素种数，每段 {0} 雷伤 | attack_multiple_by_used_elements（新） | 保持原样   |
| ice_storm                           | 4    | waterbend         | 水   | ice        | 手牌中每有一张元素牌造成一次伤害             | attack_multiple_by_cards_in_hand（新） | ice_storm  |
| falling_stone                       | 4    | earthbend         | 土   | physical   | 物理伤，若灵气≥6 伤害+X%                     | attack_with_energy_count_check（新）   | 保持原样   |
| fire_storm                          | 5    | firebend          | 火   | fire       | 耗尽剩余灵气，每点灵气造成 {0} 火伤          | attack_exhaust_energy（新）            | fire_storm |

### 加持

| id                        | rank | kind      | 元素 | 效果                            | script                     | animation overlay |
| ------------------------- | ---- | --------- | ---- | ------------------------------- | -------------------------- | ----------------- |
| punch_defend_exhaust_mana | 1    | punch     | 无   | 护甲（保留不动）                | self_buff                  | 保持原样          |
| stone_shield              | 1    | earthbend | 土   | 护甲 = 当前灵气 ×{0}            | gain_defense_by_mana（新） | 保持原样          |
| wind_haste                | 1    | airbend   | 风   | 迅捷+护甲                       | speed_quick_defend         | 保持原样          |
| mana_surge                | 2    | xinfa     | 无   | 元气 1:1 转化为灵气（费用恒 0） | convert_vigor_all          | restore_mana      |
| water_mend                | 3    | waterbend | 水   | 治疗并移除自身全部元素异常      | heal_water_mend（新）      | water_buff        |

## 三、实施任务分解

### 任务 1：cards.json5 —— 改造 4 张现有卡

1. `punch_attack_exhaust_mana_fire/ice/lightning`：补 `elementType: "element_fire/water/lightning"`。
2. `falling_stone` → `earth_spike`：改 id/键名、description 改新键、script 改 `attack_earth_spike`、
   valueData 改 `[{18, 1.8}, {50, maxLevel:0}]`。
3. `stone_shield`：valueData 改 `[{3, 0.15}, {15, maxLevel:0}]`，description 改新键。
4. `wind_haste`：description 改新键。

### 任务 2：cards.json5 —— 新增 6 张卡

按「悟道·攻击」「悟道·加持」分区插入：`fire_lash`、`ice_shard`、`wind_thunder`、
`fire_storm`、`mana_surge`、`water_mend`、`sandstorm`、`earth_armor`（实为 8 张）。
字段规范：id=键名、snake_case、rank、genre=spellcraft、费用统一 `{spell: {base:0, rankIncrement:1}}`
（mana_surge 例外 `{life: 0}`）、元素卡必须有 elementType 。
插画映射：火→spellcraft_fire_attack、水→spellcraft_water_attack（加持用水防御图）、
风→spellcraft_wind_attack/defend、雷→spellcraft_lightning_attack、土→spellcraft_earth_attack/defend、
xinfa→占位图（后续 image-gen 补）。
动画：法术沿用 spell_attack/spell_attack_recovery + overlays（fireball/ice_block/lightning/falling_stone/
stone_shield/wind_buff 已有，新 overlay 需补 animation.json5 或先复用）。

### 任务 3：card_script.ht —— 新增 7 个脚本函数

| 函数                               | 逻辑要点                                                                                                                                                         |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `attack_multiple_debuff`           | 循环 value[1] 次 takeDamage，结束后 opponent.addStatusEffect(buffId, value[2])                                                                                   |
| `attack_multiple_by_used_elements` | 读 `self.turnFlags['usedElements']`（Set，五行轮转分支同款键）+ 本牌元素去重；段数 = max(1, 集合大小)，循环 takeDamage                                           |
| `attack_multiple_by_cards_in_hand` | 检查手牌中元素牌数，循环 takeDamage ，此为通用脚本，具体卡牌类型不一定是元素，用法类似 drawCards的options                                                        |
| `attack_with_energy_count_check`   | 灵气 ≥6 → `self.cardFlags.damage.percentageChange1 += value[1]/100`，再 takeDamage，此为通用脚本，具体资源不一定是灵气，具体资源名保存在affix                    |
| `attack_exhaust_energy`            | 读剩余灵气并全部 removeStatusEffect，total×value[0] 一次 takeDamage（模板同 spellcraft_ultimate_spell）此为通用脚本，具体资源不一定是灵气，具体资源名保存在affix |
| `gain_defense_by_energy`           | 灵气层数 × value[0]，四舍五入，加 defense 此为通用脚本，具体资源不一定是灵气，具体资源名保存在affix                                                              |
| `heal_remove_debuffs`              | changeLife(value[0], isHeal)，移除所有element_ailment 一共七种。在affix上提供debuff列表                                                                          |

### 任务 4：外部类扩展（battle_character.ht + Dart）

- `battle_character.ht` 新增声明：`function getHandCards() -> List`
- `lib/scene/battle/character.dart` 暴露 `List getHandCards()`（返回手牌区卡牌 data 列表），
  并在 `lib/app.dart` 绑定（如外部类走自动生成则只需 Dart 侧实现）。
  **注意**：当前卡表 16 张均不依赖此方法（chain_lightning 已改为只读 turnFlags），
  此任务是预留能力 + 可选防御性实现；若评估改动面大，可降级为「本次不做」。

### 任务 5：本地化 battlecard.json

- 新卡名 ×4：`battlecard_punch_attack_exhaust_mana_fire`「火云拳」、`..._ice`「寒冰拳」、
  `..._lightning`「惊雷拳」、`battlecard_punch_defend_exhaust_mana`「灵气拳」。
- 词条描述键（数值占位 {0}/{1}/{2}）：
  `affix_attack_spell_fire_burning`、`affix_attack_spell_ice_frostbite`（含门槛说明）、
  `affix_attack_spell_multiple_clumsy`、`affix_attack_spell_chain_elements`、
  `affix_attack_spell_mana_boost`、`affix_attack_spell_fire_mana_all`、
  `affix_defend_by_mana`、
  `affix_mana_surge`、`affix_heal_water_mend`、`affix_earth_armor`。
- 文案全部中文中国风，数值占位与 valueData 下标一一对应。

### 任务 6：编译验证

```bat
"C:/Users/Administrator/AppData/Local/Dart/install/bin/hetu.bat" compile scripts/main/main.ht assets/mods/main.mod
flutter analyze   # 仅当改了 Dart
```

## 五、自查清单（对照 battlecard-content skill §7）

- [ ] 16 张卡 id=键名，元素卡全部有 elementType
- [ ] 费用符合单资源模型（spell 色 / mana_surge 恒 0）
- [ ] 每个新 script 函数存在且签名为 (self, opponent, card, affix)
- [ ] valueData 元素数与脚本读取的 value[i] 对应
- [ ] 本地化：卡名键、affix\_ 描述键、引用的 status（burning/frostbite/dodge_clumsy 等）存在
- [ ] rank 分布 1~5 铺满，五元素各 rank 有牌可 roll
- [ ] hetu 编译通过；若改 Dart 则 flutter analyze 通过
