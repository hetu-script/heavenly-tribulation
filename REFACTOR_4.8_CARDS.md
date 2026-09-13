# 阶段 4.8 · 卡面实时数值 + 绝世卡牌

> 总览见 `REFACTOR.md`。本阶段两个独立需求，可分开执行：
> 需求 1（卡面实时数值）优先——精神（念力）伤害极大受对方属性影响，
> 阶段 5 落地前需要卡面能反映实时数值，才好验证调参。
> 本文档为纯计划，创建阶段未改动任何其他文件。

## 一、战斗中卡面数值实时刷新

### 1.1 现状（调查结论）

- 卡面数字的唯一来源是 `affix['value']`——卡牌创建时按 `value = base + increment × level`
  算好的**静态值**（`scripts/main/cardgame/card.ht:178-201` `_updateAffixValue`），之后任何
  状态变化都不会改变它。
- 描述生成：`GameData.getBattleCardDescription`（`lib/data/game.dart:1194-1312`），
  对每个词条取本地化字符串后 `interpolate(affix['value'])` 替换 `{0}/{1}` 占位符。
- 渲染：Samsara `CustomGameCard.description` 的 setter 会立即重建富文本
  （`../samsara-engine/lib/cardgame/custom_card.dart:38-41,340`），下一帧自动刷新；
  富文本支持 `<yellow>N</>` / `<red>N</>` 标签（`richtext_builder.dart:75-197`）。
  项目已有运行时改描述的先例（打出时鉴定刷新 `character.dart:950`、卡牌库打造刷新
  `card_library.dart:577`）。
- 手牌每回合重抽（`clearHand` `battle.dart:703`）；`createBattleCard` 时描述只生成一次。
- 状态变更（addStatusEffect/removeStatusEffect/takeDamage/changeLife）**不发事件**，
  无法挂钩监听，只能在固定时机手动刷新。

### 1.2 定案（作者已确认）

1. **预测范围：只算确定性部分**——基础值 + 增强/削弱净值 + 元素抗性 + 护甲抵扣 + 必暴。
   不含护盾抵消、易伤、萧索之气、闪避免疫/踉跄、阳气 baseChange、penetration 状态等
   脚本回调类修正（它们有消耗/取消语义，预测会产生副作用；列入后续补齐，见 1.4）。
2. **暴击**：默认显示非暴击伤害；攻击方 `turnFlags['guaranteedCrit'] == true`（豪气）
   时按暴击倍率显示。不显示期望值。
3. **颜色规则**：预测值 > 原始静态值 → `<yellow>`；< 原值 → `<red>`；相等不变色。
   比较基准永远是 `affix['value']` 原始值，不是上次显示值。
4. **只对攻击类词条的伤害数字实时化**；护甲、抽牌、资源获得等静态词条不动。
5. 精神伤害（念力对抗公式）待阶段 5 落地后纳入预测（本阶段预留入口）。

### 1.3 实现方案

1. **伤害预测（Dart 纯函数）**：在 `lib/scene/battle/character.dart` 新增
   `int predictDamage(BattleCharacter attacker, dynamic affix)`（self 为防守方）：

   ```
   base = affix.value[伤害索引]                    // 索引表见下
   p1 = 0.01 × (attacker.hasStatusEffect('enhance_${cardType}')
              - attacker.hasStatusEffect('weaken_${cardType}'))     // 下限 -0.75
   dmg = (base × (1 + p1)).round()
   若 damageType ∈ {fire, ice, lightning, poison}:
     dmg = (dmg × (1 - 0.01 × self.getElementalResist(damageType))).round()
   若 damageType == 'physical' 且 attacker.turnFlags['guaranteedCrit'] == true:
     dmg = (dmg × attacker.stats.critMultiplier / 100).round()
   若 damageType ∈ {physical, chi}:
     penetration = (damageType == 'chi' ? 0.5 : 0.0)   // 不含穿透状态/正气（脚本类，后续补齐）
     blocked = min(self.hasStatusEffect('defense'), (dmg × (1 - penetration)).round())
     dmg -= blocked
   ```

   与 `takeDamage` 的确定性分支保持同一顺序（乘区 → 抗性 → 暴击 → 护甲）。

   脚本 → 伤害 value 索引表（`card_script.ht` 全部攻击脚本已枚举）：
   `attack: 0`、`attack_multiple: 1`、`attack_exhaust / attack_slow_exhaust /
   attack_clumsy_exhaust: 1`、`attack_multiple_exhaust: 2`。
   不在表内的脚本（defend/heal/draw/gain_resource 等）不预测，显示静态值。

