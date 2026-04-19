## Plan: 门派外交关系数据结构设计

重构现有 `Diplomacy` struct，从单一的三元分类扩展为支持 6 种关系类型的外交系统，保持对称双向、纯事件驱动。以角色 Bond 系统为蓝本但大幅简化，优先满足镇魔司和幻术堂的数据需求。

### 现状

- `Diplomacy` struct 已定义（`scripts/main/data/sect/sect.ht` L6）
- `game.diplomacies` 全局存储已有
- 月会系统提到了外交通知但未实现

### 关系类型（6 种）

| type      | 含义     | 评分要求 | 设施共享         | 入城限制     | 备注                     |
| --------- | -------- | -------- | ---------------- | ------------ | ------------------------ |
| `neutral` | 中立     | 无       | 否（可租用）     | 无限制       | 默认初始状态             |
| `pact`    | 互不侵犯 | 20       | 否（可租用）     | 合同约定     | 承诺不宣战，违约有惩罚   |
| `ally`    | 同盟     | 50       | 全部设施免费共享 | 无限制       | 无法宣战，最高级正面关系 |
| `enemy`   | 敌对     | -20      | 否（不可租用）   | 仅允许无境界 | 宣战状态                 |
| `truce`   | 停战     | 无       | 否（不可租用）   | 合同约定     | 无法宣战，到期转 neutral |

互不侵犯、贸易、结盟、停战都需双方同意，宣战则单方面即可。

A 对 B 宣战时，B 的盟友 C 应该自动对 A 降低 score（-5）。

附庸类型（vassal）和贸易类型（trade）暂保留，因为涉及交易路线，贡品缴纳等复杂逻辑，后续再做。

### 新增常量

`kDiplomacyScorePactThreshold = 20`、`kDiplomacyScoreTradeThreshold = 30`

### Score 驱动事件（DEMO 阶段）

1. **领土争夺**：占领城市 -20，失去城市时攻方 +5
2. **成员互动**：成员被击杀 -10，完成帮助请求 +5
3. **外交行为**：赠礼 +gift/10，宣战 -30（旁观门派也 -5）
4. **事件触发**：暗杀任务完成 -15（被发现额外 -10），镇魔司悬赏完成 -5

### 实现步骤

#### Phase 1: 常量层

8. Dart 侧新增常量（`lib/data/common.dart`），Hetu 常量同步（`scripts/main/data/common.ht` + `lib/data/constants.dart` + `scripts/main/binding/constants.ht`）
9. 本地化字符串（`assets/locale/zh/`）

#### Phase 2: 脚本侧新API（脚本侧）

修改或新增 API 函数

1. `updateDiplomacy(sect1, sect2, { type, score, timespanByMonth })` — 更新或创建关系类型和分数，调用此接口会触发外交 Incident。并且会根据具体关系，更新sect.enemySectIds和sect.allySectIds。同时所有外交关系变更会记录到sect.flags.monthly.diplomaciesChanges中，供月会通知使用。
2. `updateDiplomacyScore(sect1, sect2, delta)` — 仅更新分数，不触发 Incident，但用engine.info记录日志
3. `getDiplomacy(sect1, sect2)` — 获取当前关系数据
4. `isHostile(sect1, sect2)` — 快捷查询是否敌对门派
5. `canAccessLocation(character, location)` — 入城检查
6. `getEnemySectMembers(sect)` — 快速获取所有敌对门派的所有成员
7. 查询函数 `canAccessLocation`、`getEnemySectMembers`

#### Phase 3: 脚本侧旧API和数据修改（_depends on Phase 2_）

8. `sandbox.ht`中，世界生成时为相邻门派建立初始外交关系。门派只对离自己近（以总部所在据点判断距离）的几个有随机的pact和enemy关系，远的保持neutral。然后最终会在整个地图上随机对一些尚无关系的门派之间创建一两个敌对关系。具体的距离数值和关系数量，由地图大小和地图中的门派数量决定。
9. 领土变更挂钩 — 在 `addLocationToSect`/`removeLocationFromSect` 中触发分数变动
10. 增加一种特殊的职位`envoy`（不涉及职级，单纯是功能性职位，只是一个临时性的title。）受掌门委托负责门派外交，类似使者或者外交官之类。拥有此职位的角色可以在对方门派总部NPC处看到外交相关互动选项。并且在完成任务后此称号和职位就被收回。

#### Phase 4: Dart 侧API和UI（_depends on Phase 2_）

11. \_onInterectNpc，在和门派总部NPC互动时，如果玩家是掌门或者外交官（当前头衔为`envoy`），会看到一个新的选项，第一级菜单显示为`门派外交`，点进去之后，会根据两个门派之间现在的关系，提供一些选项，例如订立条约（互不侵犯，同盟），宣战，停战，等等。这个功能之前已经部分实现，可以检查逻辑并完善。
12. \_updateSectMonthly需要检查外交关系的有效时间，如果有到期的关系（例如停战），需要自动变更为 neutral。此变更调用updateDiplomacy接口，会有相应事件和记录。
13. \_checkRented现在需要判断门派关系
14. 月会外交通知 — 补全 `lib/logic/sect.dart` 月会 Part 1
15. 外交操作 UI — 门派界面新增宣战/结盟/签约等操作
16. 门派信息视图SectView增加当前关系列表

### Relevant Files

- `scripts/main/data/sect/sect.ht` — Diplomacy struct 重构、API 函数实现、确认 sect.diplomacies 初始化
- `scripts/main/data/game.ht` — 确认 game.diplomacies 初始化
- `lib/data/common.dart` — Dart 侧新增外交常量
- `lib/data/constants.dart` — HTExternalClass 桥接
- `scripts/main/binding/constants.ht` — Hetu 侧桥接常量
- `lib/logic/sect.dart` — 月会相关外交剧情（目前只对本月本门派的外交变化做通知）
- `assets/locale/zh/` — 本地化字符串

### TODO

暂时没有添加进入领地和进入据点时候敌对门派的判断和剧情对话相关。单纯提供了初步逻辑。
没有提供真正的战争选项。目前外交关系除了对进入建筑场景有影响，其他均无任何影响。
