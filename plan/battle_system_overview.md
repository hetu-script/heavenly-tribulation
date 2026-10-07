# 战斗·卡牌·装备系统总览

> 本文从总体上记录与卡牌战斗相关的系统（战斗流程、卡牌、装备、天赋），供后续工作查阅。
> 分层原则：**Dart = 机制层**（回合骨架与阶段顺序、费用模型与支付、回调分发总线、卡牌过滤引擎、交互 UI、动画、卡牌生命周期）；**Hetu = 内容层**（一切"在时机 X 用数值 Y 做 Z"的行为）；**JSON5 = 绑定与参数**（内容 id → 脚本函数 + 数值/过滤条件/阈值）。Dart 代码中不应出现具体内容 id（卡牌/装备/天赋），新机制必须参数化、由数据字段驱动。

## 1. 战斗场景层（Dart）：lib/scene/battle/battle.dart

BattleScene（Samsara Scene 子类）是战斗的总控制器。

- 组建战斗：加载双方 BattleCharacter（带动画状态机，从牌组卡牌的 animation 字段收集 startup/recovery/actions/overlays 动画）、牌库区 BattleDeckZone、弃牌区 DiscardZone、手牌区 HandZone、能量显示 EnergyDisplay、装备栏 EquipmentsBar。
- 战斗流程（\_startBattle 循环 → \_onBattleStart → \_startTurn → \_onBattleEnd）：
  - 先手按身法加权随机（0.5 + (heroDex - enemyDex)/100），偷袭直接先手；后手方补偿回血至上限。
  - 软狂暴：roundCount > 8 后每个普通行动回合开始前叠 1 层劫气（回合开始回调扣 10% 生命上限）。
  - 回合内固定顺序：观星（turnStartScry，抽牌前）→ 抽牌（kBattleDrawCount + battleDrawBonus）→ 回合开始回调（DOT/死气/幻觉等）→ 清空上回合残留阳气（每角色本场首次行动不清空；energyRetain 资源保留在此结算）→ 本回合资源产出（元气 = kBattleBaseEnergy + basicEnergyBonus）→ 出牌阶段 → 回合结束回调 → 清手牌（保留 isRetained 卡）→ 速度阈值触发的额外回合 do-while。
  - 胜负检查在每张牌结算完毕的边界进行（\_checkBattleResult），敌方优先死亡判英雄胜；回合上限 endBattleAfterRounds 默认 50。
- 玩家出牌模型：队列制。点选手牌 → \_enqueueCard（费用预占硬检查 \_canPayCardCost，计入已入队卡）→ \_processCardQueue 异步逐张 \_playCard（支付 → hero.onUseCard(card) → 弃牌/符箓碎裂 CardShatterEffect）。结束回合按钮将 \_endPlayerTurn 置位。
- 敌方 AI：简单策略——血量 <50% 优先 buff，否则优先 attack，逐张打到无可支付候选或手牌空。
- 费用系统（单资源模型）：card_cost.dart 共用支付计算；元气不能以太极抵扣，有色先扣本色气、缺口用太极补齐；isWildcardCostForbidden 禁止抵扣。动态条目 {base, isDynamic:true} 达到门槛后耗尽本色气，统一豁免减费及置零。队列按顺序模拟资源预占，实际支付明细写入 cardFlags['paidCost']，供 refund_cost / attack_by_paid_resource 读取。置灰与缺资源提示使用同一规则。
- 伤害预测：refreshHandCardDescription 逐词条调用 enemy.predictDamage(hero, affix, cardCost: ...)，把 predictedValue/predictedCrit/predictedAilment 写进词条数据，由 GameData.getBattleCardDescription(withPrediction: true) 渲染着色对比。
- 观星 scry（:1094）：中央展示牌库顶 N 张（N = 传入 count + scryBonus），玩家点选一张放回牌库顶，其余进弃牌堆；\_handInteractionDisabled 期间禁止手牌交互；永不触发洗牌；支持费用修正 options（天机术 scryOptions）；分发 self_scry 状态回调（:1202，窥天镜）。
- 战前准备：kStatsToPermanentEffects（攻防增减、四元素抗性/弱点）与纯增益属性（persistent/penetration/increase*damage*_）把角色 stats 转成永久状态图标；*prepareBattleStart（:275）按聚合后的 battleStatus 授予永久状态，并处理 start_battle_with*_ / start*turn_with*\* 被动（含 opponent\_ 前缀的给对方上状态版本）。
- 机制字段挂钩（全部数据驱动，无内容 id 硬编码）：deckCostReduction → getDeck（:366 组牌阶段减/加费，下限 0）；shuffleIntoDeck → \_startBattle（:773 手牌/牌库/弃牌堆三区域查重后洗入，故后洗入的卡天然免疫组牌减费）；turnStartScry → \_startTurn（:1779 抽牌前观星）；turnStartExtraDraw → \_startTurn（:1794 补抽 + \_applyTurnCostIncrease 本回合临时加费、回合结束还原）；符箓（isEphemeral）打出碎裂 + usedInBattle 标记 → 战后 settleScrollCharges 扣次数；无效卡/缺卡替换为 blank_default 默认卡。
- 战后：胜负提示图、业力池 +5、清 ephemeral passives、按回合数比例回血、生命写回角色数据（setCharacterLife），最后 onBattleEnd 回调 + popScene。

