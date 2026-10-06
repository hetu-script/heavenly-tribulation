# 伤害类型重构：无属性化 + 元素异常转化 + 真气内伤渗透

> 状态：决策已定稿（2026-10-06），待实施。
> 范围：战斗伤害类型体系（无属性/元素/真气）。数值平衡与敌方 AI 本期不做（demo 先行）。

## 1. 动机

现状问题：元素伤害（火/冰/雷/毒）**常驻无视护甲**，导致护甲对纯元素构筑完全失效——护甲卡牌、护甲保持（persistent）、护甲衰减节奏设计整片沦为摆设；护甲变成"二元废/立"属性。

改造目标：

1. 护甲普遍有意义——每个流派都有一部分伤害必须与护甲交互，"无视护甲"从常驻特权变为以异常为燃料的回合内决策（元素），或以积伤为刻度的跨回合渗透（真气）。
2. 元素异常从"贴上等它跳"的 DOT 变成可消费的战术资源（铺 → 兑现双层结构）。
3. 简化理解成本：最多见的伤害类型不带前缀，描述直接写"造成 X 点伤害"。
4. 防守方形成三角克制：护甲管无属性伤害、抗性管转化态元素伤害、辟邪/治疗驱散管异常供给（元素燃料与真气标尺共用）。

## 2. 新规则

### 2.1 伤害类型表（8 → 6 种表述）

| 伤害类型 | 键名 | 与护甲 | 其他对策 | 暴击 |
| --- | --- | --- | --- | --- |
| 物理（纯武技：elementType 为空的拳脚/武器卡） | `physical` | 全额交互 | — | **可暴击（唯一可暴击类型）** |
| 无属性（元素卡的未转化态 / 控制元素卡常驻态） | `ordinary` | 全额交互 | — | 否（不参与暴击与充能） |
| 真气 | `chi` | 交互，穿透 = 5% × 对方内伤层数（见 2.6） | 内伤驱散/辟邪 | 否 |
| 元素（转化态）×4 | `fire` / `ice` / `lightning` / `poison` | 无视 | 对应抗性（上限 75%，可负） | 否 |
| 精神 | `psychic` | 不交互 | 念力差（计划中，本次不实现） | 否 |
| 纯粹 | `pure` | 不交互 | 无 | 否 |

- 数据层不再有任何卡印刷元素伤害类型；`fire/ice/lightning/poison` 只作为**战斗内转化态**存在。
- "物理"字眼全 retire：描述统一改为"造成 X 点伤害"（无前缀），需要强调时写"无属性伤害"。
- 暴击限定无属性，为未来扩展留口：暴击附加效果（如暴击时碎甲）列为后续方向，本期不做。

### 2.2 元素转化机制（核心新规则）

- 卡牌印刷伤害类型只有两类：**无元素武技卡（拳脚/武器）印 `physical`**（可暴击），**带元素类型的卡印 `ordinary`**（不暴击；契约由校验器强制：elementType 非空的攻击卡 damageType 必须为 ordinary）。卡牌保留 `elementType`（元素协同不变：usedElements、五气朝元、抱真守一、五行轮转等照常）。
- **转化条件**：卡牌元素属于四个爆发元素（火/水/雷/木），且**对方**当前持有对应元素异常（≥1 层），则该卡在手牌中转化为对应元素伤害（无视护甲、吃对应抗性、不暴击）。
- **消耗规则（定案）**：每张转化态的卡在打出结算时消耗对方 1 层对应异常（**按牌不按段**，多段牌也只耗 1 层）。结算后刷新手牌——异常耗尽时，剩余手牌退回无属性形态。
- **参与范围（定案）**：仅攻击卡（有 damageType 的卡）参与转化与消耗；带元素的加持卡（如 water_mend 水疗术）不转化、不消耗。
- **实现形态**：不改动伤害结算管线（takeDamage 的元素分支原样复用），改为**手牌卡面级动态转化**——
  - 刷新时机：回合开始（出牌阶段前）+ 每次打出一张牌后 + 手牌构成变化时，并入现有的 `refreshHandCardDescription`（`lib/scene/battle/battle.dart:1315`，已在抽牌/出牌/升级后多点调用）一并刷新。
  - 刷新逻辑（幂等，每次从元素映射重算）：`damageType = 敌方持有对应异常 ? 映射元素伤害 : ordinary`。
  - 手牌中的卡是战斗深拷贝，原地改 `affixes[0].damageType` 安全；牌库/弃牌堆/观星视图不转化（非手牌，显示原始无属性形态）。
  - 伤害预测（`predictDamage` 读 affix 当前 damageType）与卡面描述（`getBattleCardDescription` 同数据源）**自动跟随**，无需特例。
  - 敌方对称生效（敌方手牌按其对方=玩家身上的异常转化）；AI 出牌策略本期不做。

