# 阶段 4.5 · 元素体系补强：全抗、抗性结算收敛、元素异常系统

> 总览见 `REFACTOR.md`，在阶段 4（元素拆分）基础上追加。
> 本阶段四个方向：全抗属性回归、元素抗性结算收敛进 takeDamage、
> 元素异常几率/伤害新属性、四种异常按新定案重写。
> 阶段 4 中"异常由卡牌主动附加"的设计（attack_element_dot_exhaust）作废，改为概率触发。

## 〇、架构总评（对当前伤害计算的总体意见）

当前伤害计算的混乱根源：**同一件事的修正分散在四级跳转里**。
以抗性为例：装备词条 → 角色 stats → 战斗开始转换成永久状态（kStatsToPermanentEffects）
→ 状态脚本回调改乘区。而暴击这种纯属性从未变成状态，只能直接在 Dart 读 stats。
两条路径并存，导致"哪些修正在哪一层生效"难以追踪。

**收敛原则（本阶段执行）**：

1. **Dart 拥有管线骨架与"纯属性"结算**：乘区、护甲、穿透、暴击、抗性、异常触发、跳字、音效，
   全部固定在 `takeDamage`，直接读 stats 与状态净值，一次算清。
2. **Hetu 状态脚本只保留"行为型"效果**：取消（护盾）、消耗（易伤）、转化（冰缓）、
   资源联动（阴阳气）、周期结算（DOT/伤势）这类有逻辑分支的效果。
   纯数值修正型状态（抗性/弱点）的脚本退役，状态仅作计数与 UI 展示。
3. **抗性的唯一真值来源（作者澄清修订）**：战斗开始后 stats 仍转换为
   `resistant_X`/`weakness_X` 永久图标——纯显示、**无脚本回调**（与增强/削弱图标同款模式，
   但注意增强/削弱目前仍有脚本，仅抗性本次退役脚本）。
   因此 Dart 侧 `BattleCharacter.getElementalResist(damageType)` **只读状态净值**
   （resistant_X − weakness_X + resistant_elemental − weakness_elemental），75 封顶：
   若同时读 stats 会与图标数值双重计算；图标层数即真值，
   降抗词条的 weakness 经 kOppositeStatus 互斥自然抵消图标层数（30 抗遇 10 弱点 → 图标 20）。
   takeDamage 与 DOT 脚本都只调用它，不各自重算。
4. **DOT 不走 takeDamage**（定案）：DOT 与状态强绑定、非物理无需护甲、不应触发护盾/易伤/
   暴击/异常连锁。为此给 `changeLife` 扩展跳字支持（见 2.2），让 DOT 跳字带伤害类型颜色。
5. **长期方向（本阶段不做，仅记录）**：最终统一伤害入口——takeDamage 增加 source 标记
   （attack / dot / regen），changeLife 并入 takeDamage 的纯生命变化分支，脚本与 Dart 的
   职责边界届时重新划定。此为大改，建议在阶段 5 之后单独立项。

## 一、元素异常定案（作者已确认，代码以此为准）

本地化与文档（`status_effect.json`、`battle/readme.md`）已先行更新，**数据与脚本按此重写**：
（灼伤已改名**点燃**；异常伤害均受对应元素抗性减免，并受施加方 ailmentMultiplier 放大）

| 元素 | 状态 id                 | 名称 | 机制（定案）                                                                                | 节奏     |
| ---- | ----------------------- | ---- | ------------------------------------------------------------------------------------------- | -------- |
| 火   | `element_dot_fire`      | 点燃 | **回合开始时**受到 5 点火焰伤害（固定，不随层数放大），**同时消耗 1 层**；层数=剩余触发次数 | 稳定     |
| 雷   | `element_dot_lightning` | 感电 | **回合开始时层数直接耗尽**，每层随机受到 1~10 点雷电伤害（每层单独跳字）                    | 爆发     |
| 冰   | `element_dot_ice`       | 冰缓 | **回合结束时层数直接耗尽**，每层受到 1 点寒冰伤害，并分别随机转化为缓慢或迟钝               | 绵长干扰 |
| 毒   | `element_dot_poison`    | 中毒 | **回合结束时**受到 5 点毒素伤害（固定），**不自动消耗**；治疗时消耗 1 层（与流血同规则）    | 累积     |

