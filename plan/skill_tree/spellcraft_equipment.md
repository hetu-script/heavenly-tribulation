# 悟道绝世装备实施计划

> 设计来源：`plan/skill_tree/spellcraft.md` §绝世装备（窥天镜/五行珠/天机盘/蓄灵佩/聚灵旗）。
> 本文档 = 实施层面的机制分析 + 数据/脚本/本地化/资源清单 + 步骤拆解。
> 设计原则沿用绝世通用原则：正反双段式；方向性限制 > 对称效果 > 自伤/自异常；软流派锁允许。

## 0. 机制现状盘点（调查结论）

装备与天赋词条在 `character.passives` **同通道汇合**（battle_entity.ht:692-699），战斗侧被动字段消费点已齐全。
**好消息：大量机制已存在，甚至字段注释里已预留了这些装备的位置。**

| 机制 | 现状 | 位置 |
| --- | --- | --- |
| energyRetain（回合结束资源保留+每点代价） | **已完整实现，无数据使用** | character.dart:643-702；字段格式 `{resourceId, max, costPerPoint?, costDamageType?}`，注释已点名蓄灵佩 |
| scryBonus（观星深度加成） | **已有 stats 词条，注释已点名窥天镜** | battle.dart:1030-1031；passives.json5:1167-1174（注明不进随机池） |
| battleDrawBonus（回合抽牌加成） | 已有 stats 词条 | battle.dart:1704-1707；passives.json5:1148-1156 |
| self_scry 回调（观星结算后） | 已分发，details `{count, chosen}` | battle.dart:1131-1136（费用修正之后触发） |
| deckCostReduction（组牌费修） | 已支持负值加费 + `notGenres` 取反，注释已点名聚灵旗 | battle.dart:367-390；**缺口：单色盲区 + 0 费卡盲区** |
| 临时费用（本回合 +N 还原） | **不存在**；attune 的入手改费/离手还原是最接近先例 | card_script.ht:524-549；clearHand 离手派发 battle.dart:870 |
| 异常层数修正 | **不存在**；gained_debuff 回调只能 cancelAmount 向下抵消 | character.dart:610-639 |
| 绝世装备数据通道 | 就绪：items.json5 模板 :235-268；固定词条实例化 equipment.ht:145-151；唯一性检查 battle_entity.ht:656-661 | — |

**法器 kind 注意**：法器 = category `talisman` + kind `pearl`（唯一 kind）。窥天镜/天机盘/聚灵旗三件共用 pearl，默认图标相同——绝世装备必须各自配专属 icon 字段与图标文件。

## 1. 逐件装备方案

### 1.1 窥天镜 `heaven_peeking_mirror`（法器 talisman/pearl，rank 1）

> 观星时额外查看 2 张；每次观星对自身随机施加 2 种不同的元素异常（各 1 层）。

- 词条 1：`scryBonus`（**已有**，passives.json5:1167），数值 2。
- 词条 2（新）：`scry_self_ailments` → `battleStatus: "scry_self_ailments"`。
- 新状态 `scry_self_ailments`（status_effect.json5）：isPermanent，script 同名，callbacks `["self_scry"]`，
  图标 1 个（150×150 永久状态图标）。
- 新状态脚本 `scry_self_ailments_self_scry`（status_script.ht）：从 `Constants.elementAilments`
  的值域随机抽 2 个不重复 id，`self.addStatusEffect(id, amount: 1, source: self)`。
  （`source: self` 见 §2.1——配合五行珠时自施异常应双向放大。）
- **纯内容层，零 Dart 改动**（依赖 §2.1 的 source 参数仅是联动增强，非必需）。
- 决策点：自施异常会经 `self_gained_debuff`，若未来有辟邪类效果可能抵消自异常——当前合理，写入描述即可。

### 1.2 五行珠 `five_elements_pearl`（jewelry/amulet，rank 2）

> 你造成的元素异常层数 +2；你受到的元素异常层数 +2。

- 新词条 2 个（passives.json5，stats 聚合，不进随机池，kinds: amulet）：
  `ailmentInflictBonus`、`ailmentReceiveBonus`，数值各 2。
- **需 Dart 机制 §2.1**：addStatusEffect 增加 `source` 参数 + stats 层数修正；
  stats 聚合管线五处同步（参照 passive-status skill：battle_entity.ht 聚合 / passives.json5 /
  stats.dart 显示 / character.json 属性名 / 本条词条）。
- predictDamage 同步修正（路径①预览一致，character.dart:271-345）。
- 语义确认（已按设计兑现）：自施异常时「造成+受到」双向 +4，需在自施脚本显式传 `source: self`。

### 1.3 天机盘 `heavenly_mechanism_disc`（法器 talisman/pearl，rank 3）

