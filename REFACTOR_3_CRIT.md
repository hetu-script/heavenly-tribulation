# 阶段 3 · 暴击系统与豪气/正气改造

> 总览见 `REFACTOR.md`，依赖阶段 2（护甲已合一、穿透已收敛）。
> 本阶段是新增重头戏：代码里目前没有任何暴击系统（全库零命中），需要全栈新建。

## 目标

1. 新建暴击系统：只有**物理**伤害可以暴击。
2. 豪气（`energy_positive_pure`）从穿透改为暴击资源。
3. 正气（`energy_positive_leech`）承接穿透效果。
4. 衰气（`energy_negative_pure`）改为暴击削弱。
5. 装备/天赋盘新增暴击词条。

## 设计定案（来自总览决策 3、7、8）

| 项           | 定案                                                                                                                    |
| ------------ | ----------------------------------------------------------------------------------------------------------------------- |
| 可暴击类型   | 仅物理（含风、土系法术——它们在阶段 4 转物理后也可暴击）                                                                 |
| 基础暴击率   | 5%（可调）                                                                                                              |
| 基础暴击伤害 | 150%（可调）                                                                                                            |
| 暴击乘区     | 独立乘区（与乘区 1/2/3 相乘），在护甲扣除**之前**计入——配合阶段 1 的结算顺序，大数字才能砸穿护甲                        |
| 豪气         | `energy_positive_crit`（原名 energy_positive_pure）：消耗 1 层 → 下一次物理攻击**必定暴击**                             |
| 正气         | `energy_positive_penetrate`（原名 energy_positive_leech）：消耗 1 层 → 本回合获得 20% 防御穿透                          |
| 衰气         | `energy_negative_crit`（原名 energy_negative_pure）：触发暴击时消耗，降低该次暴击伤害（每层使暴击倍率 −0.25，数值待调） |
| 抗暴         | **不设置**——暴击保持纯进攻属性                                                                                          |

命名定案：leech/pure 系列改名 penetrate/crit 系列，**阴气与阳气英文名保持对称**（仅 positive/negative 前缀不同）：
`energy_positive_leech → energy_positive_penetrate`（正气）、`energy_negative_leech → energy_negative_penetrate`（戾气）、
`energy_positive_pure → energy_positive_crit`（豪气）、`energy_negative_pure → energy_negative_crit`（衰气）。
**吸血（leech）机制整体删除**（与仙侠主题不符）；戾气保留原效果（攻击后自身受伤），仅改 id。

## 改动清单

### 3.1 暴击结算（Dart）

`lib/scene/battle/character.dart` `takeDamage`：

- 新增暴击分支：`damageType == physical` 时，按 `攻方暴击率` roll；
  暴击则伤害 × 暴击倍率（独立乘区，建议直接乘在 finalDamage 上、护甲扣除之前）。
- 暴击率/倍率来源：`data.stats.critChance` / `data.stats.critDamage`（新增派生属性，
  基础值 + 装备 + 天赋，见 3.4）。
- 保底暴击：`turnFlags['guaranteedCrit']`（由豪气脚本设置）为 true 时跳过 roll 直接暴击，用后清除。
- 暴击标记写入 `damageDetails['isCritical']`，供跳字和音效使用。

`scripts/main/cardgame/battle_character.ht`（external class 声明）与 `lib/scene/battle/character_binding.dart`：
如脚本需要读取暴击结果（例如未来"暴击时触发"的词条），补绑定；本阶段可只进不出。

### 3.2 暴击表现

- 跳字：暴击数字放大 + 醒目色（物理伤害色基础上加粗/加大，或独立金色）。
  现状 `addHintText` 只有文本和颜色参数，可能需要扩展字号参数或新增 `addCritText`。
- 音效：暴击独立音效（`GameSound` 新增一项，复用现有重击音效亦可）。
- **美术资源**：如需新音效归入 `assets/audio/`。**【是否有现成音效待确认】**

### 3.3 阴阳气改造

`assets/locale/zh/rpg/status_effect.json` + `assets/data/status_effect.json5` + `scripts/main/cardgame/status_script.ht`：

- **豪气（energy_positive_pure → `energy_positive_crit`）**：
  - 删除穿透脚本（`energy_positive_pure_self_attacking`，该回调已在阶段 1 修活）。
  - 新脚本：使用攻击牌时（`self_using_card`），若该牌为物理伤害（`cardFlags` 的 damageType == physical），
    消耗 1 层 → `self.turnFlags.guaranteedCrit = true`（当次攻击必定暴击）。
  - 描述改为："消耗 1 层豪气，使你的下一次物理攻击必定暴击。"
