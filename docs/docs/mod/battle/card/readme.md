# 卡牌词条回调（CardScript）

卡牌效果由词条驱动。词条脚本是 `scripts/main/cardgame/card_script.ht` 中
`CardScript` 命名空间下的函数，由 Dart 侧在对应时机调用：

- **打出时（on-play）**：`lib/scene/battle/character.dart` 的 `BattleCharacter.onUseCard`
- **其他时机回调**（如入手）：`lib/scene/battle/battle.dart` 的 `BattleScene.handleCardAffixCallback`

卡牌数据在 `assets/data/cards.json5`（主词条），额外词条池在 `assets/data/card_affixes.json5`。
卡面描述中的 `{0}`、`{1}` 占位符按词条 `value` 列表（由 valueData 求值）从 0 开始插值。

---

## 统一签名

所有词条脚本（打出时与时机回调）的签名统一为：

```hetu
function attack(self, opponent, card, affix) {
  opponent.takeDamage({
    isMain: true,
    kind: affix.kind,
    cardType: affix.cardType,
    damageType: affix.damageType,
    baseValue: affix.value[0],
  })
}
```

| 参数       | 含义                                                                                                |
| ---------- | --------------------------------------------------------------------------------------------------- |
| `self`     | 出牌方战斗角色（`BattleCharacter` 外部类）                                                          |
| `opponent` | 对方战斗角色                                                                                        |
| `card`     | 卡牌数据本体（BattleCard struct），可读写其字段（如 `card.isRetained`，Dart 侧经 `card.data` 读取） |
| `affix`    | 本词条数据（可读 `value` / `buffId` / 自定义字段，如 `attributeId`）                                |

需要主词条时通过 `card.affixes[0]` 访问（`final mainAffix = card.affixes[0]`）；
打出主词条本身时 `affix` 即主词条。

---

## 打出时（on-play）

每张卡牌的 `affixes` 列表中，首个词条是主词条（决定卡名、插画、动画与费用），其余为额外词条。
打出卡牌时，每个声明了 `script` 字段的词条都会执行一次脚本（函数名 = `script` 字段）。

执行顺序（`onUseCard`）：

1. 写入 `cardFlags`（category / genre / kind / cardType / damageType / damage 累计表）
2. 派发状态回调 `opponent_using_card` / `self_using_card`
3. `priority < 0` 的额外词条（按 priority 降序）——可能在主词条之前生效的增益
4. 主词条（先播放 `animation`，再执行脚本）
5. `priority >= 0` 的额外词条（按 priority 降序）——可读取主词条造成的伤害等联动
6. 元素牌联动（抱真守一 / 五行轮转）、`self_attacked` / `self_buffed` 等收尾回调
7. 无条件记录 `turnFlags['lastUsedCard'] = card`（本回合上一张打出的牌引用，
   供 `matchLastUsedCard` / `getLastUsedCard` 读取，见下文「上一张打出的牌」；
   记录点在所有词条脚本之后 → priority<0 的词条读到的是真正的「上一张」）
8. 派发状态回调 `opponent_used_card` / `self_used_card`

**Dart 侧对每个词条脚本统一 `await`**（同步脚本的 await 是空操作）。因此调用了
异步 BattleCharacter 方法（`drawCards` / `scry` / `upgradeHandCards`）的词条脚本
**必须声明 `async` 并在脚本内 `await`**（如 `draw_cards` / `scry` / `scry_then_draw`）：
hetu 的 `await` 可挂起在这些方法返回的 Dart Future 上（与是否声明 external async 无关），
结算流程会暂停直至脚本完成（如观星交互期间，后续词条与队列中的下一张牌都会等待）；
漏写 async 的脚本，其异步方法会脱离结算顺序并发执行。
时机回调（`added_to_hand` / `removed_from_hand` 等）由 `handleCardAffixCallback`
**同步派发（不 await）**，时机回调脚本应保持同步。

`damageDetails` / `cardFlags` / `turnFlags` 的读写约定见
[战斗回调契约](../readme.md)（`../readme.md`）。

---

## 时机回调（callbacks）

打出之外，词条数据可以声明 `callbacks` 列表来响应其他时机：

```json5
retain: {
  id: "retain",
  // ...
  script: "retain",
  callbacks: ["added_to_hand"],
},
```

时机触发时，调用的函数名是 `{script}_{时机}`（与状态回调的命名规则一致），签名相同：

```hetu
function retain_added_to_hand(self, opponent, card, affix) {
  card.isRetained = true
}
```

规则：