2. **描述生成扩展**：`getBattleCardDescription` 增加可选参数
   `Map<int, List>? valueOverrides`（词条索引 → 显示用值列表，元素可为已包裹
   颜色标签的字符串），插值前替换。单点改动，Hovertip 详细描述
   （`lib/scene/battle/hand_zone.dart:69-83`）自动复用。

3. **刷新入口**：`BattleScene.refreshHandCardDescriptions()`——遍历 hero 手牌区
   所有卡牌，逐词条计算预测值并构造 overrides（无差异则传原值），
   重新赋值 `card.description`。敌方手牌背面朝上不处理。

4. **刷新时机**（固定时机手动调用，作者指定 + 补齐）：
   - 战斗准备完成后（`battle.dart:679` 之后）
   - 抽牌完成后（`drawCardsToHand` 之后，`battle.dart:958` 附近；含脚本 `draw` 词条
     触发的抽牌——`character.dart:1071` `drawCards` 尾部）
   - 每次出牌结算完成后（`_playCard` `battle.dart:878` 之后；敌方出牌循环
     `battle.dart:1034` 之后）
   - 回合结束状态结算后（`battle.dart:1041` 之后）
   若日后发现漏网时机，再评估改为状态变更函数尾部统一触发（注意敌方回合频繁
   重建富文本的性能，手牌 ≤10 张问题不大）。

### 1.4 后续补齐（本阶段不做，仅记录）

- 脚本回调类修正的预测：阳气每层 +5 baseChange、penetration 状态、正气穿透、
  易伤、萧索之气、护盾 cancelDamage、闪避免疫/踉跄——需要给状态脚本加
  `isPrediction` 约定或 Dart 侧逐个硬编码，单独立项评估。
- `heal_exhaust`（按 lifeMax% 回血）等依赖当前生命上限的脚本数字动态化。
- `by_damage_*` 类词条依赖本牌已造成伤害，无法预测，永久保持静态。
- 精神伤害预测（依赖阶段 5 念力公式）。

## 二、绝世卡牌（unique）

设计文档：`docs/docs/how2play/rpg/battle/card/readme.md`「特殊卡牌·绝世」。
测试卡：`draw_cards`（`assets/data/cards.json5:58-91`，已有 uniqueId/isUnique/
预定义 affixes 列表/专属边框 `border_unique.png`）。

### 2.1 现状与缺口（调查结论）

- `draw_cards` 已定义但**没有任何正常获取途径**（仅 debug.ht 全卡作弊）；且未标
  `isUnpackable`，目前会被普通随机生成和 NPC 卡组抽中，但生成时其预定义 affixes
  列表**没有任何代码消费**——生成出来的是"随机词条的绝世卡"，与设计不符。
- 实例已透传 `isUnique`（`card.ht:104`），但**未显式保存绝世 uniqueId**（仅间接
  存在于 `affixUniqueIds` 互斥集合）。
- 鉴定机制：现状只服务"战前探查敌方卡牌"（prebattle.dart）；玩家自己的卡默认
  已鉴定，且**入卡组时被强制鉴定**（`deckbuilding_zone.dart:356-359`）。
  `identifyCard()`（card.ht:287-296）整体被注释。`isIdentified` 门控已存在
  （checkRequirements / checkDeckRequirement / 卡面描述红字 unidentified）。
- 鉴定卷轴（`identify_scroll`）已实现：物品栏使用 → 选择未鉴定物品 → 鉴定
  （`logic.dart:1216-1230`），目前只作用于装备。
- 六种精炼全部已实现（card.ht:300-472，Dart 入口 `card_library.dart:533-577`
  `onUseCraftMaterial`），但**都不检查 isUnique**。
- 卡组唯一性：`tryAddCard` 的 `containsCard(c.uniqueId)` 里的 uniqueId 是 Samsara
  组件 id（默认等于实例 id），只防同一实例重复入组，不防同一绝世 id 多张实例。