> 回合开始时额外抽 1 张牌；通过此效果抽到的非悟道牌，本回合费用 +1。

- 新词条 `turnStartExtraDraw`（passives.json5，不进随机池），字段：
  `turnStartExtraDraw: {count: 1, costIncrease: {amount: 1, notGenres: ["spellcraft"]}}`。
- **需 Dart 机制 §2.2**：抽牌阶段额外抽牌 + 命中卡临时加费（记在卡上）+ 回合结束/开始清理。
- 不用现成 battleDrawBonus：那个加的是普通抽牌数，无法标记「通过此效果抽到」。
- 语义说明（写入描述）：保留（retain）牌若带临时加费跨回合，在下回合开始时还原。

### 1.4 蓄灵佩 `spirit_storing_amulet`（jewelry/amulet，rank 4）

> 回合结束时至多保留 2 点未使用的灵气到下回合；每保留 1 点，下回合开始受到 3 点纯粹伤害。

- 新词条 `energyRetainSpell`（passives.json5，不进随机池，kinds: amulet）：
  `energyRetain: {resourceId: "energy_positive_spell", max: 2, costPerPoint: 3, costDamageType: "pure"}`。
- **纯数据，零代码**：机制已完整（伤害在回合开始清理残余资源时结算，正合「下回合开始受到」）；
  阴阳五行结算已自动扣除保留部分（status_script.ht:330-353），描述里写明即可。
- 本件是绝佳的「先行件」——建议最先落地验证通道。

### 1.5 聚灵旗 `spirit_gathering_banner`（法器 talisman/pearl，rank 5）

> 回合开始时灵气 +3；你打出的非悟道牌费用 +2。

- 词条 1（新）：battleStatus 状态 `turn_start_mana_bonus`（isPermanent，callbacks
  `["self_produce_resources"]`）+ 状态脚本 `turn_start_mana_bonus_self_produce_resources`：
  `self.addStatusEffect('energy_positive_spell', amount: effect.amount)`，状态数据 `amount: 3`。
  （挂 produce_resources 时机——更早授予会被当残留清空；与太上感应同通道。）
- 词条 2（新）：`deckCostIncreaseAll` →
  `deckCostReduction: {color: "all", amount: -2, notGenres: ["spellcraft"]}`。
- **需 Dart 机制 §2.3**：getDeck 支持 `color: "all"`（命中卡首个费用条目）且加费可从 0 起。
- 状态图标 1 个（永久状态图标）。

## 2. Dart 机制改动（3 处，均小体量）

### 2.1 addStatusEffect：source 参数 + 异常层数 stats 修正（五行珠）

文件：`lib/scene/battle/character.dart`（:472 起）、`lib/scene/battle/character_binding.dart:94-96`、
`scripts/main/cardgame/battle_character.ht:48`。

- 签名扩展：`addStatusEffect(String id, {int? amount, BattleCharacter? source, ...})`，
  `source ??= opponent`（外部类 namedArg `source` 透传；缺省语义 = 对方施加，覆盖路径①与对手直施）。
- 在混沌抵消之后、累层之前插入：
  `id.startsWith('ailment_')` 时 `amount += source.stats.ailmentInflictBonus + data.stats.ailmentReceiveBonus`（各自缺省 0）。
- `predictDamage`（:271-345）路径①的异常预览同步加同一份修正。
- stats 聚合：`battle_entity.ht` 的 characterCalculateStats 增加两个字段聚合（照 scryBonus :356 模式）。

### 2.2 抽牌阶段：turnStartExtraDraw + 临时费用与清理（天机盘）

文件：`lib/scene/battle/battle.dart`（抽牌 :1704-1707、clearHand :1844 附近、_startTurn 保留卡巡检）。

- 抽牌阶段正常抽完后，读 passives 的 `turnStartExtraDraw`（累加 count）：
  逐张 `drawCardsToHand`；命中 `costIncrease.notGenres`（卡 genre 在列表则跳过）的卡，
  其 coloredCost 首个条目 +amount（允许 0→1），把 `{color, amount}` 记入 `card.data['turnCostIncrease']`。
- 清理两处：① `clearHand` 弃牌前按记录还原（与 removed_from_hand 派发同循环）；
  ② `_startTurn` 对手牌区（保留卡）巡检还原并清记录——保证「本回合」语义严格。
- 卡面变色：临时加费不动 originalColoredCost 基线，卡面自然显示红色增费（既有机制）。

### 2.3 getDeck：deckCostReduction 支持 color: "all"（聚灵旗）

文件：`lib/scene/battle/battle.dart:367-390`。

