# 被动词条来源记录与聚合算法重构计划

> 本文是 `plan/greater_affix_rework.md` 的前置基础计划，目标是先把被动词条从“按 ID 累减等级”改为“按来源保存、按 ID 聚合”。
>
> 本期不实现太古、不调整卡牌/装备/丹药词条数量，也不改变丹药与聚灵阵的批次替换规则。`greater` 相关字段只预留快照位置，不在本期产生或消费。

## 1. 背景与判断

当前 `characterSetPassive` 以被动 ID 为键，直接执行以下操作：

- 新增来源时增加 `level`；
- 移除来源时减少 `level`；
- 根据合计等级重新计算一个最终 `value`；
- 合计等级不大于 0 时删除整个被动。

这个模型无法表达以下来源差异：

1. 同一被动 ID 的不同来源具有不同等级、数值公式或品质。
2. 同一被动 ID 的不同来源携带不同机制配置。
3. 两个固定机制来源只保留一个时，剩余来源仍应独立生效。
4. 卸下某件装备或退回某个天赋时，只应移除该来源，而不是从聚合结果中反推应减多少等级。
5. 后续主词条固有强化和太古额外词条需要在各自来源上采用不同算法，不能先合并等级再统一计算。

因此应先独立完成来源模型重构。太古重构随后只需要在“单个来源贡献”的计算阶段插入定制变换，不应再次修改穿脱、退点和临时被动的基本结构。

## 2. 目标与非目标

### 2.1 目标

- 增加角色原始被动来源数据 `passivesRaw` 与 `ephemeralPassivesRaw`。
- 原始来源记录成为唯一真值；现有 `passives` 与 `ephemeralPassives` 改为完全派生的聚合结果。
- 同一 ID 的每个来源独立保存完整词条快照、来源身份和有效等级。
- 穿脱装备、退天赋、单条临时效果覆盖及后续批次替换均不再依赖负等级。
- 普通数值按来源计算未取整贡献，按被动 ID 汇总后统一取整一次。
- 机制字段按各自契约从全部来源聚合，不再因相同 ID 而丢失来源。
- 重复执行属性重算具有幂等性，不会重复叠加 `statsBonus` 等派生属性。
- 保留现有最终 Map 的主要读取形状，减少 UI 与战斗代码的修改范围。
- 为后续 `isMain`、`isGreater`、`greater` 和 `greater.data` 提供明确接入点。

### 2.2 非目标

- 不实现太古生成、展示、锁定或定制机制。
- 不实现主词条固有数值强化。
- 不修改普通词条数值公式和境界数量表。
- 不实现装备破境。
- 不实现丹药/聚灵阵整套临时配置替换；本期只为其建立 Raw 数据基础。
- 不考虑旧存档兼容与迁移。

## 3. 最终数据模型

### 3.1 角色上的四组数据

```text
passivesRaw             永久被动原始来源，规范真值
passives                永久被动聚合结果，派生只读

ephemeralPassivesRaw    临时被动原始来源，规范真值
ephemeralPassives       临时被动聚合结果，派生只读
```

`passives` 与 `ephemeralPassives` 不得再被装备、天赋、丹药或场景代码直接写入。所有变更必须先修改对应 Raw，再通过统一聚合函数重建最终 Map。

`character.stats` 仍保存最终可供战斗和非战斗系统读取的属性及机制聚合结果，但不是被动来源真值。

### 3.2 Raw 的结构

两组 Raw 都采用 `Map<被动ID, Map<sourceKey, 词条快照>>` 的嵌套结构。内层使用 HTStruct/Map 而不是数组，使写入、更新和删除都可以直接按 key 完成：

