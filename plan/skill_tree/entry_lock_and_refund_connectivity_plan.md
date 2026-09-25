# 天赋树：流派入口唯一性 + 退点连通性检查 实施计划

> v2：根据设计讨论修正——天赋盘对标 PoE 自由路径（可先走到外环、绕圈、再沿另一条半径走回中心），
> 因此加点/退点规则整体从「有向（子→父）语义」切换为「无向邻接语义」。
> `connectedNodes` 数据仍然每条边只写一次（任意一端书写均可），反向邻接由代码在载入时补全。

## 1. 现状分析

### 1.1 数据与代码结构

- 节点定义：`assets/data/passive_skills.json5`，id = `track_{轨道}_{弧位}`，坐标由 `kTrackRadius` + `generateDividingPointsOnCircle` 算出（`lib/scene/cultivation/cultivation.dart:1419-1436`）。场景为每个轨道位置创建按钮，无数据的节点在 dev 模式显示 wip 占位（不可点击），release 模式不创建。
- `connectedNodes` **当前语义** = 前置（父）节点列表（子 → 父，指向圆心方向），两处用途：
  1. 画连接线（`cultivation.dart:1438-1477`，对双向重复自动去重）；
  2. 学习开放判断 `checkPassiveStatus`（`cultivation.dart:313-331`）：`isOpen = 数据 isOpen 字段 ?? connectedNodes 是否为空 ?? true`；不开放时，任一父节点已解锁即开放。
- **本计划将其重新定义为「无向邻接，每条边只在任意一端写一次」**（见第 2 节）。
- 入口节点 `track_0_0`~`track_0_4`：`isOpen: true` + `connectedNodes: []`。
- 已解锁记录：`character['unlockedPassiveTreeNodes']`（HTStruct，`scripts/main/data/character/battle_entity.ht:203` 初始化）。属性节点存所选属性 id 字符串，其余节点存 `true`。HTStruct 支持 `contains` / `keys` / `isEmpty` / `isNotEmpty`。

### 1.2 加点/退点管线

- 场景交互 `onSkillButtonTapUp`（`cultivation.dart:355-440`）：
  - 左键：`isLearned || !isOpen` 拦截 → 技能点检查 → 境界节点（rank == 当前境界+1）转突破试炼 `tryTribulation` → 属性节点弹五选一 → `GameLogic.characterUnlockPassiveTreeNode` → 扣点；
  - 右键：rank > 0 的境界节点不可退 → 退点。**432 行已有 TODO：`检查节点链接，如果有其他节点依赖于该节点，则不能退点`**，即退点连通性检查的挂接点。
- 底层函数（`lib/logic/character.dart`，经 `lib/logic/logic.dart` 的 GameLogic 静态包装暴露）：
  - `_characterUnlockPassiveTreeNode`（2027）：无任何前置检查，直接写入 + `characterSetPassive`；
  - `_characterRefundPassiveTreeNode`（2084）：无任何检查，对称扣除 + `unlockedNodes.remove`；
  - `_characterAllocateSkills`（2119）：NPC 预分配，**整体已注释**。其引用的 `kCultivationRankPaths` / `kCultivationStylePaths`（`lib/data/common.dart:1429-1768`）是**旧布局残留数据**（`track_5_0`、`track_3_0`、`track_9_*`、`track_8_*` 等 id 在当前 passive_skills.json5 中不存在），将来重新启用 NPC 分配时需按新布局重写。本次不动。
- 场景的其他打开方式：开发者实体面板可用 NPC 身份打开（`lib/scene/world/widgets/entity_list.dart:667` 传 `characterId`）；`isEditorMode` 为编辑器模式（已跳过技能点和试炼检查）。

### 1.3 为什么有向语义不成立（设计讨论结论）

目标玩法对标 PoE：玩家可以先走到外环、沿环横向移动、再沿另一条半径走回中心。在有向（子→父）语义下这种路径**在加点阶段就不成立**——例如悟道主轴每个节点的前置都是更内侧节点（`track_8_8 ← track_6_8`），从御剑轴经中层通道走到 `track_10_4` 后，无法向内走 `track_8_8`。

