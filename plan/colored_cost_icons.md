# 卡牌费用图标渲染（compact 模式）& 卡面布局改版 & qiCost → coloredCost 统一

> **实施状态：已完成，并已与新拉取的战斗资源重构（plan/battle_resource_rework.md）合并**。
> 注意：本文档涉及"总费用 = rank + 1"的表述已被对面的双侧阶梯模型取代——
> 元气（life）与有色费用各自独立走 L(rank) = ⌊rank/2⌋+1，不再有余额推导与 clamp；
> 费用推导唯一实现为 hetu 侧公开函数 `updateCardCost`（Dart `createBattleCard` 经 invoke 调用）。
> 渲染（compact）、注册、布局、命名、支付读取等本文档内容不受影响，均已落地。
> 验证：冲突解决后 `python build.py` 编译通过、`flutter analyze` 零错误。
> 卡面视觉效果待运行目检。

## 1. 背景与目标

Samsara Engine 侧 `CustomGameCard`（`../samsara-engine/lib/cardgame/custom_card.dart`）已有彩色费用
图标渲染雏形（注册表 + 彩色分支 + 万智牌式数字徽章）。本次需求：

1. **费用渲染 compact 化**：不平铺 pip，而是**每种颜色一个图标 + 图标上写数量数字**
   （与战斗资源行 `energy_display.dart` 的视觉语言一致），结构性解决高境界 pip 溢出问题；
2. **费用数据统一**：元气（无色费用）也进入 `coloredCost` 映射（`life` 键），计算与渲染走同一条
   路径；卡牌不再单独保存 `cost` 字段（spec 标注侧仍只写有色，余额自动推导为 life）；
3. **卡面布局改版**：标题改为左对齐；境界徽章（cultivation$rank.png）脱离费用底图单独显示，
   与流派图标在右侧、费用行之下排成竖列；
4. 费用行位置与旧版费用图标相同（卡面右上角），排列方向**向左**，margin = 0；
5. 项目内所有 `qiCost` 统一改名为 `coloredCost`（代码、注释、文档、数据）；
6. 开发阶段，**不考虑旧存档兼容**。

## 2. 现状梳理

### 2.1 引擎侧现状（需要改动，见 §3.1）

- `static Map<String, Sprite> coloredCostSprites`：颜色 id → 图标的共享注册表，
  `registerColoredCostSprite(colorId, spriteId: ...)` 注册。
- `showColoredCost` 默认值：`data?['coloredCost'] != null`。
- `_expandColoredCost()`：把 `data['coloredCost']`（`{颜色id: 数量}`，兼容 Map 与河图 struct）
  展开成重复的颜色 id 序列。
- `render()` 彩色分支（`custom_card.dart:608-641`）：基准位置先画**通用费用数字徽章**
  （`costIconSprite` + `modifiedCost` 数字），随后彩色 pip 沿 `coloredCostDirection` 平铺，
  间距 `图标边长 × 缩放 + coloredCostIconMargin`；未注册颜色跳过且不留空位。
  `coloredCost` 为 null 时走旧版分支（`_costIconRect` + `showCostIcon`/`showCostNumber`）。
- **差距**：需要新增 compact 布局（每色一图标 + 数量数字），并删除彩色分支的数字徽章块
  （元气费用改由 `life` 条目渲染）。`_coloredCostIconRect.shift(_coloredCostIconOffset(i, scale))`
  已能算出每个图标的 rect，直接传给 `drawScreenText` 即可。

### 2.2 游戏侧现状

- `GameData.createBattleCard()`（`lib/data/game.dart:1523`）：调 `deriveBattleCardCost()` 推导费用，
  写入 `cardData['cost']` 和 **`cardData['qiCost']`**（字段名与引擎 `coloredCost` 不一致，
  彩色分支目前永不触发）；费用徽章用 `'cultivation/cultivation$rank.png'` 底图 + 数字。
- 费用推导双端各一份（需保持同步）：Dart `deriveBattleCardCost()` + `_deriveQiCostAmount()`
  （`lib/data/game.dart:1456-1511`）；Hetu `_updateCardCost()` + `_calcQiCostAmount()`
  （`scripts/main/cardgame/card.ht:1-51`）。
