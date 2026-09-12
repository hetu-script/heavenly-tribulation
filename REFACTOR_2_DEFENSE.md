# 阶段 2 · 防御统一与真气穿透

> 总览见 `REFACTOR.md`，依赖阶段 1（护甲结算已在乘区后）。
> 本阶段以数据删改为主，完成后物理/真气的核心矛盾闭环，游戏立即可玩。

## 目标

1. 四种防御（`defense_physical/chi/elemental/psychic`）合并为单一**护甲**（id 建议沿用 `defense_physical` 或改名 `defense`，见下）。
2. 真气伤害自带 50% 防御穿透；穿透属性只作用于物理/真气。
3. 穿透词条、护盾、易伤按总览的"建议"收敛。
4. 删除/改造所有产 chi/elemental/psychic 防御的数据。

## 改动清单

### 2.1 防御状态合一

- `assets/data/status_effect.json5`：
  - 保留一个防御状态。建议**沿用 `defense_physical` 作为唯一 id**（改动面最小：
    卡牌主词条 defend 牌已全是 physical，脚本里 `'defense_${affix.damageType}'` 只需把 damageType 固定为 physical）。
    本地化标题改为"护甲"（新建locale键或改 `status_defense_physical` 文案）。
  - 删除 `defense_chi` / `defense_elemental` / `defense_psychic`。
  - `persistent_physical/chi/elemental/psychic` 四个"防御持久"状态合并为一个（`persistent_physical` 保留，
    文案改为"护甲持久"）。
- `scripts/main/cardgame/status_script.ht`：
  - `defense_self_turn_start` / `defense_self_taking_damage`：damageType 匹配逻辑简化为只服务唯一护甲
    （真气 50% 穿透在 takeDamage/脚本中按伤害类型特判，见 2.2）。
- `lib/scene/battle/common.dart` 等处的防御相关映射同步清理。

### 2.2 真气自带 50% 穿透

- 结算时点（阶段 1 已把护甲移到乘区后）：`blocked = min(护甲, finalDamage × (1 − penetration))`。
- 真气伤害的 `penetration` 在结算时 **+0.5**（与词条穿透叠加，总和封顶建议 0.75，可调；
  现代码 `details.penetration.clamp(0, 1)` 处调整）。
- 实现位置建议：`takeDamage`（Dart）里 `if (damageDetails['damageType'] == 'chi') penetration += 0.5`，
  与阶段 5 的精神公式并列，作为"伤害类型固有规则"集中处理。
- 穿透属性从此只对 physical / chi 有意义：咒术（精神/纯粹）牌不再受益。

### 2.3 卡牌数据清理

`assets/data/cards.json5`：

- 主词条 defend 牌（punch/kick/sabre/sword/spear/staff 等）现状全是 physical——无需改伤害类型，
  只需确认 `uniqueId: "defend_physical"` 语义保留。
- **两张多重防御牌重设计**（`defend_multiple_exhaust` 脚本将失去意义）：
  - `flying_sword_defense`（御剑，原物理+元素双防）→ 改为"消耗剑气，获得护甲 + 附加效果"
    （建议附加：剑气相关或 speed_quick，保持御剑风味）。**【附加效果待确认】**
  - 法身 scripture 的 karma 版（约 1966 行，原物理+精神双防）→ 同上思路。**【待确认】**
  - 脚本 `defend_multiple_exhaust` 删除或保留（若没有其他使用者则删除）。
- `speed_quick_defend_physical` / `dodge_nimble_defend_physical` 等复合主词条：damageType 字段语义不变，无需大改。

`assets/data/card_affixes.json5`（额外词条）：

- `defend_chi` / `defend_elemental` / `defend_psychic` 删除，只留 `defend_physical`（唯一护甲词条）。
- `by_damage_gain_defense_chi/elemental/psychic` 删除，只留 physical 版。
- `consume_vigor_gain_defense_chi/elemental/psychic` 删除，只留 physical 版。

`scripts/main/cardgame/card_script.ht`：

- `defend` / `defend_exhaust` 等脚本中 `'defense_${affix.damageType}'` 简化（固定物理或保留插值但数据只剩 physical）。
- 删除 `defend_multiple_exhaust`（若 2.3 的两张牌不再使用）。

### 2.4 装备 / 天赋盘清理

`assets/data/passives.json5`：