- `color == 'all'` 时命中卡的 coloredCost 首个条目（不再限定单色）；
- 加费方向（amount < 0）允许作用于显式 0 费条目（0→2）；减费方向保持 `max(0, …)` 与 `value > 0` 前置不变。
- 文档同步：docs/docs/mod/battle/readme.md 的被动字段契约（若该处有 deckCostReduction 条目）与
  `utils/data_validate/game_data_validate.dart` 的 kCostColors 检查（允许 'all'）。

## 3. 数据/脚本/本地化清单

### items.json5（5 件，放绝世装备模板区 :235-268 附近）

| id | category/kind | rank | affixes | 说明 |
| --- | --- | --- | --- | --- |
| heaven_peeking_mirror | talisman/pearl | 1 | scryBonus(2), scry_self_ailments | 窥天镜 |
| five_elements_pearl | jewelry/amulet | 2 | ailmentInflictBonus(2), ailmentReceiveBonus(2) | 五行珠 |
| heavenly_mechanism_disc | talisman/pearl | 3 | turnStartExtraDraw | 天机盘 |
| spirit_storing_amulet | jewelry/amulet | 4 | energyRetainSpell | 蓄灵佩 |
| spirit_gathering_banner | talisman/pearl | 5 | turn_start_mana_bonus, deckCostIncreaseAll | 聚灵旗 |

字段照模板：isUnique/isEquippable/name(=id)/flavortext(=`flavortext_{id}`)/icon（专属图标）/rarity。

### passives.json5（新 6 条 + 复用 1 条）

复用：`scryBonus`（:1167）。新增：`scry_self_ailments`（battleStatus）、
`ailmentInflictBonus` / `ailmentReceiveBonus`（stats 聚合）、`turnStartExtraDraw`（机制字段）、
`energyRetainSpell`（energyRetain 字段）、`turn_start_mana_bonus`（battleStatus）、
`deckCostIncreaseAll`（deckCostReduction）——均标注「绝世装备专用，不进随机词条池」（不写 isEquipmentMain/ExtraAffix）。

### status_effect.json5（新 2 个）

`scry_self_ailments`、`turn_start_mana_bonus`：均 isPermanent + script 同名 + callbacks + icon + amount。

### status_script.ht（新 2 个函数）

`scry_self_ailments_self_scry`、`turn_start_mana_bonus_self_produce_resources`。

### 本地化

- `item.json`：5 个 `{id}` 装备名 + 5 个 `flavortext_{id}` 描述（写明机制与代价，含「保留灵气不触发阴阳五行」「保留牌跨回合还原」等语义注记）。
- `passive.json`：6 个 `passive_*_description`。
- `status_effect.json`：2 组 `status_*` / `status_*_description`。
- `character.json`：`ailmentInflictBonus` / `ailmentReceiveBonus` 属性名+描述（stats 面板）。

### 图标（image-gen skill）

- 装备图标 5 个（绝世专属，不复用 kind 默认图）；尺寸风格对齐 `assets/images/item/equipment/` 现有图。
- 状态图标 2 个（150×150，`icon/status/permanent/`，参照 passive-status skill 流程）。

## 4. 实施步骤

1. **蓄灵佩先行**（纯数据，验证绝世装备全通道：items.json5 → passives → 战斗 energyRetain → 本地化 → 图标）。
2. **Dart §2.3**（getDeck 'all'）→ 聚灵旗词条 2；词条 1（状态+脚本）与窥天镜（§scryBonus + self_scry 脚本）同为内容层，可并行。
3. **Dart §2.1**（source + 异常 stats）→ 五行珠；顺带让窥天镜自施脚本传 `source: self`。
4. **Dart §2.2**（临时费用）→ 天机盘。
5. 图标生成与注册（5 装备 + 2 状态）。
6. 校验：`utils` 校验器同步扩展后全绿（见 §5）；`python build.py`（hetu.bat）重编译；`flutter analyze`。

## 5. 校验器同步（game_data_validate.dart）

- `deckCostReduction.color` 允许 `'all'`（kCostColors 检查处特判）。
- 新增字段结构检查（可选但建议）：`energyRetain`（resourceId 引用 + max/costPerPoint 数值）、
  `turnStartExtraDraw`（count 数值 + costIncrease.{amount, notGenres}）。
- items.json5 暂不在校验范围（本次亦不扩展，待装备条目增多后再议）。

## 6. 风险与决策点

- **自异常被辟邪抵消**（窥天镜/相生相克自施段）：当前无不妥，若未来出现自施被自辟邪挡的投诉再议。
- **五行珠自施 +4**：按设计「双向放大、自异常构筑第二个正面」兑现，需自施脚本显式 `source: self`；
  缺省 `source ??= opponent` 在敌方无此词条时行为不变，安全。
- **临时费用的跨回合泄漏**：保留卡已在 §2.2 用回合开始巡检兜底；弃牌堆/牌库中的卡费用无意义，
  下次入手若仍带记录会在 §2.2 清理点 ① 已还原（clearHand 时已处理），无泄漏路径。