## 2. 卡牌数据模型（Hetu）：scripts/main/cardgame/card.ht

- BattleCard struct：暗黑式随机生成——从 game.battleCards（cards.json5）筛主词条（按 category/kind/genre/rank 过滤 + 绝世两段式 roll：uniqueCardChance 概率从 isUnique 池抽），再从 game.battleCardAffixes（card_affixes.json5）按境界随机补额外词条。
- 额外词条数量：getMinMaxExtraAffixCount（logic.dart:542，卡牌/装备/丹药共用）= minExtra rank、maxExtra rank+1（无境界 0-1 个 → 化神 5-6 个）。minGreater/maxGreater（太古词条）有计算但全仓库无消费方，未实现。
- 词条等级在境界区间内随机：minLevelForRank = rank×10，maxLevelForRank = (rank+2)×10−5。数值由 calculateCardAffixValue（GameLogic，logic.dart；经 app.dart 绑定回脚本全局调用）计算：(base + increment×(等级−本境界下限)) × 1.3^rank（+ rankIncrement×rank），函数内 floor；isFixed: true 表示固定 base 不随等级缩放。
- 绝世卡：isUnique + uniqueId，词条固定（affixes 列表按 rank+1 顺序解锁），未鉴定不可用，命名走 uniquecard\_{id} 本地化键；天赋授予型再加 isUnpackable（不进卡包/随机池），由代码显式 invoke('BattleCard', affixId: ...) 发放。
- 费用：updateCardCost 是唯一写入入口——显式 coloredCost 条目（数值或 {base, rankIncrement} 公式）经 calculateCostValue（GameLogic；固定数值 floor、公式 ceil）求值写入，life 键排首位，同时记录 originalColoredCost 基线供卡面变色（增红减黄）；破境重算更新基线，战斗内动态改费不更新基线。
- 打造操作：addAffix（灵宝）/ replaceAffix（神照）/ freezeAffix（真定）/ removeAffix（坐忘）/ rerollAffix（混元）/ upgradeRank（破境，绝世卡保留全部词条并解锁下一个预定义词条，普通卡只保留主词条+锁定词条再重 roll）/ upgradeCard；全部对绝世卡禁用（破境/混元除外），返回本地化错误键。
- Cardpack struct：卡包物品，3 张牌（1 张定向 + 2 张随机）。

## 3. 卡牌数据层（JSON5）