因此加点规则与退点规则必须一起切换为无向语义：

- 解锁开放：任一**相邻**节点已解锁即开放（原为任一父节点）；
- 退点连通：从已解锁根节点出发的**无向** BFS 覆盖检查（原为沿父边向根收敛）。

无向化后与需求一（入口唯一）恰好互补：玩家绕圈可以走到其他流派的入口 `track_0_1` 附近——入口锁（有任何已解锁节点时入口不可点）正好封死这个口子；退入口节点时其余节点必然失根，因此入口只能最后退，退完五个入口重新可选，闭环。

境界节点的既有规则在无向模型下无需改动：试炼触发条件是 `rankRequirement == 当前境界+1`，从外侧绕到其他流派的低境界节点时自然变为普通解锁——即"兼修"其他流派的境界天赋，符合自由加点设计。

### 1.4 发现的数据问题（与本需求直接相关）

1. **`track_1_0`、`track_1_1` 带有多余的 `isOpen: true`**（其余 track_1_x 没有）。后果：不选入口也能直接点这两个节点；与入口锁叠加后会产生死角——先点 `track_1_0` 会使五个入口全部锁定，玩家永远拿不到入口节点。建议删除这两个字段。
2. **隐式根节点**：`track_3_2` / `track_3_6` / `track_3_10` / `track_3_14` / `track_3_18`（相邻流派共享主轴）`connectedNodes: []` 且无 `isOpen` 字段，按当前判定属于"隐式根"，开局即可直接分配，**目前就可以绕过入口限制**。无向化后根节点口径改为"显式 `isOpen: true`"，这些节点在补写连线前会变为不可达（属预期——连线完成后自然接入），同时由载入校验列出提醒。
3. **悬空引用**：`track_3_3/3_5/3_7/3_9/3_11/3_13/3_15/3_17`、`track_2_9` 等被 `connectedNodes` 引用但本身无数据。现有画线（`connectedButton != null` 才画）和解锁判断（视为未解锁）均已容忍；邻接表构建与连通性检查同样按"不存在 = 未解锁、非根"跳过即可（同时由载入校验列出）。

### 1.5 关于"是否需要补全双向 connectedNodes"

**结论：不需要手写双向数据，但需要把语义改为无向，并由代码补全反向邻接。**

- 区分两个概念：
  - "一个节点从两个方向都可到达" = 一条无向边。数据上**只在任意一端写一次**（写左写右、写内写外都可以），代码在载入时对每条 `A→B` 同时登记 `B→A`，得到完整邻接表；
  - "手写双向数据"（两端各写一遍）永远不需要：冗余且在手工调整期极易不一致。
- 此前 v1 中"共享节点必须写全两侧父节点"的约定**作废**：无向语义下每条边写一次即双向生效。只需要求"每条设计上的连接至少在一端被写出"，由载入校验兜底（见第 6 节）。
- 解锁、退点、画线全部基于同一份邻接语义，所见即所得：写出的边画线、可通行；没写的边不存在。

### 1.6 设计决策：岔路承载共享构筑，圆环只作通行（v3，推荐，待确认）

> 取代 v2 的"筑基闸门 A/B 方案"。设计背景见 plan/skill_tree/ 下五个流派文档与 intersection.md：
> 每个流派有四条岔路，相邻流派两两共享岔路上的构筑内容与关键天赋。

**决策建议**：关键共享天赋**不**放在筑基之后的圆环上（太慢——凝气期约 15 级将没有任何构筑成型内容）；采用"凝气后长岔路"结构：

- 岔路从**凝气节点之后**的主轴岔出；此后每个境界节点再各分一条（筑基/结丹/还婴后各一条，共四条，化神为终点核爆不需要岔路），每个境界阶段解锁一个新构筑方向；
- **关键共享天赋放在岔路中部**——相邻两个流派从各自主轴端进入，到关键点的距离相等，天然就是共享位，不需要圆环承担；
- 走通整条岔路（约 6~10 点）可抵达相邻流派主轴——这就是"较长的岔路通往别的流派"。凝气期点数有限，跨界需 all-in 式投入，构成 PoE 式**距离软闸门**，替代硬性"筑基才能跨界"规则；
- **圆环不取消，降级为纯通行走廊**：现有中层环（track 10-11）、外层环（track 18-19）本来就全是属性节点，正好保持"筑基/还婴后便宜旅行"的定位，与"早期但贵"的岔路互补。附带好处：环形回路提供替代路径，使退点连通检查下玩家洗点更自由（主轴中段也可退）；
- 既有兜底规则不变：到对方主轴后向内走只能白拿 rank ≤ 自身境界的节点，向外推进触发自身下一境界突破试炼——兼修深度自动与境界同步。

