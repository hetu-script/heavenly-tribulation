---
name: battlecard-content
description: |
  在《天道奇劫》中创建/修改战斗卡牌内容（普通卡牌、绝世卡牌、卡牌词条）时使用。
  涵盖三层联动：数据（assets/data/cards.json5 主词条 / card_affixes.json5 额外词条）、
  脚本（scripts/main/cardgame/card_script.ht 词条效果 / status_script.ht 状态效果）、
  本地化（assets/locale/zh/rpg/battlecard.json 等）。当任务涉及新增卡牌、绝世卡、词条、
  卡牌效果脚本，或修改卡牌数值/费用/动画/境界/流派时加载本技能。
---

# 战斗卡牌内容创建技能

本项目战斗卡牌 = 暗黑式词缀系统。一张卡 = 1 个主词条（决定卡的身份）+ 0~6 个额外词条（随机/固定）。
创建任何卡牌内容都必须**三层同步**：数据、脚本、本地化，缺一不可。

## 0. 快速决策：我该改哪个文件？

| 需求 | 主词条(cards.json5) | 额外词条(card_affixes.json5) |
|---|---|---|
| 一种**新卡牌**（有自己的卡面/动画/身份） | ✅ 新增 | |
| 给卡牌**附加一个效果**（可随机出现在多类卡上） | | ✅ 新增 |
| **绝世卡**（固定词条组合的稀有卡） | ✅ isUnique + affixes 列表 | （预定义词条若不存在也需新增） |
| 新**效果机制** | 配套写 CardScript 函数 | 配套写 CardScript 函数 |

- **主词条**（cards.json5）：一张卡的"本体"。决定 category/kind/cardType/damageType/插画/动画/费用/主数值。
- **额外词条**（card_affixes.json5）：可随机附加到卡上的修饰。决定附加效果。必须能泛用于多类卡。

## 1. 三层同步清单（每次新增必做）

### A. 数据层（json5）

- 顶层对象，键 = 实体 id（snake_case），对象内 `id` 字段必须等于键名。
- **主词条**加进 `assets/data/cards.json5`，按分区放在对应注释区块下
  （绝世·加持 / 天赋授予卡 / 通用·攻击 / 通用·加持 / 悟道· / 锻体· / 御剑· / 法身· / 炼魂·）。
- **额外词条**加进 `assets/data/card_affixes.json5`，放对应分区
  （通用 / 攻击 / 时机回调）。
- 稀有度/境界：用 `rank` 字段（0~5），不是 rarity。
- 注释用中文。

### B. 脚本层（card_script.ht）

- 词条数据的 `script` 字段 = `scripts/main/cardgame/card_script.ht` 中 `namespace CardScript` 的函数名。
- 统一签名：`function xxx(self, opponent, card, affix)`
  - `self`/`opponent`：出牌方/对方 BattleCharacter（外部类，API 见 `scripts/main/cardgame/battle_character.ht`）。
  - `card`：卡牌数据本体（BattleCard struct），可读写字段。
  - `affix`：本词条数据，读 `affix.value`（数值数组）、`affix.buffId` 等自定义字段。
- 数值读取：`affix.value[0]`、`affix.value[1]`…（与 valueData 数组一一对应）。
- **时机回调词条**（非打出时触发）：数据加 `callbacks: ["added_to_hand"]` 等列表，
  脚本提供 `{script}_{时机}` 函数（如 `retain_added_to_hand`），并保留同名占位函数。
- **条件过滤词条**：参照 `draw_cards`，数据加 `filter: { genre/cardType/... }` 子表，
  脚本把 `affix.filter` 作为 options 传给对应的 BattleCharacter 方法
  （如 `upgrade_hand_cards` → `self.upgradeHandCards(n, options: affix.filter)`）；
  匹配字段见 `matchCardCriteria`（battle.dart），且需在 battle_character.ht 声明该方法。
- 词条脚本必须能独立生效；执行顺序由 `priority` 控制（priority<0 的额外词条先于主词条）。
- 可用 API（BattleCharacter 外部类）：`takeDamage` `addStatusEffect` `removeStatusEffect`
  `changeLife` `setLifeMax` `hasStatusEffect` `drawCards` `scry` `upgradeHandCards` `addHintText`
  `turnFlags` `cardFlags` 等。
- 全局工具函数（namespace 外可直接调）：`upgradeCard(card, inBattle: true)`、常量 `Constants.*`。

### C. 本地化层（battlecard.json）

- 词条 `description` 字段 = `assets/locale/zh/rpg/battlecard.json` 的键。
- 词条名：`"affix_xxx": "名称"`；若需长描述再加 `"affix_xxx_description": "..."`。
- 描述中的数值占位用 `{0}` `{1}`，对应 valueData 数组下标。
- **绝世卡**必须加卡名：`"uniquecard_{主词条id}": "卡名"`。
- keywords 若引用状态，需确保 `status_effect.json` 有对应 `status_xxx` / `status_xxx_description`。
- 仅用中文，中国风措辞（不用拼音做键名，键名用英文含义）。