- cards.json5：分区清晰——占位/默认卡 → 绝世·加持 → 绝世·悟道 → 抉择临时卡 → 天赋授予卡（紫微斗数/万法归宗，isUnpackable）→ 通用/悟道/锻体/御剑/法身/炼魂各自的攻击与加持。字段约定：category（attack/buff）、genre（流派，省略=中立）、cardType（七类：unarmed/weapon/spell/curse/shenfa/xinfa/divinity）、kind（命名/动画类别）、damageType（八种，攻击卡必填）、elementType、equipment（装备需求）、rank（境界门槛 0~5）、coloredCost、valueData（{base, increment, maxLevel?}）、animation（startup/recovery/actions/overlays/sound）、script、keywords、isUnique/isEphemeral/isUnpackable。
  - 费用惯例：流派卡 = rank 点流派色（悟道 {spell:{base:0,rankIncrement:1}} / 御剑 weapon / 锻体 unarmed / 炼魂 curse）；中立卡（含法身）= {life:{base:0.5,rankIncrement:0.5}}（calculateCostValue 内 ceil，即 1,1,2,2,3,3）；免费卡显式 {life: 0}。
- card_affixes.json5（额外词条池）：通用增益（护甲/速度/闪避/治疗）、buff 系、debuff 系、伤害联动、时机回调词条（retain/scry/attune，带 callbacks 列表）。过滤维度：categories + genres + rank + uniqueId 去重（含主词条 uniqueIds 预留位）。机制字段平铺在词条上：filter / require / resourceId / resourceThreshold / buffId / attributeId / priority / callbacks 等。
  - filter 条件口径（matchCardCriteria，battle.dart）：category/genre/cardType/kind/elementType + not 反选子表；draw_cards 的 filter/reduceCost、upgrade_hand_cards、getHandCards、matchLastUsedCard 共用同一口径。字符串 'self' 是占位符，由 CardScript.\_resolveCriteriaSelf（card_script.ht:489）解析为本牌主词条同名字段的值，解析出 null 则条件不成立、效果不触发。

## 4. 卡牌脚本层（Hetu）：scripts/main/cardgame/

### 4.1 card_script.ht —— CardScript 命名空间

- 统一签名 (self, opponent, card, affix)；词条 script 字段是函数名数组，打出时按序逐个 invoke。card 为卡牌本体（主词条经 card.affixes[0] 访问），affix 为本词条数据（affix.value[i] 对应 valueData[i]）。
- 执行顺序：priority < 0 的额外词条（按 priority 降序）→ 主词条（先播放动画）→ 其余额外词条（按 priority 降序）。
- Dart 对每个词条脚本统一 await；调用异步 API（drawCards / scry / upgradeHandCards / discover）的脚本必须声明 async 并 await，否则脱离结算顺序。
- 时机回调：词条声明 callbacks 列表后，在对应时机调用 {script}\_{时机} 函数（现有时机：added_to_hand / removed_from_hand）；声明的回调函数必须存在（缺失抛错中断结算）；额外词条的打出时基名函数可缺省（ignoreUndefined，告警一次），主词条基名必须存在。契约详见 docs/docs/mod/battle/card/readme.md。
- 功能分组：牌库操作（draw_cards 带 filter/reduceCost、scry、scry_then_draw）；攻击（attack / attack_multiple / attack_debuff / attack_buff / attack_multiple_ailment / attack_multiple_by_used_elements / attack_multiple_by_cards_in_hand / attack_with_energy_count_check / attack_by_paid_resource / attack_rank_scaled）；增益减益（self_buff / opponent_debuff / 降全抗 / 降全攻 / 生命上限 / heal / heal_lifeMax / heal_remove_debuffs / gain_defense_by_mana）；资源转化（heal_vigor_all / convert_vigor_all / refund_cost）；绝世专属（attack_by_paid_resource / scry_then_draw / ailments_by_used_elements / discover_element_amplify / gain_mana_by_self_ailments）；攻击联动（by_damage_heal / by_damage_defend / for_attribute_increase_damage / increase_damage_by_last_card_used / increase_damage_by_energy_count）；时机回调与其他（retain / attune / upgrade_card / upgrade_hand_cards / gain_resource_next_turn / draw_by_last_card_used / ailment_spread）。

### 4.2 status_script.ht —— StatusScript 命名空间