- `start_battle_with_defense_chi/elemental/psychic` 删除；`start_battle_with_defense_physical` 保留（文案改"战斗开始获得护甲"）。
- `start_battle_with_shield_chi/elemental/psychic` 删除；`start_battle_with_shield_physical` 保留并改为通用护盾（见 2.5）。
- 穿透类装备词条收敛（已确认）：`unarmedPenetration/weaponPenetration/spellPenetration/cursePenetration`
  → **合并为单一 `penetration` 词条**（isItem，适用装备部位取原四者的并集）。
  属性与**伤害类型**绑定而非攻击类型：词条文本注明"只作用于物理和真气伤害"。
  `cursePenetration` 随之删除。

`assets/data/passive_tree.json5`：

- 引用被删 passive 的天赋节点替换为对应新节点（护甲、穿透、护盾）。
  注意节点带轨道坐标与 `connectedNodes`，尽量**原位替换 passives 数组内容**，不动布局。

### 2.5 护盾与易伤收敛

- **护盾（已确认）**：`shield_physical/chi/elemental/psychic` 四件合并，并入阴阳气系统，作为**浩然之气**：
  id `energy_positive_shield`，每层抵挡一次任意**非纯粹**伤害，触发消耗 1 层。
  - `shield_self_taking_damage` 脚本逻辑保留（cancelDamage），移除 damageType 匹配。
  - `start_battle_with_shield_*` 四个 passive 合并为 `start_battle_with_energy_positive_shield`。
  - 对位**萧索之气** = `energy_negative_shield`：新脚本，持有者受击时（`self_taking_damage`）消耗 1 层，
    使该次伤害 ×2（独立倍率，任意伤害类型含纯粹）。多段攻击每段各消耗 1 层（与护盾消耗规则一致）。
  - 本地化："阳气包括"清单加入浩然之气（护盾）、"阴气包括"加入萧索之气；原四护盾键删除。
- **易伤（已确认，总览决策 15）**：`vulnerable_physical/chi/elemental/psychic` → 合并为单一 `vulnerable`
  （受到任何伤害时消耗并增加等量伤害；百分比弱点在阶段 4 只保留元素分型）。
  `kDebuffs`（`scripts/main/cardgame/common.ht`）中的四个 vulnerable 条目替换为单一 `vulnerable`（保留在随机池中）。

### 2.6 本地化

`assets/locale/zh/rpg/`：

- `status_effect.json`：删除 defense_chi/elemental/psychic、shield 三件、persistent 三件、vulnerable 三件的键；
  修改保留键的文案（护甲、护甲持久、通用护盾、通用易伤）。
- `battlecard.json` / `craft.json` / `passive.json`：删除/修改对应词条描述
  （`affix_defend_chi`、`affix_by_damage_gain_defense_chi`、`passive_unarmed_penetration_description` 等）。

### 2.7 伤害颜色与 UI

- `lib/scene/battle/character.dart` `getDamageColor`：本阶段伤害类型不变（physical/chi/elemental/psychic/pure 仍在），
  无需改动；元素拆分在阶段 4 处理。
- 战斗内状态栏：防御图标从最多 4 个降为 1 个，检查状态栏布局是否正常。

## 涉及文件

- `assets/data/status_effect.json5`、`assets/data/cards.json5`、`assets/data/card_affixes.json5`
- `assets/data/passives.json5`、`assets/data/passive_tree.json5`
- `scripts/main/cardgame/status_script.ht`、`card_script.ht`、`common.ht`
- `lib/scene/battle/character.dart`、`lib/scene/battle/common.dart`、`lib/scene/battle/battle.dart`（若有 defense 映射）
- `assets/locale/zh/rpg/status_effect.json`、`battlecard.json`、`craft.json`、`passive.json`
- `docs/docs/how2play/rpg/battle/readme.md`（防御一节重写）

## 验证清单

- [ ] 编译通过，`flutter analyze` 无新增错误
- [ ] 实机：打出任意 defend 牌只获得一种护甲；真气攻击 20 点对 8 护甲造成 16 点（10 穿透 + 10−8）
- [ ] 实机：穿透词条对咒术牌不再生效
- [ ] 装备/天赋界面不再出现被删词条；旧存档兼容（见下）
- [ ] 旧存档迁移：角色已有的 `defense_chi` 等状态/词条在加载时的处理策略（直接丢弃或映射为护甲）**【待确认】**
