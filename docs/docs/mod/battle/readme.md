**玩家回合（heroTurn == true）与敌方回合（heroTurn == false）共用同一套流程（`_startTurn`）：**

1. 摸牌：`drawCardsToHand()`
2. 执行 `currentCharacter.onStartTurn()`：回合开始回调（死气/劫气失去生命、元素 DOT、缓慢跳过判定等）
3. 检查战斗结果：回合开始效果致死则立即结束，不进入后续阶段
4. 记录是否跳过出牌阶段（`turnFlags.skipTurn` 或空手空库），但不跳过资源与回合结束结算
5. 清空资源：`clearResourceEffects()`（每个角色第一次行动保留战初阳气；以后所有阳气在下次行动开始清空；煞气未用量返回业力池；阴气永久存在，直到被对应阳气对冲抵消）
6. 产出结算：`produceTurnStartResources()`（元气 rank+3 / 剑气=上回合所有武器牌数，包括攻击与加持 /
   怒气=上回合受伤÷10 / 灵气获取天赋+1 / 煞气从业力池提取），刷新能量瓶
7. start_turn 被动注入（施加给对方的状态），刷新手牌预测与置灰状态
8. 出牌阶段（若标记跳过则略过本阶段）：
   - 玩家：点击卡牌 → `_enqueueCard`（`heroTurn` 守卫 + 费用硬检查，含队列占用）
     → `_processCardQueue` 依次 `_playCard`（`_payCardCost` 支付：
     无色扣元气层数，有色先扣本色气、缺口自动扣无极之气）→ 弃牌
   - 敌方：循环 `_canPayCardCost` 过滤可支付手牌 → AI 选牌 → 支付并出牌，直至无牌可出
9. 执行 `currentCharacter.onEndTurn()`：先由 Dart 侧进行回合结束资源结算
   （灵气溢出天赋 → 元气回血），再派发其余回合结束回调
10. 检查战斗结果；若未结束，读取额外回合标记，`clearHand()` 弃掉本回合手牌
11. 切换回合（`heroTurn = !heroTurn`），非己方回合整手置灰

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
- 卡牌脚本：命名空间 `CardScript`（主词条，签名 `(self, opponent, affix, mainAffix)`）/
  `priority` 为负数的额外词条在主词条**之前**执行，其余按 priority 降序执行。
- `details` 是一个共享 Map，**既是入参也是出参**：脚本写入的修正值会被 Dart 侧读取。

## 回调时机清单

| 时机                                                       | 说明                                                                                                                                                                              |
| ---------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `self/opponent_turn_start` / `self/opponent_turn_end`      | 自己/对方回合开始、结束                                                                                                                                                           |
| `self/opponent_deck_start` / `self/opponent_deck_end`      | 自己/对方卡组第一张牌、最后一张牌                                                                                                                                                 |
| `self/opponent_consumed`                                   | 使用消耗牌后                                                                                                                                                                      |
| `self/opponent_heal`                                       | 恢复生命时（仅 changeLife 的 isHeal 分支触发）                                                                                                                                    |
| `self/opponent_doing_damage`                               | 造成伤害时（可修改 damageDetails）                                                                                                                                                |
| `self/opponent_taking_damage`                              | 受到伤害时（可修改 damageDetails，可写入 cancelDamage）                                                                                                                           |
| `self/opponent_done_damage` / `self/opponent_taken_damage` | 造成/受到伤害后                                                                                                                                                                   |
| `self/opponent_gained_energy_positive`                     | 获得阳气后                                                                                                                                                                        |
| `self/opponent_gained_debuff`                              | 获得负面效果后（一次获得多层只触发一次；可写入 cancelAmount 按层抵消）                                                                     |
| `self/opponent_gained_injury`                              | 获得伤势后                                                                                                                                                                        |
| `self/opponent_overflowed_energy`                          | 资源溢出时（details 含 overflow；返回 true 表示保留溢出值）。**当前无状态注册该时机**：溢出天赋已改为回合结束按剩余层数触发（Dart 侧回合结束资源结算），该派发保留但为空转 |
| `self/opponent_using_card` / `self/opponent_used_card`     | 使用卡牌时 / 后                                                                                                                                                                   |
| `self/opponent_attacked`                                   | 使用攻击牌后                                                                                                                                                                      |
| `self/opponent_use_card_kind_*`                            | 使用特定流派（kind）卡牌时                                                                                                                                                        |
| `self/opponent_use_card_genre_*`                           | 使用特定学类（genre）卡牌时                                                                                                                                                       |
| `self/opponent_extra_turn`                                 | 再次行动时                                                                                                                                                                        |