- 函数名 = {statusId}\_{时机}，签名 (self, opponent, effect, details)，必须非阻塞。
- 时机体系：双方各自的 turn*start / turn_end / doing_damage / taking_damage / gained_debuff / using_card / used_card / attacked / buffed / extra_turn / use_card_genre*_ / use*card_kind*_，以及 self_produce_resources（产出阶段，如太上感应）等。
- 已实现：kind 系增伤、速度/闪避四阈值状态（迅捷→额外回合、缓慢→跳过、敏捷→免伤、迟钝→易伤75%）、护甲衰减（persistent 保留）、易伤、幸运（必暴击/必异常）、辟邪、护盾、破绽、邪祟、七种元素异常（点燃/感电回合开始耗尽全层、冰缓/中毒回合结束移除 1 层 + 流血/内伤/幻觉）、资源气增伤减伤（每层 ±5）、怒气受伤 +5%/层、死气/劫气扣血、真气渗透（穿透 = 内伤层数 ×5%，伤害附内伤）、悟道境界节点（supreme_sensing / yin_yang_five_elements / five_qi_convergence）与分支节点（embrace_simplicity / element_cycle）、绝世装备状态（scry_self_ailments / turn_start_mana_bonus）等。
- 状态数据在 assets/data/status*effect.json5（script 字段 + 机制参数），本地化在 status_effect.json（status*{id} + status\_{id}\_description）。

### 4.3 battle_character.ht —— BattleCharacter 外部类（Dart 绑定的脚本 API 面）

- 属性：data / turnFlags / cardFlags / life / lifeMax / turnCount。
- 方法：takeDamage / changeLife / setLifeMax / addStatusEffect（带 source 供异常层数修正归属）/ removeStatusEffect / hasStatusEffect / drawCards / scry / discover（抉择，敌方随机）/ upgradeHandCards / getHandCards / matchLastUsedCard / getLastUsedCard / applyTurnCostModifier（回合级临时费修）/ addHintText / getElementalResist / setState / setCompositeState。
- 标志约定：turnFlags['usedElements']（本回合已用元素 Map，Dart 侧元素牌结算后无条件记录）、turnFlags['lastUsedCard']（上一张打出的牌引用）、turnFlags['pendingResources']（下回合额外产出的跨回合标记）；cardFlags['paidCost']（支付明细）、cardFlags.damage（伤害统计与乘区 percentageChange1 等）。

## 5. 装备系统

### 5.1 物品数据模型（Hetu）：scripts/main/data/item/

- item.ht：
  - 分类常量：type（equipment/consumable/cardpack/craftmaterial/miscellaneous，物品栏筛选用）× category（小类别，决定装备数量限制与 onUseItem 分支）× kind（具体种类，决定命名/图标/词条过滤）。
  - createItemById(id, {amount, rank, level})（item.ht:75）：从 game.items（items.json5）prototype Object.create；isRankedItem 由 rank 推导 rarity 并按境界命名；普通物品 rarity↔rank 互推——两者都写时 rarity 优先（rarity:"arcane" 会压成 rank 5），故绝世装备只写 rank。isUnstackable 使运行时 id 变随机 UID，唯一性检查只能用 uniqueId。
  - 词条实例化（item.ht:130-163）：绝世（isUnique）按 min(词条数, rank+1) 解锁 affixes 列表前 N 条（与绝世卡同规则；装备破境未实现，解锁数生成时固定）；词条有 increment/rankIncrement 才 roll level（increment 绝对值<1 时 minAffixLevel=ceil(1/|increment|)）并用 calculatePassiveAffixValue 算 value；机制型词条无 increment，跳过 roll，数值定值内嵌在机制字段里。affixUniqueIds 收集 uniqueIds/uniqueId 供互斥去重。
  - calculatePrice：itemWithAffixKinds 按 (rank²+1)×(level+1)×(词条数+1)×basePriceByKind 计价。
  - createLoot（item.ht:534）：八种奖励配置（exp/material/equipment/cardpack/potion/contribution/credit/prototype）的统一发放入口。
