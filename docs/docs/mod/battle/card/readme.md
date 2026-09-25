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
7. 派发状态回调 `opponent_used_card` / `self_used_card`

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

| 时机            | 触发点           | 说明                                                                                                                                                                      |
| --------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `added_to_hand` | 卡牌进入手牌区时 | 触发源：抽牌（`drawCardsToHand`，含 filter 过滤抽牌）、战斗开始授予卡（如「紫微斗数」）。不触发：观星（选中牌回牌库顶而非入手）、支付失败退回手牌、战斗重开时队列卡牌回手 |

---

## 词条数据字段速查

| 字段         | 说明                                                                                                   |
| ------------ | ------------------------------------------------------------------------------------------------------ |
| `script`     | `CardScript` 中的函数名（打出时调用；时机回调为 `{script}_{时机}`）                                    |
| `callbacks`  | 额外响应的时机列表（见上方时机清单）                                                                   |
| `priority`   | 额外词条执行顺序：负数在主词条**之前**执行，其余在主词条之后按降序执行                                 |
| `valueData`  | 数值表（`base` / `increment` / `rankIncrement` / `maxLevel`），由 `calcAffixValue` 求值为 `value` 列表 |
| `buffId`     | `self_buff` / `opponent_debuff` / `attack_debuff` 等脚本读取的状态 id                                  |
| `keywords`   | 卡面附加说明的本地化标签（悬浮提示中展开为「标签 - 说明」）                                            |
| `categories` | 额外词条可附加的卡牌类别（`attack` / `buff`）                                                          |
| `genres`     | 额外词条限定的流派列表（缺省不限流派；如 `retain` 限御剑、`scry` 限悟道）                              |
| `uniqueId`   | 同名限制：一张卡上同 uniqueId 的词条最多一个                                                           |
| `rank`       | 词条出现的最低卡牌境界                                                                                 |

---

## 现有脚本清单

整理自 `card_script.ht`，按用途分组：

### 牌库操作

| 函数         | 效果                                                                                                            |
| ------------ | --------------------------------------------------------------------------------------------------------------- |
| `draw_cards` | 抽 `value[0]` 张牌；词条可附 `filter` / `reduceCost` 条件子表（字段：category/genre/cardType/kind/elementType） |
| `scry`       | 观星 `value[0]` 张（缺省 3）：查看牌库顶 N 张，选一张放回牌库顶，其余进弃牌堆；牌库为空不触发                   |

### 攻击

| 函数                 | 效果                                                       |
| -------------------- | ---------------------------------------------------------- |
| `attack`             | 造成 `value[0]` 伤害                                       |
| `attack_multiple`    | 造成 `value[0]` 伤害 × `value[1]` 次                       |
| `attack_debuff`      | 造成 `value[0]` 伤害，对手获得 `buffId` 减益 `value[1]` 层 |
| `attack_rank_scaled` | 造成 角色境界 × 5 伤害（默认卡基础拳法用）                 |

### 增益 / 减益

| 函数                         | 效果                                           |
| ---------------------------- | ---------------------------------------------- |
| `speed_quick_defend`         | 自身速度 +`value[0]`，护甲 +`value[1]`         |
| `dodge_nimble_defend`        | 自身闪避 +`value[0]`，护甲 +`value[1]`         |
| `buff_lifemax`               | 自身生命上限 +`value[0]`（并回复等量生命）     |
| `debuff_lifemax`             | 对手生命上限 -`value[0]`                       |
| `heal`                       | 自身生命 +`value[0]`                           |
| `heal_lifeMax`               | 回复生命上限 `value[0]`% 的生命（可超过上限）  |
| `self_buff`                  | 自身获得 `buffId` 增益 `value[0]` 层           |
| `opponent_debuff`            | 对手获得 `buffId` 减益 `value[0]` 层           |
| `opponent_reduce_resist_all` | 对手全部元素抗性 -`value[0]`（以弱点形式附加） |
| `opponent_weaken_attack_all` | 对手全部类型攻击力 -`value[0]`                 |

### 资源转化

| 函数                | 效果                                                                                |
| ------------------- | ----------------------------------------------------------------------------------- |
| `heal_vigor_all`    | 消耗所有元气，每点回复生命上限 × `value[0]`% 的生命（归元功，费用恒 0，消耗走效果） |
| `convert_vigor_all` | 消耗所有元气，按 `value[0]`% 转化为 `buffId` 指定的气（费用恒 0，消耗走效果）       |
| `refund_cost`       | 按本牌实际支付量返还所消耗的气（读取 `cardFlags.paidCost`）                         |

### 绝世卡专属

| 函数                        | 效果                                                                   |
| --------------------------- | ---------------------------------------------------------------------- |
| `spellcraft_ultimate_spell` | 万法归宗：耗尽全部灵气（含已付费用），每点灵气造成 `value[0]` 雷电伤害 |

### 攻击联动（额外词条）

| 函数                            | 效果                                            |
| ------------------------------- | ----------------------------------------------- |
| `by_damage_heal`                | 本牌每造成 10 点伤害，自身生命 +`value[0]`      |
| `by_damage_defend`              | 本牌每造成 10 点伤害，自身护甲 +`value[0]`      |
| `for_attribute_increase_damage` | 按 `attributeId` 属性提升伤害（每点属性 +0.5%） |

### 时机回调

| 函数                   | 时机            | 效果                                                                             |
| ---------------------- | --------------- | -------------------------------------------------------------------------------- |
| `retain`               | （打出时占位）  | 空函数，打出时无效果                                                             |
| `retain_added_to_hand` | `added_to_hand` | 保留（御剑专属词条）：给卡牌添加 `isRetained` 标记，回合结束清理手牌时留在手牌中 |
