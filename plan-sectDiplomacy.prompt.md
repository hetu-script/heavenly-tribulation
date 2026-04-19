## Plan: 门派外交关系数据结构设计

重构现有 `Diplomacy` struct，从单一的三元分类扩展为支持 6 种关系类型的外交系统，保持对称双向、纯事件驱动。以角色 Bond 系统为蓝本但大幅简化，优先满足镇魔司和幻术堂的数据需求。

### 现状

- `Diplomacy` struct 已定义（`scripts/main/data/sect/sect.ht` L6）
- `game.diplomacies` 全局存储已有
- 月会系统提到了外交通知但未实现

### 关系类型（6 种）

| type      | 含义     | 设施共享         | 入城限制     | 备注                     |
| --------- | -------- | ---------------- | ------------ | ------------------------ |
| `neutral` | 中立     | 否（可租用）     | 无限制       | 默认初始状态             |
| `pact`    | 互不侵犯 | 否（可租用）     | 合同约定     | 承诺不宣战，违约有惩罚   |
| `ally`    | 同盟     | 全部设施免费共享 | 无限制       | 无法宣战，最高级正面关系 |
| `enemy`   | 敌对     | 否（不可租用）   | 仅允许无境界 | 宣战状态                 |
| `truce`   | 停战     | 否（不可租用）   | 合同约定     | 无法宣战，到期转 neutral |

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

#### Phase 1: 数据层（脚本侧）

修改或新增 API 函数

1. `updateDiplomacy(sect1, sect2, { type, score, timespanByMonth })` — 更新关系类型和分数，添加外交 Incident
2. `updateDiplomacyScore(sect1, sect2, delta)` — 仅更新分数，不触发 Incident，但用engine.info记录日志
3. `getDiplomacy(sect1, sect2)` — 获取当前关系数据
4. `isHostile(sect1, sect2)` — 快捷查询是否敌对门派
5. `canAccessLocation(character, location)` — 入城检查
6. `getEnemySectMembers(sect)` — 快速获取所有敌对门派的所有成员

#### Phase 2: 常量层（_parallel with Phase 1_）

5. Dart 侧新增常量（`lib/data/common.dart`）
6. Hetu 常量同步（`scripts/main/data/common.ht` + `lib/data/constants.dart` + `scripts/main/binding/constants.ht`）
7. 本地化字符串（`assets/locale/zh/`）

#### Phase 3: 逻辑集成（_depends on Phase 1_）

8. 查询函数 `canAccessLocation`、`getEnemySectMembers`
9. 领土变更挂钩 — 在 `addLocationToSect`/`removeLocationFromSect` 中触发分数变动
10. 月更新中调用 `checkDiplomacyExpiry()`
11. 世界生成时为相邻门派建立初始外交关系（lazy init，不两两穷举）

#### Phase 4: Dart 侧集成（_depends on Phase 2_）

12. 月会外交通知 — 补全 `lib/logic/sect.dart` 月会 Part 1
13. 外交操作 UI — 门派界面新增宣战/结盟/签约等操作

### Relevant Files

- `scripts/main/data/sect/sect.ht` — Diplomacy struct 重构、API 函数实现、确认 sect.diplomacies 初始化
- `scripts/main/data/game.ht` — 确认 game.diplomacies 初始化
- `lib/data/common.dart` — Dart 侧新增外交常量
- `lib/data/constants.dart` — HTExternalClass 桥接
- `scripts/main/binding/constants.ht` — Hetu 侧桥接常量
- `lib/logic/sect.dart` — 月会相关外交剧情（目前只对本月本门派的外交变化做通知）
- `assets/locale/zh/` — 本地化字符串

### Decisions

- 对称双向（一条记录共享），不做角色 Bond 那样的单向模式
- 纯事件驱动，不做 score 自然衰减
- 世界生成时建立部分初始关系。门派只对离自己近（以总部所在据点判断距离）的几个有高级关系，远的保持neutral。