- equipment.ht（Equipment struct，普通随机装备主流程）：category/kind 缺省时从 Constants.equipmentCategoryKinds 反查/随机；level 在境界区间内随机（同卡牌 minLevelForRank/maxLevelForRank）；主词条（equipment.ht:72-82）过滤 isEquipmentMain ∧ kinds 含本 kind ∧ affix.rank≤装备 rank 随机取一、level=装备 level；额外词条（:103-144）数量同 getMinMaxExtraAffixCount，逐条过滤 isEquipmentExtraAffix ∧ uniqueId 互斥 ∧ kinds ∧ rank，level=getRandomLevel(minAffixLevel, 装备 level)。
- extracted_affix.ht：ExtractedAffix——精炼产物，单词条物品（category=extracted_affix），打造时填充词条槽。
- usable.ht：可使用物品（丹药/卷轴等，onUseItem 分支；丹药词条 roll 法与装备相同）。

### 5.2 装备词条池：passives.json5（与天赋共享）

- 用途标记布尔字段区分词条池：isEquipmentMain / isEquipmentExtraAffix / isToolExtraAffix / isPotionMain / isEphemeral（+ephemeralType）；天赋树节点无视用途标记直接引用 id；rank 门槛只对装备/丹药生效。同一词条可叠加多个标记（如 elementalResist 同时是装备主词条+额外词条+临时增益词条）。
- 数值公式：calculatePassiveAffixValue = (base??0) + increment×level（maxLevel 封顶）——属性词条只有 increment 无 base；与卡牌的境界指数公式（calculateCardAffixValue）是两套。isDecrement 标记负向词条。
- uniqueId 互斥组（同组词条一件装备只能 roll 到一个，如 increase*damage*\* 共享 uniqueId）；priority 全文件递减排序。
- 机制字段（7 个，契约见 docs/docs/mod/battle/readme.md:95-108）：battleStatus（战斗开始授予永久状态，行为在 status_script.ht）/ deckCostReduction{color, amount, genres?, notGenres?}（组牌费修，amount 负=加费，color:'all' 命中首个费用条目）/ shuffleIntoDeck[卡牌主词条 id] / turnStartScry N / turnStartExtraDraw{count, costIncrease?{amount, notGenres?}} / energyRetain{resourceId, max, costPerPoint?, costDamageType?}（回合结束资源保留+每点代价）/ statsBonus{statsId: 数值}（stats 直加，scryBonus / ailmentInflictBonus / ailmentReceiveBonus 等）。
- 机制字段之外的普通数值词条（basicEnergyBonus / battleDrawBonus / deckMinSizeReduce）不在白名单，走 .value 数值。
- 绝世装备专用词条区（passives.json5:1328-1379）：不写用途标记、不进随机词条池，数值定值内嵌机制字段；一件装备的逻辑效果合并为一条主词条（多机制字段共存），affixes 只写主词条、给后续额外词条留出解锁位。

### 5.3 装备→战斗联动链路

