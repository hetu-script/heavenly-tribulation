## Plan: 镇魔司交互逻辑设计与实现

镇魔司（justicehall）是权霸流派的特色建筑，定位为战斗/暗杀导向的悬赏系统。与会堂悬赏（运送、护送、采购等通用跑腿任务）形成差异化互补：镇魔司专注于猎杀、暗杀、捉拿等以角色为目标的战斗型任务。

### 前置依赖

- 门派外交系统（diplomacy）已有数据结构（`Diplomacy` struct in `scripts/main/data/sect/sect.ht`），敌对/盟友/中立关系已可存储，但尚未完全应用于游戏逻辑
- 会堂悬赏系统已完整实现，可作为参考模板

### 功能设计

#### 1. 接取悬赏

进入镇魔司后，与司正（warden）NPC 互动，菜单中出现「接取悬赏」选项。

悬赏列表每月刷新，数量 = `kBaseJusticeHallBountyAmount + development`（类似会堂的 `replenishBounty`）。

每个悬赏目标是一个具体 NPC 角色（非本据点门派的成员），信息包括：

- 目标姓名、境界、所在城市（或"下落不明"）
- 赏金（灵石）
- 时限（天数）
- 任务类型：猎杀（击败即可）/ 捉拿（击败后押送回镇魔司）/ 暗杀（击败，但不能被其他NPC目击）

玩家接取后记入事项（journal），前往目标所在城市找到目标触发战斗，胜利后回镇魔司交差领赏。

#### 2. 发布悬赏（development >= 2 解锁）

玩家选择一个已知角色（曾遭遇过的 NPC），支付赏金发布悬赏。

- 系统异步处理：每月结算时按概率判定是否有刺客完成任务
- 成功率受目标境界、赏金金额、镇魔司规模影响
- 结果通过月初事项通知玩家

#### 3. 暗杀委托（development >= 4 解锁）

针对敌对门派高层（堂主及以上）的高价值目标。赏金更高、目标更强。

- 这类任务固定为「暗杀」类型
- 完成后额外获得功勋和声望变化

### 任务数据结构

在 `quests.json5` 中新增任务类型：

```
hunt_target:      猎杀目标（击败即可），policy: "expansion"
capture_target:   捉拿目标（击败后押送），policy: "expansion"
assassinate:      暗杀目标（击败+不被目击），policy: "expansion", rank: 1
```

在 `scripts/main/data/quest.ht` 中新增对应的 quest 生成函数，仿照 `createQuest` 的模式，但目标从物品/地点改为角色 NPC。

### 与会堂悬赏的差异

| 维度     | 会堂悬赏                         | 镇魔司悬赏               |
| -------- | -------------------------------- | ------------------------ |
| 任务类型 | deliver/escort/purchase/discover | hunt/capture/assassinate |
| 目标     | 物品/材料/地点                   | 特定 NPC 角色            |
| 核心玩法 | 跑腿 + 购物                      | 追踪 + 战斗              |
| 政策关联 | null/consolidation               | expansion                |
| 声望影响 | 正面                             | 可能为负面（暗杀）       |
| 刷新位置 | 任意城市会堂                     | 仅有镇魔司的据点         |

---

### 实现步骤

#### Phase 1: 数据与常量

1. 在 `assets/data/quests.json5` 中新增 `hunt_target`、`capture_target`、`assassinate` 三个任务定义
2. 在 `assets/locale/zh/` 中添加对应的本地化字符串（任务名称、描述模板）
3. 在 `scripts/main/data/quest.ht` 中新增常量 `kBaseJusticeHallBountyAmount`

#### Phase 2: 悬赏生成

4. 在 `scripts/main/data/quest.ht` 中新增 `createJusticeHallQuest()` 函数，从非本门派的 NPC 中选取目标，生成包含目标角色信息的任务对象
5. 新增 `replenishJusticeHallBounty(location)` 函数，仿照 `replenishBounty()` 的模式，在每月初为镇魔司刷新悬赏列表，存入 `location.justiceHallBounties`

#### Phase 3: NPC 交互

6. 在 `lib/logic/character.dart` 的 NPC 交互逻辑中（`_onInteractNpc`），为 `siteKind == 'justicehall'` 添加「接取悬赏」菜单项，复用 `QuestView` UI 组件展示悬赏列表
7. 添加「发布悬赏」菜单项（当 development >= 2），展示角色选择 UI 和赏金设置

#### Phase 4: 任务完成与结算

8. 在 `scripts/main/event/` 中处理任务目标的战斗胜利判定，匹配当前事项中的镇魔司任务
9. 在月度结算逻辑中添加「发布悬赏」的异步结算（成功/失败概率计算）

### 涉及文件

- `assets/data/quests.json5` — 新增任务类型定义
- `scripts/main/data/quest.ht` — 新增生成函数和刷新函数
- `lib/logic/character.dart` — `_onInteractNpc` 中添加镇魔司交互分支
- `lib/data/game.dart` — 任务描述格式化（如需新模板）
- `assets/locale/zh/` — 本地化字符串
- `docs/docs/how2play/rpg/quest/readme.md` — 更新任务列表文档
- `docs/docs/how2play/tycoon/site/readme.md` — 更新镇魔司建筑说明

### Verification

1. 进入有镇魔司的城市，与司正 NPC 互动，确认「接取悬赏」菜单出现
2. 悬赏列表显示目标角色信息（姓名、境界、城市、赏金）
3. 接取任务后事项面板正确显示任务内容
4. 找到目标并战斗胜利后，回镇魔司可以交差领赏
5. `python build.py` 编译通过

### Decisions

- 「暗杀」类型中的「不被目击」机制，初版可简化为：目标身边无其他 NPC 时击败即算暗杀成功，否则降级为猎杀
- 「发布悬赏」的异步结算为概率事件，不做实时模拟
- 任务 policy 统一为 `expansion`，与权霸门派的扩张倾向一致
- 初版不实现「捉拿」的押送机制，先按猎杀处理，后续再加押送逻辑
