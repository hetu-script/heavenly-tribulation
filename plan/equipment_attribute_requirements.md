# 装备属性要求实施计划

> 状态：已按本计划实施。
>
> 目标：让玩家在天赋树中的属性投入转化为稳定的装备构筑能力，同时保留卡牌跨流派组合的自由度。NPC 忽略装备属性要求，避免扩大 NPC 加点与装备生成系统的改造范围。

## 1. 设计决定

- 装备要求由 `kind` 决定，不写入 `passives.json5` 的主词条。主词条是随机效果，不能承担装备身份。
- 第一版每件装备最多要求一种主属性；暂不做双属性、境界或流派硬限制。
- 要求随装备实际 `level` 成长，而不是只按 `rank` 分档。
- 绝世装备默认继承所属 `kind` 的规则，可在 `items.json5` 原型上覆盖。
- 玩家装备验收使用“常驻属性”：基础属性加永久被动来源，排除装备与临时增益，避免装备互相支撑及卸下装备后的连锁失效。
- 已装备物品在属性下降后可以进入 `isInvalid` 状态：不提供词条、功能或卡牌装备条件，但仍占用栏位并受装备数量限制。
- NPC 忽略装备属性要求，其装备始终有效；物品转移到玩家身上后必须按玩家属性重新判断。
- 所有当前及新增装备 `kind` 都必须有明确配置，由校验器检查，不能静默获得意外规则。

## 2. kind 与主属性分配

所有种类的第一版 `base` 均为 0。`factor` 是装备等级的系数，最终向上取整。

| kind     | category | 主属性         | factor |
| -------- | -------- | -------------- | -----: |
| `sword`  | weapon   | `dexterity`    |    1.5 |
| `sabre`  | weapon   | `strength`     |    1.5 |
| `spear`  | weapon   | `perception`   |    1.5 |
| `staff`  | weapon   | `perception`   |   1.25 |
| `bow`    | weapon   | `willpower`    |   1.25 |
| `dart`   | weapon   | `willpower`    |    1.5 |
| `pearl`  | talisman | `spirituality` |    1.5 |
| `shield` | shield   | `strength`     |    1.0 |
| `armor`  | armor    | `strength`     |   1.25 |
| `gloves` | gloves   | `dexterity`    |    1.0 |
| `helmet` | helmet   | `willpower`    |    1.0 |
| `boots`  | boots    | `dexterity`    |   1.25 |
| `ship`   | vehicle  | `perception`   |    1.0 |
| `ring`   | jewelry  | `spirituality` |    1.0 |
| `amulet` | jewelry  | `spirituality` |   1.25 |

这套分配与现有 NPC 流派武器生成规则一致：御剑使用剑，锻体使用刀，炼魂使用弓和暗器，法身使用棍杖和枪矛。悟道没有固定武器，其灵力要求主要由宝珠、戒指和护身符承载。防具与其他部位会引导玩家进行适度的横向属性投入，而不是让所有部位都只要求本流派属性。

## 3. 常量与数据契约

### 3.1 集中定义 kind 配置

在纯常量模块 `lib/data/constants.dart` 中定义：

```dart
const kEquipmentAttributeRequirementProfiles = <String, Map<String, dynamic>>{
  'sword': {'attribute': 'dexterity', 'base': 0, 'factor': 1.5},
  // 其余 kind 按第 2 节完整列出。
  'ring': {'attribute': 'spirituality', 'base': 0, 'factor': 1.0},
};
```

字段含义：

- `attribute`：`kBattleAttributes` 中的属性 ID。
- `base`：固定基础要求，第一版全部为 0。
- `factor`：装备等级系数，必须为非负数。

不建议拆成多个按 kind 对齐的独立表，避免属性、基础值和系数在后续修改中发生错位。

### 3.2 等级公式

```text
attributeRequirement = base + ceil(level × factor)
attributes = { attribute: attributeRequirement }
```

