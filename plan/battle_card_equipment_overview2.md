战斗系统的理解

 ### 1. 场景层（Dart）：lib/scene/battle/battle.dart

 BattleScene（Samsara Scene 子类）是战斗的总控制器，核心职责：

 - 组建战斗：加载双方 BattleCharacter（带动画状态机，从牌组卡牌的 animation 字段收集
   startup/recovery/actions/overlays 动画）、牌库区 BattleDeckZone、弃牌区 DiscardZone、手牌区
   HandZone、能量显示 EnergyDisplay、装备栏 EquipmentsBar。
 - 战斗流程（_startBattle 循环 → _onBattleStart → _startTurn → _onBattleEnd）：
     - 先手按身法加权随机（0.5 + (heroDex - enemyDex)/100），偷袭直接先手；后手方补偿回血至上限。
     - 软狂暴：roundCount > 8 后每个普通行动回合开始前叠 1 层劫气（回合开始回调扣 10% 生命上限）。
     - 回合内固定顺序：观星（天赋）→ 抽牌（kBattleDrawCount+加成）→ 回合开始回调（DOT/死气/幻觉等）→
       清空上回合残留阳气（首次行动不清空）→ 结算本回合资源产出 → 出牌阶段 → 回合结束回调 → 清手牌（
       保留 isRetained 卡）→ 速度阈值触发的额外回合 do-while。
     - 胜负检查在每张牌结算完毕的边界进行（_checkBattleResult），敌方优先死亡判英雄胜；回合上限
       endBattleAfterRounds 默认 50。
 - 玩家出牌模型：队列制。点选手牌 → _enqueueCard（费用预占硬检查 _canPayCardCost，计入已入队卡）→
   _processCardQueue 异步逐张 _playCard（支付 → hero.onUseCard(card) → 弃牌/符箓碎裂
   CardShatterEffect）。结束回合按钮将 _endPlayerTurn 置位。
 - 敌方 AI：简单策略——血量 <50% 优先 buff，否则优先 attack，逐张打到能量耗尽或手牌空。
 - 费用系统（单资源模型）：_cardCostColored 读 coloredCost；无色（life=元气）不受虚空之气影响也不能用
   无极抵扣；有色先扣本色气（kCostColorStatusIds 映射）、缺口用无极之气（kWildcardStatusId）补齐；虚
   空之气每层 +1 有色费用。支付明细写入 cardFlags['paidCost'] 供 refund_cost 等词条返还。置灰仅影响绘
   图，悬浮提示由 _missingCostReport 生成缺资源明细。
 - 伤害预测：refreshHandCardDescription 逐词条调用 enemy.predictDamage(hero, affix, cardCost: ...)，
   把 predictedValue/predictedCrit/predictedAilment 写进词条数据，由
   GameData.getBattleCardDescription(withPrediction: true) 渲染着色对比。
 - 观星（scry）：中央展示牌库顶 N 张，玩家点选一张放回牌库顶，其余进弃牌堆；_isScrying 期间禁止手牌交
   互；永不触发洗牌。
 - 战斗前准备：kStatsToPermanentEffects（攻防增减、四元素抗性/弱点）与纯增益属性
   （persistent/penetration/increase_damage_*）把角色 stats 转成永久状态图标；_prepareStatus 处理
   start_battle_with_* / start_turn_with_* 被动（含 opponent_ 前缀的给对方上状态版本）。
 - 特殊机制挂钩：悟道筑基减费、万法归宗洗入牌库、返朴归元授予紫微斗数、天道推演回合开始观星、符箓
   （isEphemeral）打出碎裂 + usedInBattle 标记 → 战后 settleScrollCharges 扣次数；无效卡/缺卡替换为
   blank_default 默认卡。
 - 战后：胜负提示图、业力池 +5、清 ephemeral passives、按回合数比例回血、生命写回角色数据
   （setCharacterLife），最后 onBattleEnd 回调 + popScene。

 ### 2. 卡牌数据模型（Hetu）：scripts/main/cardgame/card.ht

 - BattleCard struct：暗黑式随机生成——从 game.battleCards（cards.json5 加载）筛主词条（按
   category/kind/genre/rank 过滤 + 绝世两段式 roll：uniqueCardChance 概率从 isUnique 池抽），再从
   game.battleCardAffixes（card_affixes.json5）按境界额度随机补额外词条（getMinMaxExtraAffixCount，无
   境界 0 个 → 化神 4-6 个），词条等级在境界等级区间内随机（minLevelForRank/maxLevelForRank），数值由
   calcAffixValue(base + increment×level, rank) 计算。
 - 绝世卡：isUnique + uniqueId，词条固定（主词条 affixes 列表按 rank+1 顺序解锁），未鉴定不可用，命名
   走 uniquecard_{id} 本地化键。
 - 费用：updateCardCost 是唯一实现——显式 coloredCost 条目（数值或 {base, rankIncrement} 公式）求值写
   入，life 键排首位，同时记录 originalColoredCost 基线供卡面变色（增红减黄）；破境重算更新基线，战斗
   内动态改费不更新。
 - 打造操作：addAffix（灵宝）/ replaceAffix（神照）/ freezeAffix（真定）/ removeAffix（坐忘）/
   rerollAffix（混元）/ upgradeRank（破境，绝世卡保留全部词条并解锁下一个预定义词条，普通卡只保留主词
   条+锁定词条再重 roll）/ upgradeCard；全部对绝世卡禁用（破境/混元除外），返回本地化错误键。
 - Cardpack struct：卡包物品，3 张牌（1 张定向 + 2 张随机）。

 ### 3. 数据层（JSON5）

 - cards.json5（约 90 个主词条）：分区清晰——占位/默认卡 → 绝世·加持（参玄功/先天功/分心诀/气疗术）→
   天赋授予卡（紫微斗数/万法归宗，isUnpackable）→ 通用/悟道/锻体/御剑/法身/炼魂 各自的攻击与加持。字
   段约定：category（attack/buff）、genre（流派）、cardType（七类）、kind（命名/动画类别）、
   damageType（八种）、elementType、equipment（装备需求）、rank（境界门槛）、coloredCost、
   valueData（base+increment×level，可带 maxLevel）、
   animation（startup/recovery/actions/overlays/sound）、script、keywords、
   isUnique/isEphemeral/isUnpackable。
 - card_affixes.json5（额外词条池）：通用增益（护甲/速度/闪避/治疗）、buff 系（幸运/辟邪/护盾）、
   debuff 系（易伤/缓慢/迟钝/不幸/邪祟/破绽/降抗/降攻）、伤害联动（by_damage_heal/defend、各流派属性
   增伤）、时机回调词条（retain/scry，带 callbacks 列表）。过滤维度：categories + genres + rank +
   uniqueId 去重（含主词条 uniqueIds 预留位）。

 ### 4. 脚本层（Hetu）

 - CardScript 命名空间：统一签名 (self, opponent, card, affix)。牌库操作（draw_cards 带
   filter/reduceCost 条件表、scry）、攻击（attack / attack_multiple / attack_debuff /
   attack_rank_scaled）、增益减益（self_buff/opponent_debuff/降全抗/降全攻/生命上限/治疗）、资源转化
   （heal_vigor_all 归元功、convert_vigor_all 气转换 1:1 或 1:0.5、refund_cost 费用返还）、绝世专属（
   万法归宗按总耗灵气造成伤害）、攻击联动（按伤害量回血/得甲、属性增伤）、时机回调（retain 占位 +
   retain_added_to_hand 写 isRetained）。执行顺序：priority<0 额外词条 → 主词条（先动画）→ 其余额外词
   条。
 - StatusScript 命名空间：函数名 = {statusId}_{时机}，签名 (self, opponent, effect, details)，必须非
   阻塞。时机体系很丰富（双方各自的
   turn_start/turn_end/doing_damage/taking_damage/gained_debuff/using_card/used_card/attacked/buffed/
   extra_turn/use_card_genre_*/use_card_kind_*）。实现了：kind 系增伤、速度/闪避四阈值状态（迅捷→额外
   回合、缓慢→跳过、敏捷→免伤、迟钝→易伤75%）、护甲衰减（persistent 保留）、易伤、幸运（必暴击/必异常
   ）、辟邪、护盾、破绽、邪祟、七种元素异常（火/雷回合开始、冰/毒回合结束 + 流血/内伤/幻觉）、资源气
   增伤减伤（每层 ±5）、怒气受伤 +5%/层、死气/劫气扣血。
 - battle_character.ht：BattleCharacter 外部类声明（Dart 绑定的 API 面）。

 ### 5. 本地化（assets/locale/zh/rpg/）

 - battlecard.json：kind 名（battlecard_*）、绝世卡名（uniquecard_*）、词条描述（affix_*）、插画名等
   。
 - battle.json：战斗内提示（先手/后手回血/观星/暴击预测/缺卡替换等）。
 - status_effect.json：status_{id} 名称 + status_{id}_description 描述。

 ### 6. 文档（docs/docs/how2play/rpg/）

 battle/readme.md 定义了完整的规则体系：16 种攻击 kind / 14 种加持 kind 表、五流派资源表、八伤害类型
 及对策（物理-护甲可暴击、真气-50%穿透、四元素-抗性上限75%、精神-念力对抗、纯粹-无对策）、暴击/异常双
 充能计数器（阈值基础10、5-15）、幸运/不幸语义、资源回合节奏（摸牌→回合开始回调→清残留阳气→新产出）、
 软狂暴劫气；battle/card/readme.md 定义费用阶梯、词条等级/卡牌等级/境界关系、六种精炼、绝世卡、符箓、
 易逝；battle/resource/readme.md 定义 6 阳 6 阴资源气对、阴阳对冲净值显示、统一生命周期（对方回合期间
 保留可见）、产出模型、溢出原则、流派资源不对称软限制。