# 场景链地牢：Location／NPCList 复用与实施计划

> 状态：阶段 1 已部分实施，包括随机角色入口、初始 `CampScene`、NPC／功能界面解耦和无世界存档基础；`DungeonScene`、固定路线流程、战斗门控与难度循环尚未实施。具体路线与美术明细见 `plan/scene_chain_content.md`。
>
> 目标依据：`plan/demo_scope.md`。当前版本采用“初始营地 + 场景链秘境”，不以六边形世界或六边形随机地牢承载核心玩法。
>
> 后续可选的格子房间扩展见 `plan/grid_dungeon.md`，不构成本计划首版场景链的前置依赖。

## 1. 结论与目标

现有 Location、NPCList、对话、战斗和奖励系统足以支撑新地牢的大部分表现与交互，但应采用**组件级和内容工厂级复用**，而不是把地牢塞进 Location 的世界地点模型。

推荐结构：

- 新建轻量 `CampScene` 与 `DungeonScene`，直接组合现有背景、场景卡和 UI Overlay。
- 由 Hetu 定义并初始化 `DungeonRun`，作为 HTStruct 保存在 `game.flags.dungeon`，统一管理当局场景、固定路线、难度、奖励和流程状态；Dart 不另建重复的持久状态对象。
- 复用 `BattleEntity`、战斗场景、对话、商人、物品与奖励生成，但不复用会写入世界坐标和世界对象的 `ObjectEnemy`、`ObjectMerchant` 等包装。
- 整个游戏只有一个当前英雄及其角色数据。营地和秘境直接读取、修改同一个英雄，不创建营地档案、当局角色或双份资产。
- 卡牌、装备、材料、金钱、经验和境界均在获得时直接写入当前英雄并持久保存。`isDungeonCard` 只是为未来沙盒融合预留的卡牌实例标记，DEMO 不据此清除卡牌。
- 秘境失败即结束本次游戏并返回主菜单，不删除既有存档；玩家可以读取存档，或重新开始并创建新的随机角色。
- Boss 胜利后英雄仍留在秘境中，可继续挑战更高难度，不返回营地，不做战利品入库或当局角色销毁。
- 存档系统正式支持“无六边形世界”的营地／秘境流程，不创建空白世界作为绕过方案。

首个可玩目标：

> 点击无尽模式 → 随机创建角色并进入初始营地 → 选择有效初始卡组 → 按固定顺序完成普通战斗、商人、营地、精英与 Boss → 保留同一角色和全部资产并开启更高难度；另验证失败后返回主菜单、读取存档可恢复失败前的进度。

## 2. 已确认的角色、资产与胜负规则

### 2.1 角色创建

首版不制作英雄创建或角色选择界面。每次从主菜单点击“无尽模式”时：

1. 创建一份无六边形世界的新游戏数据；
2. 使用与当前 `debug.generateHero()` 相同的方式随机创建一个角色；
3. 首版从等级 0、境界 0 开始，跳过角色创建和角色选择；
4. 直接进入第一个 `CampScene`。

角色命名、外观、流派选择和正式创建流程另行规划，不在本计划中扩展。

### 2.2 单一角色与资产

- `game.heroId` 始终指向当前唯一英雄，营地与秘境之间不切换英雄对象。
- 初始卡组、装备和后续奖励都直接使用该英雄的 `cardLibrary`、`battleDecks`、`inventory`、`equipments` 与 `materials`。
- 不建立 `game.camp`、`CampProfile`、永久卡库副本、当局卡组副本或装备深拷贝。
- 不需要 `highestRank`；当前英雄的 `rank` 就是已突破境界，突破成功后直接保存在英雄上。
- 永久卡获得时不需要额外入库；它已经在当前英雄的卡牌库中。永久升级也直接修改原卡牌实例。
- `isDungeonCard` 缺省为 `false`，不与 `isEphemeral` 或 `isUnpackable` 混用；DEMO 仅保存该标记，不执行失败清除、额外入库或卡面分流。

### 2.3 战斗失败与主动放弃