`status_effect.json5` 数据调整：callbacks 改为 点燃/感电 `["self_turn_start"]`、
冰缓 `["self_turn_end"]`、中毒 `["self_turn_end", "self_heal"]`；
dotDamage 改为 5 / 0 / 1 / 5（感电为脚本内随机 1~10）；decay 字段废弃删除（消耗逻辑全部内联进脚本）。

`status_script.ht` 的 `element_dot_*` 按上表重写（turn_start / turn_end / self_heal 三函数），
抗性系数改为一行调用：`final factor = 1 - 0.01 * self.getElementalResist(effect.damageType)`，
伤害再乘 `(effect.ailmentMultiplier ?? 100) / 100`（见 3.3）。

本地化文案同步修正（作者裁决：感电数值取原定案 1~10；中毒不自动消耗）：

- 感电：`status_element_dot_lightning_description` 改为
  "回合开始时耗尽所有层数，每层随机受到 1~10 点雷电伤害。"
  （`battle/readme.md` 感电行的"随机消耗层数 / 5 点"同步修正）
- 中毒：`status_element_dot_poison_description` 改为
  "回合结束时受到 5 点毒素伤害。每次恢复生命时，减少 1 层中毒。"
  （`battle/readme.md` 中毒行的"每层失去 3 点生命"同步修正）

### 一·补、伤势驱散文案落地（作者临时加入本阶段）

作者已将 `status_effect.json` 中流血/内伤/幻觉的描述改为"都有可以被移除的方法"，代码需兑现：

- **流血**：恢复生命减 1 层——已实现（`self_heal`），无需改动。
- **内伤**："每次获得元气时，减少 1 层内伤"。修复既有死回调：`status_effect.json5`
  登记的 `self_gain_energy_positive` 与 Dart 实际触发的 `self_gained_energy_positive`
  不一致；统一为 `self_gained_energy_positive`，脚本判定 `details.id == 'energy_positive_life'`
  （元气）才减 1 层。
- **幻觉**："每次获得灵气时，减少 1 层幻觉"（新机制）。callbacks 增加
  `self_gained_energy_positive`，脚本判定 `details.id` 为 `energy_positive_spell`（灵气）
  或 `energy_positive_ultimate`（无极之气，作者裁决：算作灵气）时减 1 层。
- 配套：`character.dart` `addStatusEffect` 触发
  `self_gained_energy_positive` / `opponent_gained_energy_positive` 时传入
  details `{id, amount}`（原来无 details）。

## 二、抗性结算收敛

### 2.1 takeDamage 内置元素抗性

`lib/scene/battle/character.dart` `takeDamage`：damageType ∈ {fire, ice, lightning, poison} 时，
在乘区结算之后（元素无视护甲，不进护甲分支）调用 `getElementalResist(damageType)`，
最终伤害 ×(1 − 0.01 × 抗性)。

新增方法（作者澄清修订：只读状态净值，图标即真值）：

```dart
/// 元素抗性唯一真值来源：resistant/weakness 状态净值（含全元素对），上限 75
/// 战斗开始时 stats（含全抗折算）已转换为 resistant_X 永久图标，故不再读 stats
/// 允许负抗性（定案）：弱点净值超过抗性时伤害加深，与 weakness 既有语义一致
int getElementalResist(String damageType) {
  int resist = hasStatusEffect('resistant_$damageType');
  resist -= hasStatusEffect('weakness_$damageType');
  resist += hasStatusEffect('resistant_elemental');
  resist -= hasStatusEffect('weakness_elemental');
  return resist > kBaseResistMax ? kBaseResistMax : resist;
}
```

配套调整：

- `lib/scene/battle/battle.dart` `kStatsToPermanentEffects`：**保留四元素抗性映射**
  （作者澄清：战斗开始仍需按属性显示抗性图标，图标纯展示、无脚本回调；
  图标层数被 getElementalResist 读取，即真值来源）。
