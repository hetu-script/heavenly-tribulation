**玩家回合（heroTurn == true）与敌方回合（heroTurn == false）共用同一套流程（`_startTurn`）：**

1. 回合开始观星（被动 `turnStartScry` 字段，如悟道分支「天道推演」）：抽牌阶段之前观星 N 张，选中的牌置于牌库顶随本回合抽牌入手
2. 摸牌：`drawCardsToHand()`（张数 = kBattleDrawCount + battleDrawBonus 属性）
3. 执行 `currentCharacter.onStartTurn()`：回合开始回调（死气/劫气失去生命、元素 DOT、缓慢跳过判定等）
4. 检查战斗结果：回合开始效果致死则立即结束，不进入后续阶段
5. 记录是否跳过出牌阶段（`turnFlags.skipTurn` 或空手空库），但不跳过资源与回合结束结算
6. 清空资源：`clearResourceEffects()`（每个角色第一次行动保留战初阳气；以后所有阳气在下次行动开始清空；煞气未用量返回业力池；阴气永久存在，直到被对应阳气对冲抵消；
   被动 `energyRetain` 字段匹配的阳气可至多保留 max 层到下回合，每保留 1 层结算一次代价伤害）
7. 产出结算：`produceTurnStartResources()`（元气 = 固定基准 kBattleBaseEnergy + 装备词条加成 battleEnergyBonus；
   有色气产出由流派境界节点状态脚本挂在 `self_produce_resources` 时机提供，如悟道「太上感应」），
   末尾派发 `self/opponent_produce_resources` 回调，刷新能量瓶
8. start_turn 被动注入（施加给对方的状态），刷新手牌预测与置灰状态
9. 出牌阶段（若标记跳过则略过本阶段）：
   - 玩家：点击卡牌 → `_enqueueCard`（`heroTurn` 守卫 + 费用硬检查，含队列占用）
     → `_processCardQueue` 依次 `_playCard`（`_payCardCost` 支付：
     无色扣元气层数，有色先扣本色气、缺口自动扣太极之气）→ 弃牌
   - 敌方：循环 `_canPayCardCost` 过滤可支付手牌 → AI 选牌 → 支付并出牌，直至无牌可出
10. 执行 `currentCharacter.onEndTurn()`：先还原回合级临时费用修正（`applyTurnCostModifier` 的记录），
    再派发回合结束回调（`self/opponent_turn_end`，悟道「阴阳五行」的灵气溢出伤害等挂这里）
11. 检查战斗结果；若未结束，读取额外回合标记，`clearHand()` 弃掉本回合手牌
12. 切换回合（`heroTurn = !heroTurn`），非己方回合整手置灰

额外回合（`turnFlags.extraTurn`）重复 1-10 后才会切换回合。每张牌完整结算并处理去向后也会检查战斗结果，已分出胜负时不再执行队列中的后续牌。

软狂暴遵循当前实现：当 `roundCount > 8` 后，每次普通行动回合开始前为当前角色赋予 1 层
`debuff_tribulation`，随后的回合开始回调消耗 1 层并使其失去当前战斗生命上限 10% 的生命；额外回合不重复赋予。

---

# 战斗回调契约（Dart ↔ Hetu）

战斗中的状态效果与卡牌效果通过回调函数在 Dart 与 Hetu 脚本之间协作。
本文档列出回调的派发规则、时机清单和 details 数据键的读写约定，
是编写/修改 `status_script.ht` 与 `card_script.ht` 的参考。

## 派发规则

- 状态回调：命名空间 `StatusScript`，函数名 = `{状态script字段}_{回调时机}`，
  如 `resistant` + `self_taking_damage` → `resistant_self_taking_damage`。
  函数签名固定为 `function (self, opponent, effect, details)`：
  `self`/`opponent` 是战斗角色对象，`effect` 是状态实例（可读数据条目上的自定义字段，
  如 `effect.damageType`、`effect.amount` 为层数）。