- 战斗失败或主动放弃即结束当前游戏进程中的这次冒险，返回主菜单。
- 不执行失败回血、返回营地、角色销毁、卡牌清除、装备销毁或战利品回滚。
- 不自动覆盖或删除既有存档。读取冒险中的存档可以恢复到对应场景边界。
- 再次点击无尽模式会创建新游戏和新的随机角色，不延续上一局的等级、天赋或资产。

### 2.4 Boss 与更高难度

- Boss 胜利后立即保留全部奖励和突破结果，当前英雄继续处于秘境模式。
- Boss 场景提供“挑战更高难度”，确认后增加 `difficulty`，将 `currentSceneIndex` 重置到路线起点，并按新难度生成新一批敌人、商人和奖励。
- 同一难度内回访、场景恢复和读档不得重 roll；只有明确开始下一难度时才重新生成路线实例内容。
- 首版不提供 Boss 后返回营地、收益入库或撤离结算。

## 3. 现有能力与复用判断

### 3.1 Location 场景外壳

可直接复用：

- 全屏插画背景、`PiledZone` 队列、聚焦和展开布局；
- `GameData.createSiteCard` / `createSiteCardByData`；
- 背景、卡片聚焦、鼠标指针和 Hover 的交互模式；
- `GameUIOverlay` 的现有面板和 NPC 区域。

不直接复用 Location 的世界职责：

- `_loadSites()` 中按城市／建筑 kind 硬编码的功能分发；
- `worldId`、`worldPosition` 和退出时的世界坐标写回；
- `GameData.getLocation()`、`GameData.getNpcsAtLocation()` 对全局沙盒数据的依赖；
- 进入时推进游戏时间、更新任务和门派地点的默认行为。

因此不继承 `LocationScene`，也不为地牢伪造 `Location` 对象。

### 3.2 NPCList 与 NPC 互动

需要支持：

- 可选 `onInteract` 回调，默认仍调用 `GameLogic.onInteractCharacter()`；
- 可选名称显示策略，功能 NPC 不依赖 `haveMet`；
- NPC 数量变化后 clamp／重置滚动起点；
- 离开营地或地牢场景时清空 `GameState.npcs`，避免泄漏到战斗或下一场景。

### 3.3 战斗、敌人与奖励

- `EnemyState.show()`、战前准备面板和 `BattleScene` 的显式 `heroData` / `enemyData` / `onBattleEnd` 可直接复用。
- 敌人直接由 `BattleEntity` 与 `generateBattleDeck()` 创建，不调用 `ObjectEnemy`。
- `createReward()` 生成的奖励直接通过 `Player.acquire()` 进入当前英雄，不经过待入库或营地结算。
- 战斗结束回调只负责当前场景胜负、奖励领取状态和固定路线门控，不操作六边形地图。
- 所有奖励生成结果在展示前保存到 `game.flags.dungeon`，重复回调和读档不得重复发奖。

### 3.4 商人、工坊与修炼的无世界适配

已核对的现有耦合与适配方式：

- 商人：`MerchantDialog` 可以直接消费包含 `inventory` 和 `materials` 的 `BattleEntity`，使用 `MerchantType.none`，关闭补货和偷窃；不要求 Location、门派或世界坐标。商人由独立工厂创建并调用 `characterInitItems()`，不调用 `ObjectMerchant`。
- 装备工坊：`WorkshopDialog` 已允许 `locationData == null`，但 `GameUIOverlay` 需要透传可选 `development`，以限制可打造稀有度；无 Location 时不把未领取成品写入地点。
- 炼丹：`AlchemyDialog.locationData` 改为可选，并由 Overlay 透传 `development`。
- 修炼：`CultivationScene` 已支持通过 `mode` 而不是 Location 选择模式，并具有显式 `development` 和 `advanceTime` 参数。当前只允许从初始营地功能卡进入，传入 `advanceTime: false`；秘境不提供修炼入口。
- 卡牌库与符箓工坊：只允许从初始营地功能卡进入。`DungeonScene` 的 `GameUIOverlay` 必须设置 `enableLibrary: false`、`enableCultivation: false`，休息房间也不得提供绕道入口。
- 休息：不调用依赖真实 Location、房租和世界时间的 `GameLogic.heroRest()`；由场景数据提供受控恢复动作。

