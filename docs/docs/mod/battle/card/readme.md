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
3. `priority < 0` 的额外词条（按 priority 降序）——可能在主词条之前生效的增益；
   有依赖关系的词条必须显式使用不同 priority，不能依赖同优先级的排序结果
4. 元素转化：负优先级词条结算完毕后，按对方当前持有的对应异常决定最终 damageType；
   转化成功时消耗 1 层异常，并更新 `cardFlags['damageType']`。因此落雷击顶等词条可让本次伤害立即转化
5. 主词条（先播放 `animation`，再执行脚本）
6. `priority >= 0` 的额外词条（按 priority 降序）——可读取主词条造成的伤害等联动
7. 元素牌使用记录（`turnFlags['usedElements']`，元素牌无条件记录，供 chain_lightning 等词条
   与五行轮转等状态结算本回合元素种数）、`self_attacked` / `self_buffed` 等收尾回调
8. 无条件记录 `turnFlags['lastUsedCard'] = card`（本回合上一张打出的牌引用，
   供 `matchLastUsedCard` / `getLastUsedCard` 读取，见下文「上一张打出的牌」；
   记录点在所有词条脚本之后 → priority<0 的词条读到的是真正的「上一张」）
9. 派发状态回调 `opponent_used_card` / `self_used_card`（抱真守一 / 五行轮转等元素牌联动
   以状态脚本挂在此时机，经 `getLastUsedCard()` 读取刚打出的牌）

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
- 派发时遍历卡牌的全部词条（含主词条），主词条也可以声明 `callbacks`。
- 函数存在性规则：打出时对每个带 `script` 的**额外词条**无条件 invoke 基名，基名允许缺省
  （纯回调词条），缺失时忽略并由解释器日志告警一次（`ignoreUndefined`）；
  **主词条**基名与声明的 `{script}_{时机}` 回调函数必须存在，缺失会抛出脚本错误并中断结算。

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
| `valueData`               | 数值表（`base` / `increment` / `rankIncrement` / `maxLevel`），由 `calculateCardAffixValue` 求值为 `value` 列表                                                                         |
| `buffId`                  | `self_buff` / `opponent_debuff` / `attack_debuff` 等脚本读取的状态 id                                                                                                                   |
| `keywords`                | 卡面附加说明的本地化标签（悬浮提示中展开为「标签 - 说明」）                                                                                                                             |
| `categories`              | 额外词条可附加的卡牌类别（`attack` / `buff`）                                                                                                                                           |
| `genres`                  | 额外词条限定的流派列表（缺省不限流派；如 `retain` 限御剑、`scry` 限悟道）                                                                                                               |
| `uniqueId`                | 同名限制：一张卡上同 uniqueId 的词条最多一个                                                                                                                                            |
| `rank`                    | 词条出现的最低卡牌境界                                                                                                                                                                  |
| `filter`                  | 条件子表（category/genre/cardType/kind/elementType 任意组合），脚本传给 matchCardCriteria 系 API；某字段值为 `true` 表示「该字段非空即可」                                              |
| `not`                     | `filter` 内的反选子表：其中每个字段要求卡牌该字段值**不等于**指定值；值 `true` 表示「该字段必须为空」（与正选 `true` =「非空即可」对称）。见下文「条件子表与占位约定」                  |
| `require`                 | 生成侧过滤子表：以主词条（`card.affixes[0]`）字段为准——值 `true` = 该字段非空、值为数组 = 字段值 ∈ 数组、其余 = 等值匹配；不满足则生成时跳过该词条。见下文「条件子表与占位约定」        |
| `resourceId`              | 资源气状态 id（如 `energy_positive_spell` 灵气），`increase_damage_by_energy_count` / `gain_resource_next_turn` / `attack_by_paid_resource` / `attack_with_energy_count_check` / `gain_defense_by_mana` 等脚本读取 |
| `resourceThreshold`       | 资源门槛层数（缺省 1），与 `resourceId` 配套；达到门槛才生效                                                                                                                            |
| `debuffs`                 | 状态 id 列表，`heal_remove_debuffs` / `heal_remove_debuffs_by_stack` 等脚本读取 |
| `genre`                   | 单词条流派参数，供回合级流派费修、跨回合流派增伤等脚本读取；与随机池过滤字段 `genres` 区分 |
| `threshold` / `count`     | 通用门槛 / 次数参数；元素异常种数判定、条件抽牌等脚本读取 |
| `inUnpackable`            | 额外词条为 `true` 时不进入随机额外词条池，只能由绝世卡预定义列表固定授予；主词条沿用“不进卡包/随机池”语义 |
| `isWildcardCostForbidden` | 主词条标记（合并到卡牌实例）：费用禁止以太极之气抵扣，必须本色气全额支付（如绝世·万法归宗） |

