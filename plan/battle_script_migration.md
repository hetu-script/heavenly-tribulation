# 战斗内容脚本化改造

> 目的：消除战斗引擎（`lib/scene/battle/`）中的内容 id 硬编码，把内容行为统一迁移到 Hetu 脚本；
> 为绝世装备与后续流派开发铺平「被动 → 永久状态 → 状态脚本」路径。
> 分层准则见 `AGENTS.md`「战斗内容分层」。

## 背景

悟道流派开发中，以下境界/分支节点行为以内容 id 硬编码在 Dart 侧：

| 节点                    | 位置                  | 行为                                       |
| ----------------------- | --------------------- | ------------------------------------------ |
| 太上感应（rank_1）      | character.dart:675    | 产出阶段按灵力发放灵气                     |
| 天道循环（rank_2）      | battle.dart:352       | 组牌阶段悟道牌灵气费用 -1                  |
| 阴阳五行（rank_3）      | character.dart:1321   | 回合结束未用灵气转随机元素伤害             |
| 五气朝元（rank_4）      | character.dart:1341   | 回合开始轮流获得单元素增伤                 |
| 万法归宗（rank_5）      | battle.dart:511       | 战斗开始洗入绝世卡                         |
| 紫微斗数（branch_draw_1）| battle.dart:742       | 战斗开始洗入授予卡                         |
| 天道推演（branch_draw_2）| battle.dart:1663      | 回合开始（抽牌前）观星                     |
| 抱真守一（branch_element_1）| character.dart:1268 | 使用元素牌后手牌同元素牌升级               |
| 五行轮转（branch_element_2）| character.dart:1281 | 本回合每用一种新元素灵气 +1                |

问题：每加一个流派节点都要改引擎文件（其余四流派重构时约 40+ 块）；内容逻辑散落；
天赋树本体虽不开放 MOD，但 `passives.json5` 本就是运行时数据——本改造只搬行为代码，不改变树的封闭性。

## 目标

- `battle.dart` / `character.dart` 中不再出现具体内容 id（卡牌/装备/天赋）。
- 天赋与装备的战斗行为统一经「被动携带 `battleStatus` → 战斗开始授予永久状态 → 状态脚本」路径实现。
- 所有新增 Dart 机制参数化（读数据字段），同时服务天赋与装备（装备词条与天赋被动共用 `game.passives` 数据管线）。

**范围准则**：只有战斗中**反复触发**的行为效果才制作永久状态（回合开始/结束、用牌后、观星后等时机）。
纯属性/单值修改（攻防、抗性、伤害增加等装备词条式被动）**不建状态**——走 stats 聚合管线
（`battle_entity.ht` 聚合 → `kStatsToPermanentEffects` 转图标，图标仅展示净值，无脚本回调）。
一次性动作（战斗开始洗入牌库）与机制参数（费用修正、观星深度、资源保留上限）走泛化数据字段，同样不建状态。

## 阶段 1：通用机制（Dart，全部数据驱动）

> 涉及**新增 stat** 的机制，需同步 stats 管线五处（passives.json5 → passive.json → `characterCalculateStats` → stats.dart → character.json），流程见 `.agents/skills/passive-status` 第 6 节。

