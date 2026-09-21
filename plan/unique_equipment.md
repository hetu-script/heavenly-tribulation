# 绝世装备（unique equipment）

绝世装备是预定义的特殊装备：词条 **id 固定**（数值仍按规则随机 roll），同一 id 的绝世装备身上只能装备一件（类比绝世卡牌在卡组中只能有一张），且获得时默认未鉴定。

## 已核实的现状机制

### 卡牌 id / uniqueId 机制（绝世装备照此模式）

- 每张 `BattleCard` 的 `id = crypto.randomUID(withTime: true)`（`scripts/main/cardgame/card.ht:94`），普通卡牌没有数据层 `uniqueId`。
- 绝世卡：`isUnique = mainAffix.isUnique`，`uniqueId = mainAffix.uniqueId ?? mainAffix.id`（card.ht:167-170），即以主词条 id 作为去重键。
- 引擎侧 `GameCard.uniqueId = uniqueId ?? id`（`samsara-engine/lib/cardgame/card.dart:126`）。
- 构筑去重两关（`lib/scene/card_library/deckbuilding_zone.dart` tryAddCard）：
  1. `containsCard(c.uniqueId)`（:349）——防同一实体卡重复入组；普通卡每张 id 不同，同种卡可多张进卡组。
  2. `isUnique && 数据层 uniqueId 重复`（:357-362）——绝世卡按词条 id 去重，返回 `deckbuilding_unique_card_exists`。

### 装备打造 / 析取（已实现，在工坊）

- `lib/widgets/view/workshop.dart`：
  - `craftEquipment()`（:146）调 Hetu `Equipment` 结构体，传 `affixes` 参数跳过随机词条（equipment.ht:143-149 分支）。
  - `extractAffix()`（:199）调 `ExtractedAffix` 结构体并销毁原装备。
  - 目前均**无 isUnique 处理**。

### createItemById 对预定义装备的够用性

`scripts/main/data/item/item.ht:75` 已支持：固定 rarity/rank（含 arcane）、affixes id 列表从 `game.passives` 实例化并随机 level/value（:130-151）、`isIdentified: false` 复用鉴定卷轴、createLoot 的 prototype 分支发放（:580-585）。

**注意**：非 ranked 且非 unstackable 的物品保留原型 id，重复获得会在背包堆叠（item.ht:105, :309-312）。绝世装备必须写 `isUnstackable: true` 使 id 变为随机 UID（与卡牌模式一致）。

## 设计决定

- 装备必须字段**不**由 createItemById 自动补，靠 items.json5 注释和文档约定。
- 词条数值允许随机，固定的只是词条 id 列表（现有 affixes 处理已够用，无需扩展数据格式）。
- 唯一性规则：**按 id 去重**——同一 id（由 `uniqueId` 字段携带原型 id）的绝世装备同时只能装备一件；不同 id 的绝世装备（即使同 kind）互不影响。
- **不**做世界唯一（不限制全存档存在数量）。
- 默认**需要鉴定**：数据中写 `isIdentified: false`，获得后需使用鉴定卷轴（类比绝世卡牌）。

## 待办

### 1. items.json5：注释约定 + 数据模板

在文件末尾 `/// 绝世装备` 注释下补充字段约定注释，并约定模板：

```json5
// 绝世装备（unique equipment）约定：
// 必须字段:
//   type: 'equipment'
//   category / kind: 必须为合法装备类别与种类（参考 Constants.equipmentCategoryKinds）
//   isEquippable: true
//   isUnstackable: true   // 必须！否则重复获得时会在背包堆叠
//   isUnique: true
//   uniqueId: 去重键，必须等于本条目 id（json5 键名）。
//     因为 isUnstackable 会使运行时 item.id 变为随机 UID，
//     唯一性检查只能用 uniqueId 字段，不能用 item.id
//   isIdentified: false   // 必须！绝世装备默认未鉴定，需使用鉴定卷轴
//   rarity: 通常为 'arcane'，rank 可不写（由 rarity 推导）
//   affixes: [词条id...]  // 词条 id 固定，level/value 生成时随机 roll
//   name / flavortext / icon: 本地化键与图标路径
// 可选字段:
//   isUntradable / isCursed 等通用物品字段
example_unique_sword: {
  id: "example_unique_sword",
  name: "example_unique_sword",
  flavortext: "flavortext_example_unique_sword",
  type: "equipment",
  category: "weapon",
  kind: "sword",
  rarity: "arcane",
  icon: "item/equipment/sword.png",
  isEquippable: true,
  isUnstackable: true,
  isUnique: true,
  uniqueId: "example_unique_sword",
  isIdentified: false,
  affixes: ["equipment_sword", "increase_damage_sword", ...],
},
```

### 2. 文档：docs/docs/how2play/rpg/item/equipment/readme.md

扩充「绝世 unique」章节：