对 v2 的修正：不再需要"筑基前主轴两两不连通"的硬闸门；入口锁 + 距离成本构成软闸门。

## 2. 语义调整：无向邻接（前置基础）

### 2.1 构建邻接表

`lib/data/game.dart`：

```dart
/// 天赋树无向邻接表（由 passiveSkills 的 connectedNodes 派生，每条边双向登记）
static final Map<String, List<String>> passiveSkillsAdjacency = {};
```

在 `GameData.init` 载入 `passive_skills.json5` 之后构建：

```dart
passiveSkillsAdjacency.clear();
for (final entry in passiveSkills.entries) {
  final List? connected = entry.value['connectedNodes'];
  if (connected == null) continue;
  for (final other in connected) {
    passiveSkillsAdjacency.putIfAbsent(entry.key, () => []).add(other);
    passiveSkillsAdjacency.putIfAbsent(other, () => []).add(entry.key);
  }
}
```

（悬空引用保留在表中无害：`unlockedNodes.contains` 永远为 false；由校验列出。）

### 2.2 解锁规则改为无向

`cultivation.dart` 的 `checkPassiveStatus`：

```dart
(bool, bool) checkPassiveStatus(String nodeId) {
  final nodeData = GameData.passiveSkills[nodeId];
  final unlockedNodes = character['unlockedPassiveTreeNodes'] as HTStruct;
  final isLearned = unlockedNodes.contains(nodeId);
  // 根节点（入口）恒开放；其余节点任一相邻节点已解锁即开放
  bool isOpen = nodeData?['isOpen'] ?? false;
  if (!isOpen) {
    for (final adj in GameData.passiveSkillsAdjacency[nodeId] ?? const []) {
      if (unlockedNodes.contains(adj)) {
        isOpen = true;
        break;
      }
    }
  }
  return (isLearned, isOpen);
}
```

注意口径变化：根节点 = **显式 `isOpen: true`**（不再把 `connectedNodes` 为空当作隐式根）。这使得未连线的共享轴节点变为不可达（预期行为，见 1.4-2），同时封死入口绕过。

画线逻辑（`cultivation.dart:1438-1477`）保持不变——每条边只在一端写出也会正确画一次（既有 `lineId1/lineId2` 去重）。

## 3. 需求一：流派入口唯一性（仅场景、仅玩家英雄）

规则：`track_0_0`~`track_0_4` 仅当 `unlockedPassiveTreeNodes` 为空时可分配；选定任一入口后其余四个锁定；全部退回后重新可选（`isEmpty` 判断天然支持）。无向化后此规则同时封住"绕圈走到其他流派入口"的路径。

改动点（`lib/scene/cultivation/cultivation.dart`）：

1. 新增常量与方法：

```dart
/// 五个流派入口节点
static const _kEntryNodeIds = {
  'track_0_0', 'track_0_1', 'track_0_2', 'track_0_3', 'track_0_4',
};

/// 入口节点锁定判断：仅玩家英雄、非编辑器模式下生效
bool _isEntryNodeBlocked(String nodeId) {
  if (isEditorMode) return false;
  if (character['id'] != GameData.hero['id']) return false;
  if (!_kEntryNodeIds.contains(nodeId)) return false;
  return (character['unlockedPassiveTreeNodes'] as HTStruct).isNotEmpty;
}
```

2. `onSkillButtonTapUp` 左键分支，`if (isLearned || !isOpen) return;` 之后、属性选择弹窗（`selectHeroAttribute`）之前插入：