```json5
passivesRaw: {
  turnStartExtraDraw: {
    "equipment:item_uid_a:0": {
      sourceKey: "equipment:item_uid_a:0",
      sourceType: "equipment",
      sourceId: "item_uid_a",
      affixIndex: 0,
      id: "turnStartExtraDraw",
      isMain: true,
      level: 1,
      description: "passive_turnStartExtraDraw_description",
      priority: 3490,
      turnStartExtraDraw: {
        count: 1,
        costIncrease: { amount: 1, notGenres: ["spellcraft"] },
      },
    },
    "equipment:item_uid_b:3": {
      sourceKey: "equipment:item_uid_b:3",
      sourceType: "equipment",
      sourceId: "item_uid_b",
      affixIndex: 3,
      id: "turnStartExtraDraw",
      isMain: false,
      level: 1,
      description: "passive_turnStartExtraDraw_description",
      priority: 3490,
      turnStartExtraDraw: {
        count: 1,
        costIncrease: { amount: 1, notGenres: ["spellcraft"] },
      },
    },
  },
}
```

上例中两个来源都应被保留。聚合后的 `stats.turnStartExtraDraw.count` 为 2；移除其中任意一个后应为 1，而不是丢失整个机制。

### 3.3 单条来源记录字段

必备身份字段：

- `sourceKey`：单个词条来源的稳定唯一键，用于幂等更新和精确移除。
- `sourceType`：来源类别，如 `equipment`、`passive_tree`、`script`、`potion`、`exp_array`。
- `sourceId`：来源拥有者 ID，如装备 UID、天赋节点 ID、临时批次 ID。
- `affixIndex`：来源对象内的词条位置；没有该概念时可为 null。
- `id`：被动词条 ID，必须与 Raw 外层 key 一致。

必备或可选词条快照：

- `level`：本来源有效等级；纯机制词条统一使用 1。
- `rank`：词条自身境界；没有时使用 null。
- `base`、`increment`：普通数值计算参数。
- `description`、`priority`、`isDecrement`、`keywords`：展示与排序所需字段。
- `isMain`：是否在来源对象中担任主词条。普通装备/丹药在入账时按词条位置显式写入，不能依赖原型用途标记猜测。
- `battleStatus`、`deckCostReduction`、`shuffleIntoDeck`、`turnStartScry`、`turnStartExtraDraw`、`energyRetain`、`statsBonus`：机制字段快照。
- `isPermanent`：仅临时来源使用；缺省不等于 true。
- `greater`、`isGreater`：本期只允许作为未来快照字段预留，不产生、不消费。

Raw 保存生成时的词条实例快照。Hetu 侧通过 `Object.create(affix)` 创建独立实例：对 HTStruct 会调用 `clone()`，其自有字段及嵌套的 List、Map、HTStruct 均递归深拷贝。随后在该实例上写入 `sourceKey/sourceType/sourceId/affixIndex/isMain` 等来源元数据，不修改共享游戏数据。

`Object.create/clone` 会保留原型引用，因此“字段深拷贝”不等于“完全脱离原型”。本项目的词条数据字段必须在生成时已经成为实例自有字段；聚合只读取快照自有字段，不通过原型链补取数值或机制配置。如果以后允许关键字段只存在于自定义原型上，快照工厂必须先把这些字段显式物化，不能依赖原型引用充当快照。

Raw 中的 `value` 不作为永久被动的计算真值。普通永久来源应由 `base/increment/level` 重算贡献；传入的物品展示用 `value` 不直接覆盖聚合结果。后续临时太古若确需保存特殊快照，必须另行明确其生成与重算规则。

### 3.4 派生 `passives` 的结构

继续以被动 ID 为 key，每项至少包含：

- `id`、`description`、`priority`、`increment`；
- `level`：全部来源等级之和，仅用于展示和兼容旧读取，不再用于反推最终数值；
- `value`：全部来源数值贡献汇总后统一 `round` 的最终值；无数值来源时为 null；
- `sourceCount`：来源数量；
- 后续可增加 `greaterCount`，本期不生成。

最终 Map 不再承担机制来源保存职责。战斗机制应从 Raw 聚合进 `character.stats`，不能依赖最终 Map 中“第一个来源留下的机制字段”。

## 4. 来源键与写入规则

### 4.1 各类来源键