### 2.3 异常充能改键（关键联动，方案成立的隐藏前提）

现状（`lib/scene/battle/character.dart:1093-1129`）：异常充能计数器以 **damageType** 为键——只有四种元素伤害才累积 `ailment_charge`，触发时 `ailmentId = 'ailment_$damageType'`。卡牌全部改印 `ordinary` 后，充能永不发生，铺异常只剩直施手段（侵染/相生相克），机制无法自举。

**必须同步改键**：充能与异常赋予改由卡牌的**潜伏元素**（elementType 经四元素映射）驱动，与该次命中是否处于转化态无关：

- takeDamage 充能块：判定从 `isElemental(damageType)` 改为 `elementType ∈ {fire, water, lightning, wood}`；ailmentId 改从映射表取（`Constants.elementAilments[elementType]`）。elementType 经出牌时写入的 `cardFlags['elementType']`（`character.dart:1247` 旁）传入，避免改动全部攻击脚本的 details 组装。
- 幸运（`scripts/main/cardgame/status_script.ht:128-140` buff_crit）：元素必异常分支同理改读 elementType。
- 预测 tooltip 的异常层数预告（`predictDamage`，character.dart:332 起）同步改键。
- 暴击充能（`crit_charge`）与暴击判定只认**物理伤害**（定案 8 修订：暴击身份从 elementType 混合门槛收回伤害类型单轴——物理 = 无元素武技牌；元素牌的无属性形态不暴击、不积累充能，转化态同样不暴击）。幸运 buff_crit：物理牌 → 必暴；火/水/雷/木潜伏元素牌 → 必异常；其余（无属性元素卡、真气牌）不触发不消耗。

### 2.4 元素分类：爆发元素 vs 控制元素

| 元素 | 映射伤害 | 对应异常 | 定位 |
| --- | --- | --- | --- |
| 火 element_fire | fire | ailment_fire（点燃） | 爆发：异常是燃料 |
| 水 element_water | ice | ailment_ice（冰缓） | 爆发：异常是燃料 |
| 雷 element_lightning | lightning | ailment_lightning（感电） | 爆发：异常是燃料 |
| 木 element_wood | poison | ailment_poison（中毒） | 爆发：异常是燃料 |
| 金 element_metal | （不转化） | ailment_bleeding（流血） | 控制：异常本体是收益 |
| 土 element_earth | （不转化） | ailment_internal_injury（内伤） | 控制 + **真气穿透标尺**（见 2.6，双重身份） |
| 风 element_wind | （不转化） | ailment_hallucination（幻觉） | 控制：异常本体是收益 |

- 映射表放 `lib/data/common.dart`（新常量，如 `kElementDamageTypes`），同步导出 `lib/data/constants.dart` + `scripts/main/binding/constants.ht` + 校验器。
- 悟道卡池现状天然满足"每流派都有无属性伤害"：wind_blade / wind_storm / falling_stone 为风/土无属性卡，其余为可转化卡。

### 2.5 四种燃料异常的移除方式（定案，已实施 2026-10-06）

- **火（点燃）/雷（感电）：持有者回合开始时耗尽所有层数**——爆发对。点燃每层固定 5 点（稳定），感电每层 1~10 随机（波动）。当回合燃料：铺上当回合就要用，否则在对方回合开始自爆（自爆前 DOT 不浪费）。
- **冰（冰缓）/毒（中毒）：持有者回合结束时移除 1 层**——绵长对。冰缓每层附带转化 1 层迟钝；可跨回合储存燃料。
- 直观依据：火烧尽、电放完，都是瞬时爆发；冰寒侵骨、毒素缠绵，都是缓释。元素玩法分化：火/雷卡组打"铺了即爆"，冰/毒卡组可蓄。
- 修订记录：最初方案二的配对是"火/毒可存、冰/雷引爆"；按直观感受修订为"火/雷引爆、冰/毒可存"，已落地于 status_script.ht 与本地化（2026-10-06，随真气改造一并实施）。

### 2.6 真气-内伤渗透（定案，已实施 2026-10-06：与元素同韵不同构）

真气不做"门控转化"，而是**自我强化的渗透斜坡**：

