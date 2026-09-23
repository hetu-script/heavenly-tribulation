# 战斗/卡牌/装备系统现状梳理（规划基础档案）

## 1. 战斗流程（对称式，类杀戮尖塔但敌我平等）

`lib/scene/battle/battle.dart` + `docs/docs/mod/battle/readme.md`（回调契约文档，与实际代码一致）。

- 敌我共用同一套 `_startTurn()` 流程：摸牌 → `onStartTurn()` 回调（DOT/劫气/缓慢跳过判定）→ 胜负检查 → `clearResourceEffects()` 清空上回合阳气（首次行动保留战初阳气；煞气未用返回业力池；阴气永久存在直到对冲）→ `produceTurnStartResources()` 产出（元气 kBattleBaseEnergy+`battleEnergyBonus` 装备词条 / 剑气=上回合武器牌数 / 怒气=上回合受伤÷10 / 灵气天赋 / 煞气业力池提取）→ start_turn 被动注入 → 出牌阶段（玩家点选入队 `_enqueueCard`→`_processCardQueue`→`_playCard`；敌方 AI 循环打出可支付卡）→ `onEndTurn()`（灵气溢出天赋→元气回血→其余回调）→ 额外回合判定 → 换手。
- 费用硬检查：无色费用 ≤ 元气层数；每色需求 ≤ 本色气 + 无极之气（万能色）存量；虚空之气每层使有色费用 +1。支付先扣本色、缺口扣无极。费用不足置灰（`_canPayCardCost` / `_payCardCost`，battle.dart:845-940）。
- 软狂暴：`roundCount > 8` 后每次普通回合开始给当前角色 1 层 `debuff_tribulation`（回合开始消耗 1 层失去 10% 上限生命）。
- 伤害公式：`(baseValue + baseChange) × (1+pct1) × (1+pct2) × (1+pct3)`，pct1 下限 -0.75；暴击（仅物理）与护甲（仅物理/真气，真气自带 50% 穿透）在此后结算。`damageDetails` 是共享 Map，脚本写入 Dart 读取。
- 暴击/元素异常为充能阈值制（基础 10，clamp 5~15，stats 中 critThreshold/ailmentThreshold）；幸运必暴/必异常，衰气按层抵消。

## 2. 卡牌系统（暗黑式词缀随机生成 + 流放之路式打造）

- 数据：`assets/data/cards.json5`（主词条，~2335 行；字段 category/genre/kind/cardType/damageType/rank/script/valueData/coloredCost/equipment/isUnique/affixes(绝世预定义)/animation 等）；`assets/data/card_affixes.json5`（额外词条，按 categories/genres/uniqueId/rank 过滤，支持 priority，负数在主词条前执行）。
- 生成：`scripts/main/cardgame/card.ht` 的 `BattleCard` 构造器。主词条 roll（绝世池 uniqueCardChance 两段式）→ rank/level 确定 → `_updateAffixValue` 算主词条数值（value = base + increment×level + rankIncrement×rank，见 `calcAffixValue`，scripts/main/data/common.ht:146）→ 普通卡 `_addExtraAffixes`（数量由 `getMinMaxExtraAffixCount(rank)` 即 Dart 侧决定）/ 绝世卡 `_addPredefinedAffixes`（rank+1 个固定词条）。
- 费用：`updateCardCost`（card.ht:23）唯一实现，阶梯 L(rank)=⌊rank/2⌋+1，显式 `coloredCost` 优先（支持 {base, rankIncrement} 公式），否则按流派色推导（悟道→灵气 spell、御剑→剑气 weapon、锻体→怒气 unarmed、炼魂→煞气 curse、法身→怒气+煞气对半拆）。元气费用在 coloredCost 的 life 键。
- 打造（PoE 式）：`addAffix`（灵宝·加词条）、`replaceAffix`（神照·换最低 rank 词条）、`freezeAffix`（真定·锁定，需材料 rank≥已锁数+1）、`removeAffix`（坐忘·删词条）、`rerollAffix`（混元·重 roll 数值）、`upgradeRank`（破境·升境界重算费用与词条）。绝世卡禁止灵宝/神照/真定/坐忘，只能混元+破境。绝世卡需鉴定。
- 特殊：符箓 = 复制卡牌为消耗品（isEphemeral，次数制，打出碎裂）；卡包 Cardpack（3 张牌）。

## 3. 脚本系统（Dart ↔ Hetu 回调契约）

- 卡牌脚本 `scripts/main/cardgame/card_script.ht`：命名空间 `CardScript`，函数名=词条 `script` 字段，签名 `(self, opponent, affix, mainAffix)`。现有：attack / attack_multiple / attack_debuff / attack_rank_scaled / speed_quick_defend / dodge_nimble_defend / buff_lifemax / debuff_lifemax / heal / heal_lifeMax / self_buff / opponent_debuff / reduce_resist_all / by_damage_heal / by_damage_defend / for_attribute_increase_damage / draw_cards。
- 状态脚本 `scripts/main/cardgame/status_script.ht`：命名空间 `StatusScript`，函数名=`{状态script字段}_{回调时机}`，签名 `(self, opponent, effect, details)`，**必须非阻塞**。时机包括 turn_start/end、deck_start/end、doing/taking/done/taken_damage、gained_energy_positive/debuff/injury、using/used_card、attacked、use_card_kind_*/genre_*、extra_turn、heal、overflowed_energy（目前空转）等。执行顺序：永久状态 → 资源状态 → 其他。
- 共享数据：出牌期间 `角色.cardFlags`（category/genre/kind/damageType/damage.total 等）；回合期间 `角色.turnFlags`（skipTurn/extraTurn/invincible/guaranteedCrit 等）。