### 纯数据修饰字段

无 `script` 的词条不参与打出回调；宿主主脚本可遍历 `card.affixes`，收集这些字段后兑现。
所有机制字段均由主词条与额外词条共用校验器检查结构、类型和嵌套引用。

**观星 `scryOptions`**（`scry_then_draw` 汇总；数值键累加、布尔键取真）：

| 键 | 类型 | 含义 |
| --- | --- | --- |
| `chosenCostChange` / `othersCostChange` | 数值 | 选中 / 未选牌费用变化；未选牌加费以卡上标记保证本场战斗只生效一次 |
| `upgradeChosen` | 数值 | 选中牌战斗内升级 N 级 |
| `retainChosen` | 布尔 | 选中牌获得保留 |
| `scryBonus` | 数值 | 本次观星额外查看 N 张，与角色 `stats.scryBonus` 累加 |

**元素抉择**：主词条 `discoverOptions` 为 `{hint, choices: [{key, cardId}]}`，
`elementStatusMap` 为 `{元素key: 状态id}`。`discover_element_amplify` 收集以下额外词条字段：

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `guardValue` | 数值 | 下次受到所选元素伤害时获得 N 层护盾，兑现后消耗 |
| `chosenDamageTakenReduce` | 数值 | 本回合受到所选元素伤害 -N%，不消耗 |
| `mirrorMana` | 数值 | 对手使用所选元素牌后，自己下回合产出 +N 灵气 |
| `chosenCostReduce` | 数值 | 本回合手牌中所选元素牌费用 +N（负数即减费） |
| `amplifyPerMana` | 数值 | 打出时每点灵气使**自身**增幅 +N%；对方只获得主词条基础增幅 |

**抽牌修饰**（`ziwei_draw` 对 `lastDrawnCards[0]` 兑现，全部修饰完成后才处理额外抽牌）：

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `drawnUpgrade` | 数值 | 抽到的牌战斗内升级 N 级 |
| `drawnRetain` | 布尔 | 抽到的牌获得保留 |
| `drawnManaIfGenre` | `{genre, resourceId, count?}` | 抽到指定流派牌时获得 count 层 resourceId（缺省 1） |
| `drawnExtraDrawIfNotGenre` | `{genre, count?}` | 未抽到指定流派牌时额外抽 count 张（缺省 1），不再套用首张修饰 |

**状态实例参数 `statusParams`**：负优先级词条通过 `apply_status_params` 把子表累计到
`cardFlags['statusParams']`；`self_buff` 授予状态时经 `addStatusEffect(params:)` 合并并清空。
数值键按增量叠加（如默认 10 加 -3 得 7），字符串和布尔直接覆盖。状态脚本读取实例字段，
从而只修改本次所授状态，不污染全局状态原型。

## 条件子表与占位约定

### 动态费用 coloredCost

数据条目支持 `{base, rankIncrement?, isDynamic?}`，`rankIncrement` 默认 0。
普通条目求值为整数；动态条目求值为 `{base: 最低门槛, isDynamic: true}`，并深拷贝到
`originalColoredCost` 作为显示基线。动态 base 为 0 仍保留，卡面显示 `X`；正数显示 `N+X`。

动态费用不参与任何减费或费用置零。加费提高最低门槛，临时加费到期还原基础门槛。
支付时达到门槛后耗尽对应资源，太极只补最低门槛缺口，不随 X 一并耗尽；
`isWildcardCostForbidden` 可禁止该抵扣。X 允许为 0。

资源在词条及状态的用牌回调之前支付，实际扣除量记录在 `cardFlags['paidCost']`。
`attack_by_paid_resource` 读取 `affix.resourceId` 的实际支付量乘以 `value[0]` 造成伤害，
支付量为 0 时跳过伤害；效果结算中新获得的气不会再次扣除。
队列按顺序模拟支付，动态费用预占执行到该位置时的全部本色气。

