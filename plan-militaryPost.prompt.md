## Plan: 哨所(Military Post)基础侦察功能

哨所提供城市侦察功能：玩家选择一个已发现的城市为目标，支付费用后派出斥候。斥候在若干天后返回（异步非阻塞），玩家回到哨所查看侦察报告，获得目标城市的建筑列表+规模、资源存量范围、驻守NPC数量和最高境界。

### 与观星台的情报分工

| | 观星台（被动/神秘） | 哨所（主动/现实） |
|---|---|---|
| **对象** | 角色隐藏属性、门派类型、外交关系 | 城市建筑布局、资源存量、兵力情况 |
| **手段** | 占卜消耗灵材，即时出结果 | 派出斥候消耗金钱，需等待若干天 |
| **行动性** | 纯信息获取 | 升级后可执行破坏/保护（本次不做） |

---

### Phase 1: 数据与常量准备

1. **添加哨所常量** — 在 [lib/data/common.dart](lib/data/common.dart) 中定义侦察基础费用（按rank缩放）、等待时间公式（按距离缩放，基础3天+距离因子）
2. **定义侦察任务数据** — 存储在 `game['flags']` 中，包含 targetCityId、startTimestamp、endTimestamp、postLocationId
3. **添加本地化字符串** — `assets/locale/zh/` 中添加侦察相关文本（派出斥候、选择目标、费用提示、报告标题、斥候未返回等）

### Phase 2: 场景UI入口

4. **LocationScene 添加 militarypost case** — 在 [lib/scene/location/location.dart](lib/scene/location/location.dart) 的 `_loadSites()` 中创建"派出斥候"卡牌，点击调用 `GameLogic.onInteractMilitaryPost()`

### Phase 3: 核心逻辑

5. **实现 `_onInteractMilitaryPost()`** — 在 [lib/logic/location.dart](lib/logic/location.dart) 中：
   - 检查是否有进行中的侦察任务：
     - 已完成（timestamp >= endTimestamp）→ 生成报告，展示给玩家，清除任务
     - 未完成 → 提示"斥候尚未返回，预计X天后回来"
   - 无任务 → 弹出已发现的城市列表（排除当前城市），显示距离和费用
   - 选择后确认支付 → 扣费 → 写入 flags → 记录 Incident 日志

6. **侦察报告生成** — 读取目标城市数据：
   - **建筑列表+规模**：遍历城市 siteIds，获取 kind 和 development
   - **资源存量**：获取城市资源，模糊化为"匮乏/一般/充裕/丰富"
   - **驻守NPC**：统计 locationId 属于此城市的角色数量 + 最高 rank
   - 以对话框展示 + 写入 Incident 日志

7. **距离与费用计算** — hex距离影响等待天数和费用：
   - 等待天数 = 3 + distance / speed_factor
   - 费用 = baseCost × (rank + 1) × (1 + distance / 10)

### Phase 4: 注册

8. **在 [lib/logic/logic.dart](lib/logic/logic.dart) 注册** `onInteractMilitaryPost` 静态方法

---

**Relevant files**
- [lib/data/common.dart](lib/data/common.dart) — 侦察费用和时间常量
- [lib/data/game.dart](lib/data/game.dart) — flags 操作、MonthlyActivityIds
- [lib/scene/location/location.dart](lib/scene/location/location.dart) — `_loadSites()` 添加 militarypost case
- [lib/logic/location.dart](lib/logic/location.dart) — 新增 `_onInteractMilitaryPost()`
- [lib/logic/logic.dart](lib/logic/logic.dart) — 注册静态入口
- [scripts/main/incident.ht](scripts/main/incident.ht) — Incident 创建模式参考

**Verification**
1. 进入有哨所的城市，确认出现"派出斥候"卡牌
2. 点击后弹出已发现城市列表，显示距离和费用
3. 支付后确认费用扣除 + 日志记录
4. 未到时间回来 → 提示"斥候尚未返回"
5. 时间到达后回到哨所 → 展示侦察报告，内容准确
6. 余额不足时提示并阻止

**Decisions**
- 仅实现侦察，不做破坏/保护（升级功能留后续）
- 每个哨所同一时间只能有一个侦察任务
- 只能侦察已发现的非当前城市
- 侦察结果不缓存，查看后清除

**Further Considerations**
1. **侦察任务存储** — 建议用 `game['flags']['scoutMission_{locationId}']` 存储，简单直接
2. **多哨所独立** — 不同城市的哨所各自追踪自己的任务
3. **哨所关闭时** — 进行中的任务不取消，但无法查看报告直到重新开放