- 穿脱（battle_entity.ht:762-847）：characterEquip 校验（在 inventory、isEquippable、空栏位 equipmentSlotCount=rank+3 封顶 8、绝世 uniqueId 唯一）→ 遍历 item.affixes 逐条 characterSetPassive(entity, id, level)（:629-656，同名词条 level 贡献累加、卸下减对应贡献）写入 character.passives 副本 → characterCalculateStats 重算（改 passives 后必须重算才生效）。UI 调用链：stats_and_item.dart 右键菜单 → Player.equip/unequip（player.ht:352-356, :390-393）。
- 类别限制只在 UI 层：kRestrictedEquipmentCategories（common.dart:359-367，weapon/shield/armor/gloves/helmet/boots/vehicle 七类）已装备同类时拒绝，除非角色有 ${category}UnrestrictedEquip 被动；characterEquip 内部不查类别。
- 透传白名单 \_kPassiveMechanismFields（battle_entity.ht:583-591）：7 个机制字段经 \_createPassiveData（:596-621）挂到 PassiveData（HTStruct 动态属性，结构体本身不声明），漏加则字段永远到不了战斗侧。
- 聚合（characterCalculateStats :392-468，passives + ephemeralPassives 双来源）：battleStatus 按状态 id 合并、层数累加；deckCostReduction 规则列表按来源拼接全部生效；shuffleIntoDeck 列表拼接（去重在战斗侧）；turnStartScry 求和；turnStartExtraDraw count 求和、costIncrease 后者覆盖；energyRetain 按 resourceId 合并（max 取大、代价沿用首个配置）；statsBonus 逐键累加进 character.stats。
- Dart 消费点：
  - battle.dart：见 §1 机制字段挂钩。
  - character.dart：energyRetain → clearResourceEffects（:667，保留+每点代价伤害，每角色本场首次行动跳过）；ailmentInflictBonus/ailmentReceiveBonus → 异常计数器（:342）与 addStatusEffect 直施（:509）两路径同口径修正（修正后 ≤0 静默不施加）；basicEnergyBonus → produceTurnStartResources（:726）。
- 战斗内展示：EquipmentsBar（lib/scene/battle/equipments_bar.dart）固定 8 格只读图标+rank 边框，仅悬停提示（物品/属性/流派被动说明），战斗中不可穿脱；战前整备另有 EquipmentBar（prebattle.dart）。

### 5.4 装备 UI（Dart）：lib/widgets/character/

- stats_and_item.dart（CharacterStatsAndItem）：EquipmentBar（竖排装备栏）+ CharacterStats（属性面板）+ Inventory（背包）三联；右键菜单 equip/unequip/use/charge/discard，前置校验（未鉴定/诅咒/类别限制/绝世重复）。
- inventory/：equipment_bar.dart（角色面板装备栏）、inventory.dart + item_grid.dart（背包格子）、material.dart（材料栏）；merchant/ 交易界面。
- item_craft.dart（ItemCraft）：材料选择面板——CraftMode.affix/scroll/identify/all 决定 category 过滤（craftmaterial_affix/scroll_paper/identify_scroll/全部），可选 rank 下限；右键发 GameEvents.craftMaterialSelected 供工坊场景消费，本身不含打造逻辑。
- stats.dart 的 kMoreStats（:34-42）展示 scryBonus / ailmentInflictBonus / ailmentReceiveBonus / turnStartScry 等新 stat。

### 5.5 打造与精炼（lib/widgets/view/workshop.dart）

- 打造 craftEquipment（:152-188）：即时完成（无耗时逻辑）；材料 = craftables.json5 基准 × (rank²+1)（:91-98）+ 每词条 shard 费（:256-262）；建筑 development 门控可打造稀有度（:74-85）；打造时额外词条固定取上限 maxExtra（:100-101）；ExtractedAffix 用于填充词条槽（:105-130, :162-176）；产物存 locationData 待拾取（:190-203）。
- 精炼 extractAffix：只能提取额外词条（sublist(1) 排除主词条，:141），销毁原装备（:205-226），产物 ExtractedAffix 物品；绝世装备不可析取（:133-138）。
- 装备破境（升境）与重铸未实现。

### 5.6 绝世装备

- 数据约定（items.json5:235-271 模板注释 + :273-362 悟道五件）：显式写 rank（不写 rarity）、uniqueId == id、isUnstackable、isUnique、isIdentified: false（默认未鉴定）、affixes 首条为主词条、图标初期占位 item/unknown.png。同一 uniqueId 同时只能装备一件。
- 悟道五件（装备 → 词条 → 机制）：
  - 窥天镜 heaven_peeking_mirror（rank1，talisman/pearl）→ battleStatus: scry_self_ailments（观星后自施 2 种元素异常）+ statsBonus: {scryBonus: 2}
  - 五行珠 five_elements_pearl（rank2，amulet）→ statsBonus: {ailmentInflictBonus: 2, ailmentReceiveBonus: 2}
  - 天机盘 heavenly_mechanism_disc（rank3，talisman/pearl）→ turnStartExtraDraw: {count: 1, costIncrease: {amount: 1, notGenres: [spellcraft]}}
  - 蓄灵佩 spirit_storing_amulet（rank4，amulet）→ energyRetain: {resourceId: energy_positive_spell, max: 2, costPerPoint: 3, costDamageType: pure}
  - 聚灵旗 spirit_gathering_banner（rank5，talisman/pearl）→ battleStatus: turn_start_mana_bonus + deckCostReduction: {color: all, amount: -2, notGenres: [spellcraft]}