Samsara 沿用现有绘制位置和字号显示 `X` / `N+X`，本次不处理文字溢出。

### not 反选子表

`filter` 条件子表（及一切走 `matchCardCriteria` 的入口：抽牌的 `filter` / `reduceCost`、
`getHandCards`、`upgradeHandCards`、`matchLastUsedCard`）支持可选 `not` 反选子表：
其中每个字段要求卡牌该字段值**不等于**指定值；值 `true` 表示「该字段必须为空」
（与正选 `true` =「非空即可」对称）。`not` 键不在匹配字段表内，正选循环自然忽略，单独处理。

例：`{elementType: true, not: {elementType: "element_fire"}}` = 是元素牌但不是火系。

### 'self' 占位

`filter` / `not` 中的字符串值 `'self'` 表示「**本牌主词条同名字段的值**」，
由 `CardScript._resolveCriteriaSelf(criteria, card)` 在执行前解析成具体条件表
（返回新表，不改动词条数据；`not` 子表同样处理）。
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
  criteria 条件（支持 `not` 反选）；
- `self.getLastUsedCard()` —— 本回合上一张打出的牌的完整数据（BattleCard struct），无则 null。

`turnFlags` 回合开始清空 → 「上一张打出的牌」限定本回合；每回合首张打出的牌无上一张，
条件不成立。记录点在所有词条脚本之后 → priority<0 的词条读到的是真正的「上一张打出的牌」。

### turnFlags['usedElements'] 本回合已用元素

Dart 侧在元素牌（主词条 `elementType` 非空）结算完毕后无条件记录：
`turnFlags['usedElements']` 是 `Map<元素键, 使用次数>`，元素键取
`elementType ?? damageType`，回合开始随 turnFlags 清空。记录点同样在所有词条脚本之后，
因此打出中的本牌不在表中，`attack_multiple_by_used_elements` 等脚本需自行把本牌元素
补充去重（含本牌至少 1 段）。该键与悟道分支「五行轮转」（每种新元素灵气 +1）共用。

### 抽牌 / 产能中间结果与跨回合效果

- `cardFlags['lastDrawnCards']`：Dart 在每次 `drawCardsToHand` 开始时覆盖为空列表，
  再按实际入手顺序记录卡牌数据；一张未抽到时也保持空列表。紫微斗数先读完首张修饰，
  再执行可能覆盖该记录的额外抽牌。
- `cardFlags['lastManaGained']`：蓄灵诀主词条写入本次计算的灵气获得数，未获得也写 0，
  供纳气之后、灵气回响、反噬成道读取，避免吃到上一次打出的残留。
- `turnFlags['pendingResources']`：下回合资源表，键为资源状态 id、值为累加层数。
  `onStartTurn` 清空前暂存并放回，`produceTurnStartResources` 取出并授予（非正数跳过）。
  必须延迟到清空残留之后的产出阶段，提前授予会被 `clearResourceEffects` 冲掉。
- `turnFlags['pendingEffects']`：跨回合效果队列，与 `pendingResources` 一样跨回合开始清空保留。
  `{type: 'genreDamageBonus', genre, percent, oneShot: true}` 在下回合首张匹配流派牌打出时消费；
  `{type: 'pendingSelfDamage', amount, damageType}` 在下回合产出阶段消费并移除。
  战斗重置（`reset()`）统一清空这两类标记。

### Constants.elementAilments 元素异常映射

`Constants.elementAilments`（Dart 常量 `kElementAilmentIds`，`lib/data/common.dart`）是
元素 → 元素异常的映射（对应关系以本地化 `status_element_ailment_description` 为准）：
**金:流血、木:中毒、水:冰缓（ailment_ice）、火:点燃（ailment_fire）、土:内伤、
风:幻觉、雷:感电**。

供 `ailment_spread` / `attack_multiple_ailment` / `attack_with_energy_count_check`
可选尾部等词条脚本**直接施加**元素异常查表——不经 takeDamage 的异常计数器，必然生效，
对抗面是辟邪（buff_ward 按层抵消获得的负面效果）；异常计数器保持 damageType 口径
（火/冰/雷/毒），幸运/不幸语义不变（决议见 `plan/skill_tree/spellcraft_extra_affix_rework.md` §7）。