- 战斗支付：`lib/scene/battle/battle.dart` `_cardCostColored()`（825 行，`is Map` 类型检查需改
  鸭子类型）、`_canPayCardCost()`、`_payCardCost()`、`_missingCostReport()`；
  无色费用读组件字段 `card.cost`（3 处），有色读 `card.data['qiCost']`。
  支付规则差异（须保留）：虚空之气每层只使**有色**费用 +1；无极之气只补齐**有色**缺口；
  元气（life）两者皆不适用，单独与存量比较。
- `character.energy` 就是 `energy_positive_life` 状态层数（`character.dart:154`），
  元气与四色气机制同构——这是数据统一的领域依据。
- 卡牌 `['cost']` 字段无其他消费者（已全库核查：仅 createBattleCard 写入、validator 查 spec
  使用；脚本侧只有 `_updateCardCost`/player.ht 写入，无读取），统一进 map 后可直接移除。
- 数据：`assets/data/cards.json5` 56 处 `qiCost:`（全部单色 `{base, rankIncrement}` 公式；
  法身双色来自缺省推导）。
- 布局现状：标题顶部居中（rect 0.2~0.8）；流派图标在**左上角**（0.049, 0.04，尺寸
  0.162×0.119，与费用矩形同尺寸）——注意它当前是显示的；稀有度图标未显示（辉光代替）。

### 2.3 参照：战斗资源行（`lib/scene/battle/energy_display.dart`）

`_QiSlot.render()`：图标 + `drawScreenText('$_amount', config: bottomRight 锚点、描边、
Kaiti 粗体 12)`。compact 模式的卡面费用与之同款，数字样式建议直接对齐（bottomRight、描边）。

### 2.4 颜色 id → 图标映射

图标在 `assets/images/icon/cost/`（pubspec.yaml:99 已包含）。映射以
`assets/data/status_effect.json5` 各气状态的 `icon` 字段为单一事实来源：

| 颜色 id   | 含义               | 气状态 id                 | 图标             |
| --------- | ------------------ | ------------------------- | ---------------- |
| `life`    | 元气（无色费用）   | `energy_positive_life`    | `qi_basic.png`   |
| `spell`   | 灵气               | `energy_positive_spell`   | `qi_mana.png`    |
| `weapon`  | 剑气               | `energy_positive_weapon`  | `qi_chakra.png`  |
| `unarmed` | 怒气               | `energy_positive_unarmed` | `qi_rage.png`    |
| `curse`   | 煞气               | `energy_positive_curse`   | `qi_karma.png`   |
| `ultimate`| 无极之气           | `energy_positive_ultimate`| `qi_ultimate.png`|

- 有色 4 色由 `kCostColorStatusIds`（`lib/data/common.dart:375`）定义，ultimate 由
  `kWildcardStatusId`（`common.dart:383`）定义；新增常量 `kColorlessCostColorId = 'life'`
  （注册、支付特判、validator、脚本共用，经 `constants.dart`/`binding/constants.ht` 导出到脚本侧）。

## 3. 修改方案

### 3.1 引擎：新增 compact 布局（`../samsara-engine/lib/cardgame/custom_card.dart`）

1. 新增枚举：

```dart
/// 彩色费用的布局方式
enum ColoredCostLayout {
  /// 平铺 pip：几费几个图标
  pips,

  /// 紧凑：每种颜色一个图标，图标上写数量数字
  compact,
}
```

2. 新增字段：`coloredCostLayout`（默认 `pips`，保持引擎向后兼容）、
   `coloredCostNumberTextConfig`（compact 模式数量文字样式）；构造参数与 `clone()` 同步。
3. 重构 `_expandColoredCost()`：抽出一个返回**有序 (颜色id, 数量) 对**列表的辅助方法
   （跳过 count 非 num 或 ≤ 0 的条目），pips 模式由它展开重复序列，compact 模式直接用它。
