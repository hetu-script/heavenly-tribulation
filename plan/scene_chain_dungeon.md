# 场景链地牢：Location／NPCList 复用与实施计划

> 状态：阶段 1 与阶段 2 已实施，包括营地、固定路线、房间实例、直接战斗、自动普通奖励、搜刮三选一、商人、休息、前后导航与失败最小出口；Boss 跨轮结算、设施突破和当前房间读档恢复仍属后续阶段。
>
> 目标依据：`plan/demo_scope.md`。当前版本采用“固定营地 + 场景链秘境”，角色在胜利、失败和突破后持续存在。
>
> 首条路线与资源明细见 `plan/scene_chain_content.md`。后续格子房间扩展见 `plan/grid_dungeon.md`，不是首版依赖。

## 1. 结论与核心循环

现有 Location、NPCList、对话、战斗、仓库和奖励系统足以支撑新模式的大部分表现与交互，但应采用组件级和内容工厂级复用，不把地牢塞进 Location 的世界地点模型。

核心结构：

- 新建轻量 `CampScene` 与 `DungeonScene`，直接组合背景、场景卡和 UI Overlay。
- 整个游戏只有当前英雄及其持久角色数据；同一角色跨多轮秘境继续成长，不为每轮创建新角色。
- `DungeonRun` 由 Hetu 初始化，作为 HTStruct 保存在 `game.flags.dungeon`；Dart 不另建重复的持久状态对象。
- 战斗、商人和奖励复用现有能力，但不复用会写入世界坐标和世界对象的 `ObjectEnemy`、`ObjectMerchant`。
- 初始新游戏暂不制作角色创建界面。只有从主菜单开始无尽模式时才随机创建角色；每轮结束返回营地，不重新随机。

核心循环：

> 营地整理仓库与永久卡组 → 开始一轮秘境 → 固定路线战斗、交易与恢复 → 击败 Boss 或失败 → 返回营地结算 → 整理、修炼与突破 → 开始下一轮。

## 2. 跨轮角色、物品与卡牌规则

### 2.1 角色、手动升级与境界试炼

- `game.heroId` 始终指向当前英雄，营地与秘境不切换角色对象。角色身份、修为等级、经验、境界和天赋跨轮保留。
- 修炼界面在营地和秘境中都可以打开，用于查看经验、手动升级和分配天赋；秘境中仍不开放卡牌库。
- 升级继续复用现有 `CultivationScene.tryLevelUp()` 与 `Player.levelUp()`：玩家手动点击升级，扣除当前等级所需经验、等级加一并获得天赋点。达到当前境界等级上限后不能继续升级，经验仍可保留。
- 原流派境界节点不再触发试炼，改为普通天赋节点。手动调用 `GameLogic.checkRequirements(node, checkRank: true)`，只检查现有 `rank` 字段，不附带判断 `level`；满足后按普通节点规则消耗天赋点，不再免费，也不因试炼成功自动解锁。

境界突破只能从提供 `startBreakthroughTrial` 动作的设施发起。当前由营地突破设施提供，未来沙盒中的门派、洞府或渡劫场景复用同一动作：

1. 设施动作生成包含当前 `level` 要求的数据，并复用 `GameLogic.checkRequirements(..., checkLevel: true)`；首版要求达到 `maxLevelForRank(hero.rank)`；
2. 要求携带一个 `craftmaterial_upgradeRank`，其物品境界为 `hero.rank + 1`，即现有破镜丹系列；
3. 确认开始试炼时消耗该物品，成功与失败都不返还；
4. 试炼失败只消耗此物品，返回设施所在场景，不清理物品、地牢卡或秘境层级，也不产生其他失败惩罚；
5. 试炼成功后调用角色境界提升逻辑，只增加 `hero.rank`，不自动解锁境界天赋节点；
6. 突破成功后同步 `game.flags.dungeon.rank = hero.rank`、`level = 0`，营地发展度由新境界派生；不突破则可继续当前境界的秘境。

