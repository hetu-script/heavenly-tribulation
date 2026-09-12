# 阶段 4 · 元素体系拆分

> 总览见 `REFACTOR.md`，依赖阶段 2（防御已合一）。
> 本阶段是工作量最大的阶段：既有数据映射改动 + 大量新增内容（新伤害类型、新抗性、新词条、新状态、美术）。

## 目标

1. `elemental` 伤害类型拆分为四种：**fire / ice / lightning / poison**。
2. 风、土系伤害类型转为物理；水→冰、木→毒。
3. 删除旧四抗性（physical/chi/elemental/psychic），新建四元素抗性。
4. 新增"降低对手元素抗性"词条（元素系的进攻对策）。
5. 新增元素状态（灼伤/寒冷/麻痹/中毒），中毒从伤势迁出。

## 元素映射总表

| 功法（kind）           | 原伤害类型 | 新伤害类型    | 备注                                              |
| ---------------------- | ---------- | ------------- | ------------------------------------------------- |
| 御火术 firebend        | elemental  | **fire**      |                                                   |
| 雷法 lightning_control | elemental  | **lightning** |                                                   |
| 御风术 airbend         | elemental  | **physical**  | 风刃如刀；仍是法术牌，吃灵气加成；阶段 3 后可暴击 |
| 土遁术 earthbend       | elemental  | **physical**  | 土石物理；土系加持牌给护甲风味天成（岩甲）        |
| 御水术 waterbend       | elemental  | **ice**       | 水冰同源                                          |
| 木遁术 plant_control   | elemental  | **poison**    | 瘴气毒藤                                          |

**数据现状注意**：`cards.json5` 中目前 elemental 攻击牌只存在于 firebend / airbend / lightning_control
（约 507、534、566、602、605、634、637 等行）；waterbend / earthbend / plant_control 当前是加持类。
冰、毒的**攻击主词条卡牌是净新增内容**（含插画），见 4.4。

## 改动清单

### 4.1 伤害类型枚举扩展

- `lib/data/common.dart`：`DamageType` 删除 `elemental`，新增 `fire` / `ice` / `lightning` / `poison`；
  `kDamageTypes` 更新为 physical / chi / fire / ice / lightning / poison / psychic / pure。
- `lib/data/constants.dart` + `scripts/main/binding/constants.ht`：同步导出。
- `lib/scene/battle/character.dart` `getDamageColor`：四种元素各配颜色
  （建议 fire=橙红、ice=青蓝、lightning=金黄、poison=紫绿）。
- 全库搜索 `"elemental"`（dart/ht/json5/json），逐一判定归属。

### 4.2 卡牌 damageType 重映射

`assets/data/cards.json5`：

- 按映射总表逐张修改 `damageType`（含 `damageType: ["physical", "elemental"]` 这类数组形式，如约 1518 行）。
- airbend 攻击牌（约 566、723 行）→ physical。
- firebend → fire；lightning_control → lightning。
- 检查 `card_affixes.json5` 中 `damageType: "elemental"` 的词条
  （`consume_mana_for_extra_damage_elemental` 等）→ 改为具体元素或重做。**【逐条判定】**
- 描述文案中的"元素伤害"表述逐条改为具体元素名。

### 4.3 元素抗性（替代旧四抗性）

`assets/data/status_effect.json5`：

- 删除 `resistant_physical/chi/elemental/psychic`、`weakness_physical/chi/elemental/psychic`。
- 新增 `resistant_fire/ice/lightning/poison`（脚本沿用通用 `resistant`，damageType 匹配机制不变）。
- 新增 `weakness_fire/ice/lightning/poison`（负抗性，百分比弱点只保留元素分型——来自总览建议）。

`assets/data/passives.json5`：

- 删除 `physicalResist/elementalResist/chiResist/psychicResist` 及对应 `*ResistMax`。
- 新增 `fireResist/iceResist/lightningResist/poisonResist` + `*ResistMax`
  （isItem、isItemMain，装备部位沿用原抗性的 armor/gloves/boots/helmet/shield；上限 75% 规则不变）。

`scripts/main/data/character/battle_entity.ht`：

- stats 派生：四种新抗性及其上限，替换旧四组。

`lib/scene/battle/battle.dart`：

- `kEquipmentStatsToStatus` 映射表：`physicalResist → resistant_physical` 等四组
  替换为 `fireResist → resistant_fire` 等新四组；删除 chiResist/psychicResist 映射。

`assets/data/passive_skills.json5`：

- 旧抗性节点原位替换为四元素抗性节点（数量可能增加，注意布局预留）。

`lib/widgets/character/stats.dart`：

- `kStats` 中的 `'physicalResist'` / `'chiResist'` / `'elementalResist'` / `'psychicResist'`
  替换为 `'fireResist'` / `'iceResist'` / `'lightningResist'` / `'poisonResist'`。

`assets/locale/zh/rpg/character.json`：

- 四种元素抗性及其上限的属性名与描述键同步增删。

### 4.4 新增内容（本阶段重头）

1. **冰攻击主词条卡牌**（御水术攻击牌）：数张 + 插画 + 动画 + 音效。
2. **毒攻击主词条卡牌**（木遁术攻击牌）：同上。淬毒装备（resource 文档已有设计）造成的武器附加毒伤
   在本阶段落地为直接 poison 伤害（吃毒抗）。**【淬毒联动范围待确认】**