- 额外词条在生成时一次性随机（`_addExtraAffixes` card.ht:256-285），破境时丢弃
  未锁定词条全部重随机（`upgradeRank` card.ht:448-466）——无"按境界逐步解锁
  预定义词条"机制。

### 2.2 定案（作者已确认）

1. **随机池保留 + 概率控制**：绝世卡可以被随机抽到，但不是直接随机——两段式
   roll（见 2.3.7），概率常量实机调。`draw_cards` 不加 `isUnpackable`。
2. **鉴定复用鉴定卷轴**：绝世卡生成时 `isIdentified: false`；在卡牌库右键进入
   打造界面时，未鉴定卡牌只显示唯一一种打造道具：鉴定卷轴；使用后鉴定。
3. **精炼限制**：绝世卡只能混元（重 roll 数值）和破境（升境界）；灵宝/神照/
   真定/坐忘全部禁止（设计："所有词条固定"）。
4. **卡组唯一性**：同一卡组中同一 uniqueId 的绝世卡只能有一张（文档原文
   "卡组中只能有一个相同uniqueId的绝世卡牌"）。
5. **词条解锁**：rank 0 → 1 个额外词条 … rank 5 → 6 个（即 rank+1 个），按
   cards.json5 预定义 `affixes` 列表顺序取；词条等级实例化后走与普通额外词条
   相同的随机等级逻辑（可用混元重 roll）。

### 2.3 实现方案

1. **实例存绝世 uniqueId**：`card.ht:104` 附近——`isUnique` 时
   `this.uniqueId = mainAffix.uniqueId ?? mainAffix.id`。
   （注意主词条的 `uniqueId` 字段同时服务词条互斥，只有 `isUnique` 时才当作
   绝世 id 存到卡牌实例上。）

2. **固定词条生成**：`BattleCard` 构造器（card.ht:145）——`isUnique` 时跳过
   `_addExtraAffixes` 随机抽取，改为从 `mainAffix.affixes` 列表取前 `rank + 1` 个
   词条 id，按 `card_affixes.json5` 原型实例化（复用 `_addAffixToCard` /
   `_randomizeAffixLevel` 的现有逻辑），再 `_updateAffixUniqueIds`。
   执行时核对 `draw_cards` 预定义列表中的 id（defend/heal/speed_quick/dodge_nimble/
   gain_resource_ward/gain_resource_ultimate）在 card_affixes.json5 中都存在，缺的补。

3. **破境解锁**：`upgradeRank`（card.ht:429-472）——`isUnique` 卡不清空、不重随机
   额外词条，追加下一个预定义词条（数量 = 新 rank + 1，列表取满为止）。

4. **精炼限制**：`addAffix`/`replaceAffix`/`freezeAffix`/`removeAffix` 入口检查
   `card.isUnique`，返回提示文本（invoke 返回非 null 即弹提示的既有机制，
   `card_library.dart:551-554`）；`rerollAffix`/`upgradeRank` 放行。本地化加提示键。

5. **卡组唯一性**：`deckbuilding_zone.dart:349` `tryAddCard` 增加
   "卡组内已有同 uniqueId 绝世卡"判断并提示；`logic.dart:952` `checkDeckRequirement`
   加同款兜底校验（防存档/作弊途径绕过）。

6. **鉴定流程**：
   - `card.ht` 构造器：`isUnique` 时 `isIdentified` 默认 false。
   - `scripts/main/data/game.ht:298-300` `setHero()` 的强制鉴定循环跳过 isUnique 卡
     （旧存档没有绝世卡，跳过安全）。
   - `deckbuilding_zone.dart:356-359` 删除入组强制鉴定；未鉴定卡由
     `checkDeckRequirement`（checkIdentified）自然拦截在卡组/战斗之外。
   - `lib/state/craft.dart` `CraftMode` 新增 `identify`；`item_craft.dart` 对应
     filter `category: 'identify_scroll'`；`card_library.dart` `onStartCraft`
     （:602-）在 `card.data['isIdentified'] != true` 时使用 `CraftMode.identify`
     （未鉴定卡只显示鉴定卷轴）。
   - `onUseCraftMaterial`（card_library.dart:533）加 `identify_scroll` 分支：
     设 `isIdentified = true`、消耗卷轴（`Player.lose`）、播放音效、刷新卡面描述。
   - 本地化：提示与界面键（如 `craft_identify_hint` 等，参照既有 `craft_*_hint`）。