秘境境界与跨轮层级统一保存在 `game.flags.dungeon.rank` 和 `level`。该 HTStruct 在营地也保留，`active` 表示当前是否处于一轮秘境中，不另建英雄侧层级字段。

### 2.2 仓库、装备栏与随身物品栏

物品是否保留由所在位置决定，不增加物品永久标记：

- `hero.warehouse`：仓库中的装备、物品和材料始终保留；
- `hero.equipments`：角色已经装备的物品始终保留，包括本轮获得后穿上的装备；
- `hero.inventory` 与随身材料：Boss 胜利后全部带回营地，由玩家整理入库；失败时清空未装备、未入库的随身物品与材料。

仓库不需要真实 Location。`hero.warehouse` 使用包含 `id`、`name`、`inventory`、`materials` 的 HTStruct，直接复用 `GameLogic.openDepositBox()` 与 `MerchantType.depositBox`。旧 Location 的 `storage` 用于建筑维护，不作为新仓库。

装备栏数量仍受境界限制。换上新装备后旧装备回到随身物品栏，失败时仍会丢失。

### 2.3 永久卡与地牢卡

- 永久卡保存在当前英雄的 `cardLibrary` 中，跨轮保留；主要由低概率普通战斗掉落、精英高概率和 Boss 保底的卡包产出。
- 卡包只能在营地打开，秘境中可以获取、携带和查看但不能使用；打开后永久卡只进入卡库，不自动加入出战卡组。
- 未打开卡包在 Boss 胜利后随背包带回营地，失败时按未保护随身物品规则丢失。
- `isDungeonCard` 缺省为 `false`。`isDungeonCard: true` 的卡牌只属于本轮，胜利或失败返回营地时都移除。
- 地牢卡来自战胜敌人后的搜刮：普通战利品窗口关闭后，立即从敌人当前实际出战卡组随机抽取三张不同卡牌实例并保存为候选，在当前房间自动显示搜刮 Component。
- 玩家可以暂时关闭搜刮 Component，之后通过点击已击败敌人重新打开同一组候选；关闭、前进和回访不完成搜刮，也不重 roll。
- 选择后复制所选卡牌数据给当前英雄，只需在副本上赋予 `isDungeonCard: true`，再加入卡库和当前锁定出战卡组；不得修改敌人原卡。选择或明确放弃才真正关闭搜刮，放弃不获得卡牌。
- 地牢卡可以使实际卡组超过永久基础数量；秘境中不提供常规删牌入口，只有明确说明的少数特殊效果可以移除，本轮结束后全部移除。
- `isDungeonCard` 不复用 `isEphemeral`，也不与 `isUnpackable` 混用。

### 2.4 永久卡组与默认补位

- 每轮从当前英雄的永久卡库沿用或调整出战卡组，不要求每轮重新组牌。
- 点击开始秘境时打开简单的卡组确认对话框，沿用卡牌库已经设置的 `battleDeckIndex`，不另做卡组编辑器或逐张卡牌浮窗。
- 对话框只显示当前卡组名称、永久卡数量和默认补位提示，提供“调整卡组”“开始秘境”“取消”；调整卡组时进入营地卡牌库。
- 当前 `battleDeckIndex` 无效时可选择第一个非空卡组；没有可用的非空卡组时提示“无可用卡组”，禁止进入秘境，玩家必须自行在营地创建或调整。
- 永久出战卡组的基础数量固定为当前有效卡组下限；额外永久卡留在卡库。
- 非空永久卡组不足下限时，仍由现有战斗逻辑保证：`BattleScene.getDeck()` 使用 `blank_default` 补齐缺少数量；不允许空卡组或全部默认卡进入秘境。
- 默认卡只是战斗时创建的临时战斗卡，不写入永久卡库或卡组列表。
- 地牢卡计入实际卡组数量，会自然减少默认卡补位；地牢卡移除后，下一轮不足的位置再次自动补默认卡。
- 非空卡组删牌导致低于下限不会阻止操作，也不导致无法战斗。

## 3. 胜利、失败与秘境层级

### 3.1 Boss 胜利