```dart
if (_isEntryNodeBlocked(nodeId)) {
  dialog.pushDialog('passivetree_entry_locked_hint');
  dialog.execute();
  return;
}
```

3. `onSkillButtonMouseEnter`：`!isLearned` 分支中，`_isEntryNodeBlocked(nodeId)` 为真时显示 `passivetree_entry_locked_hint`，替代原有的 unlock/points 提示。

4. 本地化 `assets/locale/zh/rpg/passive_skills.json` 新增：

```json
"passivetree_entry_locked_hint": "<red>不可用: 已选定流派起点。如需更换流派，请先退回全部已解锁节点。</>",
```

底层 `_characterUnlockPassiveTreeNode` **不加**检查：NPC 自动分配、突破试炼 unlock（境界节点非入口，本就不受影响）保持原样。

## 4. 需求二：退点连通性检查（无向 BFS）

规则：右键退点时，若移除该节点后任意剩余已解锁节点与根节点失去连接，则禁止退回。根节点 = 已解锁且 `isOpen == true` 的节点（即入口）。

改动点：

1. `lib/logic/character.dart` 新增纯检查函数（不改数据）：

```dart
/// 检查退回 [nodeId] 后，[character] 剩余已解锁的天赋树节点
/// 是否仍然全部与根节点连通（无向 BFS）
bool _checkPassiveTreeRefundable(dynamic character, String nodeId) {
  final unlockedNodes = character['unlockedPassiveTreeNodes'];
  if (!unlockedNodes.contains(nodeId)) return false;

  final remaining = unlockedNodes.keys.where((id) => id != nodeId).toSet();
  if (remaining.isEmpty) return true;

  // 从所有已解锁的根节点出发做无向 BFS
  final visited = <String>{};
  final stack = <String>[
    for (final id in remaining)
      if (GameData.passiveSkills[id]?['isOpen'] == true) id,
  ];
  while (stack.isNotEmpty) {
    final current = stack.removeLast();
    if (!visited.add(current)) continue;
    for (final adj in GameData.passiveSkillsAdjacency[current] ?? const []) {
      if (remaining.contains(adj)) stack.add(adj);
    }
  }
  return visited.length == remaining.length;
}
```

2. `lib/logic/logic.dart` 加 GameLogic 静态包装（与既有包装同风格）：

```dart
static bool checkPassiveTreeRefundable(dynamic character, String nodeId) =>
    _checkPassiveTreeRefundable(character, nodeId);
```

注意：底层 `_characterRefundPassiveTreeNode` 本身**不加**检查，保持执行函数纯净；检查只在场景交互层进行（NPC 不走退点）。

3. `cultivation.dart` 右键分支，替换 432 行 TODO：

```dart
// 检查节点链接：退回后将导致其他已解锁节点不连通，则不能退点
if (!isEditorMode &&
    !GameLogic.checkPassiveTreeRefundable(character, nodeId)) {
  dialog.pushDialog('passivetree_disconnect_refund_hint');
  dialog.execute();
  return;
}
```

位置在境界节点不可退判断之后、实际退点之前。编辑器模式跳过，避免妨碍天赋树设计工作。

4. `onSkillButtonMouseEnter`：`isLearned` 且非境界节点时，若不可退则显示 `passivetree_disconnect_refund_hint` 替代 `passivetree_refund_hint`。

5. 本地化新增：

```json
"passivetree_disconnect_refund_hint": "<red>不可退回: 退回后将有已解锁节点与流派起点失去连接。</>",
```

两个需求的协同：入口锁 + 不可退连通检查共同防止"退到只剩孤立的不可退境界节点、入口永久锁定"的死角——退掉连接境界节点的中间节点会被连通性检查拒绝；退入口时其余节点必然失根，入口只能最后退。

复杂度：单次 BFS O(N+E)，节点数百级别，可忽略。

## 5. 数据修复（建议，需确认）

- `assets/data/passive_skills.json5`：删除 `track_1_0`、`track_1_1` 的 `isOpen: true`（见 1.4-1，否则入口锁存在死角）。

## 6. 数据校验工具（已实现）