4. `render()` 彩色分支：
   - **删除** `if (modifiedCost > 0) { costIconSprite + '$modifiedCost' 数字 }` 徽章块及
     "万智牌式"注释（元气改由 `life` 条目渲染，引擎不再耦合费用色概念）；
   - `pips`：维持现有平铺循环（含 life，只要注册过就会画）；
   - `compact`：遍历有序对，第 i 个图标
     `rect = _coloredCostIconRect.shift(_coloredCostIconOffset(i, fontScale))`，
     渲染图标后 `drawScreenText(canvas, '$count', position: rect.topLeft,
     config: coloredCostNumberTextConfig?.copyWith(size: rect.size.toVector2(), scale: fontScale))`；
     数量恒显（含 1，与资源行一致）；未注册颜色跳过且不留空位。
   - 旧版分支（`coloredCost == null`）保持不变。

### 3.2 注册六种费用图标（`lib/data/game.dart` `GameData.init()`）

在 `init()` 末尾（`_isInitted = true` 之前），从已加载的 `statusEffects` 推导图标路径：

```dart
// 注册彩色费用图标（颜色 id → 图标 sprite，与气状态图标同源，所有卡牌共享）
final costColorIconStatusIds = <String, String>{
  kColorlessCostColorId: 'energy_positive_life',
  ...kCostColorStatusIds,
  'ultimate': kWildcardStatusId,
};
for (final entry in costColorIconStatusIds.entries) {
  final icon = statusEffects[entry.value]?['icon'];
  if (icon != null) {
    await CustomGameCard.registerColoredCostSprite(entry.key, spriteId: icon);
  }
}
```

### 3.3 费用数据统一进 coloredCost（双端推导）

规则不变（总费用 = rank + 1；显式条目优先；缺省按流派推导），**输出统一为一张含 life 的 map**：

- life = `max(0, rank + 1 − Σ有色)`，> 0 时写入 map **首位**（渲染时元气在最右/基准位）；
- spec（cards.json5 主词条的显式 coloredCost）仍只写有色；显式给出 `life` 视为覆盖余额推导
  （validator 校验 Σ(含 life) == rank + 1 报警）；
- 幂等性：物化后的 map（含 life）再次喂给推导时结果不变。

具体改动：

- Dart `deriveBattleCardCost()`（`lib/data/game.dart:1473`）：返回值从 `(int, Map)` 改为
  `Map<String, int>`（含 life）；`_deriveQiCostAmount` → `_deriveColoredCostAmount`。
- Hetu `_updateCardCost()`（`card.ht:14`）：`card.qiCost` → `card.coloredCost`，
  末尾写入 `card.coloredCost[Constants.colorlessCostColorId]`（>0 时），删除 `card.cost` 赋值。
- `player.ht:176-178`：符箓卡 `newCardData.cost = 1; newCardData.qiCost = {}` →
  `newCardData.coloredCost = {life: 1}`。
- `common.dart` 新增 `const kColorlessCostColorId = 'life';`，`constants.dart` 与
  `scripts/main/binding/constants.ht` 增加 `Constants.colorlessCostColorId` 导出。

### 3.4 `createBattleCard()` 布局与参数（`lib/data/game.dart:1523`）

```dart
final coloredCost = deriveBattleCardCost(cardData);
cardData['coloredCost'] = coloredCost;   // 含 life；不再写 cardData['cost']
```

CustomGameCard 构造参数变化：

- **删除**：`cost`、`costIconSpriteId`、`showCostNumber`、`costNumberTextConfig`、
  `costIconRelativePaddings`（彩色分支不再使用，旧版分支对战斗卡是死路径）；
- **费用行（compact）**：
  `coloredCostIconRelativePaddings: const EdgeInsets.fromLTRB(0.789, 0.04, 0.049, 0.841)`
  （同旧费用矩形）、`coloredCostDirection: ColoredCostDirection.left`、
  `coloredCostIconMargin: 0`、`coloredCostLayout: ColoredCostLayout.compact`、
  `coloredCostNumberTextConfig`：对齐资源行样式（bottomRight 锚点、outlined、
  Kaiti 粗体，字号试 12 起）；
- **标题左对齐**：`titleConfig.anchor` 改 `Anchor.centerLeft`；
  `titleRelativePaddings` 改 `fromLTRB(0.049, 0.05, 0.35, 0.865)`
  （左缘对齐到原流派图标位，宽度 0.6 与原值相同，右界 0.65 避开费用行）；