- 返回 Boss 房间时生成一次本轮 Boss 奖励，自动通过 `Player.acquire()` 放入当前英雄背包，并通过 `Game.promptItems()` 展示战利品。
- 返回营地后保留随身物品、永久卡和角色成长，由玩家将需要的物品入库。
- 将 `game.flags.dungeon.level` 更新为 `min(level + 1, levelMax)`；达到上限后继续获胜不再提升。
- 移除所有 `isDungeonCard` 卡牌，将 `active` 设为 `false` 并清理本轮房间与战斗状态，清除 `hero.dungeonId`；保留 `rank` 和 `level`。

### 3.2 冒险失败

- 失败是正常跨轮结算，不结束游戏、不返回主菜单，也不要求重新创建角色。
- 保留角色、境界、修为、天赋、永久卡库、仓库与已装备物品。
- 清空未装备、未入库的随身物品和材料，移除所有地牢卡。
- 将 `game.flags.dungeon.level` 设为 0，将 `active` 设为 `false` 并清理本轮房间与战斗状态，清除 `hero.dungeonId`，返回营地；保留 `rank`。

### 3.3 难度推进

沿用旧版秘境的层级结构：

- 新境界的初始 `level = 0`；
- `levelMax = rank * 2 + 1`；
- 敌人等级为 `minLevelForRank(rank) + level + enemy.levelBonus`；
- Boss 胜利后，下一轮 `level = min(level + 1, levelMax)`；
- 失败后 `level = 0`；
- 境界提升后，使用新 `rank` 并将 `level` 归零；
- 不使用旧门票、旧世界入口或无限数值增长。

## 4. 现有能力复用与无世界适配

### 4.1 Location 与场景组件

可复用全屏插画、`PiledZone`、场景卡、聚焦、Hover 和 `GameUIOverlay`。不复用 Location 的世界坐标写回、世界时间、地点查询、门派职责或按建筑 kind 硬编码的分发。不继承 `LocationScene`，也不为地牢伪造 Location。

### 4.2 NPCList

支持可选 `onInteract`、直接显示名称、滚动范围修正与场景退出清理。秘境中的敌人、商人和休息设施角色通过 NPCList 交互；初始营地设施不使用 NPCList。敌人沿用 `BattleEntity` 自动分配的随机头像；商人固定使用 `illustration/avatar/npc/trader.png`。角色实例保存在房间中，回访和读档不重新随机头像。

### 4.3 战斗、商人与奖励

- 场景链不使用 `PreBattleDialog`：点击敌人后仅用普通对话确认，再通过 `Game.showBattle()` 或 `BattleScene` 的显式角色、背景和回调直接进入战斗；旧沙盒暂时保留原战前界面。
- 敌人由 `BattleEntity` 与 `generateBattleDeck()` 创建。
- 商人由无世界工厂创建并调用 `characterInitItems()`；`MerchantDialog` 使用 `MerchantType.none`，关闭补货和偷窃。
- `onBattleEnd` 只记录战斗结果与待结算房间；返回 `DungeonScene.onStart()` 后再结算胜利奖励，避免战利品弹窗停留在战斗场景。
- 普通物品奖励沿用旧版 `createReward()`，在胜利返回房间时生成一次并保存，随后逐件通过 `Player.acquire()` 自动进入当前英雄背包，并调用 `Game.promptItems()` 展示。
- 每房只能自动发放一次；场景重入、回访和读档不得重复生成或发放。卡包仍是普通物品，但只能在营地打开，永久卡只进入卡库。
- 普通战利品展示关闭后，立即从敌人当前实际出战卡组随机抽取三张不同卡牌实例并保存，在当前房间自动显示搜刮 Component；选择后复制卡牌数据，只在玩家副本上设置 `isDungeonCard` 并加入当前卡库与锁定出战卡组。
- 搜刮 Component 直接装配在当前 `DungeonScene`，不创建新场景；参考 `BattleScene` 的观星点选与 `CardLibraryScene` 的开卡包展示，固定五个卡位只使用前三个，不使用 `ItemSelectDialog` 或新增 Overlay 状态。
- 暂时关闭 Component 不完成搜刮，点击敌人可重新打开原候选；选择或明确放弃才真正关闭。候选与完成状态随房间保存，关闭、回访或读档不允许刷新。