## damageDetails 键（伤害事件）

伤害结算公式：`(baseValue + baseChange) × (1 + percentageChange1) × (1 + percentageChange2) × (1 + percentageChange3)`，
之后依次结算暴击（仅物理）、护甲（仅物理/真气）。乘区 1 最小值为 -0.75。

| 键                                 | 方向 | 含义                                                      |
| ---------------------------------- | ---- | --------------------------------------------------------- |
| `kind` / `cardType` / `damageType` | 入   | 攻击流派 / 卡牌类型 / 伤害类型                            |
| `baseValue`                        | 入   | 伤害基础值                                                |
| `isMain`                           | 入   | 是否来自主词条攻击（false 表示状态或额外词条造成的伤害）  |
| `baseChange`                       | 出   | 基础值修正（数值加减）                                    |
| `percentageChange1`                | 出   | 乘区 1：攻击增强/削弱、抗性、弱点、伤害增加（下限 -0.75） |
| `percentageChange2`                | 出   | 乘区 2：闪避免疫（-0.75）、迟钝踉跄（+0.75）              |
| `percentageChange3`                | 出   | 乘区 3：预留                                              |
| `penetration`                      | 出   | 防御穿透 0~1（只作用于物理/真气；真气自带 0.5）；攻击方的 penetration 永久状态（由属性转换）每层额外 +1% |
| `cancelDamage`                     | 出   | 写 true 取消本次伤害（护盾）                              |
| `isCritical`                       | 回   | takeDamage 写入：本次是否暴击                             |
| `blocked` / `blockedAmount`        | 回   | takeDamage 写入：被护甲抵消的量                           |

注意：攻击方的 `cardFlags['damage']` 中的 `baseChange/percentageChange*/penetration`
会在 takeDamage 开始时合并进 damageDetails。

## buffDetails 键（资源溢出事件）

| 键         | 方向 | 含义           |
| ---------- | ---- | -------------- |
| `overflow` | 入   | 溢出的资源层数 |

返回值 true 表示保留溢出部分。当前无注册者；灵气溢出天赋的实际触发点为
回合结束资源结算（Dart 侧，按剩余层数，先灵气溢出、后元气回血）。

**费用（新费用体系）**：打出卡牌前做硬检查——无色费用 ≤ 元气层数，
每色需求 ≤ 本色存量 + 无极存量；虚空之气使所有有色费用 +1/层（无上限，唯一的增费机制）。
其他阴气对费用的影响通过阴阳对冲体现（阴气抵消阳气，阳气不足则无法支付）。
支付时先扣本色气、缺口自动扣无极之气（`kWildcardStatusId`）。

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

| 字段                      | 含义                                              |
| ------------------------- | ------------------------------------------------- |
| `category`                | attack / buff                                     |
| `genre` / `kind`          | 学类 / 流派                                       |
| `cardType` / `damageType` | 主词条的卡牌类型 / 伤害类型                       |
| `damage.total`            | 本张牌已造成的总伤害（takeDamage 累加）           |
| `damage.penetration` 等   | 脚本可写入（如正气消耗后 +0.2），出牌时合并进伤害 |

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