| 来源 | `sourceType` | `sourceId` | `sourceKey` 规则 |
| --- | --- | --- | --- |
| 装备词条 | `equipment` | 装备 UID | `equipment:{装备UID}:{affixIndex}` |
| 天赋节点词条 | `passive_tree` | 天赋节点 ID | `passive_tree:{节点ID}:{被动ID}` |
| 脚本授予 | `script` | 调用方必须提供的稳定来源 ID | `script:{sourceId}:{被动ID}` |
| 单条丹药效果 | `potion` | 丹药 UID 或调用方批次 ID | `potion:{sourceId}:{affixIndex}` |
| 聚灵阵效果 | `exp_array` | 本次冥想批次 ID | `exp_array:{批次ID}:{affixIndex}` |

装备、天赋和脚本授予都必须使用显式来源键。项目当前不需要旧 API 兼容，因此不设置隐式缺省来源，也不保留通过正负等级增减的调用方式。

### 4.2 写入语义

- 写入直接使用 `raw[id][sourceKey] = source`；同一 key 再次写入自然执行更新或幂等替换，不可能产生重复来源项。
- 不同 `sourceKey` 即使被动 ID 和词条内容完全相同，也必须保留为两个来源。
- 删除直接使用 `delete raw[id][sourceKey]`，不需要遍历来源数组。
- 删除后如果 `raw[id]` 为空，再执行 `delete raw[id]` 清理外层 key。
- 新 key 按 Map 写入顺序参与机制聚合；更新已有 key 保持原位置。需要明确顺序的机制不得使用无序遍历。
- 不再向 Raw 写入负等级来源。
- 同一来源对象的多条词条可以分别写入，全部完成后统一执行一次属性和机制重算。

## 5. 统一 API 与重算生命周期

### 5.1 新 API

在 `scripts/main/data/character/battle_entity.ht` 提供以下职责明确的函数，名称可按项目脚本风格微调：

```text
characterAddPassiveSource(character, source, {isEphemeral = false})
characterRemovePassiveSource(character, dataId, sourceKey, {isEphemeral = false})
characterRemovePassiveSourcesByOwner(character, sourceType, sourceId, {isEphemeral = false})
characterRefreshEquipmentPassives(character, item)
characterRecalculatePassives(character)
```

规则：

- `characterAddPassiveSource` 只负责 Raw upsert，不直接修改最终 Map 或 stats。
- `characterRemovePassiveSource` 通过被动 ID 和 sourceKey 直接删除一个来源。
- `characterRemovePassiveSourcesByOwner` 用于穿脱装备等按拥有者整体移除的场景。
- `characterRecalculatePassives` 从两组 Raw 全量重建两个最终 Map，不计算角色基础属性。
- `characterCalculateStats` 开头必须调用 `characterRecalculatePassives`，随后重新生成 stats，保证任何调用方都无法长期读取到过期结果。
- 多条词条变更完成后统一调用一次 `characterCalculateStats`。

### 5.2 旧永久接口移除与单条临时辅助

彻底移除 `characterSetPassive(character, dataId, {level})`，不提供兼容包装：

- 装备穿脱、天赋解锁/退点全部改用显式来源 API。
- `Player.gainPassive/refundPassive` 等脚本入口同步改为来源写入/移除接口，调用方必须提供稳定来源身份。
- 清除 Dart、Hetu、声明、注释和测试中的旧函数引用，避免新内容再次走负等级路径。
- `characterHasPassive` 等只读查询继续读取派生 `passives`，不受影响。

`characterSetEphemeralPassive` 可以保留为领域辅助函数，但它不再是旧聚合算法的一部分：

- 内部只对一个明确的临时 sourceKey 执行 Raw upsert。
- 同 ID、同 sourceKey 再次调用自然覆盖对应 Map 项。
- 后续仅主词条丹药可继续使用该语义，批次入口则直接构建 Raw 配置。

### 5.3 清除与生命周期

- 战斗结束清除临时被动时，从 `ephemeralPassivesRaw` 删除所有 `isPermanent != true` 的来源，再重算；不得只清最终 Map。
- 永久来源保留在 Raw 中，战后重建后仍存在。
- 后续整套临时配置替换只需替换 Raw 中的目标来源集合，不需要另建一套聚合算法。
- 角色初始化同时创建四个空 Map，不保留只初始化最终 Map 的旧路径。