- **境界徽章**（复用 rarityIcon 槽位，rank↔rarity 经 kRankToRarity 一一对应）：
  `rarityIconSpriteId: 'cultivation/cultivation$rank.png'`，
  `rarityIconRelativePaddings: const EdgeInsets.fromLTRB(0.789, 0.17, 0.049, 0.711)`
  （费用行下方，右对齐，尺寸 0.162×0.119 同旧费用图标）；
- **流派图标**（移入右侧竖列，境界下方，同尺寸）：
  `genreIconRelativePaddings: const EdgeInsets.fromLTRB(0.789, 0.30, 0.049, 0.581)`，
  `genreIconSpriteId` 不变；
- `showColoredCost` 不传（自动判定）；插画/描述/辉光等其余参数不变。

布局示意（相对坐标，右缘 0.951）：

```
y 0.04~0.16   [标题…………]        [life][spell]…   ← 费用行（compact，左排）
y 0.17~0.29                     [境界徽章]
y 0.30~0.42                     [流派图标]
```

### 3.5 支付侧读取调整（`lib/scene/battle/battle.dart`）

- `_cardCostColored()`：改读 `card.data['coloredCost']`；**去掉 `is Map` 类型检查**——数据可能是
  Map 或河图 struct（读档时），按项目约定用 `keys` + `[]` 鸭子类型遍历（dynamic），
  与引擎 `_expandColoredCost` 同款写法；返回值现在含 life 键。
- 三处 `card.cost` 读取改为从 map 取 life：
  `_canPayCardCost` 的 `accumulate`（`colorlessNeed += c.cost`）、
  `_payCardCost`（`colorlessNeed = card.cost`）、`_missingCostReport`（`colorlessNeed = card.cost`）。
- 支付循环对 life 特判（规则差异保留）：`if (entry.key == kColorlessCostColorId)` →
  计入 colorlessNeed，`continue`——不加虚空之气增费、不走无极补齐，其余颜色照旧。

```dart
/// 卡牌费用（颜色 → 数量，含 life），无则空表。
/// 数据可能是 Map 或河图 struct，不做类型检查，按约定直接用 keys/[] 访问。
Map<String, int> _cardCostColored(CustomGameCard card) {
  final coloredCost = card.data['coloredCost'];
  if (coloredCost == null) return const {};
  final result = <String, int>{};
  for (final key in coloredCost.keys) {
    final value = coloredCost[key];
    if (value is num) result['$key'] = value.toInt();
  }
  return result;
}
```

### 3.6 qiCost → coloredCost 逐文件重命名

| 文件 | 改动 |
| --- | --- |
| `assets/data/cards.json5` | 56 处 `qiCost:` → `coloredCost:`（纯字段名替换，值不变） |
| `scripts/main/cardgame/card.ht` | `_calcQiCostAmount` → `_calcColoredCostAmount`；`mainAffix.qiCost` → `mainAffix.coloredCost`；`card.qiCost` → `card.coloredCost`；注释同步（见 §3.3） |
| `scripts/main/binding/player.ht` | 见 §3.3 |
| `lib/data/game.dart` | `_deriveQiCostAmount` → `_deriveColoredCostAmount`；`_validateBattleCardCostColored` 局部变量与警告文案；`deriveBattleCardCost`；`createBattleCard`（见 §3.4） |
| `lib/scene/battle/battle.dart` | 见 §3.5 |
| `docs/docs/how2play/rpg/battle/resource/readme.md:46` | `（qiCost）` → `（coloredCost）`，并补充"元气也在 coloredCost 中（life 键）" |

### 3.7 validator 调整（`lib/data/game.dart:526`）

- 合法颜色集合改为 `kCostColorStatusIds.keys + {kColorlessCostColorId}`（非绝世卡）；
- 显式 life 条目参与 Σ 校验：Σ(含 life) ≠ rank + 1 时报警；
- 其余规则（公式条目、clamp 警告）不变。

### 3.8 清理过渡方案残留

- `lib/data/game.dart:1396-1415`：`getBattleCardDescription()` 中整段注释掉的"过渡期文本行显示
  有色费用"代码删除。
- `assets/locale/zh/rpg/battlecard.json:107`：`battlecard_qiCost_hint` 仅被该注释段引用，一并删除。

