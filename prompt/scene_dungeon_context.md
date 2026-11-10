# 场景链秘境重构：文件索引

> 场景链处于实施中：阶段 1 的营地、秘境外壳、仓库和无世界基础已完成；固定路线、房间交互、战斗门控与跨轮结算尚未实施。不要根据后续计划假定运行时代码已经支持对应功能。

当前方向是将 DEMO 收敛为固定营地与固定顺序的场景链秘境，复用现有卡牌战斗、装备、角色和存档能力。六边形世界与旧六边形地牢不属于当前 Demo 的必经流程。

## 推荐阅读顺序

| 文件 | 状态与用途 |
| --- | --- |
| `plan/demo_scope.md` | 当前 Demo 的总体定位、范围与验收边界。 |
| `plan/scene_chain_dungeon.md` | 当前首要实施计划：Location／NPCList 复用、固定路线、营地、永久成长与存档。 |
| `plan/dungeon_deck_lock.md` | 秘境卡组锁定、卡牌生命周期与永久卡库的相关约定。 |
| `plan/grid_dungeon.md` | 后续可选的格子房间扩展；不是首版依赖，不应提前实施。 |

## 相关现有代码入口

- `lib/scene/location/location.dart`：插画背景、功能卡和 Location 场景外壳。
- `lib/widgets/npc_list.dart`：NPC 列表与互动入口。
- `lib/state/game_save.dart`、`lib/data/game.dart`、`scripts/main/data/game.ht`：游戏创建、保存与读档。
- `scripts/main/event/dungeon.ht`、`scripts/main/world/dungeon.ht`：旧六边形地牢的遭遇、敌人、商人和奖励设计参考。
- `lib/scene/mini_game/mouse_maze/mouse_maze.dart`：仅供未来格子地图绘制参考，不是当前场景链实现基础。

先阅读计划文件，再按实际任务查看上述代码。不要修改或扩展 `grid_dungeon.md` 中的后续机制，除非当前任务明确要求。