## 6. 普通数值聚合算法

本期仅处理现有普通公式，不实现太古变换。

### 6.1 单来源贡献

对具有 `base` 或 `increment` 的来源：

```text
rawContribution = (base ?? 0) + (increment ?? 0) × (level ?? 1)
```

- 每个来源保留未取整数值。
- 不在单来源阶段调用 `round`。
- 纯机制来源没有数值贡献，不因此生成虚假的 `value: 0`。

当前数据中的被动原型没有实际 `base/maxLevel` 条目，因此这一迁移不会改变现有普通数值词条的预期公式。旧 `maxLevel` 不再写入 Raw，后续由太古主计划统一清理遗留参数和旧调用代码。

### 6.2 按 ID 汇总

```text
finalValue = round(sum(全部来源的 rawContribution))
displayLevel = sum(全部来源的 level)
```

- 最终只取整一次。
- `displayLevel` 仅用于展示，不参与最终值反推。
- 永久与临时两组分别汇总，不跨组求和。
- 不同被动 ID 流入同一属性时，仍按现有属性公式使用各 ID 的最终值。

### 6.3 后续太古接入点

太古主计划实施后，单来源阶段改为：

```text
ordinary = 当前来源的普通未取整贡献
mainAdjusted = 主词条固有强化（仅未来规则允许时）
greaterAdjusted = 太古强化（仅未来 isGreater == true 时）
rawContribution = 对应变换后的贡献
```

随后仍按同一被动 ID 汇总并取整。装备、天赋和临时效果的 Raw 结构、移除方式与机制遍历不再改变。

## 7. 机制字段聚合算法

机制字段不能只取来源 Map 的首项或末项。每个字段按自己的契约消费全部来源：

| 字段 | 聚合规则 |
| --- | --- |
| `battleStatus` | 普通原型机制按“被动 ID＋状态 ID”只生成一份基础绑定；需要数值作为状态层数时读取该被动 ID 的最终 `value`，无值时计 1。多个来源不重复增加同脚本触发次数。未来 `greater.data` 的新状态由定制消费方按来源单独处理。 |
| `deckCostReduction` | 按 Raw 来源顺序拼接全部规则；永久来源组先于临时来源组。 |
| `shuffleIntoDeck` | 按来源拼接卡牌 ID，战斗侧继续负责查重。 |
| `turnStartScry` | 所有来源求和。 |
| `turnStartExtraDraw` | 所有来源 `count` 求和；`costIncrease` 按稳定来源顺序由后者覆盖，保持现有契约。 |
| `energyRetain` | 所有来源按 `resourceId` 合并，`max` 取大，代价沿用首个配置。 |
| `statsBonus` | 所有来源逐键求和；每次重算必须从干净基值开始，不得在旧 stats 上累加。 |

普通数值型 `start_battle_with_*` / `start_turn_with_*` 不属于上述机制字段，继续从最终永久/临时 Map 读取聚合后的 `value`。

`status_script.ht` 中仍直接遍历最终 Map 读取 `energyRetain` 的逻辑，应改为读取 `character.stats.energyRetain` 的统一聚合结果，避免与新的来源模型产生两套口径。

## 8. 属性重算的幂等性

当前 `statsBonus` 在旧 `character.stats` 上执行增量加法，重复重算可能重复累计。此次必须一起修复：

1. 每次 `characterCalculateStats` 都从角色基础属性和 Raw 来源重新生成全部被动派生字段。
2. 不在上一轮 stats 的被动派生值上继续加减。
3. 对确需保留的非被动运行时 stats 字段建立明确白名单，不能靠偶然的旧对象残留保存。
4. `reset` 参数不再决定被动结果是否正确；无论是否 reset，同一 Raw 和基础属性都应得到相同被动派生结果。
5. 连续调用两次 `characterCalculateStats`，最终 Map 与 stats 必须完全一致。

## 9. 现有调用方迁移

### 9.1 装备穿脱