- 词条没有 `script` 字段则不参与任何回调（含打出）。
- 声明了 `callbacks` 的词条仍然需要 `script` 字段作为函数名前缀；
  打出时无效果的词条需提供同名空函数占位（如 `CardScript.retain`），否则打出时会报错。
- 派发时遍历卡牌的全部词条（含主词条），主词条也可以声明 `callbacks`。

### 时机清单

| 时机                | 触发点           | 说明                                                                                                                                                                                                                              |
| ------------------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `added_to_hand`     | 卡牌进入手牌区时 | 触发源：抽牌（`drawCardsToHand`，含 filter 过滤抽牌）。洗牌后重新抽到同一张牌会**再次**触发（调息等词条需自行保证幂等，见 `removed_from_hand`）。不触发：观星（选中牌回牌库顶而非入手）、支付失败退回手牌、战斗重开时队列卡牌回手 |
| `removed_from_hand` | 卡牌离开手牌区时 | 触发源：打出（双方均在支付成功后、结算前派发；支付失败退回手牌的异常路径不触发）、回合结束清手牌（`clearHand`，含战斗重开回库；保留卡留手不触发）。不触发：观星等不经过手牌区的移动                                               |

---

## 词条数据字段速查

| 字段                      | 说明                                                                                                                                                                                    |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `script`                  | `CardScript` 中的函数名（打出时调用；时机回调为 `{script}_{时机}`）                                                                                                                     |
| `callbacks`               | 额外响应的时机列表（见上方时机清单）                                                                                                                                                    |
| `priority`                | 额外词条执行顺序：负数在主词条**之前**执行，其余在主词条之后按降序执行                                                                                                                  |
| `valueData`               | 数值表（`base` / `increment` / `rankIncrement` / `maxLevel`），由 `calcAffixValue` 求值为 `value` 列表                                                                                  |
| `buffId`                  | `self_buff` / `opponent_debuff` / `attack_debuff` 等脚本读取的状态 id                                                                                                                   |
| `keywords`                | 卡面附加说明的本地化标签（悬浮提示中展开为「标签 - 说明」）                                                                                                                             |
| `categories`              | 额外词条可附加的卡牌类别（`attack` / `buff`）                                                                                                                                           |
| `genres`                  | 额外词条限定的流派列表（缺省不限流派；如 `retain` 限御剑、`scry` 限悟道）                                                                                                               |
| `uniqueId`                | 同名限制：一张卡上同 uniqueId 的词条最多一个                                                                                                                                            |
| `rank`                    | 词条出现的最低卡牌境界                                                                                                                                                                  |
| `filter`                  | 条件子表（category/genre/cardType/kind/elementType 任意组合），脚本传给 matchCardCriteria 系 API；某字段值为 `true` 表示「该字段非空即可」                                              |
| `filterNon`               | `filter` 内的反选子表：其中每个字段要求卡牌该字段值**不等于**指定值；值 `true` 表示「该字段必须为空」（与正选 `true` =「非空即可」对称）。见下文「条件子表与占位约定」                  |
| `require`                 | 生成侧过滤子表：以主词条（`card.affixes[0]`）字段为准——值 `true` = 该字段非空、值为数组 = 字段值 ∈ 数组、其余 = 等值匹配；不满足则生成时跳过该词条。见下文「条件子表与占位约定」        |
| `resourceId`              | 资源气状态 id（如 `energy_positive_spell` 灵气），`increase_damage_by_energy_count` / `gain_resource_next_turn` / `attack_exhaust_energy` / `attack_with_energy_count_check` 等脚本读取 |
| `resourceThreshold`       | 资源门槛层数（缺省 1），与 `resourceId` 配套；达到门槛才生效                                                                                                                            |
| `debuffs`                 | 状态 id 列表，`heal_remove_debuffs` 读取并整层移除（如 water_mend 甘霖术列全部 7 种元素异常）                                                                                           |
| `isWildcardCostForbidden` | 主词条标记（合并到卡牌实例）：费用禁止以无极之气抵扣，必须本色气全额支付（如绝世·万法归宗）                                                                                             |

---

## 现有脚本清单

整理自 `card_script.ht`，按用途分组：

### 牌库操作

