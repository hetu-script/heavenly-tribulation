# Phase 1 报告：数据层

> 所属计划：`plan-battle_qi_cost_rework.md` §8 Phase 1

## 任务完成情况

**1. status_effect.json5** ✅

- 20 处 icon 死链全部按 §5 映射表修复（6 阳气 → `icon/cost/qi_*.png`，死气 → `icon/status/decay.png`，5 资源阴气 → 对应阳气 cost 图标，8 中立气 → `status_placeholder.png`）。

- 新增 `tribulation` 条目（非资源、`isDebuff: true`、`callbacks: ["self_turn_start"]`、`script: "tribulation"`、placeholder 图标）。

**2. status_script.ht** ✅ 新增 `tribulation_self_turn_start`（status_script.ht:431-437），逐行复刻 `energy_negative_life_self_turn_start` 的行为（回合开始 -10% 生命上限，消耗 1 层）；死气回调本身未动。

**3. kOppositeStatus 收窄** ✅ lib/scene/battle/common.dart:28-39，仅保留 life/spell/weapon/unarmed/curse/ultimate 6 对，移除 penetrate/crit/ward/shield 4 对。

**4. 本地化** ✅ `status_energy_positive_shield`→"buff_shield/护盾"、`status_energy_positive_crit`→"buff_crit/幸运"（名称 + 描述内自称 + 阳气总览行同步）；护盾/幸运/4 阴性的描述核对后无需改动（本无资源措辞）；新增 `status_tribulation` / `status_tribulation_description`，文案按任务给定。

**5. 常量三处同步** ✅ `kGenreCostColors` / `kCostColorStatusIds` / `kWildcardStatusId`，位于 lib/data/common.dart:364-383（紧随 kGenreToAttribute），按既有模式导出到 lib/data/constants.dart（`Constants.genreCostColors` 等）和 scripts/main/binding/constants.ht。

**6. costChi 校验** ✅ lib/data/game.dart — `init()` 加载 cards.json5 后调用新增私有方法 `_validateBattleCardCostChi()`（game.dart:518-569）：校验 ① 费用色 ∈ 四色（`isUnique` 卡豁免）② 数值合法性 ③ `cost + ΣcostChi = rank + 1`（cost 缺省推导：有流派卡 ⌊(rank+1)/2⌋、无流派卡 rank+1）。全部只 `engine.warning`，不中断加载。当前无任何卡牌含 costChi，零触发。

**自查（任务 6）**：lib/ 下 `energy_positive` 使用点全部核对——`character.dart` 的 `getResourceColor` 只是颜色映射且仅在 `isResource` 分支调用，`resourceEffects/otherEffects` 按 flag 动态过滤，无硬编码全列表；`startsWith('energy_positive')` 的获得回调对 4 中立阳气的触发行为与旧版一致（保留）；`battle.dart` 的 `kStatusOnCircumstance` 是天赋注入池、与资源属性无关，无需改；`card_script.ht` 两处 `gain_buff` 仅调 `addStatusEffect`，对非资源状态同样有效，确认无碍。battle.dart:973 死气自动叠层按计划留待 Phase 3。

## 修改文件清单

`assets/data/status_effect.json5`、`assets/locale/zh/rpg/status_effect.json`、`lib/scene/battle/common.dart`、`lib/data/common.dart`、`lib/data/constants.dart`、`lib/data/game.dart`、`scripts/main/cardgame/status_script.ht`、`scripts/main/binding/constants.ht`，及构建产物 `assets/mods/main.mod`、`assets/mods/story.mod`（story 源码未变，系整编重建）。