涉及 `scripts/main/data/character/battle_entity.ht`：

- 装备时遍历 `item.affixes`，为每条词条生成独立 Raw 快照。
- 按数组位置写入 `affixIndex` 和 `isMain`，`sourceId` 使用装备 UID。
- 全部词条写入后统一重算。
- 卸装时按 `sourceType: equipment + sourceId: 装备UID` 删除该装备的全部来源。
- 增加 `characterRefreshEquipmentPassives(entity, item)`：已装备物品的词条、等级或太古状态发生变化时，按相同 sourceKey 集合重新生成并替换该装备的 Raw 来源，然后统一重算。后续养剑升级装备时必须调用该同步入口，不能只修改物品快照。
- 同步刷新与穿脱使用同一份“装备词条 → Raw 来源”构建函数，避免两条路径字段不一致。
- 不再遍历词条执行负等级 `characterSetPassive`。
- 重复装备校验仍在写入前完成，避免失败路径留下 Raw 来源。

### 9.2 天赋解锁与退点

涉及 `lib/logic/character.dart`：

- 解锁节点时，为该节点每个被动写入显式 `passive_tree` 来源。
- 属性节点选择同样记录节点 ID，不与装备或其他节点的同 ID 属性合并来源。
- 退点时按节点 ID 删除来源，不再传负等级。
- 天赋预览和最终角色数据均通过同一聚合结果读取。

### 9.3 丹药、聚灵阵和其他脚本

涉及 `scripts/main/data/character/battle_entity.ht`、`scripts/main/binding/player.ht`、`lib/logic/logic.dart`：

- 本期保持丹药逐条生效、同 ID 临时效果覆盖的旧行为，只把底层存储改为 Raw。
- 聚灵阵本期仍逐轮生效，不提前实现第二份计划的待生效批次。
- 审核 `decreaseTribulationDifficulty` 等直接写入入口，统一走临时 Raw 兼容 API。
- 后续第二份计划再以批次 ID 管理这些来源。

### 9.4 战斗与展示读取

- `lib/scene/battle/battle.dart` 继续读取最终 `passives/ephemeralPassives` 的数值和 stats 的机制结果。
- 对方施加类状态也应同时检查永久与临时最终 Map，修复当前只读取永久来源造成的临时效果失效。
- `lib/data/game.dart` 继续读取最终 Map，因此常规角色被动说明不需要按来源重画。
- 装备与丹药悬浮提示仍读取物品自身词条快照，不读取角色聚合值。
- 需要调试来源时增加开发模式输出，不改变普通玩家 UI。

## 10. 分阶段实施顺序

### 阶段一：隔离实现 Raw 模型与纯函数测试

1. 初始化四组 Map，新增来源记录结构和 CRUD API。
2. 实现普通数值按来源未取整贡献、按 ID 汇总取整。
3. 实现七类机制字段的纯聚合函数。
4. 先完成同 ID 多数值来源、精确移除、重复重算及重复机制来源测试。
5. 本阶段只在隔离测试中调用新函数，不切换正式角色数据，也不删除旧 API。

### 阶段二：原子切换全部生产写入路径

1. 装备穿脱与装备词条同步改为完整快照和按拥有者移除/刷新。
2. 天赋解锁/退点改为节点来源。
3. 丹药、聚灵阵、其他临时写入和战后清除同步迁移到 Raw，保留当前玩法行为。
4. 从 Raw 接入七类机制字段聚合，将直接读取最终 Map 机制字段的消费者迁移到 stats。
5. 修复 `statsBonus` 重复重算累计和临时对方状态未读取的问题。
6. 让 `characterCalculateStats` 自动重建最终 Map，并在同一切换中移除 `characterSetPassive` 及其全部声明和调用。
7. 不得拆成“先删旧 API、后迁移调用方”或“先启用派生重建、后迁移临时写入”的中间状态。

### 阶段三：总回归与冻结基础模型