- `status_script.ht` 的 `resistant` / `weakness` 脚本整体删除（四种元素抗性已进 takeDamage；
  旧四抗性已删，这两个脚本无其他服务对象）。状态条目保留，**剥掉 script/callbacks 字段**，
  仅作计数与展示。
- `lib/scene/battle/common.dart` `kOppositeStatus`：新增 `resistant_elemental ↔ weakness_elemental` 互斥对。

### 2.2 DOT 留在脚本侧，changeLife 扩展跳字

DOT 不触发护盾/易伤/暴击/异常连锁（定案）。`changeLife` 增加可选参数
`damageType`：提供时跳字用 `getDamageColor(damageType)` 着色（音效暂不加或复用轻量音效，
占位即可）。DOT 脚本由 `self.changeLife(-dmg)` 改为
`self.changeLife(-dmg, damageType: effect.damageType)`。

配套（计划书原清单漏列，执行时补上）：

- `lib/scene/battle/character_binding.dart`：`changeLife` 绑定加 `damageType` 命名参数转发；
  新增 `getElementalResist` 绑定。
- `scripts/main/cardgame/battle_character.ht`：external class 声明同步
  （顺带修复既有笔误：`changeLife` 声明中命名参数误写为 `changeLife`，应为 `isHeal`）。

### 2.3 攻击增强/削弱收敛（作者裁决：纳入本阶段）

`enhance_*`/`weaken_*`（unarmed/weapon/spell/curse 四对）与抗性同构：只来自
`kStatsToPermanentEffects` 的 stats 镜像转换，无任何脚本在战斗中动态添加，
属"纯数值修正型状态"，按原则 2 一并收敛：

- `character.dart` `takeDamage`：乘区结算时直接读取攻击方状态净值——
  `enhance_{cardType} − weaken_{cardType}`，乘区1 += 0.01 × 净值（图标即真值，不读 stats）。
- **恢复 weaken 的 cardType 匹配**（作者裁决）：`weaken_weapon` 只削弱武器攻击，与 enhance 对称；
  现网 weaken 脚本的 cardType 判断被注释（status_script.ht 旧 bug），迁移时修复并在文档注明。
- `status_script.ht` 删除 `enhance` / `weaken` 脚本；`status_effect.json5` 8 个条目
  剥掉 script/callbacks 字段，仅作计数与展示；`kStatsToPermanentEffects` 攻击映射保留（图标照显）。
- 注：kind 分型的 `increase_damage`（天赋来源）暂留脚本侧，后续与天赋树重整一并评估。

## 三、新属性

### 3.1 全元素抗性 elementalResist（加回，但**不作为独立面板属性**）

定案：全抗是物品/天赋词条；角色属性派生时**折算进每一个单抗**，属性窗口不单独显示。

- `assets/data/passives.json5`：新增 `elementalResist` 词条，结构沿用单抗
  （isItem/isItemMain/isEphemeral: defense、kinds 防具五部位），increment 初值 **0.25**
  （单抗 0.5 的一半，实机调）。
- `scripts/main/data/character/battle_entity.ht`：四个单抗派生各加全抗——
  `stats.fireResist = passives.fireResist + passives.elementalResist + ephemeral...`（四行同理），
  封顶钳制沿用各单抗 ResistMax（75），全抗不单设 Max 词条、不出现在 stats.dart。
- 天赋树节点：**本阶段不做**（定案：天赋树将有单独的重新整理计划，届时统一加节点）。
- 对应弱点：`status_effect.json5` 加回 `resistant_elemental` / `weakness_elemental`
  （isPermanent，作为战斗内全元素修正，经 getElementalResist 状态净值生效）。
- 本地化：passive.json（passive_elemental_resist_description）、
  status_effect.json（两个状态键）。

### 3.2 元素异常几率 ailmentChance 与元素异常伤害 ailmentMultiplier

对标暴击（kBaseCritChance = 5 / kBaseCritMultiplier = 150，passives critChance/critMultiplier）：

- `lib/data/common.dart`：`kBaseAilmentChance = 15`、`kBaseAilmentMultiplier = 100`；
  `lib/data/constants.dart` 与 `scripts/main/binding/constants.ht` 同步导出。