## 4. 目标场景结构

### 4.1 场景栈与房间抽象

使用 Samsara 场景栈管理根场景和全屏功能界面，但**不为路线中的每个房间分别创建 Flame Scene**。整次秘境只创建一个持续存在的 `DungeonScene`，房间切换只替换背景、NPC、功能卡和当前可用动作。

场景栈结构：

```text
MainMenuScene
  → CampScene                 初始准备
      → CardLibraryScene      功法与精炼，仅营地
      → CultivationScene      修炼，仅营地
  → DungeonScene              整次秘境只创建一个
      → BattleScene           战斗时临时 push
      → 其他秘境功能界面      不包含卡牌库与修炼
```

战斗结束后回到同一个 `DungeonScene`，不得因返回房间而重新生成敌人、商人、商品或奖励。商人等模态界面继续使用现有 Overlay。

房间采用**统一数据模型 + 按类型分派动作处理器**，不为 `battle`、`merchant`、`rest` 等类型分别继承 Scene，也不把所有类型逻辑堆进一个巨型房间类：

- JSON5 房间模板：定义类型、标题、背景、卡图、敌人、商人池、奖励和动作参数；
- 运行时房间实例：作为 HTStruct 保存在 `game.flags.dungeon`，记录生成结果、完成状态和设施使用状态，不复制成另一份 Dart 持久对象；
- Dart 房间视图：根据当前房间实例装配共同外壳；
- Dart 动作处理器：按 `kind` 分派战斗、交易和设施行为。

`battle`、`elite` 与 `boss` 共用战斗处理器，区别来自数据配置；Boss 仅额外提供胜利后的下一难度动作。统一的是房间生命周期与交互协议，具体机制仍由类型处理器负责，避免在场景类中堆积大型 switch。

只有房间确实需要独立摄像机、碰撞、持续更新或复杂空间交互时，才允许临时 push 专用 Flame Scene；当前静态插画与功能卡房间不具备这种需求。未来格子模式也复用相同房间实例和动作处理器，只替换导航与地图展示。

### 4.2 初始营地

`CampScene` 使用固定营地插画，提供首批准备功能：

- 开始秘境；
- 初始卡组确认；
- 装备配置、工坊与炼丹；
- 修炼、基础教学与存档。

营地只是新游戏起点，不是每局失败或 Boss 后的返回点。开始秘境、卡牌库、装备工坊、炼丹和修炼等设施统一使用底部功能卡入口，不放入 NPCList。营地首版不需要功能 NPC；未来即使增加 NPC，也不提供移动、生产、日程或完整沙盒社交菜单。

### 4.3 固定路线地牢场景

`DungeonScene` 每次只展示一个当前房间：

1. 插画背景与房间标题；
2. 左上角 `NPCList` 中的当前敌人、商人或设施角色；
3. 左下角的下一房间卡，以及右下角的返回前一房间卡；
4. 由 `currentSceneIndex` 和房间实例决定可执行动作。

进入房间时不自动打开战前界面，也不立即进入战斗。首版房间内容主要通过 NPC 交互触发：

- 敌人未击败：点击敌人后通过对话选择是否战斗，确认后才打开现有战前准备界面；
- 敌人已击败：NPC 头像替换为宝箱，点击后领取该房间尚未领取的奖励；
- 商人：点击后打开交易界面，可以关闭、回访并再次交易，库存保持首次生成后的当前状态；
- 休息角色：点击后通过对话执行恢复；首版不提供聚灵、功法、修炼或卡牌库动作。

战斗胜利时生成并保存奖励，将 `battleWon` 设为 `true`，同时显示下一房间卡。**奖励领取不阻塞前进**：玩家可以暂时离开，之后通过返回卡回到房间，再点击宝箱领取。每个房间奖励只能领取一次；回访已领取房间不会重新生成或再次发放。

导航规则：