1. 验证同 ID 装备、同 ID 天赋及装备与天赋混合叠加。
2. 重点验证两个 `turnStartExtraDraw` 来源及移除其中一个后的结果。
3. 完成普通战斗、装备穿脱、装备词条同步、天赋退点、丹药和聚灵阵端到端检查。
4. 冻结该基础模型后，再开始太古数值变换和临时配置整体替换。

## 11. 测试计划

项目已有 Flutter/Hetu 测试方式，可新增 `test/passive_aggregation_test.dart`，直接执行真实脚本函数。

### 普通数值

- 两个同 ID、`increment: 0.5`、各 1 级的来源合计最终值为 1，验证未逐来源提前取整。
- 两个同 ID、不同等级来源的总值与合计等级展示正确。
- 移除高等级来源后只保留低等级来源，最终值立即正确。
- 永久和临时同 ID 分别聚合，不跨组错误求和。
- 纯机制来源不生成数值 0，也不影响其他数值来源。

### 来源与移除

- 两个完全相同的装备词条因 `sourceKey` 不同而同时存在。
- 同一 `sourceKey` 重复写入只更新对应 Map 项，不产生第二个 key。
- 卸下两件含同 ID 词条装备中的一件，另一件仍完整生效。
- 已装备物品词条升级后，经 `characterRefreshEquipmentPassives` 同步只更新该装备来源，不重复叠加，也不影响其他来源。
- 退回天赋节点只移除节点来源，不移除同 ID 装备来源。
- 内层来源 Map 为空时，对应 Raw 外层 key 与最终 Map key 均被清理。
- Raw 与派生 Map 经一次保存/加载往返后来源身份、嵌套机制配置和聚合结果保持一致。
- `characterSetPassive` 不再存在，全部旧调用点均已迁移到显式来源 API。

### 机制与重算

- 两个 `turnStartExtraDraw` 来源 count 为 2，移除一个后为 1。
- 两个 `statsBonus` 来源正确求和，连续重算两次结果不变。
- `deckCostReduction` 规则数量与顺序正确。
- `shuffleIntoDeck` 不丢失来源，战斗查重逻辑不变。
- `energyRetain` 合并结果与 `yin_yang_five_elements` 使用同一份 stats 数据。
- 数值型 `battleStatus` 使用最终聚合值，同脚本不因多来源重复触发。
- 对方施加类临时状态在战斗准备阶段能够读取。

### 临时生命周期

- 单条同 ID 临时效果保持覆盖语义，不产生意外重复来源。
- 战斗结束删除非永久 Raw 来源并重建最终 Map。
- `isPermanent == true` 的临时来源在战后保留。
- 永久被动不受临时清除影响。

## 12. 验证命令

```bash
flutter test
flutter analyze
python build.py
```

本计划不修改 JSON5 数据结构时，无需仅为该重构运行游戏数据校验；若同步调整被动原型字段，则追加：

```bash
dart run utils/data_validate/game_data_validate.dart
```

人工验收：

1. 同时装备两件含有相同数值词条的装备，卸下其中一件并检查属性。
2. 同时装备天机盘与聚灵旗，确认额外抽牌为 2，卸下一件后为 1。
3. 多次穿脱带 `statsBonus` 的装备，确认数值不持续增长。
4. 解锁并退回与装备同 ID 的天赋，确认只移除天赋贡献。
5. 重复使用同 ID 丹药效果并完成战斗，确认覆盖和清除行为符合本期兼容规则。

## 13. 完成标准

- `passivesRaw/ephemeralPassivesRaw` 是被动来源的唯一真值。
- `passives/ephemeralPassives` 完全由 Raw 派生，业务代码不再直接改写。
- 同 ID 多来源能正确叠加、覆盖或按机制契约聚合。
- 移除任一来源不会影响其他来源，也不再使用装备/天赋负等级反推。
- 普通数值按来源计算未取整贡献，并按 ID 最终取整一次。
- 重复属性重算幂等，机制字段和 `statsBonus` 不会残留或重复累计。
- 现有 UI 与战斗主要读取路径继续工作，临时对方状态读取缺口得到修复。
- 后续太古只需扩展单来源贡献计算与定制机制消费，不再需要改动来源存储和移除模型。
