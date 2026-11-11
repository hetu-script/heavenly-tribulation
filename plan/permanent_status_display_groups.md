# 永久状态显示分组实施计划

> 状态：已实施；技能树节点接入仍不在本次范围内。
> 目标：减少战斗界面的永久状态图标数量，同时保持现有战斗逻辑、状态回调和被动聚合不变。
> 本次不包含技能树节点新增或排布。

## 1. 背景与范围

当前每个永久状态既保存在 `BattleCharacter._statusEffects` 中，也以独立 `StatusEffect` 组件加入场景。`permanentEffects` 同时服务于状态回调和图标排列，导致同类机制较多时占用大量横向空间。

本次采用**显示分组而非逻辑合并**：

- 各状态仍保留独立 ID、实例数据、层数、参数和回调。
- 同组状态在屏幕上只显示一个分组图标。
- 悬停分组图标时显示当前实际持有的组内状态。
- 不合并不同效果的层数，不改变伤害、资源、观星和每回合触发规则。

首批配置四组：

| 分组 ID | 显示名称 | 成员范围 |
| --- | --- | --- |
| `scry` | 观星 | `scry_self_ailments`、`scry_upgrade`、`scry_shield`、`scry_mana`、`scry_all_damage` |
| `kind_damage` | 套路增伤 | 全部 `increase_damage_*` 永久状态 |
| `elemental_resist` | 元素抗性 | 四种 `resistant_*` 与四种 `weakness_*` |
| `attack_type` | 类型攻击 | 四种 `enhance_*` 与四种 `weaken_*` |

其余境界节点、关键分支、绝世装备核心规则、临时状态和资源气保持现状。

## 2. 数据与展示契约

### 2.1 状态成员声明

在 `assets/data/status_effect.json5` 的状态条目上新增可选字段：

```json5
displayGroup: "scry"
```

- 缺省表示仍显示为独立永久状态图标。
- 字段只控制显示，不参与脚本派发、状态互斥或数值计算。
- 成员归属由数据声明，不在 Dart 中根据状态 ID 前缀硬编码分组。

### 2.2 分组展示配置

在 `lib/scene/battle/status_effect.dart` 或拆分出的同目录显示组件文件中定义少量纯 UI 配置：

- 分组 ID。
- 分组图标。
- 分组名称的本地化键。
- 排列优先级。
- 悬停形式：机制说明列表或数值列表。

这些配置只描述 UI 类别，不定义卡牌、装备或天赋效果。状态成员仍完全由 JSON5 决定。

分组名称加入 `assets/locale/zh/rpg/status_effect.json`。

### 2.3 悬停内容

- `scry`：逐项显示当前组内状态的名称与现有状态描述。
- `kind_damage`：逐项显示套路名称与当前增伤数值。
- `attack_type`：逐项显示徒手/武器/法术/咒语增强或削弱及当前数值。
- `elemental_resist`：逐项显示各元素抗性或弱点及当前数值。
- 数值型分组使用“一条公共规则说明 + 各成员名称和数值”，不重复拼接相同的长篇规则。
- 不显示所有成员层数的总和。首版分组图标不显示数字角标，避免把异质效果误解为同一资源。
- 悬停内容在鼠标进入时根据当前成员实时生成，确保五气朝元切换套路、层数变化及状态移除后不会读到旧文本。
- 首版复用现有状态描述和状态层数，不另建伤害净值计算或新的被动描述聚合管线。

## 3. Dart 显示层改造

### 3.1 保持逻辑真值不变

`lib/scene/battle/character.dart` 中：

- `_statusEffects` 继续保存全部状态实例。
- `permanentEffects` 的现有含义和排序保持不变，仍供回调派发使用。
- `handleStatusEffectCallback()` 不读取显示分组，保证永久状态的执行顺序和次数完全不变。
- `hasStatusEffect()`、`addStatusEffect()` 的参数聚合和 `removeStatusEffect()` 的逻辑返回值不受分组影响。

### 3.2 新增分组显示组件

在 `lib/scene/battle/status_effect.dart` 增加分组组件，或按现有代码规模拆出一个同目录文件：

- 复用永久状态的 48×48 图标尺寸、边框和悬停方向。
- 持有分组 ID，并动态引用当前组内 `StatusEffect` 成员。
- 加载分组统一图标。
- 悬停时生成汇总内容，离开时沿用现有 `Hovertip.hide` 行为。

`StatusEffect` 本身继续承担普通状态、资源状态和未分组永久状态的现有显示职责。

### 3.3 战斗角色中的显示生命周期

在 `BattleCharacter` 中单独维护永久状态的显示条目：

- 未分组永久状态仍按现有方式加入场景。
- 分组状态仍创建并保存逻辑实例，但不再把每个成员图标分别加入场景。
- 某组首次出现成员时创建分组组件；后续成员加入时只更新组内引用。
- 某组最后一个成员移除时移除分组组件。
- 组成员增减或层数变化后，无需重建逻辑状态；悬停读取实时成员数据。
- `clearAllStatusEffects()` 同时清理分组组件。
- 战斗重开继续通过现有全量重建自然清空分组显示。

### 3.4 排列

调整 `reArrangePermanentEffects()`，使其排列“未分组状态 + 分组组件”的混合列表：

- 英雄仍从左向右，敌方仍从右向左。
- 沿用 `GameUI.permanentStatusEffectIconSize`、现有间距和两侧起始位置。
- 未分组状态的相对排序规则不变；分组按展示配置的优先级保持稳定位置。
- 不修改 `lib/ui.dart` 的既有布局常量。

