# Phase 0 报告：清理（主代理直接执行）

> 所属计划：`plan-battle_qi_cost_rework.md` §8 Phase 0

## 改动清单

1. **删除已注释的流派限制代码**：`lib/logic/logic.dart` 原 607-625 行（`checkRequirements` 中被注释的 genre 检查块，2026-05-15 注释后卡牌已无流派限制，本次正式删除）。
2. **删除死代码 `kResourceHasNegatives`**：`lib/scene/battle/character.dart` 原 26-37 行（全仓仅定义处引用，已无使用方）。
3. **修正过时注释**：`lib/scene/battle/character.dart` 原 438-441 行 `removeStatusEffect` 的 doc 注释（原描述的是已移除的"差额转阴气"旧行为），改为描述现状："资源类状态为全有或全无：存量不足时一点也不移除，返回 0"。
4. **修复 `enable_mana` 无效调用**：该被动词条存在于 passives.json5:785 且在天赋树上（passive_skills.json5:118），本地化文案为"回合结束时若灵气小于上限则获得 1 点灵气"，但对应状态条目在 status_effect.json5 中缺失，导致 battle.dart 的 addStatusEffect 静默失败（玩家点了天赋却毫无效果）。修复方式（选择"修复"而非"移除"）：
   - `assets/data/status_effect.json5`：新增 `enable_mana` 状态条目（isPermanent、icon 用 icon/cost/qi_mana.png、callbacks: ["self_turn_end"]）。
   - `scripts/main/cardgame/status_script.ht`：新增 `enable_mana_self_turn_end` 函数（灵气 < manaMax 时 +1 灵气，manaMax 读 `self.data.stats.manaMax`）。
   - `lib/scene/battle/battle.dart` 的注入调用保持不变（状态补齐后自然生效）。
   - 注：Phase 3 统一生命周期改造时此回调已改为回合开始结算（见 Phase 3 报告偏离说明 1）。
5. **怒气双重减半删一处**：原设计中怒气回合结束有两处减半（资源自身回调 + enable_rage 回调），带 enable_rage 天赋时一回合衰减到 1/4。删除 `status_script.ht` 的 `enable_rage_self_turn_end`，并从 status_effect.json5 的 enable_rage 条目 callbacks 中移除 `"self_turn_end"`；保留资源自身回调 `energy_positive_unarmed_self_turn_end`（该处在 Phase 3 被新模型整体移除）。

## 遗留（按计划归后续 Phase）

- `cultivation.dart:1689` 突破后 `rank = difficulty` 疑似应为 +1（不在本计划范围内，未动）。
- `self_deck_end` 回调 Dart 侧从未派发（Phase 3 已清理）。