不同系数的关键等级结果：

| 装备等级 | factor 1.5 | factor 1.25 | factor 1.0 |
| -------: | ---------: | ----------: | ---------: |
|       15 |         23 |          19 |         15 |
|       35 |         53 |          44 |         35 |
|       65 |         98 |          82 |         65 |

以 65 级装备为例，主属性初始约 50 的角色需要约 10/7/3 个 +5 属性节点；初始约 25 的非主属性需要约 15/12/8 个节点。第一版可通过这些结果判断属性投入是否形成足够但不过度的长期压力。

### 3.3 绝世装备原型覆盖

`assets/data/items.json5` 的可装备原型可使用可选字段：

```json5
attributeRequirement: {
  attribute: "spirituality",
  base: 10,
  factor: 1.5,
},
```

规则：

- 原型字段按字段覆盖所属 `kind` 的默认配置，不要求重复完整填写。
- `factor: 0` 配合固定 `base` 可表达不随等级成长的固定要求。
- 未配置时完整继承 `kind` 规则。
- 不修改 `passives.json5` 中的 `isEquipmentMain` 词条来表达要求。
- 物品实例最终生成 `attributes: {属性ID: 数值}`，供显示与装备检查共同使用；`attributeRequirement` 是生成配置，`attributes` 是最终要求，两者不能混用。

### 3.4 装备有效状态

物品实例增加派生字段：

```text
isInvalid: bool
```

- `isInvalid` 属于当前装备者与物品要求的关系，不是物品永久内容。
- 状态保存在物品实例上，栏位仍只保存物品 ID，避免栏位和物品各存一份状态。
- 只有已装备且属于当前玩家角色的物品需要计算无效状态；未装备物品只显示要求，不提前标记无效。
- 卸下物品时清除 `isInvalid`，避免背包残留无效标记；再次装备时重新验收。
- NPC 装备始终保持有效，不沿用物品从其他角色带来的旧状态。
- 切换英雄、物品转移和装备者变化后必须重新计算，不能依赖旧快照。

## 4. 常驻属性与生效口径

### 4.1 常驻属性

新增统一的玩家属性查询，不直接读取 `character.stats`：

```text
常驻属性 = character[attribute]
         + passivesRaw[attribute] 中所有 sourceType != equipment 的来源贡献
```

- `ephemeralPassivesRaw` 全部排除。
- 装备来源全部排除，包括正在装备和准备装备的物品。
- 天赋树、永久剧情效果等继续计入。
- 数值贡献沿用 `calculatePassiveAffixContribution`，各来源先求和，再按现有聚合规则取整。
- 装备属性不计入要求，因此不存在“装备 A 支持装备 B，卸下 A 后 B 失效”的级联计算。

### 4.2 生效与占用必须分开

| 判断场景 | 无效装备是否计入 |
| --- | --- |
| 装备词条和属性加成 | 否 |
| 卡牌的 `equipment: sword` 等需求 | 否 |
| 船只、靴子等提供的地形移动能力 | 否 |
| 战斗中的装备功能查询 | 否 |
| 装备栏位占用 | 是 |
| 武器、护甲等类别数量限制 | 是 |
| 绝世装备 `uniqueId` 重复限制 | 是 |

无效装备仍可被卸下。类别数量和绝世重复限制继续计入，是为了避免原装备恢复有效后出现多件同类别或同绝世装备同时生效。

初次装备仍要求玩家属性达标；`isInvalid` 用于处理装备后的属性下降，而不是允许玩家提前穿上不达标装备。

## 5. 具体执行步骤

### 第一步：常量与纯计算函数

- 在 `lib/data/constants.dart` 增加完整的 `kEquipmentAttributeRequirementProfiles`。
- 在 `lib/logic/logic.dart` 增加纯函数：输入 `kind`、`level` 和可选原型覆盖，输出最终 `attributes` Map。
- 通过 `lib/data/binding.dart`、`scripts/main/binding/constants.ht` 导出所需常量，并在 `lib/app.dart` 绑定计算函数供 Hetu 使用。
- 不在 Dart 机制层写具体装备内容 ID；所有种类和原型差异均由配置驱动。