3. **降抗词条**（`card_affixes.json5` 新增四条 + 脚本）：
   "降低对手 X 点火/冰/雷/毒抗"（持续本场战斗或数回合——**【时效待确认】**）。
   这是元素系唯一的进攻军备竞赛，替代穿透在元素侧的位置。
4. **元素持续伤害（DOT）**：统一规则 + 四种参数（设计定案，参数为初值）。
   统一规则：**回合开始时每层失去 X 点生命（伤害类型为对应元素，受对应抗性减免），回合结束时移除 Y 层**。
   四种元素共用**同一个参数化状态脚本**（脚本 id `element_dot`，damageType / X / Y 为参数），靠参数制造节奏差异，避免机制换皮。
   状态 id 统一为 `element_dot_fire/ice/lightning/poison`，便于检索：

   | 元素 | 状态 id                 | 中文 | X（每层伤害） | Y（每回合衰减） | 节奏                                                              |
   | ---- | ----------------------- | ---- | ------------- | --------------- | ----------------------------------------------------------------- |
   | 火   | `element_dot_fire`      | 灼伤 | 5             | 1 层            | 稳定燃烧（基准）                                                  |
   | 雷   | `element_dot_lightning` | 触电 | 10            | 全部            | 瞬时爆发：施加后立刻兑现                                          |
   | 冰   | `element_dot_ice`       | 冻伤 | 1             | 1 层            | 绵长消磨：长战有利                                                |
   | 毒   | `element_dot_poison`    | 中毒 | 3             | **不衰减**      | 累积施压：只能靠治疗/净化驱散（`self_heal` 时减层，与流血同规则） |
   - 毒"不衰减"继承旧 `injury_poison` 的性格（旧中毒本就无衰减），以低数值 + 治疗驱散平衡。
   - 实现：状态脚本内读取 `hasStatusEffect('resistant_X')` 按比例减免后 `changeLife`，
     **不走 `takeDamage`**（避免触发护甲/暴击等攻击向结算）。
   - 实机重点测两个极端：雷（全衰减，会不会太弱）与毒（不衰减，会不会滚雪球）。
   - 图标 ×4 + 本地化 ×4。

5. **本地化**：四种伤害类型名（"火焰""寒冰""雷电""毒素"）、四抗性、四弱点、四降抗、四元素状态、
   新卡牌的名称/描述/插画键。
6. **美术**：四种伤害类型图标（如状态栏需要）、四元素状态图标、新卡牌插画。
   **这是本阶段最大的隐性工作量，建议最早启动。**

### 4.5 伤势系统收编

- `assets/data/status_effect.json5`：删除 `injury_poison`（中毒迁入元素持续伤害 poisoned，见 4.4 第 4 项）。
- `assets/locale/zh/rpg/status_effect.json`：
  `status_injury_description` 改为"伤势包括: 流血、内伤、幻觉"；
  `status_ward_description` 的"负面效果包括"清单同步（去掉中毒、加入元素状态如需要）。
- `scripts/main/cardgame/common.ht` `kDebuffs`：`injury_poison` 移除；四种元素持续伤害
  （`element_dot_fire/lightning/ice/poison`）入池（已确认，总览决策 14）。
- 幻觉保持精神系伤势（不可减免）——阶段 5 可考虑念力减免幻觉，本阶段不动。

### 4.6 弱点与易伤的分工（已确认，总览决策 15）

- 弱点（百分比）= 仅四种元素分型（`weakness_fire/ice/lightning/poison`），即负元素抗性。
- 易伤（数值）= 单一 `vulnerable`，不分类型，通用增伤（阶段 2 完成合并）。
- 物理/真气没有百分比对策——护甲是它们的唯一防线；精神没有百分比对策——念力是唯一防线。
- 文档写清这条分工。

### 4.7 文档

- `docs/docs/how2play/rpg/battle/readme.md`：伤害/防御对照表重写（物理/真气/四元素/精神/纯粹）。
- `resource/readme.md`：元素一节同步。

## 涉及文件

- `lib/data/common.dart`、`lib/data/constants.dart`、`scripts/main/binding/constants.ht`
- `lib/scene/battle/character.dart`（颜色）、`lib/scene/battle/battle.dart`（映射表）
- `assets/data/cards.json5`、`card_affixes.json5`、`status_effect.json5`、`passives.json5`、`passive_skills.json5`
- `scripts/main/cardgame/status_script.ht`、`card_script.ht`、`common.ht`
- `scripts/main/data/character/battle_entity.ht`
- `assets/locale/zh/rpg/`（status_effect / battlecard / craft / passive / character）
- `assets/images/`（新图标、新插画）、`assets/audio/`（新音效，如需要）
- `docs/docs/how2play/rpg/battle/`

## 验证清单

- [ ] 编译通过，`flutter analyze` 无新增错误
- [ ] 全库无残留 `"elemental"` 伤害类型（除历史注释）
- [ ] 实机：风系法术跳物理伤害色、被护甲抵挡；火系跳火色、吃火抗
- [ ] 实机：冰/毒新牌可正常获得、打出、被对应抗性减免
- [ ] 实机：降抗词条使目标受到对应元素伤害增加
- [ ] 实机：四种元素持续伤害正确触发、按各自参数衰减，且被对应抗性减轻
- [ ] 伤势界面只显示流血/内伤/幻觉
- [ ] 旧存档迁移策略（旧 elemental 卡牌/词条映射到新类型）**【待确认】**