独立脚本：`utils/data_validate/passive_tree_validate.dart`，在 `utils/` 目录下运行
`dart run data_validate/passive_tree_validate.dart`（也可从项目根目录运行，或传参指定数据文件路径）。

检查项：
1. 入口节点完整性（`track_0_*` 应为 5 个且均 `isOpen: true`；非入口节点不应带 `isOpen`）；
2. 悬空引用（`connectedNodes` 指向不存在的节点）；
3. 孤立节点（已定义但无任何连线，入口除外）；
4. 不可达节点（从入口出发的无向遍历覆盖不到）；
5. 重复边（同一边两端各写一次；冗余无害，仅提示）。

待确认后追加（随 1.6 v3 结构调整）：
6. 岔路结构检查：每条流派主轴在凝气节点之后应至少有一条岔路最终连通到相邻流派的主轴（长岔路跨界设计）；圆环（track 10-11、18-19）节点不应挂载关键天赋词条（仅通行属性节点）。

退出码：1~4 有任何问题为 1，通过为 0。当前数据实测：2 个多余 `isOpen`（track_1_0/1_1）、9 处悬空引用、78 个不可达节点（110/188 可达），与手工连线中的进度一致。

（可选）后续还可参照 `GameData._validateBattleCardCostColored` 的模式，在游戏内 `GameData.init` 构建邻接表后做同类软警告，让运行时也能看到数据问题。

## 7. 可选：文档更新

`docs/docs/how2play/rpg/cultivation/passive_skills/readme.md` 目前只有 7 行。补上玩家向说明：起点五选一且选定后锁定（退回全部节点可重选）；节点沿连线自由加点（含绕环、沿其他半径走回）；退点不能导致已解锁节点断连。

## 8. 改动文件清单

| 文件 | 改动 |
| --- | --- |
| `lib/scene/cultivation/cultivation.dart` | `checkPassiveStatus` 无向化 + 入口锁定 + 左右键分支检查 + 悬浮提示 |
| `lib/data/game.dart` | 新增 `passiveSkillsAdjacency` 并在 init 构建（+可选校验） |
| `lib/logic/character.dart` | 新增 `_checkPassiveTreeRefundable`（无向 BFS） |
| `lib/logic/logic.dart` | 新增 `GameLogic.checkPassiveTreeRefundable` 包装 |
| `assets/locale/zh/rpg/passive_skills.json` | 2 条新提示文本 |
| `assets/data/passive_skills.json5` | 删除 `track_1_0`/`track_1_1` 多余的 `isOpen: true`（需确认） |
| `utils/data_validate/passive_tree_validate.dart`（已完成） | 天赋树连通性校验脚本 |
| `utils/pubspec.yaml`（已完成） | 新增 `json5` 依赖 |
| `docs/docs/how2play/rpg/cultivation/passive_skills/readme.md`（可选） | 补规则说明 |

## 9. 验证

- `flutter analyze`（未改动 Hetu 脚本，无需 `python build.py`）。
- 游戏内手工用例：
  1. 新角色：五个入口可点；点 `track_0_0` 后其余四个入口悬浮显示锁定提示、点击弹提示；
  2. 主轴加到 `track_2_0` 后：右键 `track_1_0` 被拒绝（`track_2_0` 会断连），右键 `track_2_0` 允许；
  3. 全部退回后入口重新可选，可换流派；
  4. 境界节点仍不可退；突破试炼解锁不受影响；
  5. 菱形分支：`track_10_0` 双邻接（`track_8_0` + `track_11_38`）都解锁时，退其一仍连通 → 允许；
  6. **自由路径**：御剑轴走到 `track_10_0` → 中层通道 `track_11_2 → track_10_2 → track_11_6` → 悟道轴 `track_10_4`，再**向内**走 `track_8_8 → track_6_8`（无向解锁开放）；此时退掉御剑侧入口链上的节点会被拒绝（悟道段靠它连通），退掉悟道段末端节点允许；
  7. 绕圈路径存在时，退掉原主轴中段（如已绕行悟道轴回来）仍连通 → 允许；
  8. 编辑器模式 / NPC 身份打开场景不受新限制；
  9. 开发者面板的 `allocatePassives`（目前空操作）行为不变。