- `battle_entity.ht`：仿 crit 行派生 `stats.ailmentChance` / `stats.ailmentMultiplier`。
- `passives.json5`：新增 `ailmentChance`（increment 0.5）与 `ailmentMultiplier`（increment 5）
  两条词条，isItem/isEphemeral: attack，装备部位走法术向（饰品 amulet/ring/pearl 系）（定案）。
- 天赋树节点：**本阶段不做**（同 3.1，留待天赋树整体重整）。
- `lib/widgets/character/stats.dart` kMoreStats：critChance/critMultiplier 后加
  `'ailmentChance'`、`'ailmentMultiplier'`（显示沿用暴击的 % 格式与高亮规则）。
- 本地化：character.json（"元素异常几率" / "元素异常伤害" 及描述）、passive.json 两条 description。

### 3.3 异常触发（takeDamage 内，攻击侧；作者澄清修订：层数与伤害数额挂钩）

takeDamage 元素伤害结算完毕后（finalDamage > 0）：

```
rolls = finalDamage ~/ 10          // 每满 10 点最终伤害判定一次
stacks = 0
重复 rolls 次：
  若 random.nextInt(100) < 攻击方 stats.ailmentChance：stacks += 1   // 每次都是独立概率
若 stacks > 0：
  给防守方加 stacks 层 element_dot_${damageType}
  并把攻击方 stats.ailmentMultiplier 写入该状态实例（effect.ailmentMultiplier，以最后一次触发为准）
```

例：100 点伤害 = 10 次判定 = 0~10 层（可能全部落空，也可能全部命中）。

- `addStatusEffect` 签名不变；takeDamage 添加后取回状态实例
  （`_statusEffects[id].data`）写入 `ailmentMultiplier`。
- DOT 脚本伤害 = `dotDamage × (effect.ailmentMultiplier ?? 100) / 100`，再乘抗性系数。
- `kDebuffs` 池中的四个 element*dot*\* 不变（直接施加，无 multiplier 时按 100% 基础值）。

## 四、卡牌与脚本清理

- `card_script.ht`：删除 `attack_element_dot_exhaust`（异常不再由卡牌显式附加）。
- `cards.json5`：`ice_blade` / `poison_vine` 改回 `attack_exhaust`，valueData 去掉第三项，
  keywords 去掉 `status_element_dot_*`，description 换为不带异常描述的新键
  `affix_spell_attack_ice` / `affix_spell_attack_poison`
  （"消耗 {0} 灵气: 法术攻击造成 {1} 寒冰/毒素伤害"）。
- `battlecard.json`：删 `affix_spell_attack_ice_dot` / `affix_spell_attack_poison_dot`，新增上述两键。
- 降抗词条 `reduce_resist_*` 不变（weakness 状态经 getElementalResist 净值继续生效）。

## 五、文档

- `battle/readme.md`：异常表修正感电（耗尽层数 / 每层 1~10）与中毒（5 点、不自动消耗、
  治疗驱散）两行；补充异常触发机制（每 10 点伤害一次独立判定、几率/倍率属性）说明；
  伤害/防御对照表补"全元素抗性折算进各单抗"说明；伤势三项补驱散方式说明。
- `resource/readme.md`：同步。
- `REFACTOR.md`：决策 11 更新为四异常新定案；追加决策 18（本阶段定案：全抗折算、
  抗性收敛进 takeDamage 且图标即真值、DOT 不走 takeDamage、changeLife 扩展跳字、
  异常几率/倍率属性、异常层数按每 10 点伤害独立判定、伤势驱散文案落地）。

## 待确认问题（全部已定案）

- ~~Q1 词条部位与天赋节点~~：已确认——ailmentChance/ailmentMultiplier 部位走法术向（amulet/ring/pearl）；
  天赋树节点本阶段不做，留待天赋树整体重整计划。
- ~~Q2 getElementalResist 下限~~：已确认——允许负抗性（不设下限，上限 75），与 weakness 语义一致。
- ~~Q3 全抗 increment~~：已确认——0.25（单抗 0.5 的一半，实机调）。
- ~~Q4 感电数值~~：已确认——每层随机 1~10 点（原定案），本地化/文档中"5 点""随机消耗层数"为误文，修正。
- ~~Q5 抗性图标去留~~：已确认——战斗开始仍由 stats 转换出 resistant/weakness 永久图标，
  纯显示无脚本回调；getElementalResist 只读状态净值（图标即真值），不读 stats，避免双重计算。