- **正气（energy_positive_leech → `energy_positive_penetrate`）**：
  - 新脚本：`self_using_card` 时消耗 1 层 → `turnFlags.penetration += 0.2`（本回合）。
  - 原 leech 脚本（turn_end 攻击回血）**删除**——吸血机制整体移除。
  - `passives.json5` 的 `start_battle_with_energy_positive_leech` 同步改名 `start_battle_with_energy_positive_penetrate`。
- **衰气（energy_negative_pure → `energy_negative_crit`）**：
  - 删除"10% 跳回合"脚本（不迁移给其他状态）。
  - 新脚本：`self_doing_damage` 且本次伤害为暴击（`details.isCritical`）时，消耗层数，
    每层使该次暴击倍率 −0.25（从 1.5 基准向下扣减，扣到 1.0 为止；数值待调）。
- **戾气（energy_negative_leech → `energy_negative_penetrate`）**：保留原效果（攻击后自身受伤），
  仅改 id 保持命名对称（风味上可理解为"穿透的是自身"）。
- **浩然之气（`energy_positive_shield`）/ 萧索之气（`energy_negative_shield`）**：已在阶段 2 落地，
  本阶段仅在阴阳气清单文案中确认其存在。
- **阴气不入 kDebuffs**（总览决策 14 修订）：阴气是资源（未来有消耗阴气打出的卡牌），
  不能通过剑气溢出轻松获得，否则溢出惩罚反而成了刷资源的手段。
- `status_energy_positive_description` / `status_energy_negative_description` 的清单文案同步更新
  （删除 leech 表述，加入 penetrate/crit/shield）。

### 3.4 装备与天赋盘新增暴击词条

`assets/data/passives.json5` 新增：

- `critChance`：isItem，暴击率 +X%（装备部位建议：武器类 + ring/amulet）。
- `critDamage`：isItem，暴击伤害 +X%（部位同上）。
- 两者同步加入天赋盘可用词条（passive_skill 节点引用）。

`assets/data/passive_skills.json5`：

- 新增暴击节点（建议放在锻体/御剑主轴附近——物理流派）；原位利用被删节点位置或新增坐标。
  新增坐标涉及轨道布局计算，工作量单独预留。

`scripts/main/data/character/battle_entity.ht`：

- `stats.critChance` / `stats.critDamage` 派生：基础 5 / 150 + passives + ephemeralPassives。
- **【待确认】身法（dexterity）是否供给暴击率**（建议不供给，让暴击纯粹来自构筑投资）。

### 3.5 卡牌词条（可选范围）

- 额外词条库是否新增暴击相关词条（如"本牌暴击率 +X%"）：**【待确认，建议本阶段不做，
  先用装备/天赋/豪气三个来源验证手感】**

### 3.6 敌人侧

- 敌人物理牌同样会暴击（共用 takeDamage，零成本）。
- 敌人 critChance/critDamage 数据：NPC 生成处给基础值即可，暂不做精细化。

### 3.7 本地化

- 新增：暴击率/暴击伤害的属性名与词条描述（`character.json` / `passive.json`）、
  豪气/正气/衰气新描述（`status_effect.json`）、"暴击！"跳字键。

## 涉及文件

- `lib/scene/battle/character.dart`、`character_binding.dart`（如需）
- `lib/data/common.dart`（基础暴击常量 kBaseCritChance / kBaseCritDamage）
- `scripts/main/cardgame/status_script.ht`、`battle_character.ht`
- `scripts/main/data/character/battle_entity.ht`
- `assets/data/status_effect.json5`、`passives.json5`、`passive_skills.json5`
- `assets/locale/zh/rpg/status_effect.json`、`character.json`、`passive.json`
- `docs/docs/how2play/rpg/battle/readme.md`、`resource/readme.md`（豪气/正气/衰气条目）

## 验证清单

- [ ] 编译通过，`flutter analyze` 无新增错误
- [ ] 实机：物理攻击出现暴击跳字（大数字），真气/元素/精神攻击永不暴击
- [ ] 实机：有豪气时打出物理牌必暴击，豪气层数正确消耗
- [ ] 实机：有正气时攻击穿透 +20%（对护甲敌人的伤害符合预期）
- [ ] 实机：暴击伤害砸穿护甲（验证阶段 1 结算顺序：护甲在大数字后扣除）
- [ ] 装备/天赋界面正确显示暴击率与暴击伤害