### 4.4 工坊、修炼、卡牌库与仓库

- 工坊与炼丹通过 Overlay 接收可选 `development`，不需要 Location。
- 卡牌库只允许从营地功能卡进入；`DungeonScene` 设置 `enableLibrary: false`。
- 修炼在营地和秘境都可进入；`DungeonScene` 设置 `enableCultivation: true`，并传入 `advanceTime: false`，不推进沙盒世界时间。
- 实施时先注释／移除境界节点上的试炼入口，再复用现有试炼战斗与成功表现，将流程迁到设施动作。节点通过 `checkRequirements(..., checkRank: true)` 只检查 `rank`，并恢复普通天赋点消耗，不能只注释试炼调用。
- 破镜丹继续保留卡牌破境用途；角色试炼在确认时直接消耗对应境界的丹药，不再依赖旧版“提前服用后降低试炼难度”的前置路径。
- 仓库复用现有家中仓库的存取界面，入口为营地功能卡。
- 休息房间不调用 `GameLogic.heroRest()`，只执行数据定义的受控恢复动作。

## 5. 场景结构与代码职责

### 5.1 场景栈

使用 Samsara 场景栈管理根场景和全屏功能界面，不为路线中的每个房间分别创建 Flame Scene。整轮秘境只创建一个持续的 `DungeonScene`，房间切换只替换背景、NPC 和导航卡。

```text
MainMenuScene
  → CampScene                 每轮之间的营地
      → CardLibraryScene      功法与精炼，仅营地
      → CultivationScene      手动升级与天赋
      → BattleScene           设施发起的境界试炼
  → DungeonScene              每轮秘境只创建一个
      → BattleScene           战斗时临时 push
      → CultivationScene      手动升级与天赋
      → 其他秘境功能界面      不包含卡牌库
```

战斗结束后回到同一个 `DungeonScene`。返回营地时结束本轮场景并清理房间实例；`game.flags.dungeon` 本身继续保留境界、层级和 `active: false`，下一轮在同一 HTStruct 上重建本轮内容。

### 5.2 房间抽象

采用**统一房间数据模型 + 按类型分派动作处理器**：

- JSON5 模板：类型、标题、背景、敌人、商人池、奖励和动作参数；
- HTStruct 运行时实例：保存生成结果、战斗、自动发奖和设施状态；
- Dart 房间视图：装配当前房间；
- Dart 动作处理器：按 `kind` 分派战斗、交易和恢复。

`battle`、`elite` 与 `boss` 共用战斗处理器，Boss 胜利后提供返回营地卡。只有需要独立摄像机、碰撞或持续更新的特殊房间才允许使用专用 Flame Scene。未来格子模式复用相同房间实例与动作处理器。

### 5.3 初始营地

营地功能统一使用底部功能卡：开始秘境、永久卡组、装备工坊、炼丹、修炼、突破试炼和仓库。开始秘境卡固定放在右下角，使用与其他场景退出卡相同的 `GameUI.siteExitCardPositon`；普通设施卡仍在左侧卡区排列。开始秘境对话框放入 `lib/widgets/dialog/`，参考 `ConfirmDialog` 的简单 `showDialog` 与 `ResponsiveView` 结构，不接入 `GameUIOverlay`，不逐张显示卡牌；仅提供当前卡组摘要、调整卡组、开始与取消。突破卡显示等级与破镜丹条件，通过 `startBreakthroughTrial` 发起试炼。首版不需要功能 NPC，不提供生产、日程或沙盒社交。

### 5.4 秘境房间交互与导航

进入房间时不自动进入战斗：

