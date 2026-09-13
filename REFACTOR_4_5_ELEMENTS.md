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
3. **抗性的唯一真值来源**：Dart 侧 `BattleCharacter.getElementalResist(damageType)`
   = 单抗 stats（已含全抗加成） + 状态净值（resistant_X − weakness_X +
   resistant_elemental − weakness_elemental），75 封顶。takeDamage 与 DOT 脚本都只调用它，
   不各自重算。
4. **DOT 不走 takeDamage**（定案）：DOT 与状态强绑定、非物理无需护甲、不应触发护盾/易伤/
   暴击/异常连锁。为此给 `changeLife` 扩展跳字支持（见 2.2），让 DOT 跳字带伤害类型颜色。
5. **长期方向（本阶段不做，仅记录）**：最终统一伤害入口——takeDamage 增加 source 标记
   （attack / dot / regen），changeLife 并入 takeDamage 的纯生命变化分支，脚本与 Dart 的
   职责边界届时重新划定。此为大改，建议在阶段 5 之后单独立项。

## 一、元素异常定案（作者已确认，代码以此为准）

本地化与文档（`status_effect.json`、`battle/readme.md`）已先行更新，**数据与脚本按此重写**：
（灼伤已改名**点燃**；异常伤害均受对应元素抗性减免，并受施加方 ailmentMultiplier 放大）

| 元素 | 状态 id               | 名称 | 机制（定案）                                                                      | 节奏     |
| ---- | --------------------- | ---- | --------------------------------------------------------------------------------- | -------- |
| 火   | `element_dot_fire`      | 点燃 | **回合开始时**受到 5 点火焰伤害（固定，不随层数放大），**同时消耗 1 层**；层数=剩余触发次数 | 稳定     |
| 雷   | `element_dot_lightning` | 感电 | **回合开始时层数直接耗尽**，每层随机受到 1~10 点雷电伤害（每层单独跳字）              | 爆发     |
| 冰   | `element_dot_ice`       | 冰缓 | **回合结束时层数直接耗尽**，每层受到 1 点寒冰伤害，并分别随机转化为缓慢或迟钝         | 绵长干扰 |
| 毒   | `element_dot_poison`    | 中毒 | **回合结束时**受到 5 点毒素伤害（固定），**同时消耗 1 层**；治疗时消耗 1 层（与流血同规则，沿用阶段 4 规则） | 累积     |

`status_effect.json5` 数据调整：callbacks 改为 点燃/感电 `["self_turn_start"]`、
冰缓 `["self_turn_end"]`、中毒 `["self_turn_end", "self_heal"]`；
dotDamage 改为 5 / 0 / 1 / 5（感电为脚本内随机 1~10）；decay 字段废弃删除（消耗逻辑全部内联进脚本）。

`status_script.ht` 的 `element_dot_*` 按上表重写（turn_start / turn_end / self_heal 三函数），
抗性系数改为一行调用：`final factor = 1 - 0.01 * self.getElementalResist(effect.damageType)`，
伤害再乘 `(effect.ailmentMultiplier ?? 100) / 100`（见 3.3）。

## 二、抗性结算收敛

### 2.1 takeDamage 内置元素抗性

`lib/scene/battle/character.dart` `takeDamage`：damageType ∈ {fire, ice, lightning, poison} 时，
在乘区结算之后（元素无视护甲，不进护甲分支）调用 `getElementalResist(damageType)`，
最终伤害 ×(1 − 0.01 × 抗性)。

新增方法：

```dart
/// 元素抗性唯一真值来源：单抗 stats（已含全抗） + 状态净值，上限 75
/// 允许负抗性（定案）：弱点净值超过抗性时伤害加深，与 weakness 既有语义一致
int getElementalResist(String damageType) {
  final stats = data['stats'];
  int resist = (stats['${damageType}Resist'] ?? 0) as int;
  resist += hasStatusEffect('resistant_$damageType');
  resist -= hasStatusEffect('weakness_$damageType');
  resist += hasStatusEffect('resistant_elemental');
  resist -= hasStatusEffect('weakness_elemental');
  return resist > kBaseResistMax ? kBaseResistMax : resist;
}
```

配套调整：

- `lib/scene/battle/battle.dart` `kStatsToPermanentEffects`：**移除四元素抗性映射**
  （装备/天赋抗性不再转换成战斗状态，避免双重计算）。
- `status_script.ht` 的 `resistant` / `weakness` 脚本整体删除（四种元素抗性已进 takeDamage；
  旧四抗性已删，这两个脚本无其他服务对象）。状态条目保留，仅作计数与展示。
- `lib/scene/battle/common.dart` `kOppositeStatus`：新增 `resistant_elemental ↔ weakness_elemental` 互斥对。

### 2.2 DOT 留在脚本侧，changeLife 扩展跳字

DOT 不触发护盾/易伤/暴击/异常连锁（定案）。`changeLife` 增加可选参数
`damageType`：提供时跳字用 `getDamageColor(damageType)` 着色（音效暂不加或复用轻量音效，
占位即可）。DOT 脚本由 `self.changeLife(-dmg)` 改为
`self.changeLife(-dmg, damageType: effect.damageType)`。

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
  `'ailmentChance'`、`'ailmentMultiplier'`。