### 第二步：装备生成时固化要求

- `scripts/main/data/item/equipment.ht`：在装备等级确定后，根据 `kind + level` 生成 `attributes`。
- `scripts/main/data/item/item.ht`：`createItemById` 对可装备原型应用 `attributeRequirement` 覆盖，并在实际等级确定后生成最终要求。
- 普通装备、绝世装备和高境界奖励必须走同一公式。
- `ExtractedAffix` 虽然使用物品结构，但不是可穿戴装备，不生成装备属性要求。
- 不向 `passives.json5` 批量添加要求字段。

### 第三步：装备入口与 NPC 豁免

- 在角色脚本侧增加“常驻属性”和“未满足装备要求”的查询函数。
- `characterEquip` 在分配栏位前检查玩家装备要求；不满足时返回 `false`，不写装备栏、不加被动来源。
- 当装备者不是当前 `hero` 时跳过属性检查，保持 NPC 当前生成和自动装备流程不变。
- UI 必须检查装备返回值，失败时不播放成功音效、不显示成功状态，并展示缺少的属性与数值。
- `setHero` 后重算新英雄属性与装备有效性，并发送必要的刷新事件。
- NPC 物品转移给玩家后不携带永久有效特权，装备时仍按玩家常驻属性验收。

### 第四步：属性变化时刷新装备有效性

- 在 `characterCalculateStats` 的最前面、被动聚合之前刷新玩家已装备物品的 `isInvalid`。
- 刷新只读取基础属性和非装备永久来源，因此不依赖本次重算后的 `stats`，也不会形成循环依赖。
- `_recalculatePassiveGroup` 聚合时跳过 `sourceType == equipment` 且对应物品无效的 sources。
- 无效装备的原始来源继续保留在 `passivesRaw`，恢复有效后直接参与聚合，不重新添加来源，避免重复叠加。
- 玩家属性上升后装备自动恢复；属性下降后自动失效，不自动卸下。
- NPC 重算时直接保持其装备有效。

### 第五步：统一装备功能查询与卡牌需求

- 增加统一的 `isEquipmentActive` 纯判断：物品已装备且 `isInvalid != true`。
- `characterEquippedCategory`、`characterEquippedKind`、对应的 First 查询和地形移动能力只统计生效装备。
- 类别数量限制和 `characterEquippedUnique` 使用占用口径；必要时拆成明确命名的 Occupied 查询或增加 `activeOnly` 参数，不能复用错误的口径。
- `GameLogic.checkRequirements` / `checkCardRequirements` 改为显式接收角色，卡牌装备需求只承认生效装备，不再固定读取 `GameData.hero`。
- 同步检查 `lib/scene/battle/battle.dart`：无效装备导致的玩家卡牌需求失败仍按现有规则替换为空卡。
- 同步检查 `lib/scene/dungeon/dungeon_controller.dart`：敌人候选卡牌不能使用玩家装备做判断；NPC 按其装备永久有效规则处理。
- 同步卡组构建、卡牌库筛选和战前提示中的需求检查，确保它们与战斗组牌结果一致。

### 第六步：悬浮提示与无效装备 UI

- `GameData.getItemDescription` 显示最终 `attributes`，并根据当前查看角色标记已满足/未满足；NPC 查看时可注明其不受属性要求限制。
- 为 `buildItemHoverInfo`、背包和装备栏补充角色参数传递，避免悬浮提示始终读取玩家。
- 未鉴定装备仍不泄露详细词条，但始终显示基础属性使用要求。
- `ItemGrid` 读取 `itemData['isInvalid']`，显示红色边框或底色，并叠加已有的 `assets/images/item/invalid.png`。
- `lib/widgets/character/inventory/equipment_bar.dart` 和 `lib/scene/battle/equipments_bar.dart` 使用相同的无效提示语义；无效装备仍可右键卸下。
- 保持 NPC 物品栏忽略右键操作的现有行为。