### D. 编译验证（必做）

改完必须重新编译脚本并检查：

```
"C:/Users/Administrator/AppData/Local/Dart/install/bin/hetu.bat" compile scripts/main/main.ht assets/mods/main.mod
flutter analyze   # 若改了 dart
```

（`python build.py` 在 Windows 下对 hetu 的调用有 PATH 问题，直接用上面的 hetu.bat 路径。）

## 2. 主词条（cards.json5）字段详解

```json5
punch_attack: {
  id: "punch_attack",            // 必须等于键名
  uniqueIds: ["defend"],         // 可选：本卡占用/排斥的额外词条 uniqueId
  category: "attack",            // attack | buff
  genre: "spellcraft",           // 流派：spellcraft/swordcraft/bodyforge/vitality/avatar；省略=中立
  kind: "punch",                 // 命名/动画类别（拳/腿/剑/…/xinfa/shenfa/…）
  cardType: "unarmed",           // 七类：unarmed/weapon/spell/curse/shenfa/xinfa/divinity
  damageType: "physical",        // 攻击卡必填：physical/chi/fire/ice/lightning/poison/psychic/pure
  elementType: "element_fire",   // 悟道元素卡：element_fire/ice/lightning/...
  rank: 1,                       // 使用境界门槛 0~5，省略=0
  description: "affix_attack_unarmed",  // 本地化键
  keywords: ["status_defense"],  // 悬浮提示关联
  image: "battlecard/illustration/punch_attack.png",
  animation: {                   // 战斗动画
    startup: ["before_melee_startup", "melee_startup"],  // 前摇（数组）
    recovery: ["melee_recovery"],   // 后摇（可选）
    actions: ["punch_attack"],      // 攻击动作（可选）
    overlays: ["restore_life"],     // 叠加特效（可选）
    sound: "xxx.mp3",
  },
  script: "attack",              // CardScript 函数名
  equipment: "sword",            // 可选：装备需求
  coloredCost: { life: { base: 0.5, rankIncrement: 0.5 } },  // 费用（见下）
  valueData: [ { base: 7, increment: 0.7 } ],  // 数值（见下）
  // 标记类（可选布尔）：
  isUnique: true,      // 绝世卡
  isEphemeral: true,   // 消耗品（打出碎裂）
  isUnpackable: true,  // 不进卡包/随机池（天赋授予卡用）
},
```

### 费用 coloredCost

- 单资源模型：一张卡只花一种资源。
- **流派卡** = rank 点流派色：`coloredCost: { spell: {base:0, rankIncrement:1} }`
  （悟道→spell / 御剑→weapon / 锻体→unarmed / 炼魂→curse）。
- **中立卡（含法身）** = rank+1 点元气：`coloredCost: { life: {base:1, rankIncrement:1} }`
  或 `{ life: {base:0.5, rankIncrement:0.5} }`。
- **免费卡**：`coloredCost: { life: 0 }`（显式 0）。
- 费用公式与词条数值**脱钩**：`calcCostValue` = `base + rankIncrement×rank`（独立线性，不被指数影响）。
- 条目可为固定数值（如 `{ life: 0 }`、`{ spell: 10 }`）或 `{base, rankIncrement}` 公式。

### 数值 valueData

- 数组，每个元素对应 `affix.value[i]`。
- `value = (base + increment×(等级 − 本境界下限)) × 1.3^境界 + rankIncrement×境界`（见 `calcAffixValue`）。
- 词条等级 = 卡牌等级（主词条）或境界区间内随机（额外词条）。
- `increment` 按本境界内等级缩放（+1 级相对提升区间起点 ≈ increment/base，全境界恒定有感）。
- `maxLevel: 0` 表示该值不随词条等级缩放（固定 base）。
- 多值词条（如 attack_multiple 的伤害+次数）用多个元素。
- 固定数值读法：数值词条必有 valueData；纯机制词条（无数值）可省略，脚本里写死逻辑。

## 3. 额外词条（card_affixes.json5）字段详解

```json5
upgrade_card: {
  id: "upgrade_card",
  uniqueId: "upgrade_card",        // 必填：同类互斥 + 主词条 uniqueIds 去重
  categories: ["buff", "attack"],  // 可附加到哪些类别（数组）
  genres: ["swordcraft"],          // 可选：限定流派（数组）；省略=全流派通用
  rank: 1,                         // 出现所需卡牌境界
  description: "affix_upgrade_card",
  keywords: ["affix_upgrade_card"],
  script: "upgrade_card",
  priority: -1,                    // 可选：<0 则打出时先于主词条执行
  callbacks: ["added_to_hand"],    // 可选：时机回调（非打出时触发）
  buffId: "defense",               // 可选：施加的状态 id（self_buff/opponent_debuff 用）
  attributeId: "dexterity",        // 可选：for_attribute_increase_damage 用
  valueData: [ { base: 1, maxLevel: 0 } ],
},
```