## 4. 资源系统（6 阳 6 阴气）

- 阳气：元气(无色费用池)、灵气/剑气/怒气/煞气(四色费用+对应攻击+5/层)、无极之气(万能费用色+全攻击+5/层)；阴气为各自反面（减攻击/死气掉血/虚空增费）。阴阳同对对冲，UI 显示净值。阳气统一生命周期=持有者下个回合开始清空（覆盖对方回合，对方可见）；阴气永久。
- 产出滞后一轮（剑气看上回合武器牌、怒气看上回合受伤），是有意的节奏设计。

## 5. 装备系统（现状：仅简单属性词条）

- 结构：`scripts/main/data/item/equipment.ht` 的 `Equipment` 构造器。category（weapon/shield/armor/gloves/helmet/boots/vehicle/jewelry/talisman，见 lib/data/common.dart:1973 `kEquipmentCategoryKinds`）+ kind（sword/sabre/.../amulet/ring/pearl 等）。rank↔rarity 互推。装备栏 8 格，可用栏位 = min(rank+3, 8)（`equipmentSlotCount`）。
- 词条来源：与天赋树/丹药**共享** `assets/data/passives.json5`（~1264 行），用标记位区分用途：`isEquipmentMain` / `isEquipmentExtraAffix` / `isToolExtraAffix` / `isPotionMain` / `isEphemeral`。词条数值 = `calcAffixValue`（increment×level + rankIncrement×rank）。
- 主词条：`isEquipmentMain` 池按 kind 匹配抽取，含武器解锁词条（equipment_sword 等"可以使用X法"，无数值）和数值词条（抗性/属性等）。
- 生效管线：`characterEquip`（battle_entity.ht:632）→ 逐词条 `characterSetPassive(entity, id, level, rank: item.rank)` 累加进 `character.passives[dataId]`（同名词条 level/rank 贡献叠加，卸下相减）→ `characterCalculateStats`（battle_entity.ht:283）聚合 passives+ephemeralPassives → `character.stats`。
- 战斗注入：`battle.dart` `_prepareBattleStart` 把 stats 转成战斗内永久状态（kStatsToPermanentEffects 攻防/抗性元组 + persistent/penetration/increase_damage_* 纯增益），`_prepareStatus(circumstance)` 按 `start_battle_with_*` / `start_turn_with_*`（含 `_opponent_` 前缀施加给对方）从 passives 读值注入战斗状态。
- 特殊装备词条：battleEnergyBonus（元气+）、battleDrawBonus（摸牌+）、deckMinSizeReduce（卡组下限-）、enable_karma/chakra/rage/ultimate（资源开关，实际在天赋）、各 UnrestrictedEquip（解除装备数量限制）等。
- UI：`lib/widgets/character/stats.dart`（CharacterStats，kStats+kMoreStats 列表，悬浮显示 description，着色比较 baseValue 与 stats 值）；战斗中有 `EquipmentsBar`。

## 6. 本地化

- 卡牌：`assets/locale/zh/rpg/battlecard.json`（affix_* 描述等）；状态：`status_effect.json`（status_* 名称/描述）；被动：`passive.json`（passive_*_description，含天赋树流派节点描述如 `passive_spellcraft_rank_1_description`）。
- 词条的 `description` 字段 = 本地化键，UI/卡面通过 `engine.locale(key)` 取值。

## 7. 关键文件索引

| 内容 | 位置 |
| ---- | ---- |
| 回合流程/费用/战斗结算 | `lib/scene/battle/battle.dart` |
| 战斗角色（takeDamage/资源产出/状态管理） | `lib/scene/battle/character.dart` |
| 卡牌生成与打造 | `scripts/main/cardgame/card.ht` |
| 卡牌/状态脚本 | `scripts/main/cardgame/card_script.ht` / `status_script.ht` |
| 装备生成 | `scripts/main/data/item/equipment.ht` |
| passives 聚合/装备穿脱/丹药 | `scripts/main/data/character/battle_entity.ht`（characterSetPassive:477、characterCalculateStats:283、characterEquip:632） |
| 词条数值公式 | `scripts/main/data/common.ht:146` calcAffixValue |
| 共享词条池 | `assets/data/passives.json5` |
| 卡牌主/额外词条 | `assets/data/cards.json5` / `card_affixes.json5` |
| 回调契约文档 | `docs/docs/mod/battle/readme.md` |
| 玩法文档 | `docs/docs/how2play/rpg/battle/`（readme/card/resource） |