- **造成伤害即附内伤**：真气伤害结算完毕且实际造成伤害（finalDamage > 0，护甲扣除后）时，直接给对方附加内伤——**每满 10 点实际伤害 1 层**（不经异常计数器；走标准 addStatusEffect 路径，辟邪可正常抵消；不幸只针对元素异常，不影响本条）。
- **内伤即穿透标尺**：真气伤害的穿透 = **5% × 对方当前内伤层数**，与词条/装备 penetration 相加后钳制 0~100%；**移除常驻 50% 穿透**。
- **不消耗内伤**：内伤不自我消耗（其"持有者使用加持牌时每层失去 5 点生命"的反噬行为不变），只会被治疗驱散/辟邪抵消。真气投入是持续的——元素是"点火-引爆"的回合内循环，真气是"积伤-渗入"的跨回合斜坡。
- 同一张多段真气牌内部逐段受益（前段附伤 → 后段穿透即提升）。
- 跨流派协同保留：任何来源的内伤（陨星术、相生相克等）都为真气牌抬穿透。
- 反制面诚实记录：比元素薄（无回合界线衰减，全部压力在治疗随机驱散与辟邪上），数值复查时留意。备选调节杆：穿透/层、伤害/层换算率、渗透上限（如 ≤75%）、内伤缓慢衰减。
- 实现：仅 takeDamage 真气分支一处改动（`character.dart:1034`）+ 结算后附内伤块；**不经手牌转化管线**（predictDamage 现状就不建模护甲/穿透，预测无需改动；玩家经敌方内伤层数图标感知）。

### 2.7 自平衡动态（设计认知记录）

充能按伤害量累积（约每 10 点伤害 1 层充能）：敌方护甲越高，无属性命中伤害越低 → 燃料攒得越慢 → 破甲越稀缺。破甲供给与敌方护甲强度负相关，护甲永不被彻底无效化。对最高护甲的真正对策是：直施手段（侵染、相生相克）、纯粹伤害、以及真气的长期渗透。此为特性而非 bug，写进玩法文档。

### 2.8 自异常的双向性（确认保留）

窥天镜/相生相克给自方铺的异常会成为敌方转化的燃料（"自异常喂养敌方破甲"是蓄灵诀引擎的既有代价面，符合半正半负设计，保留）。

## 3. 已拍板决策（2026-10-06）

1. **消耗模型：每张转化牌结算时耗 1 层**（不按段）。理由：简化算法与理解；卡面诚实（不存在多段牌中段退化的显示问题）；经济颗粒适中。
2. **仅无属性可暴击**（转化态、真气、精神、纯粹均不暴击）。未来可扩展暴击附加效果（暴击碎甲等）。
3. **异常移除保留不对称（2026-10-06 修订并实施）**：火/雷回合开始耗尽全层（爆发对），冰/毒回合结束移除 1 层（绵长对）——配对按直观感受（火烧尽、电放完 vs 冰寒侵骨、毒素缠绵），见 2.5。
4. **自异常喂养敌方转化**：保留（见 2.8）。
5. **键名用 `ordinary`**：全仓零冲突（已验证），且避开 `common` 与稀有度 common 的同字噪音。显示文案为"无属性"。
6. **elementType 补写范围**：飞剑三张（flying_sword_exhaust_mana_fire/ice/lightning）已有 elementType，无需改动；仅三张近战剑卡 sword_attack_exhaust_mana_fire/ice/lightning 需补写 `element_fire/element_water/element_lightning`。副作用（进入 usedElements 元素协同）视为修正。
7. **真气-内伤渗透**（定案，已实施 2026-10-06——仅结算与本地化；锻体围绕真气的流派内容设计另议）：真气不再常驻 50% 穿透，改为"造成伤害即附内伤（每满 10 点实际伤害 1 层）+ 穿透 = 5% × 对方内伤层数、不消耗内伤"（见 2.6）。默认细则：附伤按护甲扣除后的实际伤害换算（完全格挡则无积累）；经标准 debuff 路径施加（辟邪可抵消）；不幸不影响真气内伤。
8. **元素牌不参与暴击 → 修订为物理/无属性类型拆分**（2026-10-06 同日定案并实施）：重新引入 `physical`——无元素武技卡（拳脚+武器）印物理、可暴击；元素卡印无属性（ordinary）、不暴击不积累充能。暴击判定收回伤害类型单轴（不再检查 elementType）；校验器强制契约：elementType 非空的攻击卡 damageType 必须为 ordinary。卡池划分：16 张纯武技卡 = physical，19 张元素卡 = ordinary（含金/土/风控制元素卡）。拳脚不划入无属性（否则手套部位的暴击词条作废、基础卡手感变差）。幸运：物理牌必暴、潜伏元素牌必异常、其余不触发不消耗。（沿革：最初实现为 ordinary + elementType 混合门槛，因规则可教性与风味拆分为伤害类型单轴方案。）

