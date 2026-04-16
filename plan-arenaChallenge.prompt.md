## Plan: 斗技厅(Arena)基础功能

在斗技厅中添加"挑战"交互，玩家选择赌注档位后随机匹配同境界对手战斗，胜负决定赌注去留。对手优先从世界中在家的同境界NPC中随机选取，无合适目标时临时生成路人角色。

---

### Phase 1: 数据与常量准备

1. **添加赌注常量** — 在 [lib/data/common.dart](lib/data/common.dart) 添加基础赌注映射。rank 0 用铜钱，rank >= 1 用灵石。3档倍率：1x / 3x / 5x。同步导出到 Hetu 侧（[lib/data/constants.dart](lib/data/constants.dart) + [scripts/main/binding/constants.ht](scripts/main/binding/constants.ht)）
2. **添加本地化字符串** — 在 `assets/locale/zh/site.json` 中添加：挑战、赌注选择、胜利/失败提示、余额不足提示、路人角色名称等

### Phase 2: 场景UI入口

3. **LocationScene 添加 arena case** — 在 [lib/scene/location/location.dart](lib/scene/location/location.dart) 的 `_loadSites()` switch 中添加 `case 'arena':`，创建"挑战"卡牌，点击调用 `GameLogic.onInteractArena()`。卡牌图片使用`images/location/card/arena.png`。

### Phase 3: 核心逻辑

4. **实现 `_onInteractArena()`** — 在 [lib/logic/location.dart](lib/logic/location.dart) 中：
   - 弹出对话框选择赌注档位（低/中/高）
   - 检查余额是否足够，不足则提示
   - 扣除赌注 → 匹配对手 → `EnemyState.show()` 发起战斗
   - **胜利**：返还赌注 + 获得等额奖金
   - **失败**：赌注不返还 + 当前生命减半

5. **对手匹配逻辑** — 遍历 `GameData.game['characters'].values`，过滤 rank 相同 + 在家（`locationId == homeSiteId`） + 非英雄非同伴。从候选列表随机选一个。已经挑战过的对手，本月内将不会再出现，之后继续挑战将只能遇到随机生成的路人对手。

6. **赌注基础金额** — rank 0: 1000铜钱；rank 1+: `1+2^rank` 灵石（即2/5/9/17/33）。二档翻倍，三档五倍。赌注金额会直接影响对手等级，赌注越高，对手越强。

7. **路人角色生成** — 无合适NPC时，通过 `BattleEntity(rank: hero['rank'])` 生成临时角色，使用默认名字——固定的本地化字符串，例如修士，游侠，浪人等随机名字。名字也会和档位（难度）有关，例如壮硕，强大，等形容词。NPC角色数据战后丢弃。

### Phase 4: 注册入口

7. **在 [lib/logic/logic.dart](lib/logic/logic.dart) 注册** — 添加 `onInteractArena` 静态方法，转发到 `_onInteractArena()`

---

**Relevant files**

- [lib/data/common.dart](lib/data/common.dart) — 赌注常量定义
- [lib/scene/location/location.dart](lib/scene/location/location.dart) — `_loadSites()` 添加 arena case（参考 hotel case）
- [lib/logic/location.dart](lib/logic/location.dart) — 新增 `_onInteractArena()`（参考 `_onInteractDaoStele()` 和 sect trial 的战斗流程）
- [lib/logic/logic.dart](lib/logic/logic.dart) — 注册静态入口
- [lib/logic/character.dart](lib/logic/character.dart) — 参考 NPC rank 过滤（L1002）和 `EnemyState.show()` 模式（L920+）
- [assets/locale/zh/](assets/locale/zh/) — 本地化字符串

**Decisions**

- 仅实现基础挑战，不做升级功能（擂台赛/招募）
- 挑战次数无限制
- 路人角色临时生成战后丢弃，不加入世界