- 敌人未击败：点击敌人，通过普通对话确认后直接进入战斗，不经过 `PreBattleDialog`；
- 敌人已击败且搜刮未完成：保留原敌人 NPC 与头像，点击重新显示已保存的搜刮 Component；
- 敌人已完成搜刮：再次点击不产生交互，不重复战斗、搜刮或发奖；
- 商人：点击打开交易，可关闭、回访并再次交易；
- 休息角色：点击后通过对话执行恢复，不提供聚灵、修炼或卡牌库。

导航卡规则：

- 下一房间卡位于左下角；战斗胜利后显示，商人与休息房间始终显示，不要求完成搜刮；
- 返回前一房间卡位于右下角，`currentSceneIndex > 0` 时始终可用；
- 战斗胜利返回房间后自动发放普通物品，关闭战利品窗口后立即显示搜刮 Component；暂时关闭不妨碍前进或回访；
- Boss 胜利后显示返回营地卡；
- 前进与后退只修改 `currentSceneIndex`，回访读取原有房间实例，不重 roll 或重复发放任何内容。

### 5.5 代码组织

`lib/scene/dungeon/`：

- `camp.dart`：固定营地；
- `dungeon.dart`：统一 Flame Scene 外壳，持有并显示当前房间的搜刮 Component；
- `dungeon_controller.dart`：路线、门控、奖励幂等和结算；
- `dungeon_room_view.dart`：背景、NPC 与导航卡装配；
- `scavenge.dart`：当前场景内的三选一 Component，复用观星卡牌点选和开卡包五个卡位中的前三个；
- `room_actions.dart` 或少量类型处理器：战斗、交易与恢复。

场景组件不得各自修改路线索引、重复发奖或复制房间持久状态。

## 6. 数据与状态契约

### 6.1 JSON5 数据

新增 `assets/data/dungeon_scenes.json5` 与 `assets/data/dungeon_routes.json5`。

场景字段：

- `id`、`kind`、`title`、`description`、`background`；
- `enemy`：等级修正、精英标记、流派和卡组参数；
- `merchant`：商人类型池、商品类别、数量和价格参数；
- `reward`：内嵌旧版 `createReward()` 的概率与数量参数；
- `actions`：恢复等受控动作，不包含修炼或卡牌库。

示例：

```json5
spellcraft_gate: {
  id: 'spellcraft_gate',
  kind: 'battle',
  title: 'spellcraft_gate',
  description: 'spellcraft_gate_description',
  background: 'dungeon/background/spellcraft_gate.jpg',
  enemy: {
    name: 'dungeonGuard',
    levelBonus: 1,
    isElite: false,
    genre: 'spellcraft',
  },
  reward: {
    exp: {chance: 1.0},
    money: {chance: 1.0},
    equipment: {chance: 0.25, amount: 1},
    cardpack: {chance: 0.1, amount: 1},
    potion: {chance: 0.25, amount: 1},
    affixMaterial: {chance: 0.2, amount: 1},
  },
}
```

路线只包含有序 `sceneIds`。敌人、商人与库存在首次进入时生成，战斗奖励在胜利时生成，全部写入房间实例。

### 6.2 DungeonRun 与房间实例

`game.flags.dungeon` 至少保存：

- seed、`mode: scene_chain`、`rank`、`level`；
- `routeId`、`currentSceneIndex`；
- 以路线索引字符串为键的全部已访问 `rooms`；
- `active`、`battleResult`、`battleRoomIndex` 等必要流程状态。

房间实例：

```text
rooms: {
  '0': {
    sceneId,
    actor,              // 敌人、商人或设施角色；商人库存直接保存在 actor 中
    enemy,
    battleWon: false,
    rewards: null,      // 胜利返回房间时生成一次并保存
    rewardGranted: false,
    scavengeCandidates: null, // 战利品窗口关闭后生成三张并保存
    scavengeResolved: false,  // 选择或放弃均为完成，暂时关闭不算
    actionUses: {},
  },
}
```

自动发奖后将 `rewardGranted` 设为 `true`，清除 `battleResult` 与 `battleRoomIndex`，再展示战利品，避免场景重入重复结算。战利品窗口关闭后生成并保存 `scavengeCandidates`，随后自动显示搜刮 Component；暂时关闭不修改完成状态，选择或放弃后才将 `scavengeResolved` 设为 `true`。前进、后退、回访和读档不得重 roll 或重复发奖；新一层或新境界才开始新的房间实例集合。