- 下一房间卡位于左下角；普通战斗、精英与 Boss 必须 `battleWon == true` 才显示，商人与休息房间始终显示；
- 返回前一房间卡位于右下角，`currentSceneIndex > 0` 时保留可用，包括当前敌人尚未击败时；
- 前进与后退只修改 `currentSceneIndex` 并切换房间实例，不销毁整次秘境的 `DungeonScene`；
- 回访敌人、商人和休息房间时读取原有实例，不重 roll 敌人、卡组、商品、库存、奖励或设施使用状态；
- Boss 胜利后显示下一难度卡，奖励是否领取不影响难度解锁。

首条路线只使用 `battle`、`elite`、`merchant`、`rest`、`boss`。固定顺序、敌人等级、奖励配置和逐场景资源见 `plan/scene_chain_content.md`。首版不提供随机路线、候选房间、格子地图、六边形地图或地图解密。

### 4.4 代码职责

`lib/scene/dungeon/` 按职责组织：

- `camp.dart`：初始营地；
- `dungeon.dart`：统一 Flame Scene 外壳，不负责具体房间规则；
- `dungeon_controller.dart`：路线、前进门控、奖励幂等和难度推进；
- `dungeon_room_view.dart`：根据当前房间实例装配背景、NPC 和功能卡；
- `room_actions.dart` 或少量类型处理器：战斗、交易与设施动作。

场景组件不得各自修改路线索引、重复发奖或直接复制房间持久状态。

## 5. 数据与职责分层

首版采用 **Dart 流程控制 + JSON5 内容数据 + 现有 Hetu 内容工厂**。不新建地牢专属脚本流程层，也不默认提供 `onEnter`、`onComplete` 等场景脚本回调。

### 5.1 场景与固定路线数据

新增：

- `assets/data/dungeon_scenes.json5`：场景模板，顶层对象和 snake_case ID；
- `assets/data/dungeon_routes.json5`：固定路线，每条以 ID 为键，包含有序 `sceneIds`。

场景字段控制在：

- `id`、`kind`、`title`、`description`；
- `background`；
- `enemy`：等级修正、精英标记、流派和卡组参数；
- `merchant`：商人类型池、商品类别、数量和价格参数；
- `reward`：直接内嵌旧版 `createReward()` 的概率与数量参数；
- `actions`：休息恢复等受控动作类型与参数；首版不包含精炼、修炼或卡牌库入口。

