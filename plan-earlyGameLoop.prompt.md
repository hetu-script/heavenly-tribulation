## Plan: 开局玩法循环优化

三项改动：(A) 斗技场添加战利品掉落+经验；(B) 英雄初始城市保障斗技场+秘境；(C) 悬赏任务添加经验奖励。

### 改动后的收益矩阵

| 活动     | 风险                | 收益                            | 定位         |
| -------- | ------------------- | ------------------------------- | ------------ |
| 悬赏任务 | 低（失败仅耗体力）  | 金钱/灵石/功勋 + **经验**       | 稳定收入     |
| 斗技场   | 中（赌注货币）      | 货币 + **装备/丹药** + **经验** | 进阶挑战     |
| 秘境     | 高（门票+失败离场） | 装备/丹药/秘籍/经验/材料        | 核心装备来源 |

### Steps

**Phase A: 斗技场战利品+经验** — 修改 location.dart 的 `_onInteractArena` `onBattleEnd` 胜利分支，调用 `createReward` 生成：
exp_pack, 数值为`expForLevel(heroLevel) × tierExpRate`，Low 0.08、Mid 0.18、High 0.28，概率100%。
equipment，最多1件，根据档位，概率为10%,30%,50%
potion，最多1件，根据档位，概率为10%,30%,50%
然后用 `Player.acquire` 获取，并用 `Game.promptItems` 展示。

**Phase B: 初始城市保障** — 在 world.dart 的 `_onAfterLoadedInGameMode()` 中新增代码：检查英雄所在据点有无 arena site（没有则创建）；检查据点领地有无 dungeon（没有则在可用地块创建，不设 sectId），创建方法参考sandbox.ht。

**Phase C: 悬赏任务经验** — 修改 quest.ht Quest 构造函数，添加 exp 奖励。数值：`expForLevel(heroLevel) × (difficulty × 0.04 + 0.05)`，难度1约9%、难度5约25%。任务数据中的经验包物品数据格式参考脚本接口createLoot的注释。同时也需要修改任务描述文本（logic/game.dart中的`getQuestDetailDescription`），提示玩家有经验奖励。