| 函数             | 效果                                                                                                                                                                                                 |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `draw_cards`     | 抽 `value[0]` 张牌；词条可附 `filter` / `reduceCost` 条件子表（字段：category/genre/cardType/kind/elementType）                                                                                      |
| `scry`           | 观星 `value[0]` 张（缺省 3）：查看牌库顶 N 张，选一张放回牌库顶，其余进弃牌堆；牌库为空不触发                                                                                                        |
| `scry_then_draw` | 观星 `value[0]` 张（缺省 5），随后抽 1 张牌（观星选中牌置顶后被正好抽回；如天机术）。**async 函数**：内部 `await` 保证时序；Dart 侧统一 await 词条脚本，观星交互期间结算暂停（契约见上文「打出时」） |

### 攻击

| 函数                               | 效果                                                                                                                                                                                                                                            |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `attack`                           | 造成 `value[0]` 伤害                                                                                                                                                                                                                            |
| `attack_multiple`                  | 造成 `value[0]` 伤害 × `value[1]` 次                                                                                                                                                                                                            |
| `attack_buff`                      | 造成 `value[0]` 伤害，自身获得 `buffId` 增益 `value[1]` 层                                                                                                                                                                                      |
| `attack_debuff`                    | 造成 `value[0]` 伤害，对手获得 `buffId` 减益 `value[1]` 层                                                                                                                                                                                      |
| `attack_multiple_debuff`           | 造成 `value[0]` 伤害 × `value[1]` 次，随后对手获得 `buffId` 减益 `value[2]` 层                                                                                                                                                                  |
| `attack_multiple_ailment`          | 造成 `value[0]` 伤害 × `value[1]` 次，随后按元素映射（`Constants.elementAilments`）附加本牌元素异常 `value[2]` 层（不经异常计数器，必然施加；如 wind_storm 风雷破）                                                                             |
| `attack_multiple_by_used_elements` | 段数 = 本回合已使用的不同元素种数（含本牌，读 `turnFlags['usedElements']`，至少 1 段），每段 `value[0]` 伤害（如 chain_lightning 连环闪电；`usedElements` 契约见下文）                                                                          |
| `attack_multiple_by_cards_in_hand` | 段数 = 手牌中完全符合 `affix.filter` 条件的卡牌数（如 `filter: {elementType: true}` 匹配任意元素牌；不含打出的本牌——双方出牌前均已移出手牌区），每段 `value[0]` 伤害（如 ice_storm 寒冰风暴）                                                   |
| `attack_with_energy_count_check`   | `resourceId` 资源气层数 ≥ `resourceThreshold`（缺省 1）时本次伤害 +`value[1]`%（乘区1，写入 takeDamage 明细），造成 `value[0]` 伤害；可选尾部：`value` 有第 3 元素时按元素映射附加元素异常 `value[2]` 层（不经计数器；如 falling_stone 陨星术） |
| `attack_exhaust_energy`            | 耗尽 `resourceId` 指定的全部剩余资源气（不含已支付费用），每点造成 `value[0]` 伤害（如 fire_storm 焚天烈焰）                                                                                                                                    |
| `attack_rank_scaled`               | 造成 角色境界 × 5 伤害（默认卡基础拳法用）                                                                                                                                                                                                      |

### 增益 / 减益

| 函数                                      | 效果                                                                                                    |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `speed_quick_defend`                      | 自身速度 +`value[0]`，护甲 +`value[1]`                                                                  |
| `dodge_nimble_defend`                     | 自身闪避 +`value[0]`，护甲 +`value[1]`                                                                  |
| `speed_quick` / `dodge_nimble` / `defend` | 原子函数：单一状态 +`value[0]`（速度/闪避/护甲），供数据层自由组合                                      |
| `gain_defense_by_mana`                    | 获得 = 当前灵气层数 ×`value[0]` 的护甲（灵气层数上限 `value[1]`，超出的不转化；如 stone_shield 岩甲术） |
| `buff_lifemax`                            | 自身生命上限 +`value[0]`（并回复等量生命）                                                              |
| `debuff_lifemax`                          | 对手生命上限 -`value[0]`                                                                                |
| `heal`                                    | 自身生命 +`value[0]`                                                                                    |
| `heal_lifeMax`                            | 回复生命上限 `value[0]`% 的生命（可超过上限）                                                           |
| `heal_remove_debuffs`                     | 回复 `value[0]` 生命，并整层移除 `debuffs` 列表中的全部状态（如 water_mend 甘霖术）                     |
| `self_buff`                               | 自身获得 `buffId` 增益 `value[0]` 层                                                                    |
| `opponent_debuff`                         | 对手获得 `buffId` 减益 `value[0]` 层                                                                    |
| `opponent_reduce_resist_all`              | 对手全部元素抗性 -`value[0]`（以弱点形式附加）                                                          |
| `opponent_weaken_attack_all`              | 对手全部类型攻击力 -`value[0]`                                                                          |