- 本地化：character.json（"元素异常几率" / "元素异常伤害" 及描述）、passive.json 两条 description。

### 3.3 异常触发（takeDamage 内，攻击侧）

takeDamage 元素伤害结算完毕后（finalDamage > 0）：

```
chance = 攻击方 stats.ailmentChance
若 random.nextInt(100) < chance：
  给防守方加 1 层 element_dot_${damageType}（每次触发 1 层，重复触发叠层）
  并把攻击方 stats.ailmentMultiplier 写入该状态实例（effect.ailmentMultiplier，以最后一次触发为准）
```

- `addStatusEffect` 当前签名 `(id, {amount, handleCallback})`，需扩展支持附加字段，
  或添加后取回状态实例写入（执行时按 `character.dart:427` 实现选择）。
- DOT 脚本伤害 = `dotDamage × (effect.ailmentMultiplier ?? 100) / 100`，再乘抗性系数。
- `kDebuffs` 池中的四个 element_dot_* 不变（直接施加，无 multiplier 时按 100% 基础值）。

## 四、卡牌与脚本清理

- `card_script.ht`：删除 `attack_element_dot_exhaust`（异常不再由卡牌显式附加）。
- `cards.json5`：`ice_blade` / `poison_vine` 改回 `attack_exhaust`，valueData 去掉第三项，
  keywords 去掉 `status_element_dot_*`，description 换为不带异常描述的新键
  `affix_spell_attack_ice` / `affix_spell_attack_poison`
  （"消耗 {0} 灵气: 法术攻击造成 {1} 寒冰/毒素伤害"）。
- `battlecard.json`：删 `affix_spell_attack_ice_dot` / `affix_spell_attack_poison_dot`，新增上述两键。
- 降抗词条 `reduce_resist_*` 不变（weakness 状态经 getElementalResist 净值继续生效）。

## 五、文档

- `battle/readme.md`：异常表已是新定案（作者已改），补充异常触发机制（几率/倍率属性）说明；
  伤害/防御对照表补"全元素抗性折算进各单抗"说明。
- `resource/readme.md`：同步。
- `REFACTOR.md`：决策 11 更新为四异常新定案；追加决策 18（本阶段定案：全抗折算、
  抗性收敛进 takeDamage、DOT 不走 takeDamage、changeLife 扩展跳字、异常几率/倍率属性）。

## 待确认问题（全部已定案）

- ~~Q1 词条部位与天赋节点~~：已确认——ailmentChance/ailmentMultiplier 部位走法术向（amulet/ring/pearl）；
  天赋树节点本阶段不做，留待天赋树整体重整计划。
- ~~Q2 getElementalResist 下限~~：已确认——允许负抗性（不设下限，上限 75），与 weakness 语义一致。
- ~~Q3 全抗 increment~~：已确认——0.25（单抗 0.5 的一半，实机调）。

## 涉及文件

- `lib/scene/battle/character.dart`（takeDamage、getElementalResist、changeLife、addStatusEffect）、
  `lib/scene/battle/battle.dart`（kStatsToPermanentEffects）、
  `lib/scene/battle/common.dart`（kOppositeStatus）、
  `lib/data/common.dart` + `constants.dart`（新常量）、`lib/widgets/character/stats.dart`（kMoreStats）
- `scripts/main/cardgame/status_script.ht`（element_dot 重写、resistant/weakness 退役）、
  `scripts/main/cardgame/card_script.ht`（删 attack_element_dot_exhaust）、
  `scripts/main/data/character/battle_entity.ht`（全抗折算 + ailment 派生）、
  `scripts/main/binding/constants.ht`（常量导出）
- `assets/data/status_effect.json5`（四异常 callbacks/数值改定案、resistant_elemental/weakness_elemental 加回）、
  `assets/data/passives.json5`（elementalResist、ailmentChance、ailmentMultiplier）、
  `assets/data/cards.json5`（两张新卡清理）
  （注：`assets/data/passive_skills.json5` 本阶段不动，天赋树节点留待天赋树整体重整）
- `assets/locale/zh/rpg/`（character / status_effect / passive / battlecard）
- `docs/docs/how2play/rpg/battle/`（readme + resource/readme）、`REFACTOR.md`

## 验证清单

- [ ] 编译通过（hetu compile main/story），`flutter analyze` 无新增错误
- [ ] 实机：元素攻击牌不再必然附加异常，按 ailmentChance（默认 15%）概率触发
- [ ] 实机：四种异常按新时机/数值结算（点燃开始 5 点耗 1 层、感电开始全层耗尽每层 1~10、
      冰缓结束全层耗尽每层 1 点+转化、中毒结束 5 点耗 1 层且治疗驱散）
- [ ] 实机：异常跳字带元素颜色（changeLife damageType 扩展生效）
- [ ] 实机：异常伤害受抗性减免（含全抗折算）与 ailmentMultiplier 放大
- [ ] 实机：DOT 不消耗护盾层、不被易伤放大、不触发异常连锁
- [ ] 实机：装备的全抗与异常词条生效；属性面板只显示四个单抗（已含全抗）与两个异常属性
- [ ] 无抗性双重计算（装备抗性不再转为战斗状态；resistant/weakness 脚本已删除）