## 6. 天赋树

- 天赋节点与装备词条同池（passives.json5），天赋树结构在 passive_skills.json5（节点引用 passive id，rank/位置/连线由树节点携带；passive 条目不写 rank，解锁时 level 缺省 ?? 1）。
- 境界节点：passives.json5:1038-1074（spellcraft_rank_1~5 等，纯标记 + 机制字段），树节点附带 lifeMax 40×rank；悟道主轴已连通（track_4_4 → track_8_8 → track_12_8 → track_16_8 → track_20_4）。
- 分支节点：passives.json5:1076-1104（skilltree*branch*\* 中性 id，设计上可多流派共享）；悟道的 4 个已实现但暂未上树连线。
- 学天赋与穿装备同通道：characterSetPassive → characterCalculateStats（见 5.3），战斗侧只读被动数据。

## 7. 常量同步（Dart ↔ Hetu）

- lib/data/common.dart 是常量唯一来源（kCamelCase）；lib/data/constants.dart 经 HTExternalClass 导出；scripts/main/binding/constants.ht 在脚本侧声明；脚本中以 Constants.xxx 访问（如 Constants.elementAilments / equipmentCategoryKinds / rankToRarity / basePriceByKind）。
- 数值公式同属 Dart 机制层：calculateCardAffixValue / calculatePassiveAffixValue / calculateCostValue / calculateItemBasePrice 实现于 GameLogic（logic.dart），经 app.dart bindExternalFunction 绑定、scripts/main/logic/logic.ht 声明 external，脚本侧全局直调（同 minLevelForRank / getMinMaxExtraAffixCount 等先例）；hetu item.ht 的 calculatePrice 只是写回 item.price 的薄壳。
- lib/data/common_data.dart 是纯常量拆分（供校验器在纯 Dart VM 下 import，不能引入 Flutter/dart:ui）；结构契约表（回调契约、机制字段形状、cardType/filter 键等）硬编码在校验器中，新增数据约定时需同步校验器。

## 8. 本地化（assets/locale/zh/rpg/）

- battlecard.json：kind 名（battlecard*\*）、绝世卡名（uniquecard*\_）、卡牌词条描述（affix\_\_，数值占位 {0}{1}）、插画名（illustration\_\*，需同步 lib/data/common.dart 的 kBattleCardIllustrations）。
- battle.json：战斗内提示（先手/后手回血/观星/暴击预测/缺卡替换等）。
- status*effect.json：status*{id} 名称 + status\_{id}\_description 描述。
- item.json：装备名 {id} + flavortext*{id}（写清机制与代价）；passive.json：passive*{id}\_description（词条效果行，键名无机械转换规则，camelCase 原样保留或手写 snake_case）。

## 9. 校验与构建

- dart run utils/data_validate/game_data_validate.dart —— cards/card_affixes/passives/status_effect/items 的 id/引用/本地化/结构/绝世约定检查（当前 0 错误）。
- dart run utils/data_validate/passive_tree_validate.dart —— 天赋树连通性（当前未通过：9 个悬空引用 + 78 个不可达节点，含悟道副轴骨架，属历史遗留，待天赋树排布时清理）。
- python build.py —— 编译 Hetu 脚本到 assets/mods/（Windows 下 hetu 可能有 PATH 问题，可用 dart install 绝对路径的 hetu.bat）；flutter analyze 验证 Dart。

## 10. 文档现状（docs/ 与实现的对照）