### 资源转化

| 函数                | 效果                                                                                |
| ------------------- | ----------------------------------------------------------------------------------- |
| `heal_vigor_all`    | 消耗所有元气，每点回复生命上限 × `value[0]`% 的生命（归元功，费用恒 0，消耗走效果） |
| `convert_vigor_all` | 消耗所有元气，按 `value[0]`% 转化为 `buffId` 指定的气（费用恒 0，消耗走效果）       |
| `refund_cost`       | 按本牌实际支付量返还所消耗的气（读取 `cardFlags.paidCost`）                         |

### 绝世卡专属

| 函数                        | 效果                                                                                                                                                                                                |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `spellcraft_ultimate_spell` | 万法归宗：耗尽全部灵气（含已付费用），每点灵气造成 `value[0]` 雷电伤害                                                                                                                              |
| `ailments_by_used_elements` | 相生相克：对对手施加随机元素异常，种数 = 本回合已使用元素种数（读 `turnFlags['usedElements']`，至少 1 种），每种 `value[0]` 层；种类按 `Constants.elementAilments` 映射表不重复抽取，不经异常计数器 |

### 攻击联动（额外词条）

| 函数                            | 效果                                            |
| ------------------------------- | ----------------------------------------------- |
| `by_damage_heal`                | 本牌每造成 10 点伤害，自身生命 +`value[0]`      |
| `by_damage_defend`              | 本牌每造成 10 点伤害，自身护甲 +`value[0]`      |
| `for_attribute_increase_damage` | 按 `attributeId` 属性提升伤害（每点属性 +0.5%） |

### 时机回调

| 函数                                             | 时机                | 效果                                                                                                                                                                                          |
| ------------------------------------------------ | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `retain_added_to_hand`                           | `added_to_hand`     | 保留（御剑专属词条）：给卡牌添加 `isRetained` 标记，回合结束清理手牌时留在手牌中                                                                                                              |
| `reduce_cost_by_cards_in_hand_added_to_hand`     | `added_to_hand`     | 调息（悟道专属词条 attune）：入手时若手牌中有其他同元素牌，本牌费用 -`value[0]`（缺省 1，不低于 0）；实际减费量记录在 `card.costReduction`（{color, amount}），先按记录还原再重新检测（幂等） |
| `reduce_cost_by_cards_in_hand_removed_from_hand` | `removed_from_hand` | 调息：离开手牌区时按 `card.costReduction` 记录还原本牌费用                                                                                                                                    |

### 悟道流派专属（额外词条）

词条 id 用流派风味名（`attune` / `elemental_focus` / `ailment_spread` / `cycle_draw` / `mana_burst` / `mana_battery`），
script 用通用函数名；资源 id、过滤条件、阈值放词条数据，其他流派后续可复用同一套脚本函数
（数据见 `assets/data/card_affixes.json5`，设计见 `plan/skill_tree/spellcraft_extra_affix_rework.md`）。

| 函数                                | 效果                                                                                                         |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `increase_damage_by_last_card_used` | 上一张打出的牌与本牌同元素（`filter` 的 `'self'` 解析为本牌元素）时，本牌伤害 +`value[0]`%（乘区1）          |
| `ailment_spread`                    | 给对方施加 `value[0]` 层本牌元素对应的元素异常（`Constants.elementAilments` 查表；直接施加，不经异常计数器） |
| `draw_by_last_card_used`            | 上一张打出的牌与本牌不同元素（`filterNon` 反选排除本牌元素）时，抽 `value[0]` 张牌                           |
| `increase_damage_by_energy_count`   | 打出时 `resourceId` 资源气层数 ≥ `resourceThreshold`（缺省 1）时，本牌伤害 +`value[0]`%（乘区1）             |
| `gain_resource_next_turn`           | 下回合产出阶段额外获得 `value[0]` 层 `resourceId` 资源气（`turnFlags['pendingResources']` 标记，见下文）     |

---

## 条件子表与占位约定

悟道流派词条引入的通用机制，其他流派复用同一套脚本函数时同样适用。

### filterNon 反选子表

`filter` 条件子表（及一切走 `matchCardCriteria` 的入口：抽牌的 `filter` / `reduceCost`、
`getHandCards`、`upgradeHandCards`、`matchLastUsedCard`）支持可选 `filterNon` 反选子表：
其中每个字段要求卡牌该字段值**不等于**指定值；值 `true` 表示「该字段必须为空」
（与正选 `true` =「非空即可」对称）。`filterNon` 键不在匹配字段表内，正选循环自然忽略，单独处理。