- 状态回调必须是**非阻塞**函数（不能 async）。
- 一个事件触发时，遍历持有者全部状态，声明了该时机（`callbacks` 字段）的才会执行；
  执行顺序：**永久状态 → 资源状态（阴阳气）→ 其他状态**。
- 卡牌脚本：命名空间 `CardScript`（统一签名 `(self, opponent, card, affix)`，
  主词条经 `card.affixes[0]` 访问），
  `priority` 为负数的额外词条在主词条**之前**执行，其余按 priority 降序执行；
  打出之外的词条时机回调（`callbacks` 字段，如入手 `added_to_hand`）见
  [卡牌词条回调](card/readme.md)（`docs/docs/mod/battle/card/readme.md`）。
- `details` 是一个共享 Map，**既是入参也是出参**：脚本写入的修正值会被 Dart 侧读取。

## 回调时机清单

| 时机                                                       | 说明                                                                                              |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `self/opponent_turn_start` / `self/opponent_turn_end`      | 自己/对方回合开始、结束                                                                           |
| `self/opponent_produce_resources`                          | 自己/对方回合资源产出阶段结束时（产出型效果挂这里；更早时机授予的阳气会被清残留冲掉）             |
| `self_scry`                                                | 自己观星结算后（details 携带 `{count, chosen}`）                                                  |
| `self/opponent_doing_damage`                               | 造成伤害时（可修改 damageDetails）                                                                |
| `self/opponent_taking_damage`                              | 受到伤害时（可修改 damageDetails，可写入 cancelDamage）                                           |
| `self/opponent_done_damage` / `self/opponent_taken_damage` | 造成/受到伤害后                                                                                   |
| `self/opponent_gained_energy_positive`                     | 获得阳气后（details 携带 `{id, amount}`）                                                         |
| `self/opponent_gained_debuff`                              | 获得负面效果后（一次获得多层只触发一次；可写入 cancelAmount 按层抵消）                            |
| `self/opponent_using_card` / `self/opponent_used_card`     | 使用卡牌时 / 后                                                                                   |
| `self/opponent_attacked` / `self/opponent_buffed`          | 使用攻击牌 / 加持牌后                                                                             |

按流派（genre）/套路（kind）细分用牌行为的现行模式：挂通用时机（如 `self_doing_damage`、`self_used_card`），
在脚本内按 `details.kind` / `getLastUsedCard()` 判定（参考 `increase_damage_*`、`element_cycle`）。
（`use_card_genre_*` / `use_card_kind_*` / `extra_turn` / `overflowed_energy` 等专用时机已无 Dart 派发点，停用。）

## damageDetails 键（伤害事件）

伤害结算公式：`(baseValue + baseChange) × (1 + percentageChange1) × (1 + percentageChange2) × (1 + percentageChange3)`，
之后依次结算暴击（仅物理）、护甲（仅物理/真气）。乘区 1 最小值为 -0.75。

| 键                                 | 方向 | 含义                                                                                                     |
| ---------------------------------- | ---- | -------------------------------------------------------------------------------------------------------- |
| `kind` / `cardType` / `damageType` | 入   | 攻击流派 / 卡牌类型 / 伤害类型                                                                           |
| `baseValue`                        | 入   | 伤害基础值                                                                                               |
| `isMain`                           | 入   | 是否来自主词条攻击（false 表示状态或额外词条造成的伤害）                                                 |
| `baseChange`                       | 出   | 基础值修正（数值加减）                                                                                   |
| `percentageChange1`                | 出   | 乘区 1：攻击增强/削弱、抗性、弱点、伤害增加（下限 -0.75）                                                |
| `percentageChange2`                | 出   | 乘区 2：闪避免疫（-0.75）、迟钝踉跄（+0.75）、三清法相元素增伤（每层 +1%）                               |
| `percentageChange3`                | 出   | 乘区 3：预留                                                                                             |
| `penetration`                      | 出   | 防御穿透 0~1（只作用于物理/真气；真气自带 0.5）；攻击方的 penetration 永久状态（由属性转换）每层额外 +1% |
| `cancelDamage`                     | 出   | 写 true 取消本次伤害（护盾）                                                                             |
| `isCritical`                       | 回   | takeDamage 写入：本次是否暴击                                                                            |
| `blocked` / `blockedAmount`        | 回   | takeDamage 写入：被护甲抵消的量                                                                          |