- docs/docs/how2play/rpg/battle/readme.md：完整规则体系——16 种攻击 kind / 14 种加持 kind 表、五流派资源表、伤害类型及对策（物理-护甲可暴击、无属性-护甲不暴击（元素卡未转化态）、真气-内伤层数×5%穿透且伤害附内伤、四元素-转化态无视护甲吃抗性、精神-念力对抗、纯粹-无对策）、暴击/异常双充能计数器（阈值基础10、5-15）、幸运/不幸语义、资源回合节奏、软狂暴劫气。
- docs/docs/how2play/rpg/battle/card/readme.md：费用阶梯、词条等级/卡牌等级/境界关系、六种精炼、绝世卡、符箓、易逝。
- docs/docs/how2play/rpg/battle/resource/readme.md：6 阳 6 阴资源气对、阴阳对冲净值显示、统一生命周期（对方回合期间保留可见）、产出模型、溢出原则、流派资源不对称软限制。
- docs/docs/mod/battle/readme.md：被动机制字段契约表（7 个字段与透传白名单一一对应，最可靠的契约文档）；docs/docs/mod/battle/card/readme.md：词条脚本回调契约。
- docs/docs/how2play/rpg/item/equipment/readme.md 一致项：词条与天赋同池、境界-栏位表、绝世规则、精炼销毁原装备、打造额外词条固定上限。偏差：稀有度-词条数表过时（实现 minExtra=rank/maxExtra=rank+1，即凡品 0-1 … 神品 5-6）；太古词条（✶）未实现；「绝世仍可重铸」未实现；未写精炼只能提取额外词条、产物 ExtractedAffix 可用于打造；打造实际即时完成（无耗时/等待）；类型限制实现为 7 类（含 shield/gloves/vehicle）且 UnrestrictedEquip 被动可豁免，文档列 6 类未提豁免；生产工具（斧/锤/耙/锄/针）与 aircraft/belt 未实现。
- docs/docs/how2play/rpg/craft/readme.md 属愿景描述：图纸系统不存在、材料不能直接附加词条（装备打造只吃 ExtractedAffix）、打造不耗时；卡牌六种精炼已实现但文档未写。

## 11. 悟道流派落地现状

- 动态费用：焚天烈焰 `coloredCost: {spell: {base: 0, isDynamic: true}}`（X）；万法归宗 `base: 10`（10+X，禁止太极抵扣）。支付阶段耗尽对应气，两张牌以 `attack_by_paid_resource` 读取实际 paidCost 计算伤害。所有减费和置零入口豁免动态条目，加费提高最低门槛；Samsara 直接显示 X / N+X。费用公共逻辑在 `lib/scene/battle/card_cost.dart`，队列按顺序预占，敌方按可支付手牌出牌，不再依赖元气余额。

- 境界节点 5 个（已上树、主轴连通）：太上感应（spellcraft_rank_1，灵力÷10 产灵气）/ 天道循环（rank_2，deckCostReduction 悟道牌 -1）/ 阴阳五行（rank_3，回合结束未用灵气溢出伤害，扣除 energyRetain 保留部分）/ 五气朝元（rank_4，五元素攻击增强轮转）/ 万法归宗（rank_5，shuffleIntoDeck 洗入绝世卡）。
- 分支节点 4 个（已实现、待连线上树）：紫微斗数（skilltree_branch_draw_1，洗入授予卡）/ 天道推演（draw_2，turnStartScry 3）/ 抱真守一（element_1，用元素牌后升级手牌同元素牌）/ 五行轮转（element_2，每种新元素 +1 灵气）。
- 卡牌：主词条 16 张（cards.json5:726-1211）+ 绝世卡 5 张（:1218-1378）+ 天赋授予卡 2 张（:1415-1470）+ 一气化三清抉择临时卡 3 张（:1383-1409，不进卡池）；额外词条 9 个（card_affixes.json5:527-695）。
- 绝世装备 5 件（items.json5:273-362 + passives.json5:1328-1379）：窥天镜 / 五行珠 / 天机盘 / 蓄灵佩 / 聚灵旗。