### 6.3 无世界保存与恢复

只有普通 `CampScene` 或 `DungeonScene` 可以通过右上角 `DropMenuButton` 保存。战斗、战前、对话、战利品展示、搜刮三选一、交易、卡牌库、修炼、工坊和其他模态界面中不可保存。

`game.flags.dungeon`、当前英雄、仓库和全部房间实例随现有 game HTStruct 序列化。恢复时根据 `routeId`、`currentSceneIndex` 与 `rooms` 还原当前房间，不重新生成已有结果；未完成的搜刮继续显示原候选。`hero.dungeonId` 只用于秘境恢复标记，返回营地时清除。

已实现的空世界基础包括可空 `world`、可空 `SaveInfo.currentWorldId` 和不直接读取 `GameData.world['id']` 的保存入口。

## 7. 分阶段实施顺序

### 阶段 1：通用外壳与入口

- 完成 `CampScene`、`DungeonScene` 外壳和 NPC／功能界面解耦。
- 无尽模式只在开始新游戏时随机创建角色并进入营地。
- 增加营地仓库功能卡与 `hero.warehouse`。

### 阶段 2：单轮房间流程

- 实现简单开始秘境对话框，确认当前卡组或返回营地卡牌库调整；仅在没有可用非空卡组时提示并阻止初始化 `DungeonRun`。
- 实现 NPC 对话确认后直接进入战斗、胜利后自动发放普通物品与战利品展示，以及前进／后退，不接入 `PreBattleDialog`。
- 实现当前 `DungeonScene` 内的搜刮 Component，在战利品窗口关闭后自动显示；从敌人实际卡组抽取并固定三个候选，支持暂时关闭、点击敌人重开、选卡复制或明确放弃。
- 打通普通战斗 → 商人 → 恢复 → 精英，保存所有房间实例、搜刮候选和完成状态。
- 提前实现失败后的最小出口：返回营地、清理待结算战斗状态并恢复 `gameState.isInteractable`，不调用旧 `Game.onDying()`；物品、地牢卡和层级的完整失败结算仍在阶段 3 完成。
- 禁用秘境 Overlay 的卡牌库入口和背包卡包使用入口，保留修炼入口；修炼中只能手动升级和操作天赋，不能发起突破。

### 阶段 3：Boss 与跨轮结算

- 实现 Boss 返回营地、胜利层级推进、失败物品清理和层级归零。
- 胜利与失败均移除地牢卡，保留永久卡、仓库与装备栏。
- 实现永久卡组沿用和现有默认卡补位，不要求每轮重组。

### 阶段 4：手动升级、设施试炼与存档

- 保留现有手动升级；将境界节点改为使用 `checkRequirements()` 的普通天赋节点。
- 增加营地突破设施，检查等级与对应境界破镜丹，确认时消耗物品并进入试炼。
- 试炼失败只损失丹药；成功后提升角色境界、营地发展度和秘境境界，并将层级归零。
- 完成普通场景保存、当前房间恢复和 RNG 状态恢复。
- 按内容计划落地数据、本地化和校验。

### 阶段 5：整合

统一插画、导航卡、音效和反馈，再扩展其他流派，不等待五流派最终内容。

## 8. 测试与验收

### 数据与单元测试