## 4. 改动清单（已盘点实际分布）

### 4.1 改名 physical → ordinary（约 39 处原文 + 95 处"物理"，真实改动面如下）

- 常量：`lib/data/constants.dart:156-176`（DamageType.physical、kDamageTypes）；`lib/data/binding.dart:96` 导出无需改字面。
- Dart 逻辑：`lib/scene/battle/character.dart` —— 暴击 :315 / :995、护甲 :1028、暴击充能 :1085、跳字色 getDamageColor :23、注释若干。
- Hetu：`scripts/main/cardgame/status_script.ht:132`（buff_crit 物理分支；:248 注释代码一并清理）。
- 数据：`assets/data/cards.json5` damageType "physical" ×20；`status_effect.json5` ×1 + 描述内"物理"×5；`passives.json5` 描述 ×4（穿透等——穿透描述中"物理和真气"字样随真气新规则改写）。
- 本地化：`battlecard.json` ×12、`status_effect.json` ×5、`character.json` ×5（含 1 处英文 physical）。
- 文档：`docs/docs/how2play/rpg/battle/readme.md`（伤害类型表重写，物理×26）、`mod/battle/readme.md` ×4、`how2play/rpg/item/consumable/readme.md` ×3、`how2play/rpg/cultivation/readme.md` ×11（逐处甄别是否相关）、`docs/docs/story/main/readme.md` ×1、`plan/battle_system_overview.md`、`plan/skill_tree/spellcraft.md`。
- 忽略：`windows/runner/*`（物理像素，误报）；`.agents/skills/battlecard/SKILL.md` 在定稿后同步。

### 4.2 卡牌数据：元素伤害 → ordinary

- cards.json5 中 `damageType: fire/ice/lightning ×各5` 共 15 张改为 `ordinary`（poison 卡当前不存在）。
- 确保这 15 张都有 elementType：悟道 12 张已有；御剑飞剑三张已有；**仅御剑近战剑卡 sword_attack_exhaust_mana_fire/ice/lightning 三张需补写**（决策 6）。
- 万法归宗（spellcraft_ultimate_spell）在 15 张之内（lightning → ordinary + element_lightning 已有）。

### 4.3 转化刷新（Dart，元素转化唯一新机制代码）

- `battle.dart`：新增手牌伤害类型刷新（挂入 `refreshHandCardDescription` 或同名包装），规则见 2.2；敌方回合开始同样刷新敌方手牌。
- 出牌阶段前兜底刷新一次（turnStartScry 在抽牌前，观星/回合开始回调可能改变异常）。
- 打出结算时消耗 1 层对应异常（在 `_playCard` 结算路径上，判定该卡当前为转化态才消耗）。

### 4.4 充能/幸运/预测改键 + 真气分支

- `character.dart` takeDamage :1093-1129：充能块改键 elementType（经 cardFlags 传入，见 2.3）。
- `character.dart` takeDamage :1034 真气分支：penetration 改为 5% × 防守方 ailment_internal_injury 层数（移除 +0.5 常驻）；结算后新增"finalDamage > 0 且 damageType == chi → 附内伤 finalDamage ~/ 10 层"（见 2.6）。
- `predictDamage` :281-284 / :332 起：异常预告改键。
- `status_script.ht` buff_crit :132-138：元素分支改键。

### 4.5 校验器与常量同步

- `utils/data_validate/game_data_validate.dart` 的伤害类型合法值表；`lib/data/common_data.dart`（若枚举在其处）；`scripts/main/binding/constants.ht` damageTypes 声明。

### 4.6 文档

- how2play 战斗规则（伤害类型表、暴击/穿透/抗性规则、转化机制与真气渗透说明、自平衡动态说明）；mod 契约文档（机制字段无变化，伤害类型枚举更新）；`plan/battle_system_overview.md` §1/§10 同步。

## 5. 实施顺序

1. 改名 physical → ordinary（代码 + 数据 + 本地化 + 校验器），跑 `flutter analyze` + 数据校验。
2. 元素卡改印 ordinary + 补 elementType×3；映射表常量三处同步。
3. takeDamage 充能改键 + buff_crit 改键 + predictDamage 同步 + 真气分支改造（4.4）。
4. 转化刷新函数并入手牌刷新链路 + 结算耗层（4.3）。
5. 本地化文案与文档全面更新。
6. demo 验收 → 数值复查（另行）→ 敌方 AI（另行）。

## 6. 本期明确不做