- 额外词条通过 `_getSupportAffixes` 匹配：categories 包含卡的 category、genres 包含卡的 genre、
  rank ≤ 卡的 rank、uniqueId 未被占用。
- **中立词条**：不写 `genres`，所有流派卡都可能 roll 到。
- **流派专属**：写 `genres: ["xxx"]`（如 retain→swordcraft、scry→spellcraft、for_*_increase_damage→各流派）。

## 4. 绝世卡（isUnique）

- 主词条加 `isUnique: true` + `affixes: ["额外词条id", ...]`（按境界 rank+1 顺序解锁的固定词条）。
- 固定卡名：本地化 `uniquecard_{主词条id}`。
- 生成时默认未鉴定（`isIdentified` 由 isUnique 推导为 false），需鉴定卷轴。
- 卡组中同 uniqueId 只能放一张。
- 不能进行灵宝/神照/真定/坐忘精炼，但可混元（重roll数值）和破境。
- 天赋授予型绝世卡再加 `isUnpackable: true`（不进随机池），由代码显式 `invoke('BattleCard', affixId: ...)` 发放。

## 5. 常用 CardScript 模板

```hetu
// 攻击
function attack(self, opponent, card, affix) {
  opponent.takeDamage({ isMain:true, kind:affix.kind, cardType:affix.cardType,
    damageType:affix.damageType, baseValue: affix.value[0] })
}
// 自身增益 / 对手减益
function self_buff(self, opponent, card, affix) { self.addStatusEffect(affix.buffId, amount: affix.value[0]) }
function opponent_debuff(self, opponent, card, affix) { opponent.addStatusEffect(affix.buffId, amount: affix.value[0]) }
// 战斗内升级（可突破上限，深拷贝不污染卡库）
function upgrade_card(self, opponent, card, affix) {
  for (final i in range(affix.value?[0] ?? 1)) upgradeCard(card, inBattle: true)
}
// 升级手牌（条件子表 filter 与 draw_cards 同口径，需 battle_character.ht 声明 upgradeHandCards）
function upgrade_hand_cards(self, opponent, card, affix) {
  self.upgradeHandCards(affix.value[0], options: affix.filter)
}
```

新机制参考现有函数：`heal`/`heal_lifeMax`（治疗）、`draw_cards`（抽牌带 filter/reduceCost）、
`scry`（观星）、`convert_vigor_all`/`refund_cost`（资源）、`by_damage_*`（伤害联动）、
`for_attribute_increase_damage`（属性增伤）、`upgrade_card`/`upgrade_hand_cards`（战斗内升级）。

## 6. 状态效果（status_script.ht）

若卡牌施加的状态需要新行为（非纯增减），在 `scripts/main/cardgame/status_script.ht` 加
`function {statusId}_{时机}(self, opponent, effect, details)`，时机见文件头注释。
状态数据在 `assets/data/status_effect.json5`，名称/描述在 `assets/locale/zh/rpg/status_effect.json`。

## 7. 自查清单

- [ ] id = 键名，snake_case，英文含义（不用拼音）。
- [ ] category/kind/cardType/damageType/genre/rank 填对（攻击卡必填 damageType）。
- [ ] 费用符合单资源模型（流派色 or 元气），用 calcCostValue 语义。
- [ ] script 函数在 CardScript 存在且签名正确；时机回调有 `{script}_{时机}` + 占位函数。
- [ ] valueData 与脚本读的 value[i] 数量对应。
- [ ] 本地化：affix_xxx（+_description）、uniquecard_xxx（绝世卡）、status 引用存在。
- [ ] 绝世卡：isUnique + affixes 列表 + uniquecard_ 卡名；天赋授予加 isUnpackable。
- [ ] 数值符合新指数公式（increment 按本境界内等级，全境界 +1 级有感）。
- [ ] 重新编译 main.mod 通过；改动 dart 则 flutter analyze 通过。

## 8. 参考文档（先读再改）

- `docs/docs/how2play/rpg/battle/card/readme.md` — 卡牌/词条/精炼/绝世卡规则
- `docs/docs/how2play/rpg/battle/readme.md` — 战斗规则（伤害类型/资源/状态）
- `docs/docs/how2play/rpg/battle/resource/readme.md` — 资源气系统
- `docs/docs/how2play/rpg/craft/readme.md` — 打造/精炼
- `docs/docs/mod/battle/card/readme.md` — 词条脚本回调契约
- `plan/affix_value_formula_rework.md` — 数值公式重构（新指数公式）
- `scripts/main/cardgame/card.ht` — BattleCard/Cardpack 生成逻辑
- `scripts/main/cardgame/battle_character.ht` — BattleCharacter 外部类 API