7. **随机概率控制（两段式 roll）**：`card.ht` 主词条选取（:50-100）——
   `affixId` 指定时不受影响；随机生成时先按 `kUniqueCardChance`（新常量，
   百分比整数制，**初值 5%，实机调**；放 `lib/data/common.dart` 并同步导出 hetu，
   参照 ailmentChance 的三处同步方式）判定是否出绝世：是则从符合过滤条件的
   `isUnique` 主词条池中随机，否则从非绝世池随机；命中的池为空时回退到另一池。
   NPC 卡组生成若走同一构造器则自动继承该概率（执行时确认
   `battle_entity.ht:567` 的调用路径）。

### 2.4 不在本阶段

- 绝世卡的专门掉落/任务/商店来源设计（内容向，随 draw_cards 之外的绝世卡一起做）。
- 圣化 `isExalted`、太古词条（`getMinMaxExtraAffixCount` 的 minGreater/maxGreater
  预留）——均未实现，另行立项。
- 敌方是否可持有绝世卡及战败掉落规则（沿用"战斗后几率获得对方卡组卡牌"的
  既有规则即可，暂不做特殊处理）。

## 三、涉及文件

- 需求 1：`lib/scene/battle/character.dart`（predictDamage）、
  `lib/data/game.dart`（getBattleCardDescription 加 valueOverrides）、
  `lib/scene/battle/battle.dart`（刷新时机挂载）、`lib/scene/battle/hand_zone.dart`（复用确认）
- 需求 2：`scripts/main/cardgame/card.ht`（uniqueId、固定词条、破境、精炼限制、
  概率控制）、`scripts/main/data/game.ht`（setHero 跳过）、
  `lib/scene/card_library/deckbuilding_zone.dart`（唯一性 + 去强制鉴定）、
  `lib/logic/logic.dart`（checkDeckRequirement 兜底）、
  `lib/state/craft.dart` + `lib/widgets/character/item_craft.dart` +
  `lib/scene/card_library/card_library.dart`（鉴定卷轴打造流程）、
  `lib/data/common.dart` + `constants.dart` + `scripts/main/binding/constants.ht`（概率常量）、
  `assets/data/cards.json5` / `card_affixes.json5`（核对预定义词条 id）、
  `assets/locale/zh/rpg/`（提示键）
- 执行完成后：`REFACTOR.md` 阶段清单补本文件条目；`docs/docs/how2play/rpg/battle/card/readme.md`
  核对与实现的一致性。

## 四、验证清单

- [ ] 编译通过（`python build.py`），`flutter analyze` 无新增错误
- [ ] 实机：战斗开始/抽牌/出牌后手牌伤害数字实时刷新；高于原值黄色、低于红色
- [ ] 实机：元素牌数字反映对方抗性/弱点；物理/真气牌数字反映对方护甲；豪气在必暴时显示暴击伤害
- [ ] 实机：刷新无闪烁/性能问题；敌方回合后数字正确更新
- [ ] 实机：随机生成（卡包）以低概率产出绝世卡；draw_cards 生成时带预定义固定词条（按境界 1~6 个）
- [ ] 实机：绝世卡获得后未鉴定（卡面红字、不能入卡组/出战）；打造界面只显示鉴定卷轴，使用后鉴定成功
- [ ] 实机：绝世卡的灵宝/神照/真定/坐忘被拒并提示；混元/破境可用；破境追加下一个预定义词条
- [ ] 实机：同一卡组无法放入两张同 uniqueId 绝世卡（含提示）

## 待确认问题（全部已定案）

- ~~Q1 预测范围~~：只算确定性部分（1.2.1），脚本类修正列入后续补齐。
- ~~Q2 暴击显示~~：默认非暴击，必暴时按暴击倍率显示。
- ~~Q3 随机池~~：绝世卡保留在随机池，两段式 roll 控制概率（初值 5%，实机调）。
- ~~Q4 鉴定方式~~：复用鉴定卷轴；打造界面中未鉴定卡只显示鉴定卷轴。