战斗房间示例：

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
    cardpack: {chance: 0.4, amount: 1},
    potion: {chance: 0.25, amount: 1},
    affixMaterial: {chance: 0.2, amount: 1},
  },
}
```

商人房间使用 `merchant: {kinds: ['smith', 'enchanter', 'pharmacist', 'bookDealer'], itemCount: 5, money: 500000}`，具体类别映射沿用旧版内容。休息房间使用 `actions` 列表，不为每种动作增加脚本回调。

路线示例：

```json5
spellcraft_intro: {
  id: 'spellcraft_intro',
  sceneIds: [
    'spellcraft_gate',
    'spellcraft_gallery',
    'spellcraft_merchant',
    'spellcraft_sanctum',
    'spellcraft_elite',
    'spellcraft_depths',
    'spellcraft_boss',
  ],
}
```

路线只规定场景顺序，不包含候选房间、权重、门锁或空间位置。敌人、商人类型、商品、库存和奖励在首次进入房间时生成；战斗奖励在胜利时生成。所有结果写入对应房间实例，之后只读取已保存结果。

### 5.2 Dart

负责场景装配、固定路线加载、完成状态、前进硬门控、战斗回调、奖励幂等、难度推进、场景恢复和通用交互锁。

Dart 通过 `dynamic` 和 `[]` 直接读取、修改 HTStruct，不复制字段到另一份 Dart 持久对象。UI 通知复用 `GameState.currentDungeon` 与 `updateDungeon()`，持久真值仍只有 `game.flags.dungeon`。Dart 中不出现具体敌人、场景、路线或奖励内容 ID。

### 5.3 Hetu 与 JSON5

Hetu 负责：

- `DungeonRun` 初始化并写入 `game.flags.dungeon`；
- `BattleEntity` 与 `generateBattleDeck()` 创建敌人和卡组；
- 无世界商人创建与 `characterInitItems()`；
- `createReward()`、卡牌、装备和物品工厂。

JSON5 负责场景、路线、数值参数、图片和本地化绑定。新增数据校验检查 ID、枚举、动作参数、图片、引用和本地化键，并同步 `docs/docs/mod/` 契约。

## 6. 当局状态与存档

### 6.1 DungeonRun 与房间实例

`game.flags.dungeon` 至少保存：

- 当局 seed、`mode: scene_chain`；
- 当前秘境 `rank`、`level`、`levelMax`；
- 固定路线 `routeId` 与 `currentSceneIndex`；
- 以路线索引字符串为键的 `rooms`，保存所有已经访问的房间；
- 全局 `active`、`battlePending` 和交互锁所需的流程状态。

房间实例建议结构：

```text
rooms: {
  '0': {
    sceneId,
    actor,              // 敌人、商人或设施角色；商人库存直接保存在 actor 中
    enemy,              // 战斗房间使用的 BattleEntity
    battleWon: false,
    rewards: null,      // 胜利时生成一次
    rewardClaimed: false,
    actionUses: {},     // 恢复等设施的使用次数
  },
}
```

`rewardPending` 由 `rewards != null && !rewardClaimed` 派生，不另存容易失同步的布尔值。宝箱头像、下一房间卡和商人交互也由房间实例派生。首版不保存候选房间、门锁、体力、格子地图、待入库战利品或第二份角色资产。

状态转换集中在 Dart 地牢控制器中。战斗回调只设置战斗结果并生成奖励；领奖只修改对应房间的 `rewardClaimed`；前进与后退只修改 `currentSceneIndex`，不得清空其他房间实例。

### 6.2 难度与境界推进

沿用旧版 `DungeonFlags` 和 `nextLevel` 的层级结构，但取消门票和旧地图入口：

- 开始秘境时 `rank` 取当前英雄境界，`level = 0`；
- `levelMax = rank * 2 + 1`，`minEnemyLevel = minLevelForRank(rank)`；
- 房间敌人等级为 `minEnemyLevel + level + enemy.levelBonus`；
- 首轮路线各房间的 `levelBonus` 见 `plan/scene_chain_content.md`；
- Boss 后若 `level < levelMax`，则 `level += 1`；否则在尚未达到内容上限时 `rank += 1`、`level = 0` 并重新计算 `levelMax`；
- 每次进入新难度都重置 `currentSceneIndex = 0` 并创建新的 `rooms`，同一英雄和全部资产保持不变；
- 达到当前内容上限后显示完成反馈，不继续无限增加数值。

### 6.3 无世界保存与恢复

`game.flags.dungeon` 随整个 game HTStruct 自动序列化，场景栈继续保存构造 ID 与可序列化参数，不新增独立地牢存档文件。

只有位于普通 `CampScene` 或 `DungeonScene` 时才能保存，由右上角现有 `DropMenuButton` 提供。战斗、战前准备、对话、奖励领取、商人交易、卡牌库、修炼、工坊和其他模态界面中不提供保存操作；需要返回普通场景后再保存。

无场景记录时按英雄是否处于秘境回退到 `DungeonScene` 或 `CampScene`。恢复 `DungeonScene` 时根据 `routeId`、`currentSceneIndex` 和 `rooms` 还原当前房间，不重新生成任何已有结果。`hero.dungeonId` 仅作为秘境模式与读档恢复标记，Boss 胜利后继续保留。

已实现的空世界存档基础包括：`loadGameFromJsonData()` 允许 `world == null`，`SaveInfo.currentWorldId` 与保存接口允许空值，保存入口不直接读取 `GameData.world['id']`。当局 RNG、所有房间实例和未领取奖励均随存档保存，避免读档重 roll 或重复领奖。

## 7. 分阶段实施顺序

### 阶段 1：通用场景外壳与入口

- 新建 `CampScene` 和 `DungeonScene` 外壳，组合背景、`PiledZone`、场景卡与 `GameUIOverlay`。
- 改造 `NpcList`，完成商人、工坊、炼丹和修炼的无 Location 适配。
- 无尽模式入口每次创建新游戏和随机角色，直接进入初始营地。

### 阶段 2：当局流程与战斗门控

- 初始化 `DungeonRun`，接入普通战斗、战前准备、直接奖励与固定顺序前进。
- 完成奖励领取和重复点击防护。
- 打通普通战斗 → 随机商人 → 休息 → 精英的基本序列，商人与库存只生成一次。

### 阶段 3：Boss 与难度循环

- 接入完整固定路线、Boss 和胜利奖励。
- Boss 后保留同一英雄和全部资产，开启更高难度并重新生成路线实例。
- 实现失败与主动放弃返回主菜单，以及读取既有存档恢复。

### 阶段 4：存档与内容补齐

- 完成无世界保存、场景边界恢复、`hero.dungeonId` 根场景判断与 RNG 状态恢复。
- 按 `plan/scene_chain_content.md` 落地路线、敌人、奖励和本地化。
- 完成数据校验、文档与操作提示。

### 阶段 5：整合与后续扩展

- 统一场景插画、选项卡、音效和反馈。
- 再扩展御剑及其他流派，不在场景框架阶段等待五流派内容。

## 8. 测试与验收

### 数据与单元测试

- 场景 ID、路线引用、动作参数、图片和本地化校验无错误。
- 同一房间实例在保存前后一致，敌人、商人与奖励不会因前进、回访或读档重 roll。
- 战斗未完成时不能前进；胜利后即使尚未领奖也能前进；每个房间只能领取一次奖励。
- 同一英雄的卡牌、装备、材料、天赋与境界在营地、秘境和读档后保持一致，不存在双份资产。
- 初始卡组数量等于当前有效下限，秘境中不能切换、创建或删除卡组；删牌低于下限时按现有规则以默认卡补齐。
- 难度按旧版层数推进，达到 `levelMax` 后提升秘境境界并重建路线实例。
- 无世界读档允许 `world == null`，根场景与当前房间恢复正确。
- NPC 列表数量变化后无滚动越界，场景退出后无 NPC 残留。

### 真实场景集成验证

1. 每次点击无尽模式都会创建新的随机角色并进入初始营地，不出现角色创建界面。
2. 开始秘境 → 点击敌人并确认战斗 → 胜利后出现前进卡且 NPC 变为宝箱 → 不领奖直接前进 → 返回后领取奖励。
3. 商人交易 → 离开并回访后再次交易，商人类型与剩余库存不重置；休息设施状态同样保留。
4. 突破成功后当前英雄境界直接提升，下一难度继续使用同一英雄。
5. Boss 胜利 → 按旧版层数／境界规则开启更高难度 → 全部卡牌、装备、材料与金钱保留。
6. 战斗失败或主动放弃 → 返回主菜单 → 可读取既有存档；再次开始则创建新角色。
7. 在营地和普通秘境房间保存／读档，确认当前房间、全部房间实例和未领取奖励一致；战斗与模态界面中不能保存。

### 标准验证命令

```bash
python build.py
flutter analyze
dart run utils/data_validate/game_data_validate.dart
flutter test
```

## 9. 文档同步范围

实施各阶段时同步：

- `plan/demo_scope.md`、`plan/dungeon_deck_lock.md`：单一角色、资产保留、失败与难度规则；
- `docs/docs/how2play/rpg/encounter/`、`dungeon/` 或对应页面：固定路线、前进、Boss、失败与存档规则；
- `docs/docs/mod/`：场景与路线字段、受控动作、内容工厂和生成结果保存契约；
- `.agents/context/battle_system.md`：战斗进入、奖励或写回机制变化时更新；
- 相关 `.agents/skills/`：既有内容制作约定变化时更新。

## 10. 明确不在本计划内

- 英雄创建、英雄选择和正式新游戏配置界面；
- 营地／当局双角色、永久资产副本、入库结算、失败清档或地牢卡清除；
- Boss 后返回营地或撤离；
- 下一场景卡选择、随机路线和格子地图；
- 六边形地图、空间迷宫、寻路和地图解密；
- 沙盒世界时间、门派、任务、NPC 日程与完整社交；
- 战斗中中途存档与恢复；
- 五流派最终内容量和最终美术。