- [x] 1. **`battleStatus` 绑定机制**：被动数据支持 `battleStatus: "<statusId>"` 字段，战斗开始（`_prepareBattleStart`，battle.dart:241）授予对应永久状态（`isPermanent` 状态数据，amount 取被动 value）。天赋/装备统一绑定入口，后续阶段依赖本项。
- [x] 2. **产出阶段时机** `self/opponent_produce_resources`：在 `produceTurnStartResources` 末尾分发（character.dart:686 附近）。服务：太上感应、聚灵旗回合开始灵气。
- [x] 3. **观星时机** `self_scry`：Dart 观星结算完成后分发（battle.dart:1094 附近），details 携带 `{count, chosen}`。服务：窥天镜观星后自施异常。
- [x] 4. **观星深度 stat `scryBonus`**（新增 stat，走 stats 管线五处同步）：scry 调用点读取 `stats['scryBonus']` 作为额外查看张数。服务：窥天镜。
- [x] 5. **回合级临时费用机制**：参照 attune 的 `costReduction` 记录-还原（card_script.ht:518-543），作用域改为回合（回合结束统一还原）。服务：天机盘「抽到的非悟道牌本回合 +1 费」。
- [x] 6. **资源保留机制**：回合结束资源结算与清空逻辑（`_settleTurnEndResources`，character.dart:1320）读取 `energyRetain: {resourceId, max, costPerPoint, costDamageType}` 字段（蓄灵佩是唯一来源，结构化字段即可；将来若需多来源叠加或属性面板可见，再拆为独立 stat 走 stats 管线）。服务：蓄灵佩。
- [x] 7. **组牌费用修正泛化**：被动字段 `deckCostReduction: {color, amount, genres?, notGenres?}`，getDeck 阶段统一应用。替代 battle.dart:352 的 `spellcraft_rank_2` 硬编码；聚灵旗用 `notGenres: ['spellcraft'], amount: -2`。
- [x] 8. **洗入牌库泛化**：被动字段 `shuffleIntoDeck: [cardId, ...]`。替代 battle.dart:511（万法归宗）与 battle.dart:742（紫微斗数）。
- [x] 9. **回合开始观星泛化**：被动字段 `turnStartScry: count`。替代 battle.dart:1663（天道推演）。

## 阶段 2：现有硬编码迁移（Hetu 状态脚本）

每个迁移 = 新状态（status_effect.json5 + 本地化 + 图标）+ 状态脚本 + 被动挂 `battleStatus` + 删除 Dart 硬编码。
完整流程（含图标生成步骤）见 `.agents/skills/passive-status` skill。

- [x] 10. **阴阳五行（rank_3）→ `self_turn_end` 状态脚本**。【试点，最先做】伤害用 `changeLife` 同步结算（状态脚本非阻塞约束，不走 async 的 takeDamage）。
- [x] 11. **五气朝元（rank_4）→ `self_turn_start` 状态脚本**；轮换进度存在状态实例数据上（effect 自定义字段，跨回合持久）。
- [x] 12. **五行轮转（branch_element_2）→ `self_used_card` 状态脚本**：`getLastUsedCard()` 读元素 + `turnFlags['usedElements']` 判断是否新元素（usedElements 的无条件记录留 Dart，记录点早于 `self_used_card` 分发，顺序可用）。
- [x] 13. **抱真守一（branch_element_1）→ `self_used_card` 状态脚本**。**阻塞点**：升级手牌走 `upgradeHandCards`（async，带跳字与卡面刷新），与状态脚本非阻塞约束冲突。需先决策：提供同步降级路径（无动画升级），或该节点保留 Dart（泛化为字段）。→ 已解决：`upgradeHandCards` 实现体内无 await（升级/跳字/刷新均同步完成），状态脚本不 await 调用是安全的。
- [x] 14. **太上感应（rank_1）→ 产出阶段时机状态脚本**（依赖阶段 1.2；必须在清残留之后发放，现有 `self_turn_start` 时机太早）。

## 阶段 3：清理

- [x] 15. `status_script.ht` 头部时机列表注释更新：`use_card_genre_*` / `use_card_kind_*` 无 Dart 分发点（陈旧），现行模式 = 通用时机 + 脚本内 `details.kind` 过滤。
- [x] 16. `card_script.ht:100` 等处对 `plan/skill_tree/spellcraft_extra_affix_rework.md` 的陈旧引用改为 `spellcraft.md`。
- [x] 17. `docs/docs/mod/battle/` 契约文档同步（时机列表、被动字段约定）。

## 决策点（实施前确认）

1. 迁移后的永久状态**默认可见**（图标 + tooltip）；天赋节点迁移会新增状态图标。若个别需不可见，再加 `isHidden` 渲染标志。
2. 状态回调顺序 = 授予顺序；迁移后节点间相互作用（如太上感应产灵气 → 五气朝元增伤）的顺序需与原实现核对。
3. 敌我对称：状态总线敌我都跑；NPC 拥有被动/装备时同样生效，数值设计需有预期。

## 验证

- 脚本改动：`python build.py`（hetu PATH 问题时用 dart install 绝对路径的 hetu.bat）。
- Dart 改动：`flutter analyze`。