- 场景、路线、动作、图片与本地化校验无错误。
- 开始确认框正确显示当前卡组摘要；无效 `battleDeckIndex` 只能回退到非空卡组，无可用非空卡组时禁止进入，调整卡组只进入营地卡牌库。
- 房间前进、回访和读档不重 roll；普通物品奖励只生成并自动发放一次。
- 战斗未胜利不能前进；胜利返回房间后战利品与背包实际获得内容一致，关闭战利品窗口后自动显示搜刮 Component，暂时关闭即可前进，不要求完成搜刮。
- 每次战斗胜利只从敌人实际出战卡组抽取三个不同卡牌实例一次；暂时关闭和重新打开保持候选不变。选择后复制卡牌、只给玩家副本设置 `isDungeonCard` 并加入卡库和当前锁定卡组，敌人原卡不变；选择或放弃后都不能重做或刷新。
- 秘境中不能打开卡包；营地开包所得永久卡只进入卡库、不自动进入卡组，失败会丢失未入库卡包。
- 默认卡只在非空卡组战斗时补位，不进入永久卡库；空卡组或全部默认卡不能开始秘境，地牢卡计入数量并在本轮结束后移除。
- 失败返回营地并恢复交互，不进入旧死亡或主菜单流程；完整结算只清空随身未保护物品，仓库、装备栏、永久卡和角色成长保留。
- 成功带回随身物品，移除地牢卡，下一轮层级增加且不超过上限。
- 手动升级正确扣除经验并增加天赋点；达到境界上限后不能升级。
- 境界节点不再触发试炼，`checkRequirements(..., checkRank: true)` 只判断境界，普通天赋点消耗正确；设施试炼另行判断等级。
- 试炼要求等级和对应境界破镜丹；开始即消耗，失败无其他惩罚，成功提升境界并重置秘境层级。
- 无世界读档与当前房间恢复正确，NPC 列表无越界或残留。

### 真实场景集成验证

1. 新游戏随机角色进入营地，将装备和材料存入仓库，选择非空永久卡组；开始秘境对话框正确显示摘要，调整按钮进入卡牌库，取消不初始化秘境，无可用非空卡组时不能开始。
2. 确认开始进入秘境，点击敌人对话确认后直接战斗，不出现旧战前准备界面；胜利返回房间后自动获得并展示普通战利品，关闭战利品窗口后在同一房间自动显示搜刮 Component。
3. 暂时关闭搜刮后前进或回访，再点击敌人重新打开，确认候选仍使用五个固定卡位中的前三个且内容不变；分别验证选卡与放弃：所选复制卡立即进入当前卡组且敌人原卡不变，放弃不获得，完成后 Component 真正关闭且不能再次搜刮。
4. 在秘境中获得经验并打开修炼界面，手动升级和分配天赋，但不能突破、打开卡牌库或打开背包中的卡包；回营地后才能开包并编辑永久卡组。
5. 商人离开后回访继续交易，库存保持；休息恢复每房只能使用一次。
6. 非空永久卡不足时战斗自动补默认卡；加入地牢卡可减少补位，返回营地后地牢卡消失。
7. Boss 胜利返回营地，随身物品和未打开卡包保留并可入库；下一轮敌人层级提高。
8. 失败返回营地并恢复交互，不进入旧死亡或主菜单流程；随身物品和未入库卡包丢失，仓库和已装备物品保留，下一轮从层级 0 开始。
9. 等级或破镜丹不足时不能试炼；材料充足后试炼失败只消耗丹药，再次尝试成功后境界提升、秘境层级归零。
10. 普通场景保存／读档后，当前房间、仓库、永久卡组、普通奖励、搜刮候选与完成状态和层级一致；模态界面不能保存。

### 标准验证命令

```bash
python build.py
flutter analyze
dart run utils/data_validate/game_data_validate.dart
flutter test
```

## 9. 文档同步范围

实施时同步 `plan/demo_scope.md`、`plan/dungeon_deck_lock.md`、玩家文档与 MOD 数据契约；战斗进入、奖励或写回变化时同步 `.agents/context/battle_system.md`。内容制作约定变化时同步相关 `.agents/skills/`。

## 10. 明确不在本计划内

- 每轮重新创建角色、失败返回主菜单或失败清空永久成长；
- 双角色、双份英雄资产或物品永久标记；
- 秘境中的卡牌库入口，或绕过设施直接突破境界；
- 随机路线、候选房间、格子地图与六边形地图；
- 沙盒世界时间、门派、任务和 NPC 日程；
- 战斗中中途存档；
- 五流派最终内容量和最终美术。