- 词条 id 固定、数值随机的规则说明
- 同一 id 的绝世装备只能装备一件
- 获得时默认未鉴定，需使用鉴定卷轴（类比绝世卡牌）
- 不能词条析取（工坊中不可选为析取对象）
- 获取途径（预定义物品，按 prototype 发放，不经随机生成）
- 装备栏位表（3-8 随境界）保留不动——实现侧将改为跟随境界，见待办 7

### 3. 装备唯一性检查（核心新增逻辑）

- `scripts/main/data/character/battle_entity.ht` `characterEquip()`（:624）：装备前检查 `item.isUnique == true` 时，遍历 `entity.equipments` 比对 **item.uniqueId**（原型 id；注意不能比 item.id，运行时已被随机化），重复则拒绝并返回原因。放在这里可同时约束 NPC/敌人（battle_entity.ht:609 的 NPC 自动穿装备也走此函数）。
- `lib/widgets/character/stats_and_item.dart` equip 分支（:86-110）：参照现有 category 限制的写法，预先检查并弹提示。
- 本地化：新增提示 key（参照 `deckbuilding_unique_card_exists`、`*UnrestrictedEquip` 的命名）。

### 4. 鉴定（数据约定 + setHero 一处小改）

- 物品鉴定流程已存在：鉴定卷轴使用入口在 `lib/logic/logic.dart:1234-1239`（筛 `isIdentified: false` 的物品并置为已鉴定）；未鉴定时 UI 已禁止装备/使用（`lib/widgets/character/stats_and_item.dart:87,115,123`）。
- 数据中按约定写 `isIdentified: false`，获得后即为未鉴定状态。
- `setHero` 需补充与卡牌对称的逻辑（`scripts/main/data/game.ht:298-303`）：遍历 `hero.inventory`，非绝世物品自动鉴定（`isIdentified = true`），绝世物品保持未鉴定、需手动使用鉴定卷轴。保证初始装备/读档切换角色后规则一致。

### 5. 工坊禁止析取绝世装备

- `workshop.dart` 析取选择装备时过滤/拦截 `isUnique == true` 并提示。
- 本地化：新增提示 key（参照卡牌的 `craft_unique_forbidden_hint`）。

### 6. createItemById 小补（可选）

- 补建 `affixUniqueIds` Set（对齐 Equipment 构造器 equipment.ht:70, 94-98），保证两条创建路径产出的装备数据结构一致，便于将来装备侧词条操作查重。
- 其余字段按约定由数据保证，不加自动补全。

### 7. 装备栏位跟随境界

规则：可用栏位 = rank + 3（无境界 3、凝气 4、筑基 5、结丹 6、还婴 7、化神 8），与文档表一致。UI 始终显示全部 8 格，超出当前境界的格子为锁定态（不可装备），锁定格的美术资源后续补充。

现状存在多处不一致，一并梳理：

- `battle_entity.ht:152-164`：注释写「固定的 7 个」，实际 map 只有 '0'-'5' 共 6 键。
- `characterEquip`（battle_entity.ht:645）自动填 `range(kEquipmentMax)` = 0-4 共 5 格，第 6 格（'5'）只能显式 index 装入（assert 允许 <= 5）。
- 文档写 3-8 随境界。

改动点：

- 常量：`kEquipmentMax = 5` → 改为 `kEquipmentSlotMax = 8`（`lib/data/common.dart:409` 与 `scripts/main/data/common.ht:31` 同步；如需脚本侧访问经 `lib/data/constants.dart` / `scripts/main/binding/constants.ht` 导出）。
- 新增「当前可用栏位数」计算：`equipmentSlotCount(rank) = rank + 3`（clamp 到 8）。脚本侧放在 data/common.ht，Dart UI 侧按 character['rank'] 同样计算。
- `battle_entity.ht:156` equipments map 固定初始化为 '0'-'7' 共 8 键，注释更正。
- `characterEquip`：自动装备仅使用 index < equipmentSlotCount(entity.rank) 的格子；assert 改为 index < equipmentSlotCount(entity.rank)。
- UI：`lib/widgets/character/inventory/equipment_bar.dart` 渲染自 equipments map，map 改为 8 键后自然显示 8 格；对 index >= 可用数 的格子标记锁定态（暂不响应点击/悬停，视觉先用简单置灰，待美术资源）。`lib/scene/battle/equipments_bar.dart:59,66,89` 与 `lib/ui.dart:556` 中基于 kEquipmentMax 的循环和尺寸计算同步改为 8。
- 境界提升时无需迁移数据：map 始终 8 键，只是可用数变大。

## 待定

（原三项待定已决：按 id 去重、不做世界唯一、默认需要鉴定，见「设计决定」。）

- 世界唯一如未来需要，可参考 item.ht:80-88 注释掉的 isCreated 草稿。