注意：攻击方的 `cardFlags['damage']` 中的 `baseChange/percentageChange*/penetration`
会在 takeDamage 开始时合并进 damageDetails。

## 被动的战斗机制字段（passives.json5）

天赋与装备词条（同为 `game.passives` 数据）可通过以下字段驱动通用战斗机制
（字段由 `characterSetPassive` / `characterSetEphemeralPassive` 透传，Dart 侧按字段读取，不识别内容 id）：

| 字段                | 类型                                               | 机制                                                                                                  |
| ------------------- | -------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `battleStatus`      | 状态 id                                            | 战斗开始授予对应永久状态（行为在状态脚本实现；天赋境界/分支节点与装备词条的统一入口）                  |
| `deckCostReduction` | `{color, amount, genres?, notGenres?}`             | 组牌阶段匹配卡牌的 color 色费用减 amount（下限 0；amount 为负即加费，如聚灵旗软流派锁）；`color: 'all'` 时命中卡 coloredCost 首个条目，加费方向允许作用于显式 0 费条目（0 → -amount） |
| `shuffleIntoDeck`   | `[卡牌主词条 id, ...]`                             | 战斗开始后洗入牌库（战斗重开去重，按主词条 id 查找已有卡）                                              |
| `turnStartScry`     | 整数                                               | 每回合开始时（抽牌前）观星 N 张（多来源累加）                                                           |
| `turnStartExtraDraw` | `{count, costIncrease?: {amount, notGenres?}}`    | 回合开始正常抽牌后额外抽 count 张（多来源累加）；通过此效果抽到、且主词条 genre 未命中 notGenres 的卡，coloredCost 首个条目本回合 +amount（允许 0 → amount），增费记录写在卡上，弃牌/出牌/下回合开始（保留卡巡检）时还原（天机盘） |
| `energyRetain`      | `{resourceId, max, costPerPoint, costDamageType?}` | 回合开始清残留时该资源至多保留 max 层到下回合，每保留 1 层受到 costPerPoint 点伤害（缺省纯粹）          |
| `statsBonus`        | `{statsId: 数值}`                                  | 通用 stats 直加：聚合时将各项累加进 character.stats（如 scryBonus 观星深度、ailmentInflictBonus/ailmentReceiveBonus 元素异常层数修正；绝世装备主词条等固定词条用） |

参数型效果另可经 stats 属性管线新增属性（如观星深度 `scryBonus`），
聚合与面板显示见 `.agents/skills/passive-status` 第 6 节。

**费用（单资源模型，见 plan/battle_resource_rework.md）**：每张卡只花一种资源——
流派卡 = rank 点流派色（悟道=灵气/御剑=剑气/锻体=怒气/炼魂=煞气），中立卡（含法身）= rank+1 点元气；
费用在数据层显式写入 coloredCost（含 life 键；显式 life: 0 = 免费卡）。
打出前做硬检查——无色费用 ≤ 元气层数，每色需求 ≤ 本色存量 + 太极存量。
其他阴气对费用的影响通过阴阳对冲体现（阴气抵消阳气，阳气不足则无法支付）。
支付时先扣本色气、缺口自动扣太极之气（`kWildcardStatusId`）。