例：`{elementType: true, filterNon: {elementType: "element_fire"}}` = 是元素牌但不是火系。

### 'self' 占位

`filter` / `filterNon` 中的字符串值 `'self'` 表示「**本牌主词条同名字段的值**」，
由 `CardScript._resolveCriteriaSelf(criteria, card)` 在执行前解析成具体条件表
（返回新表，不改动词条数据；`filterNon` 子表同样处理）。
任一 `'self'` 解析为 null（本牌无该字段，如非元素牌的 `elementType`）时整体返回 null，
调用脚本视为**条件不成立**，效果不触发——同元素（专注）/ 不同元素（轮转）两类词条共用一套模板。

### require 生成过滤

额外词条数据可声明 `require` 子表，由 `card.ht` 的 `_getSupportAffixes` 在生成时过滤，
以**主词条**（`card.affixes[0]`）字段为准：

- 值 `true` → 该字段非空（如 `require: {elementType: true}` 限定元素牌）；
- 值为数组 → 字段值 ∈ 数组（如 `require: {damageType: ["fire","ice"]}`）；
- 其余值 → 等值匹配。

不满足则跳过该词条（不进入随机池）。

### 上一张打出的牌（matchLastUsedCard / getLastUsedCard）

`onUseCard` 末尾（全部词条脚本执行完之后）无条件记录 `turnFlags['lastUsedCard'] = card`
（CustomGameCard 引用，非字段副本）：

- `self.matchLastUsedCard(criteria)` —— 本回合上一张打出的牌（主词条）是否完全符合
  criteria 条件（支持 `filterNon` 反选）；
- `self.getLastUsedCard()` —— 本回合上一张打出的牌的完整数据（BattleCard struct），无则 null。

`turnFlags` 回合开始清空 → 「上一张打出的牌」限定本回合；每回合首张打出的牌无上一张，
条件不成立。记录点在所有词条脚本之后 → priority<0 的词条读到的是真正的「上一张打出的牌」。

### turnFlags['usedElements'] 本回合已用元素

Dart 侧在元素牌（主词条 `elementType` 非空）结算完毕后无条件记录：
`turnFlags['usedElements']` 是 `Map<元素键, 使用次数>`，元素键取
`elementType ?? damageType`，回合开始随 turnFlags 清空。记录点同样在所有词条脚本之后，
因此打出中的本牌不在表中，`attack_multiple_by_used_elements` 等脚本需自行把本牌元素
补充去重（含本牌至少 1 段）。该键与悟道分支「五行轮转」（每种新元素灵气 +1）共用。

### turnFlags['pendingResources'] 生命周期

「下回合获得资源」类词条（如悟道 `mana_battery`）以 `turnFlags['pendingResources']`
（Map，键 = 资源气状态 id，值 = 累加层数）为跨回合标记，脚本直接读写 `self.turnFlags`：

- **写入**：词条脚本在 `pendingResources` 子表上对 `resourceId` 键累加层数；
- **存活**：`onStartTurn` 在 `turnFlags.clear()` 之前暂存该键、清空后放回
  —— 它是 turnFlags 中唯一跨清空保留的键（`reset()` 走统一清空，不保留）；
- **消费**：`produceTurnStartResources()` 末尾取出（remove）并逐个
  `addStatusEffect(statusId, amount)` 授予（非正数跳过）。
  授予不能提前到回合开始时：onStartTurn 之后紧跟 `clearResourceEffects()`
  （清上回合残留阳气），提前授予会被当场冲掉；只有产出阶段（排在清残留之后）授予才能存活。

### Constants.elementAilments 元素异常映射

`Constants.elementAilments`（Dart 常量 `kElementAilmentIds`，`lib/data/common.dart`）是
元素 → 元素异常的映射（对应关系以本地化 `status_element_ailment_description` 为准）：
**金:流血、木:中毒、水:冰缓（ailment_ice）、火:点燃（ailment_fire）、土:内伤、
风:幻觉、雷:感电**。

供 `ailment_spread` / `attack_multiple_ailment` / `attack_with_energy_count_check`
可选尾部等词条脚本**直接施加**元素异常查表——不经 takeDamage 的异常计数器，必然生效，
对抗面是辟邪（buff_ward 按层抵消获得的负面效果）；异常计数器保持 damageType 口径
（火/冰/雷/毒），幸运/不幸语义不变（决议见 `plan/skill_tree/spellcraft_extra_affix_rework.md` §7）。
