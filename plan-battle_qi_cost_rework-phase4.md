# Phase 4 报告：战斗 UI 代码部分

> 所属计划：`plan-battle_qi_cost_rework.md` §8 Phase 4（卡面 pip 渲染按计划暂缓，人工后续）

## 验收结果

- `dart analyze lib`：**No issues found**。
- 本 Phase 未改 hetu 脚本，无需重新编译（`main.mod`/`story.mod` 保持 Phase 3 产物）。
- locale JSON 校验通过。

## 任务完成情况

**4.1 阴气反色显示** ✅

- `lib/scene/battle/common.dart` 新增 `kNegativeResourceQi` 集合与 `isNegativeResourceQi(String)` 判定 helper（6 种资源阴气，含死气）。
- `lib/scene/battle/status_effect.dart`：`StatusEffect.render` 对资源阴气用 `ColorFilter.matrix` 反色矩阵渲染（矩阵常量 `kNegativeQiInvertMatrix` 同文件顶部），惰性缓存画笔；层数文字不受影响。lib/widgets/ 下无状态图标渲染，无需额外处理。悬浮说明维持现状（显示阴气自身名称/描述）。

**4.2 手牌置灰 + 缺少提示** ✅

- 项目原先没有任何手牌置灰逻辑（计划中"现逻辑只查能量"实不存在，`battle.dart` 里只有注释掉的自动结束回合代码），本次为全新实现。
- `battle.dart` 新增 `refreshHandAffordability()`：不可支付（复用 Phase 2 `_canPayCardCost`，含无色+有色+阴气增费+队列占用）且未入队的卡牌以灰度 `ColorFilter`（`kCardGrayscaleFilter`）置灰；**非己方回合整手置灰**。调用点：回合开始产出后、入队后、每张牌打出后、队列结算完毕后、回合归属切换后。
- 未用引擎 `GameCard.isEnabled` setter——查明它会 `getPaint('invalid')` 而 'invalid' 画笔从未注册，直接调用会抛 ArgumentError（引擎陷阱）；改为操作 `card.paint.colorFilter`，置灰只影响卡面图像，文字与悬浮仍可用。
- 缺少提示：`hand_zone.dart` 新增 `onHoverDescription` 回调钩子（默认行为不变）；`battle.dart` 挂接后，置灰卡悬浮时在原描述顶部加红色缺失行（每行一种资源）：`battlecard_cost_lacking_hint` = "{0}不足：需要 {1}，拥有 {2}"（键在 battlecard.json）。"拥有"按 本色存量 + 无极存量 计算。
- 附带修复（偏离 1）：`_enqueueCard` 增加 `if (!heroTurn) return;` 守卫——旧代码在对方回合也能入队出牌（能量残留不清零导致），统一生命周期下资源跨回合可见，此漏洞影响放大，必须堵住。

**4.3 支付反馈** ✅ `_payCardCost` 成功路径：每扣一种气弹一个负量跳字（"剑气 -2"，用 `getResourceColor` 着色），无极之气抵扣部分单独弹（"无极之气 -1"）。复用现有 `addHintText`，无飞行动画。

**4.4 能量瓶与 0 费徽章** ✅

- `energy_display.dart`：图标换用 `icon/cost/qi_basic.png`（原 bottle 四图标弃用；无空瓶变体，0 时同图标、数字显示 0——限制见下）。
- `game.dart` `createBattleCard`：`cost == 0 && qiCost 非空` 时 `showCostNumber` 置 false 且 `costIconSpriteId` 传 null（引擎 `showCostIcon` 自动随 null 关闭），全有色卡不再显示 "0" 徽章。

## 修改文件

`lib/scene/battle/common.dart`、`status_effect.dart`、`hand_zone.dart`、`energy_display.dart`、`battle.dart`、`lib/data/game.dart`、`assets/locale/zh/rpg/battlecard.json`。卡面 pip 渲染（引擎 CustomGameCard）按计划未动。

## 偏离与限制

1. **heroTurn 入队守卫**（见 4.2），属 bug 修复性质。
2. **置灰只作用于卡面精灵**：引擎的屏幕文字（费用数字、标题）不走 `paint`，置灰卡上文字仍彩色；提示信息由悬浮承担。
3. **能量瓶无"空"态变体**：qi_basic.png 只有一种，元气为 0 时图标不变仅数字为 0（原 empty 瓶图标已弃用且无替代美术）。
4. **缺少提示的多色无极共享近似**：两个颜色同时缺无极时，提示按各色独立"本色+无极"计算，与 `_canPayCardCost` 的聚合判定可能有边缘出入（提示仅为辅助，入队判定以 `_canPayCardCost` 为准）。
5. 反色矩阵为全 RGB 反转（计划原文"程序化反色"），若实测观感不佳可一行换成 `BlendMode.darken` 深底方案。

## 用户实测清单

1. **阴气反色**：持有死气/逆灵/止戈/非战/无心/虚空之一时，资源栏该图标应为反色版（死气 decay.png 同样反色）；与对应阳气互斥同槽。
2. **置灰**：元气不够或有色不够的手牌整卡灰显；对方回合整手置灰；回合开始产出后/出牌后灰显实时刷新；入队牌保持高亮不灰。
3. **缺少提示**：灰卡悬浮显示红色"XX不足：需要 N，拥有 M"（多色缺则多行），下方接原卡描述；可支付的卡不显示缺失行。
4. **支付跳字**：打出有色费用卡时角色头顶弹"剑气 -1"等着色跳字，仅无极抵扣时弹"无极之气 -N"。
5. **0 费徽章**：`kick_attack_exhaust_rage` 等全有色卡右上角无数字徽章，描述区有"另需：怒气×2"。
6. **能量瓶**：显示元气层数数字，图标为 qi_basic；支付后数字实时减少。