- 数值平衡（现有元素牌基值标定于"常驻破甲"假设，demo 后统一复查；届时可评估给转化态命中加 ailmentMultiplier 甜头。真气渗透的调节杆：穿透/层、伤害/层换算率、渗透上限、内伤衰减）。
- 敌方 AI 的铺→兑现排序（当前 AI 不感知燃料，另立项）。
- 暴击附加效果扩展（暴击碎甲等，见 2.1）。
- 精神伤害的念力差实现（见 plan/other/REFACTOR_5_PSYCHIC.md）。
- 金=破甲（金属性牌削减护甲）：方向认可，但金属性已划归飞剑术，随御剑流派重构时再议（2026-10-06 暂缓）。
- 装备破境/重铸、太古词条等既有未实现项。

## 7. 实施记录

- **2026-10-06：真气渗透（2.6）与四异常移除时机（2.5）已落地**——
  - `lib/scene/battle/character.dart`：takeDamage 真气分支穿透改为 5% × 防守方内伤层数（移除常驻 50%）；真气实际造成伤害后按每满 10 点附 1 层内伤（走 addStatusEffect 标准路径）。
  - `scripts/main/cardgame/status_script.ht`：点燃改为回合开始耗尽全层（每层固定 5 点）、冰缓改为回合结束移除 1 层（1 点伤害 + 转化 1 层迟钝）；感电、中毒不变。
  - 本地化 `status_effect.json`：penetration / ailment_fire / ailment_ice / ailment_internal_injury 描述更新（内伤描述承担真气交互的玩家可见说明）。
  - 文档：`docs/docs/how2play/rpg/battle/readme.md` 真气规则与异常表、`plan/battle_system_overview.md` 同步。
  - 当时未做：physical → ordinary 改名、元素转化管线、异常充能改键（当日稍后已落地，见下条）。

- **2026-10-06（同日稍后）：改名 + 元素转化管线 + 充能改键全部落地**（§5 步骤 1~5）——
  - 改名：`DamageType.physical` → `DamageType.ordinary = 'ordinary'`（constants.dart，kDamageTypes 同步；validator 经 kDamageTypes 自动跟随）；character.dart 暴击/护甲/暴击充能四处判定、status_script.ht buff_crit、status_effect.json5 防御条目 damageType、本地化"物理"字样清扫（battlecard/status_effect/character 三个 json）、docs 与 SKILL.md。
  - 数据：cards.json5 共 35 张卡改印 `ordinary`（20 张原物理 + 15 张原火/冰/雷）；sword_attack_exhaust_mana_fire/ice/lightning 三张补写 elementType；卡牌描述模板统一去掉伤害类型字眼（"造成 {0} 点伤害"），元素身份由转化提示行动态呈现。
  - 映射：`kElementDamageTypes`（火→fire、水→ice、雷→lightning、木→poison）定义于 constants.dart，binding.dart + constants.ht 同步导出（Constants.elementDamageTypes）。
  - 充能改键：takeDamage 异常充能块与 ailmentId 改由 `cardFlags['elementType']`（onUseCard 写入）经 kElementDamageTypes 判定，与转化态无关；predictDamage 异常预告同步改键；game.dart 异常名显示改由 elementType 查表。
  - 转化管线：手牌刷新（battle.dart `_refreshHandCardDescription`）前置转化判定 + 卡面提示行（latentElementHint/transformedElementHint，battle.json）；结算真值在 `BattleCharacter.onUseCard`（双方统一口径：转化 + 消耗对方 1 层对应异常，按牌不按段；仅对有 damageType 的攻击卡生效）。
  - 幸运 buff_crit：潜伏元素牌必异常、其余无属性牌必暴（与转化态无关）。
  - 暴击门槛修正（定案 8）：暴击触发/充能/预测均以"ordinary 且 elementType 为空"为口径，元素牌（含金/土/风与元素武器牌）不暴击不积累；buff_crit 对金/土/风牌不触发不消耗；本地化与文档同步。
  - 验证：flutter analyze 0 issue；hetu 编译 main/story 通过；game_data_validate 0 错误；passive_tree_validate 维持既有基线（历史遗留）。
  - 物理/无属性拆分（定案 8 修订版，同日落地）：DamageType 加回 `physical`（kDamageTypes 共 9 种）；cards.json5 两步 replace_all 完成划分（35 张 ordinary → 全转 physical → 19 张元素卡翻回 ordinary，净结果 16 张纯武技 = physical）；暴击触发/充能/预测三处收回 `damageType == 'physical'` 单轴判定（去掉 elementType 混合门槛）；护甲块覆盖 physical/ordinary/chi；ordinary 跳字色独立为灰；校验器新增契约检查（elementType 非空的攻击卡 damageType 必须为 ordinary）；本地化与文档同步。