- **法器共用 pearl kind**：以专属 icon 字段区分；若后续法器增多再考虑 kind 扩展。
- **敌人侧安全**：新增 stats/字段在敌人数据上缺省为 0/不存在，行为不变。


## 实施记录（已完成）

- **蓄灵佩 / 五行珠 / 天机盘 / 聚灵旗 / 窥天镜** 五件全部落地：items.json5:276-360（icon 暂用 `item/unknown.png` 占位）、passives.json5 新词条 6 条（+复用 scryBonus）、status_effect.json5 新状态 2 个、status_script.ht 新函数 2 个、本地化四文件。
- **Dart 三机制**已按计划实现：getDeck `color: 'all'`（含空表回退显式费用键，补 0 费卡盲区）、addStatusEffect `source` + 异常层数 stats 修正（含 predictDamage 同步）、turnStartExtraDraw + 临时费用与清理。
- **与计划的偏差**：
  1. 窥天镜 scryBonus 未做 item.ht `{id, level}` 对象词条——改用 `base: 2, increment: 0` 定值词条（与五行珠同手法，零代码）；prototype 上的 `level: 2` 固定已移除。
  2. 临时费用清理在计划的两处（clearHand、回合开始巡检）之外，补充了出牌路径 `removed_from_hand` 派发处还原——否则打出同回合绕开 clearHand，增费记录会随卡进弃牌堆泄漏。
  3. 集成时补上 battle_entity.ht:512 机制字段透传白名单的 `'turnStartExtraDraw'`（计划遗漏）。
- **验证**：hetu 编译通过（main.mod）；`game_data_validate` 0 错误；`flutter analyze` 无问题。
- **未验证**：游戏内实战效果（装备穿戴 → 战斗触发）无法命令行验证，需手动试玩。
- **图标**：草稿合集在 `assets/images/item/equipment/unique_drafts/`（镜/珠/盘/佩/旗题材齐全），正式图标待手动裁切替换。

## 补充：绝世词条按境界解锁（后续修订）

- 语义对齐绝世卡：`createItemById`（item.ht:130-160）对 isUnique 装备只实例化 affixes 列表**前 rank + 1 个**词条；**第一个词条 = 主词条**（装备数据本身不是主词条，词条信息在 passives.json5，故必须显式写 affixes 数组）。
- 5 件装备显式写 `rank: 1~5`（原误写 `rarity: "arcane"`——createItemById 里 rarity 优先推导 rank，arcane 会把全部装备压成 rank 5；已删除 rarity 与无意义的 level 钉值，稀有度由 rankToRarity 自动推导）。
- 窥天镜 affixes 调整为 `["scry_self_ailments", "scryBonus"]`（主词条在前）。
- 当前 5 件的词条数均 ≤ rank + 1，故本批装备生成即全量生效；后续追加额外词条时才真正用到解锁梯度。装备破境（升境）暂未提供，留待以后。
- 模板注释（items.json5:235-252）已同步上述约定；Equipment 构造的固定词条分支（equipment.ht:145-151）目前无调用方传 affixes，未做同规则处理。

## 修订：主词条合并（statsBonus 通用直加通道）

初版把单件装备的逻辑主词条拆成了多条 passive（如五行珠 = 施加+承受两条 stats 词条）——原因是
stats 聚合按词条 id 驱动（一条一 stat）。解决方案：

- **battle_entity.ht 新增 `statsBonus` 通用字段**：词条数据声明 `statsBonus: {statsId: 数值}`，
  characterCalculateStats 统一累加进 character.stats（透传白名单同步）；聚合循环同时替代了
  原 scryBonus / ailmentInflictBonus / ailmentReceiveBonus 三条 id 专用聚合行（已删）。
- **每件装备的主词条合并为一条**（多机制字段本来就允许共存于一条词条）：
  - 窥天镜 `heaven_peeking_mirror`：battleStatus + `statsBonus: {scryBonus: 2}`
  - 五行珠 `five_elements_pearl`：`statsBonus: {ailmentInflictBonus: 2, ailmentReceiveBonus: 2}`
  - 聚灵旗 `spirit_gathering_banner`：battleStatus + deckCostReduction（纯字段合并，零代码）
  - 天机盘 / 蓄灵佩原本就是单词条（turnStartExtraDraw / energyRetainSpell），未动
- 删除被合并的旧词条（scryBonus / scry_self_ailments / ailment×2 / turn_start_mana_bonus /
  deckCostIncreaseAll 共 6 条 passive 及其描述键）；两个永久状态与状态脚本不变（仍由
  battleStatus 引用）。装备 affixes 列表现各含 1 条主词条，为后续额外词条留出解锁位。