### 3.9 验证

1. `python build.py` 重新编译脚本（card.ht、player.ht、constants.ht 有改动）。
2. `flutter analyze`（samsara-engine 与游戏两侧，至少确认 custom_card.dart、game.dart、
   battle.dart 无告警）。
3. 运行游戏目检卡面：
   - 悟道 rank ≥ 1 攻击卡：右上 [灵气×n][元气×n]（左排），数字 bottomRight 描边清晰；
   - 法身卡：[煞气][怒气][元气] 三个图标；
   - rank 0 / 无流派卡：只有 [元气×1]；
   - 全有色卡（cost 余额 0）：无元气图标，有色图标从右上起排；
   - rank 4-5 高境界卡：图标数 ≤ 3，无溢出；
   - 标题左对齐不遮费用行；右侧境界/流派竖列与插画右缘的叠压效果可接受；
   - 战斗中打出、置灰、缺费提示（`_missingCostReport`）逻辑不变，符箓卡（life×1）正常。
4. 启动日志：`_validateBattleCardCostColored` 无新警告。

## 4. 发现的漏洞 / 设计问题（记录）

### 4.1 既有问题

1. ~~**死引用的计划文档**~~（已解决）：`plan-battle_qi_cost_rework.md`、`plan/qi_display.md`、
   `plan/scroll_card.md` 的注释引用（含 §x.x、共识 N 标注）已全部清扫。
2. ~~**双端推导逻辑重复**~~（已解决）：费用推导已收拢为 hetu 侧公开函数 `updateCardCost`
   单一实现，Dart 侧 `deriveBattleCardCost` 已删除，`createBattleCard` 改为 invoke 调用。
3. **`ultimate` 作为费用色缺少校验与支付语义**：校验器只约束非绝世卡 4 色；支付侧
   `kCostColorStatusIds` 无 ultimate 条目，若绝世卡以 ultimate 为费用会被支付循环跳过
   （免费）。建议后续明确语义并补校验。
4. **图标资源文件名保留 `qi_` 前缀**：六个图标同时被 `status_effect.json5` 引用，本次不改名；
   日后去 qi 化需连带改 status_effect.json5 的 12 处 icon 路径。

### 4.2 本次方案引入/需注意的点

5. **标题与费用行共处顶部横带**：compact 下费用图标最多 3 个（绝世 +ultimate 4 个），
   左缘 0.465（4 个时 0.303）；标题 rect 右界 0.65。标题左对齐且卡名通常 ≤ 6 字，一般不触；
   长名 × 多色的极端组合需目检，必要时收窄标题右界。
6. **右侧竖列压插画**：插画区域 x 至 0.9378、y 自 0.135，境界/流派图标（x 0.789~0.951,
   y 0.17~0.42）会后绘盖住插画右缘。卡牌常见叠压，目检；若难看可将插画右 padding 收到 0.21。
7. **减费着色反馈消失**：数字徽章取消后，`modifiedCost != cost` 的红/绿提示不复存在。
   目前游戏无改费机制，无实际影响；未来加入时需重新设计反馈（改 map + 数字着色）。
8. **compact 数字恒显（含 1）**：与资源行一致；若觉得单图标写 "1" 吵，可后续给引擎加开关。
9. **改名破坏旧存档**：旧档卡牌存的是 `qiCost`/`cost`，改名后读取为 null，费用将按流派
   缺省推导重算。按结论开发阶段不兼容旧档，直接接受。
10. **引擎彩色分支参数分化**：`costIconSpriteId`/`showCostNumber`/`costNumberTextConfig`/
    `costIconRelativePaddings` 改后只对旧版分支生效；战斗卡不再传它们。
    `CustomGameCard.cost`/`modifiedCost` 字段对战斗卡不再使用（保留给旧版分支与其他游戏）。

## 5. 明确不做的事

- 不做旧存档兼容（开发阶段）。
- 不改六个图标文件名与 pubspec 资源配置。
- 不动战斗支付规则本身（本色/无极/虚空之气逻辑不变，仅换数据来源与读取方式）。
- 不删除引擎的 pips 平铺模式与旧版分支（保留为引擎能力，本游戏用 compact）。