动态费用使用 `{base, isDynamic: true}`：base 是最低门槛，达到后支付全部对应资源，
卡面显示 X 或 N+X。动态条目不参与减费和置零，加费只提高最低门槛。
队列按顺序预占资源；`paidCost` 记录实际支付量，具体契约见 [卡牌回调](card/readme.md)。
玩家和敌方使用相同支付计算，敌方元气耗尽后仍会筛选可支付的有色牌及免费牌，
直到没有候选手牌或战斗结束。

## debuffDetails 键（获得负面效果事件）

| 键             | 方向 | 含义                                                                       |
| -------------- | ---- | -------------------------------------------------------------------------- |
| `id`           | 入   | 本次获得的负面效果 id                                                      |
| `amount`       | 入   | 本次获得的层数                                                             |
| `cancelAmount` | 出   | 抵消的层数（辟邪按层抵消，消耗等量辟邪）；旧键 `cancelDebuff` 弃用但仍兼容 |

若持有者拥有天赋 `gained_debuff_affect_opponent`，未被抵消的层数会传播给对手
（对手获得同样的 id 与剩余层数）；被抵消的部分不会传播。传播不再触发任何回调（防止双方互传死循环）。

## cardFlags 字段（出牌期间，`角色.cardFlags`）

每次出牌时重置并写入：

| 字段                      | 含义                                                                                                       |
| ------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `category`                | attack / buff                                                                                              |
| `genre` / `kind`          | 学类 / 流派                                                                                                |
| `cardType` / `damageType` | 主词条的卡牌类型 / 伤害类型                                                                                |
| `damage.total`            | 本张牌已造成的总伤害（takeDamage 累加）                                                                    |
| `damage.penetration` 等   | 脚本可写入（如正气消耗后 +0.2），出牌时合并进伤害                                                          |
| `paidCost`                | 本张牌实际支付明细（状态 id → 实际扣除层数，含元气与太极抵扣；0 费卡为空表），支付时写入，费用返还词条读取 |

## turnFlags 字段（回合期间，`角色.turnFlags`）

每回合开始时重置：

| 字段                        | 含义                                                    | 写入方                    |
| --------------------------- | ------------------------------------------------------- | ------------------------- |
| `isExtra`                   | 本回合是额外回合                                        | onStartTurn               |
| `skipTurn`                  | 跳过本回合（缓慢达到阈值）                              | speed_slow 脚本           |
| `extraTurn`                 | 获得额外回合（迅捷达到阈值）                            | speed_quick 脚本          |
| `invincible` / `staggering` | 闪避/迟钝达到阈值后的免伤/踉跄                          | dodge_nimble/clumsy 脚本  |
| `defensePersisted`          | 护甲保留标记（有 persistent 状态）                      | defense 脚本              |
| `guaranteedCrit`            | 下一次物理攻击必定暴击（幸运）                          | energy_positive_crit 脚本 |
| `guaranteedAilment`         | 下一次元素攻击必定造成异常，每满 10 点伤害 1 层（幸运） | energy_positive_crit 脚本 |
| `totalDamage`               | 本回合造成的总伤害（戾气结算用）                        | takeDamage 累加           |

---

# 绝世卡牌约定

- 绝世卡牌（主词条数据 `isUnique: true`）使用**固定名字**，不按 kind 随机生成：
  卡名以 `uniquecard_{主词条id}` 为本地化键，保存在 `assets/locale/zh/rpg/battlecard.json`。
  **新增绝世卡牌时必须同步添加该键**，否则卡名会显示为原始键名。
- 绝世卡牌的额外词条是预定义的：主词条数据的 `affixes` 列表按境界顺序解锁
  （总数 = rank + 1），词条 id 来自 `card_affixes.json5`。
- 绝世卡牌不能进行灵宝/神照/真定/坐忘精炼，只能混元（重 roll 词条数值）与破境。
- 卡组中只能放入一张相同 uniqueId 的绝世卡牌；生成时默认未鉴定，需要鉴定卷轴鉴定后使用。