### 第七步：校验、文档与技能约定

- `utils/data_validate/game_data_validate.dart`：校验配置中的属性 ID、`base/factor` 数值、原型覆盖结构，以及新增装备 `kind` 是否缺少明确配置。
- `docs/docs/how2play/rpg/item/equipment/readme.md`：补充 kind 主属性、等级公式、常驻属性、装备失效/恢复、生效与占用区别、NPC 豁免和绝世覆盖规则。
- `docs/docs/mod/`：补充 `attributeRequirement`、运行时 `attributes` 与派生 `isInvalid` 的数据契约，明确三者用途。
- `.agents/skills/unique-equipment/SKILL.md`：同步绝世原型的可选属性要求覆盖字段。
- 不修改卡牌属性、境界和流派限制；不实现打造耗时；不引入双属性要求。

## 6. 测试与验收

### 自动化测试

优先扩展现有 `test/equipment_requirement_test.dart`，并按实际改动补充 `greater_item_test.dart` 与 `unique_equipment_test.dart`：

1. 每个当前合法 `kind` 都有明确配置，属性 ID 合法。
2. 15/35/65 级在各系数下得到第 3.2 节的精确结果。
3. 固定 `base` 与绝世原型字段覆盖生效，高境界生成按最终等级重算要求。
4. 玩家常驻属性达标可装备，不达标时装备栏和被动来源均不变化。
5. 天赋永久属性计入；装备属性、聚灵阵和丹药临时属性不计入。
6. 玩家退点后装备变为无效，词条、移动能力和卡牌装备条件立即失效，但装备仍占用栏位。
7. 重新加点后装备恢复有效，原始词条来源不重复叠加。
8. 无效装备仍计入类别数量和绝世重复限制，可以正常卸下。
9. NPC 不满足属性要求也能装备并正常提供词条、移动能力和卡牌装备条件。
10. NPC 物品转移给玩家、调试切换英雄后会按新装备者重新计算。
11. 悬浮提示显示要求及满足状态，无效格子变红并显示 `invalid.png`，NPC 物品仍不能右键操作。
12. 秘境敌人候选卡牌不读取玩家装备，玩家战斗组牌与战前提示使用同一有效性口径。

### 标准验证命令

```bash
python build.py
flutter analyze
flutter test test/equipment_requirement_test.dart test/greater_item_test.dart test/unique_equipment_test.dart test/passive_aggregation_test.dart
dart run utils/data_validate/game_data_validate.dart
```

### 实机验收

- 玩家分别使用主属性、非主属性角色装备低等级和满级物品，观察属性节点投入带来的解锁过程。
- 对已装备物品退点使其失效，再重新加点使其恢复，检查词条、卡牌、移动能力和装备栏表现。
- 检查武器、防具、首饰、法器和至少一件绝世装备的生成、悬浮提示、装备、失效与卸下。
- 检查萃取物品不会被误加属性要求，打造产物会获得正确要求。
- 检查多个流派 NPC 的自动生成装备和卡牌，无需满足属性要求即可正常使用。
- 检查 NPC 装备转移和调试切换英雄后的状态刷新。

## 7. 后续调参原则

- 若主属性角色无需投入即可长期使用高等级装备，提高对应 `factor`，不要额外叠加境界限制。
- 若跨流派装备选择几乎不可行，优先降低轻装备系数或增加通用装备，不直接改为装备属性可互相支撑。
- 若属性节点挤占过多关键构筑节点，先调整系数和装备部位分布，再考虑提高天赋节点属性收益。
- 双属性装备、职业专属装备和境界硬限制均留待第一版数值验证后再评估。