- ~~Q6 异常层数~~：已确认——每满 10 点最终元素伤害独立判定一次，每次成功 +1 层。
- ~~Q7 中毒回合末消耗~~：已确认——不自动消耗，仅靠治疗驱散（每次治疗 1 层）。
- ~~Q8 无极之气与幻觉~~：已确认——获得无极之气也算获得灵气，同样减少 1 层幻觉。
- ~~Q9 enhance/weaken 收敛~~：已确认——纳入 4.5，与抗性同批退役脚本、Dart 直读状态净值（见 2.3）。
- ~~Q10 weaken 的 cardType 匹配~~：已确认——恢复匹配（修复脚本中判断被注释的既有 bug）。

## 涉及文件

- `lib/scene/battle/character.dart`（takeDamage、getElementalResist、changeLife、addStatusEffect）、
  `lib/scene/battle/character_binding.dart`（changeLife damageType、getElementalResist 绑定）、
  `lib/scene/battle/battle.dart`（kStatsToPermanentEffects 保留不动）、
  `lib/scene/battle/common.dart`（kOppositeStatus）、
  `lib/data/common.dart` + `constants.dart`（新常量）、`lib/widgets/character/stats.dart`（kMoreStats）
- `scripts/main/cardgame/status_script.ht`（element_dot 重写、resistant/weakness/enhance/weaken 退役、
  内伤/幻觉驱散脚本）、`scripts/main/cardgame/battle_character.ht`（声明同步）、
  `scripts/main/cardgame/card_script.ht`（删 attack_element_dot_exhaust）、
  `scripts/main/data/character/battle_entity.ht`（全抗折算 + ailment 派生）、
  `scripts/main/binding/constants.ht`（常量导出）
- `assets/data/status_effect.json5`（四异常 callbacks/数值改定案、resistant_elemental/weakness_elemental 加回、
  内伤回调名修正、幻觉加 self_gained_energy_positive 回调、resistant/weakness/enhance/weaken 条目剥 script/callbacks）、
  `assets/data/passives.json5`（elementalResist、ailmentChance、ailmentMultiplier）、
  `assets/data/cards.json5`（两张新卡清理）
  （注：`assets/data/passive_skills.json5` 本阶段不动，天赋树节点留待天赋树整体重整）
- `assets/locale/zh/rpg/`（character / status_effect / passive / battlecard）
- `docs/docs/how2play/rpg/battle/`（readme + resource/readme）、`REFACTOR.md`

## 验证清单

- [ ] 编译通过（hetu compile main/story），`flutter analyze` 无新增错误
- [ ] 实机：元素攻击牌不再必然附加异常；异常层数 = 每满 10 点伤害一次独立判定
      （默认 ailmentChance 15%），100 点伤害 0~10 层
- [ ] 实机：四种异常按新时机/数值结算（点燃开始 5 点耗 1 层、感电开始全层耗尽每层 1~10、
      冰缓结束全层耗尽每层 1 点+转化、中毒结束 5 点不自动消耗且治疗驱散 1 层）
- [ ] 实机：内伤获得元气时减 1 层；幻觉获得灵气/无极之气时减 1 层
- [ ] 实机：异常跳字带元素颜色（changeLife damageType 扩展生效）
- [ ] 实机：异常伤害受抗性减免（含全抗折算）与 ailmentMultiplier 放大
- [ ] 实机：DOT 不消耗护盾层、不被易伤放大、不触发异常连锁
- [ ] 实机：战斗开始按属性显示抗性图标（纯展示无脚本）；降抗词条经互斥机制抵消图标层数
- [ ] 实机：增强/削弱按 cardType 分型生效（weaken 不再误伤其他类型）；图标照显
- [ ] 实机：装备的全抗与异常词条生效；属性面板只显示四个单抗（已含全抗）与两个异常属性
- [ ] 无抗性双重计算（getElementalResist 只读状态净值；resistant/weakness 脚本已删除）
