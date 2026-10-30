# 装备与丹药主词条固有数值设计备忘

> 状态：仅记录设计方向，暂不实施。
>
> 本文用于替代 `plan/greater_affix_rework.md` 中“共享被动原型作为主词条时，默认复用 `greater.values`”的构想。后续制定逐词条太古方案和实施太古重构前，应先审核本文，再同步修改主计划。

## 1. 背景

装备与丹药的主词条和额外词条可能引用同一个被动原型，并采用相同的普通数值公式。额外词条太古化后，可能出现同名太古额外词条数值高于主词条的情况。

为让主词条具有基础强度优势，`greater_affix_rework.md` 曾规定：共享原型担任主词条时，在当前物品等级下复用 `greater.values`，但不获得太古品质、不设为满级，也不消费 `greater.data` 或 `greater.description`。

这个做法把两个独立概念耦合在一起：

- 主词条的固有基础强度；
- 额外词条的太古品质成长。

调整太古强化会连带改变主词条，调整主词条强度也会反过来影响太古额外词条。主词条只复用 `greater` 的一部分字段，也增加了理解和校验成本。

## 2. 设计前提

主词条与额外词条平等、太古额外词条可以强于同名主词条，本身也是一种自洽模型：主词条负责决定本体和方向，太古额外词条代表稀有品质。

只有希望主词条具有明确的基础强度优势时，才需要额外的固有数值规则。该优势应显式设计，不应通过复用太古配置隐式获得。

## 3. 推荐方案：同原型增加 `main` 数值配置

对于“效果相同，仅主词条数值更高”的共享被动，保留同一个词条 ID，在原型上增加可选 `main` 表，单独保存主词条的普通公式参数：

```json5
example_attribute: {
  id: "example_attribute",
  description: "passive_example_attribute_description",

  // 普通额外词条：base + increment × level
  increment: 0.5,

  // 主词条固有数值：main.base + main.increment × level
  main: {
    increment: 1.0,
  },

  // 只用于额外词条太古化
  greater: {
    values: [
      { mode: "multiply", factor: 1.5 },
    ],
  },

  isEquipmentMain: true,
  isEquipmentExtraAffix: true,
  isEphemeral: true,
},
```

`main` 与 `greater` 完全独立：

- 主词条使用 `main.base/main.increment`，按物品当前词条等级计算；缺省字段是否回退到普通 `base/increment`，在实施时统一确定。
- 普通额外词条继续使用原型顶层的 `base/increment`。
- 太古额外词条按所属物品 rank 的满级计算普通值，再应用 `greater`。
- 主词条不写入 `isGreater`，不显示太古标识，不消费 `greater.data` 或 `greater.description`。
- `main` 只描述主词条固有强度，不是新的品质，也不引入满级规则。

## 4. 为什么暂不拆成两个完整词条

仅数值不同就复制成两个独立词条，会带来额外维护成本：

- 描述、图标、候选池、`kinds`、互斥规则和用途标记可能逐渐不一致；
- 新 ID 会改变当前按被动 ID 聚合的属性计算口径；
- 若希望 `example_attribute_main` 与 `example_attribute` 流入同一属性，需要另行引入共同的 `statId/aggregateId`；
- `uniqueId` 只负责生成互斥，不能解决属性聚合和统一取整。

使用同原型 `main` 字段可以保留现有 ID、聚合模型、天赋引用和本地化内容，同时让三种数值来源各自独立。

## 5. 适合拆成独立词条的情况

如果主词条与额外词条存在以下差异，可以直接设计成两个独立 ID，而不是使用 `main`：

- 机制效果不同；
- 装备主词条与丹药主词条需要不同强度或不同效果；
- 适用物品种类、解锁境界或互斥规则不同；
- 需要不同描述、图标或成长方式；
- 主词条与额外词条本就不应共享同一个内容身份。

拆分时应同步设计共同属性 ID 和聚合规则，不能只复制词条并修改名称。

## 6. 后续实施时需要同步的范围

本文暂不修改代码或数据。未来若采纳 `main` 方案，应至少同步：

- `plan/greater_affix_rework.md`：删除主词条复用 `greater.values` 的规则，改为显式 `main` 数值配置；
- `assets/data/passives.json5`：只为确有主词条强度差异的共享原型配置 `main`，不要求所有主词条统一加成；
- `scripts/main/data/item/equipment.ht`、`usable.ht` 与被动来源计算入口：按词条在物品中的实际角色选择公式；
- `lib/logic/logic.dart`：保持普通贡献逐来源计算、同 ID 汇总后一次取整，不因 `main` 引入另一套聚合规则；
- `utils/data_validate/game_data_validate.dart`：校验 `main` 的结构、数值字段和适用条件；
- 逐词条太古设计计划：分别列出主词条、普通额外词条和太古额外词条的数值，审核最终取整结果；
- 相关 MOD 契约、玩法文档与测试。

## 7. 当前决定

- 暂不实现 `main` 字段。
- 暂不拆分现有共享被动原型。
- 不再把“主词条默认复用 `greater.values`”视为已确定的最佳方案。
- 后续先审核本文和逐词条太古设计，再决定最终数据契约并统一实施。
