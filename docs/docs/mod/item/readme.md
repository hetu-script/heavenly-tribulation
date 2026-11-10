# 物品与装备数据

## 装备属性要求

装备种类的主属性、基础值和等级系数集中定义于 `lib/data/constants.dart` 的 `kEquipmentAttributeRequirementProfiles`：

```dart
{
  'sword': {'attribute': 'dexterity', 'base': 0, 'factor': 1.5},
}
```

普通装备和 `items.json5` 中的可装备原型在生成时按实际等级计算：

```text
attributes[attribute] = base + ceil(level × factor)
```

### 原型覆盖

可装备原型可使用可选字段 `attributeRequirement`，按字段覆盖所属 `kind` 的默认配置：

```json5
attributeRequirement: {
  attribute: "spirituality",
  base: 10,
  factor: 1.5,
},
```

`factor: 0` 可表达固定要求。该字段是生成配置，不是角色最终看到的要求数值。

### 运行时字段

- `attributes`：物品实例上的最终 `{属性ID: 数值}` 要求，由生成公式产生，悬浮提示和装备检查共用。
- `isInvalid`：玩家已装备物品的派生状态。属性不足时不提供词条、功能或卡牌装备条件，但仍占用栏位，并计入类别数量与绝世重复限制。不要写入物品原型。
- 无效装备的来源仍保留在 `passivesRaw`；聚合层跳过这些来源，属性恢复后自动重新生效。
- 卸下时清除 `isInvalid`。NPC 忽略装备属性要求，物品转移或切换英雄后按新装备者重新计算。

卡牌装备需求只承认生效装备；栏位占用、装备类别限制和绝世重复检查使用占用口径，不能混用。