## 4. 首批数据配置

### 4.1 观星

为五个观星相关状态声明 `displayGroup: "scry"`，成员省略 `icon`。

统一使用现有资源：

```text
assets/images/icon/status/permanent/scry.png
```

该图标为 150×150，眼睛与卡牌构图适合作为观星分组图标。成员不再保留冗余图标路径，历史图标可保留在 `_unused/`，不移动共享 `unknown.png`。

### 4.2 套路增伤

为全部 `increase_damage_*` 永久状态声明 `displayGroup: "kind_damage"`，成员省略 `icon`。

- 分组统一使用 `increase_damage.png`，不生成新美术。
- 历史成员图标可保留在 `permanent/_unused/`，但运行时分组成员不引用它们。
- 五气朝元仍按现有脚本移除旧套路状态、授予新套路状态，仅显示结果发生变化。

### 4.3 元素抗性

为四种 `resistant_*` 和四种 `weakness_*` 声明 `displayGroup: "elemental_resist"`，成员省略 `icon`。

分组图标使用现有 `resistant_elemental.png`。悬停仍分别列出抗性和弱点，不额外实现一套净值计算器；实际战斗仍由 `getElementalResist()` 计算。

### 4.4 类型攻击

为四种 `enhance_*` 和四种 `weaken_*` 声明 `displayGroup: "attack_type"`，成员省略 `icon`。

分组图标使用现有 `enhance.png`。悬停分别显示增强和削弱，实际伤害仍由 `takeDamage()` 和 `predictDamage()` 的现有口径结算。

## 5. `scry_all_damage` 收尾

本次完成词条能力本身，但不加入技能树节点。

当前已经存在：

- 状态数据与 `self_scry` 回调声明。
- 被动词条、`statusAmount` 和太古参数。
- 每回合首次观星后获得无极之气的状态脚本。
- 状态与被动本地化。

需要收尾：

1. 将 `scry_all_damage` 加入观星分组并省略成员 `icon`，由分组统一使用 `scry.png`，消除缺失资源错误。
2. 将其加入 `scry` 显示分组。
3. 在 `test/passive_aggregation_test.dart` 中补充覆盖：
   - 普通来源观星后获得 1 层 `buff_all_damage`。
   - 太古来源获得 2 层。
   - 同一回合多次观星只触发一次。
   - 后续回合可以再次触发。
   - 多来源参数及被动描述数值符合既有聚合规则。
4. 重新编译 Hetu 脚本，使当前 `status_script.ht` 进入 `assets/mods/main.mod`。
5. 如果该词条最终只由技能树授予，本次不增加其他卡牌或装备来源。

## 6. 校验器、文档与制作约定

### 6.1 数据校验器

更新 `utils/data_validate/game_data_validate.dart`：

- 识别可选 `displayGroup` 字段并要求为非空字符串。
- 校验已知分组 ID，避免拼写错误导致状态意外独立显示。
- 保留现有状态图标和本地化检查。
- 不因多个成员共用分组图标而误报。

### 6.2 文档同步

同一变更中更新：

- `docs/docs/how2play/rpg/battle/readme.md`：说明同类永久状态只合并图标，悬停可查看明细，规则不变。
- `docs/docs/mod/battle/readme.md`：记录 `displayGroup` 是纯显示字段及其约束。
- `.agents/context/battle_system.md`：记录显示分组实现和 `scry_all_damage` 当前状态。
- `.agents/skills/passive-status/SKILL.md`：同步永久状态图标与显示分组的内容制作约定。

不提前把其他流派规划或技能树排布写入当前实现文档。

## 7. 测试与验收

### 7.1 自动化测试

项目已有测试，本次增加显示分组的 focused tests，并保留现有战斗测试：

- 同组多个逻辑状态只生成一个显示条目。
- 未分组永久状态仍各自显示。
- 分组增减成员时不改变 `_statusEffects` 和回调遍历结果。
- 最后一个成员移除后分组消失，清空与重开不残留组件。
- 双方显示条目的排列方向和顺序正确。
- 数值型悬停显示当前成员数值，不显示跨成员合计。
- 五气朝元切换成员后，悬停内容随之更新。
- 现有观星、绝世装备、伤害预测和被动聚合测试继续通过。

### 7.2 实际场景验证

在真实战斗中检查：

1. 窥天镜相关多个状态只显示一个观星图标，悬停列出当前全部观星效果。
2. 多种套路增伤、类型攻击和元素抗性分别只占一个图标。
3. 五气朝元轮转后分组不重复、不残留旧说明。
4. 观星触发次数、升级/护盾/灵气/无极数值与分组前一致。
5. 英雄和敌方两端均无图标重叠、悬停遮挡或移除后残留。

### 7.3 命令

按改动范围运行：

```bash
python build.py
flutter analyze
dart run utils/data_validate/game_data_validate.dart
dart run utils/data_validate/passive_tree_validate.dart
flutter test
```

本次不修改天赋树结构，但当前工作区已有相关改动，因此仍运行连通性校验以确认没有引入回归。

## 8. 明确不做的事项

- 不合并逻辑状态 ID，不重写 `status_script.ht` 的观星效果。
- 不改变 `battleStatus`、`battleStatusParams`、Raw 被动来源或太古聚合规则。
- 不改变伤害公式、伤害预测、元素转化、资源生命周期和每回合触发限制。
- 不接入 `scry_all_damage` 技能树节点，不调整现有天赋树连线。
- 不对临时异常、普通增益/减益或资源气进行分组。
- 不批量删除或移动仍被引用的状态图标，不生成新的美术资源。
